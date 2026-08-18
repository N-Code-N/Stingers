// `tmdb` — a narrow read-only proxy in front of api.themoviedb.org.
//
// Contract: GET /functions/v1/tmdb/<tmdb-path>?<allowed-query>
// The TMDb JSON envelope is passed through unchanged; the client models it directly.
//
// Two things make this a proxy rather than a relay:
//   * a path allowlist — an open proxy is an SSRF primitive and a way to run someone
//     else's traffic through your quota;
//   * a query allowlist — otherwise the path is constrained but the request isn't.
//
// Side benefit of running on the edge: TMDb's geographic restrictions apply to
// Supabase's egress, not to wherever the developer happens to live.

import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders, fail, preflight } from '../_shared/http.ts';
import { snapshotFrom, tmdbGet, upsertSnapshots } from '../_shared/tmdb.ts';

const ALLOWED_PATHS: RegExp[] = [
  /^\/movie\/now_playing$/,
  /^\/movie\/\d+$/,
  /^\/movie\/\d+\/watch\/providers$/,
  /^\/search\/movie$/,
];

const ALLOWED_QUERY = new Set(['page', 'query', 'region', 'language', 'include_adult']);

const MOVIE_DETAIL = /^\/movie\/(\d+)$/;

Deno.serve(async (req: Request) => {
  const cors = preflight(req);
  if (cors) return cors;

  if (req.method !== 'GET') {
    return fail(405, 'method_not_allowed', 'Only GET is supported');
  }

  const url = new URL(req.url);
  // The function is mounted at /functions/v1/tmdb — everything after that is the TMDb path.
  const path = url.pathname.replace(/^\/+(functions\/v1\/)?tmdb/, '');

  if (!ALLOWED_PATHS.some((allowed) => allowed.test(path))) {
    return fail(404, 'not_found', 'Unsupported path');
  }

  const query = new URLSearchParams();
  for (const [key, value] of url.searchParams) {
    if (ALLOWED_QUERY.has(key)) query.append(key, value);
  }

  let upstream: Response;
  try {
    upstream = await tmdbGet(path, query);
  } catch (e) {
    console.error('tmdb fetch failed', e);
    return fail(502, 'upstream_unavailable', 'TMDb is unreachable');
  }

  const body = await upstream.text();

  if (upstream.ok) {
    const detail = MOVIE_DETAIL.exec(path);
    if (detail) await snapshotDetail(body);
  }

  return new Response(body, {
    status: upstream.status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});

/// Records what the client is about to be able to vote on. Deliberately fire-and-forget
/// in effect: a snapshot failure is logged, never surfaced, because the read succeeded.
async function snapshotDetail(body: string): Promise<void> {
  try {
    const snapshot = snapshotFrom(JSON.parse(body));
    if (!snapshot) return;
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { persistSession: false } },
    );
    await upsertSnapshots(admin, [snapshot]);
  } catch (e) {
    console.error('snapshot failed', e);
  }
}
