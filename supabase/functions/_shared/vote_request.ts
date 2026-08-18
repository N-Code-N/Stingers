// Request validation for the `vote` function.
//
// Separate from the handler for one reason: the handler calls `Deno.serve` at module
// scope, so importing it from a test would start a server. The rules below are the ones
// worth testing — everything a client can lie about passes through here first.

/// Every client the app ships for. Only `ios` and `android` can ever be attested; the
/// rest are recorded honestly so their votes are weighted as unattestable rather than
/// silently claiming to be a phone.
export const PLATFORMS = new Set(['ios', 'android', 'macos', 'windows', 'linux', 'web']);

export interface ChallengeRequest {
  tmdb_id: number;
  install_id: string;
  platform: string;
}

export interface VoteRequest extends ChallengeRequest {
  has_scene: boolean;
  worth_it: boolean | null;
  nonce: string;
  attestation_token: string | null;
  attestation_verdict: string | null;
}

/// Thrown for anything the client got wrong. Carries a message safe to hand back: it
/// describes the shape of the request, never the state of the system.
export class InvalidRequest extends Error {}

export function parseChallengeRequest(b: Record<string, unknown>): ChallengeRequest {
  return {
    tmdb_id: tmdbId(b.tmdb_id),
    install_id: installId(b.install_id),
    platform: platform(b.platform),
  };
}

export function parseVoteRequest(b: Record<string, unknown>): VoteRequest {
  const nonce = b.nonce;
  if (typeof nonce !== 'string' || nonce.length < 16 || nonce.length > 128) {
    throw new InvalidRequest('nonce is missing');
  }

  const hasScene = b.has_scene;
  if (typeof hasScene !== 'boolean') {
    throw new InvalidRequest('has_scene must be a boolean');
  }

  const worthIt = b.worth_it ?? null;
  if (worthIt !== null && typeof worthIt !== 'boolean') {
    throw new InvalidRequest('worth_it must be a boolean or null');
  }
  // Mirrors the worth_it_only_with_scene check constraint, so a bad body fails with a
  // readable message instead of a Postgres constraint violation.
  if (!hasScene && worthIt !== null) {
    throw new InvalidRequest('worth_it must be null when has_scene is false');
  }

  const token = b.attestation_token;
  const claimed = b.attestation_verdict;

  return {
    ...parseChallengeRequest(b),
    has_scene: hasScene,
    worth_it: worthIt,
    nonce,
    attestation_token: typeof token === 'string' ? token : null,
    attestation_verdict: typeof claimed === 'string' ? claimed : null,
  };
}

function tmdbId(value: unknown): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value <= 0) {
    throw new InvalidRequest('tmdb_id must be a positive integer');
  }
  return value;
}

/// Bounded on both ends: too short is not an id, and too long is someone probing what
/// this column will swallow.
function installId(value: unknown): string {
  if (typeof value !== 'string' || value.length < 8 || value.length > 128) {
    throw new InvalidRequest('install_id must be 8..128 characters');
  }
  return value;
}

function platform(value: unknown): string {
  if (typeof value !== 'string' || !PLATFORMS.has(value)) {
    throw new InvalidRequest('unsupported platform');
  }
  return value;
}
