import { assertAlmostEquals, assertEquals } from 'jsr:@std/assert@1';
import { type AttestVerdict, computeTrust } from './trust.ts';

const hourAgo = new Date('2026-08-16T11:00:00Z');
const now = new Date('2026-08-16T12:00:00Z');
const lastWeek = new Date('2026-08-09T12:00:00Z');

function trust(params: {
  verdict?: AttestVerdict;
  firstSeen?: Date;
  byDevice?: number;
  byIp?: number | null;
}): number {
  return computeTrust({
    firstSeen: params.firstSeen ?? lastWeek,
    verdict: params.verdict ?? 'genuine',
    deviceAcceptedLastHour: params.byDevice ?? 0,
    ipAcceptedLastHour: params.byIp === undefined ? 0 : params.byIp,
    now,
  });
}

Deno.test('a settled, attested device voting normally is worth full weight', () => {
  assertEquals(trust({}), 1);
});

Deno.test('a failed attestation is worth nothing, whatever else is true', () => {
  // This is the one verdict that means "the platform answered, and the answer was no".
  assertEquals(trust({ verdict: 'failed' }), 0);
});

Deno.test('an unattestable device still counts, just not for much', () => {
  // A simulator, an old OS, a build that did not come from the store. Zero here would
  // make the app look broken everywhere attestation is not available yet.
  assertAlmostEquals(trust({ verdict: 'unavailable' }), 0.3, 1e-6);
});

Deno.test('a device minted minutes ago is cheap', () => {
  assertAlmostEquals(trust({ firstSeen: now }), 0.4, 1e-6);
  assertAlmostEquals(trust({ firstSeen: hourAgo }), 0.7, 1e-6);
});

Deno.test('a device voting faster than anyone watches films is discounted', () => {
  assertEquals(trust({ byDevice: 8 }), 1);
  assertAlmostEquals(trust({ byDevice: 9 }), 0.5, 1e-6);
  assertAlmostEquals(trust({ byDevice: 16 }), 0.1, 1e-6);
});

Deno.test('one busy address is tolerated; a flood from it is not', () => {
  // The false positive here is a real audience in a real cinema — a sold-out house
  // lands in the 0.5 tier, not zero — but a farm's next order of magnitude is not.
  assertEquals(trust({ byIp: 12 }), 1);
  assertAlmostEquals(trust({ byIp: 13 }), 0.8, 1e-6);
  assertAlmostEquals(trust({ byIp: 31 }), 0.5, 1e-6);
  assertAlmostEquals(trust({ byIp: 81 }), 0.2, 1e-6);
  assertAlmostEquals(trust({ byIp: 151 }), 0.05, 1e-6);
});

Deno.test('with no address to judge, the ip factor cannot penalise', () => {
  assertEquals(trust({ byIp: null }), 1);
});

Deno.test('the factors multiply, so any one of them can condemn a vote', () => {
  // Unattested (0.3) on a fresh device (0.4) being driven hard (0.1).
  assertAlmostEquals(
    trust({ verdict: 'unavailable', firstSeen: now, byDevice: 20 }),
    0.012,
    1e-6,
  );
});

Deno.test('the result is always a usable weight', () => {
  for (const verdict of ['genuine', 'unavailable', 'failed'] as AttestVerdict[]) {
    const weight = trust({ verdict, firstSeen: now, byDevice: 20, byIp: 200 });
    assertEquals(weight >= 0 && weight <= 1, true, `${verdict} produced ${weight}`);
  }
});
