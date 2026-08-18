import { assertEquals, assertThrows } from 'jsr:@std/assert@1';
import { InvalidRequest, parseVoteRequest } from './vote_request.ts';

const valid = {
  tmdb_id: 1234,
  install_id: 'abcdefgh12345678',
  platform: 'ios',
  has_scene: true,
  worth_it: false,
  nonce: 'n'.repeat(32),
};

function rejects(body: Record<string, unknown>, because: string) {
  assertThrows(() => parseVoteRequest(body), InvalidRequest, undefined, because);
}

Deno.test('accepts a well-formed vote', () => {
  const parsed = parseVoteRequest({ ...valid });

  assertEquals(parsed.tmdb_id, 1234);
  assertEquals(parsed.has_scene, true);
  assertEquals(parsed.worth_it, false);
  // Absent rather than null in the body: both mean "the platform said nothing".
  assertEquals(parsed.attestation_token, null);
  assertEquals(parsed.attestation_verdict, null);
});

Deno.test('a missing worth_it is null, not undefined', () => {
  const { worth_it: _, ...body } = valid;

  assertEquals(parseVoteRequest(body).worth_it, null);
});

Deno.test('a no-scene vote cannot carry a worth-it answer', () => {
  // The database says the same thing with worth_it_only_with_scene; this is so the
  // caller gets a readable message instead of a constraint violation.
  rejects(
    { ...valid, has_scene: false, worth_it: true },
    'worth_it must be null without a scene',
  );
  assertEquals(
    parseVoteRequest({ ...valid, has_scene: false, worth_it: null }).worth_it,
    null,
  );
});

Deno.test('tmdb_id must be a positive integer', () => {
  for (const tmdb_id of [0, -1, 1.5, '1234', null, undefined, Number.NaN]) {
    rejects({ ...valid, tmdb_id }, `tmdb_id ${tmdb_id}`);
  }
});

Deno.test('install_id is bounded at both ends', () => {
  rejects({ ...valid, install_id: 'short' }, 'too short to be an id');
  rejects({ ...valid, install_id: 'x'.repeat(129) }, 'probing the column width');
  assertEquals(
    parseVoteRequest({ ...valid, install_id: 'x'.repeat(128) }).install_id.length,
    128,
  );
});

Deno.test('platform must be one the app actually ships', () => {
  rejects({ ...valid, platform: 'ios ' }, 'not trimmed');
  rejects({ ...valid, platform: 'IOS' }, 'wrong case');
  rejects({ ...valid, platform: 'fuchsia' }, 'a platform with no client');
  for (const platform of ['ios', 'android', 'macos', 'windows', 'linux', 'web']) {
    assertEquals(parseVoteRequest({ ...valid, platform }).platform, platform);
  }
});

Deno.test('a nonce that is too short to be one is refused', () => {
  rejects({ ...valid, nonce: 'abc' }, 'guessable length');
  rejects({ ...valid, nonce: undefined }, 'absent');
});

Deno.test('the claimed attestation verdict is carried through, never interpreted', () => {
  // The client can say anything here; the server re-derives the real verdict from the
  // token. This only checks that a lie is recorded rather than acted on.
  const parsed = parseVoteRequest({
    ...valid,
    attestation_verdict: 'genuine',
    attestation_token: 'not-a-real-token',
  });

  assertEquals(parsed.attestation_verdict, 'genuine');
  assertEquals(parsed.attestation_token, 'not-a-real-token');
});

Deno.test('a non-string attestation field degrades to null instead of throwing', () => {
  const parsed = parseVoteRequest({
    ...valid,
    attestation_verdict: 7,
    attestation_token: {},
  });

  assertEquals(parsed.attestation_verdict, null);
  assertEquals(parsed.attestation_token, null);
});
