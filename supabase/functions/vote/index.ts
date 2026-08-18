// `vote` — the only write path in the system.
//
// There is no INSERT/UPDATE policy on `votes`, so this function under service_role is
// the single place where a vote can come into existence, and therefore the single place
// where any control can exist at all. Everything the client says about *who* it is and
// *what film this is* is re-derived here: the user comes from the verified JWT, the film
// from TMDb.
//
// Two endpoints, because a nonce is meaningless outside the flow it protects:
//   POST /vote/challenge  -> issues a single-use nonce bound to (device, film)
//   POST /vote            -> casts the vote
//
// Check order (PROJECT_PLAN.md §6):
//   JWT (who) -> nonce (freshness) -> attestation (authenticity)
//   -> rate limit by device and by IP hash -> upsert the vote -> recompute trust.
//
// The governing idea: a suspicious vote is never rejected, it is made weightless.
// Rejection hands the attacker a debugging signal; HTTP 200 with a weight of zero
// does not. The only thing that *is* rejected outright is a request that cannot be
// processed at all — a missing nonce, an unknown film, a rate limit.
//
// The DB-only steps — device lookup, rate-limit counts, nonce state, the vote write
// itself — are two Postgres round trips (`vote_prepare`, `vote_finalize`), not the
// roughly ten separate queries this used to be. Splitting it there instead of one call
// exists for one reason: whether to spend the nonce depends on a rate-limit decision
// this function makes with the counts `vote_prepare` returns, and a nonce that turns out
// to guard a rejected request must not be burned. See vote_path_functions.sql.

import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';
import { verifyAttestation } from '../_shared/attestation.ts';
import { fail, hashIp, ipHashSecret, json, preflight } from '../_shared/http.ts';
import { snapshotFrom, tmdbGet, upsertSnapshots } from '../_shared/tmdb.ts';
import { type AttestVerdict, computeTrust } from '../_shared/trust.ts';
import {
  InvalidRequest,
  parseChallengeRequest,
  parseVoteRequest,
  type VoteRequest,
} from '../_shared/vote_request.ts';

const VOTES_PER_DEVICE_PER_HOUR = 30;
// A sold-out house is a few hundred seats; this stays above that so a real audience is
// never outright rejected — `ipFactor` in trust.ts is what actually leans on a busy
// address, by weight rather than by refusal.
const VOTES_PER_IP_PER_HOUR = 100;
const CHALLENGE_TTL_SECONDS = 5 * 60;
const CHALLENGES_PER_DEVICE_PER_HOUR = 60;

/// A device id is whatever the caller says it is, so every per-device limit above can be
/// reset by inventing a new one. These are the ceilings that cannot be: they count every
/// attempt from an address, accepted or not, which is what stops a caller with a garbage
/// nonce from writing `vote_attempts` rows all day. Tighter than the accepted-vote cap
/// above on purpose — a real audience casts votes, it does not generate rejected ones.
const CHALLENGES_PER_IP_PER_HOUR = 200;
const ATTEMPTS_PER_IP_PER_HOUR = 300;

Deno.serve(async (req: Request) => {
  const cors = preflight(req);
  if (cors) return cors;

  if (req.method !== 'POST') {
    return fail(405, 'method_not_allowed', 'Only POST is supported');
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );

  // --- who ------------------------------------------------------------------
  const jwt = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!jwt) return fail(401, 'unauthenticated', 'Missing bearer token');

  const { data: userData, error: userError } = await admin.auth.getUser(jwt);
  const userId = userData?.user?.id;
  if (userError || !userId) return fail(401, 'unauthenticated', 'Invalid session');

  const isChallenge = new URL(req.url).pathname.endsWith('/challenge');
  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return fail(400, 'invalid_request', 'Body must be JSON');
  }

  const ipHash = await hashIp(req, ipHashSecret());

  return isChallenge
    ? await issueChallenge(admin, body, ipHash)
    : await castVote(admin, body, userId, ipHash);
});

// ---------------------------------------------------------------------------
// POST /vote/challenge
// ---------------------------------------------------------------------------

async function issueChallenge(
  admin: SupabaseClient,
  body: Record<string, unknown>,
  ipHash: string | null,
): Promise<Response> {
  let request;
  try {
    request = parseChallengeRequest(body);
  } catch (e) {
    if (e instanceof InvalidRequest) return fail(400, 'invalid_request', e.message);
    throw e;
  }

  const { data, error } = await admin.rpc('vote_issue_challenge', {
    p_install_id: request.install_id,
    p_platform: request.platform,
    p_tmdb_id: request.tmdb_id,
    p_ip_hash: ipHash,
    p_ip_limit: CHALLENGES_PER_IP_PER_HOUR,
    p_device_limit: CHALLENGES_PER_DEVICE_PER_HOUR,
    p_ttl_seconds: CHALLENGE_TTL_SECONDS,
  });
  if (error) {
    console.error('issue challenge failed', error);
    return fail(500, 'internal', 'Could not issue a challenge');
  }
  if (data.error) {
    return fail(429, 'rate_limited', 'Too many requests, try again later');
  }

  return json({ nonce: data.nonce as string, expires_at: data.expires_at as string });
}

// ---------------------------------------------------------------------------
// POST /vote
// ---------------------------------------------------------------------------

interface PreparedVote {
  device_id: string;
  blocked_at: string | null;
  first_seen: string;
  trust: number;
  trust_locked: boolean;
  device_accepted_last_hour: number;
  ip_accepted_last_hour: number;
  ip_attempts_last_hour: number;
  nonce_ok: boolean;
  movie_known: boolean;
  existing_weight: number | null;
}

async function castVote(
  admin: SupabaseClient,
  raw: Record<string, unknown>,
  userId: string,
  ipHash: string | null,
): Promise<Response> {
  let body: VoteRequest;
  try {
    body = parseVoteRequest(raw);
  } catch (e) {
    if (e instanceof InvalidRequest) return fail(400, 'invalid_request', e.message);
    throw e;
  }

  // Independent of everything the database has to say, so it runs alongside the first
  // round trip instead of after it.
  const [prepared, verdict] = await Promise.all([
    prepareVote(admin, body, ipHash),
    verifyAttestation(body.platform, {
      claimedVerdict: body.attestation_verdict,
      token: body.attestation_token,
      nonce: body.nonce,
    }),
  ]);
  if (!prepared) return fail(500, 'internal', 'Could not resolve device');

  // --- rate limit, before the nonce is ever spent ------------------------------
  // Checked ahead of the nonce so a caller who is over their limit does not have their
  // challenge consumed on the way to being told no, and a caller sending garbage nonces
  // hits a ceiling rather than writing an audit row per request.
  const limited = isRateLimited(prepared, ipHash);
  if (limited) {
    await logAttempt(
      admin,
      prepared.device_id,
      body.tmdb_id,
      ipHash,
      'rate_limited',
      limited,
    );
    return fail(429, 'rate_limited', 'Too many votes, try again later');
  }

  if (!prepared.nonce_ok) {
    await logAttempt(
      admin,
      prepared.device_id,
      body.tmdb_id,
      ipHash,
      'rejected',
      'bad_nonce',
    );
    return fail(400, 'invalid_request', 'Challenge is missing, expired or already used');
  }

  // --- the film must exist before a vote can reference it ---------------------
  const known = prepared.movie_known || (await ensureMovie(admin, body.tmdb_id));
  if (!known) {
    await logAttempt(
      admin,
      prepared.device_id,
      body.tmdb_id,
      ipHash,
      'rejected',
      'unknown_movie',
    );
    return fail(404, 'not_found', 'Unknown film');
  }

  // --- weigh, then write -------------------------------------------------------
  // A blocked device or a failed attestation still gets a 200 and a stored row — it just
  // weighs nothing, and the silence is deliberate: an attacker who is told "rejected"
  // fixes their script.
  const weight = resolveWeight(prepared, verdict, ipHash);

  const { data, error } = await admin.rpc('vote_finalize', {
    p_device_id: prepared.device_id,
    p_tmdb_id: body.tmdb_id,
    p_user_id: userId,
    p_nonce: body.nonce,
    p_has_scene: body.has_scene,
    p_worth_it: body.worth_it,
    p_weight: weight,
    p_ip_hash: ipHash,
    p_verdict: verdict,
    p_trust_locked: prepared.trust_locked,
    // A changed answer on a film already voted on carries no new weight, so it must
    // not cost the same hourly quota as a new vote — see the column comment on
    // vote_attempts.outcome in vote_path_functions.sql.
    p_is_amendment: prepared.existing_weight !== null,
  });
  if (error) {
    console.error('vote finalize failed', error);
    return fail(500, 'internal', 'Could not store the vote');
  }
  if (data.error) {
    // Lost a race for the same nonce between the prepare peek and this call.
    return fail(400, 'invalid_request', 'Challenge is missing, expired or already used');
  }

  return json(data.stats ?? emptyStats(body.tmdb_id));
}

async function prepareVote(
  admin: SupabaseClient,
  body: VoteRequest,
  ipHash: string | null,
): Promise<PreparedVote | null> {
  const { data, error } = await admin.rpc('vote_prepare', {
    p_install_id: body.install_id,
    p_platform: body.platform,
    p_tmdb_id: body.tmdb_id,
    p_nonce: body.nonce,
    p_ip_hash: ipHash,
  });
  if (error) {
    console.error('vote prepare failed', error);
    return null;
  }
  return data as PreparedVote;
}

/// Returns the reason string when the caller is over a limit, otherwise null.
function isRateLimited(prepared: PreparedVote, ipHash: string | null): string | null {
  if (prepared.device_accepted_last_hour >= VOTES_PER_DEVICE_PER_HOUR) {
    return 'device_hourly';
  }
  if (!ipHash) return null;
  if (prepared.ip_accepted_last_hour >= VOTES_PER_IP_PER_HOUR) return 'ip_hourly';
  // Every attempt, not just the accepted ones. Without this a caller can send an endless
  // stream of unusable requests: each is refused, and each still costs an audit row.
  if (prepared.ip_attempts_last_hour >= ATTEMPTS_PER_IP_PER_HOUR) {
    return 'ip_attempts_hourly';
  }
  return null;
}

/// The film's metadata is never taken from the client. If the snapshot is missing —
/// which a vote queued offline and flushed much later can genuinely hit — it is fetched
/// from TMDb server-side.
async function ensureMovie(admin: SupabaseClient, tmdbId: number): Promise<boolean> {
  try {
    const upstream = await tmdbGet(`/movie/${tmdbId}`, new URLSearchParams());
    if (!upstream.ok) return false;
    const snapshot = snapshotFrom(await upstream.json());
    if (!snapshot) return false;
    await upsertSnapshots(admin, [snapshot]);
    return true;
  } catch (e) {
    console.error('movie backfill failed', e);
    return false;
  }
}

/// What this vote is worth. Four cases, in order of precedence:
///
///  * a blocked device weighs nothing, however well it behaves now;
///  * **an amendment keeps the weight the first answer earned.** Changing your mind is
///    not a new vote, it is a correction to one you already cast, and it should not be
///    re-judged against how the device happens to be behaving an hour later. It also
///    closes the obvious game: re-voting until the weight comes out favourable;
///  * a device whose trust has been locked keeps exactly the value it was given — the
///    point of locking is that nothing recalculates it;
///  * everyone else is measured, every time.
function resolveWeight(
  prepared: PreparedVote,
  verdict: AttestVerdict,
  ipHash: string | null,
): number {
  if (prepared.blocked_at) return 0;
  if (prepared.existing_weight !== null) return prepared.existing_weight;
  if (prepared.trust_locked) return prepared.trust;

  return computeTrust({
    verdict,
    firstSeen: new Date(prepared.first_seen),
    now: new Date(),
    deviceAcceptedLastHour: prepared.device_accepted_last_hour,
    ipAcceptedLastHour: ipHash ? prepared.ip_accepted_last_hour : null,
  });
}

async function logAttempt(
  admin: SupabaseClient,
  deviceId: string | null,
  tmdbId: number,
  ipHash: string | null,
  outcome: string,
  reason: string | null,
): Promise<void> {
  const { error } = await admin.rpc('vote_log_attempt', {
    p_device_id: deviceId,
    p_tmdb_id: tmdbId,
    p_ip_hash: ipHash,
    p_outcome: outcome,
    p_reason: reason,
  });
  if (error) console.error('attempt log failed', error);
}

/// A film with no surviving votes has no row in the view; the client needs a zero state
/// rather than a null it has to special-case.
function emptyStats(tmdbId: number): unknown {
  return {
    tmdb_id: tmdbId,
    raw_votes: 0,
    total_weight: 0,
    scene_weight: 0,
    worth_weight: 0,
    worth_total: 0,
  };
}
