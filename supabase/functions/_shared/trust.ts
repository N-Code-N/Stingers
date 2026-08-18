// Trust weighting — the layer the rest of the anti-abuse design exists to enable.
//
// The idea it is built on: **do not block bad votes, make them weightless.** Blocking
// gives an attacker instant feedback — they see the error, fix the script, retry.
// Weighting gives them HTTP 200 and a vote that silently counts for nothing, and
// debugging something that never answers costs an order of magnitude more.
//
// Every factor below is multiplicative and in 0..1, so any single strong signal can
// zero a vote out and no factor can rescue one that another has condemned.
//
// Pure and synchronous on purpose: the counts it scores are gathered once, by
// `vote_prepare` in Postgres, and handed in. The thresholds stay here, in one language,
// so there is exactly one place that can drift.

export type AttestVerdict = 'genuine' | 'unavailable' | 'failed';

/// 'unavailable' is deliberately not zero. A simulator, an old OS or a build that did
/// not come from the store all land here, and a demo on a simulator must still work —
/// it just does not get to move the numbers much.
function attestFactor(verdict: AttestVerdict): number {
  switch (verdict) {
    case 'genuine':
      return 1.0;
    case 'unavailable':
      return 0.3;
    case 'failed':
      return 0.0;
  }
}

/// A device minted a minute ago is cheap; one that has been around a week is not.
function ageFactor(firstSeen: Date, now: Date): number {
  const hours = (now.getTime() - firstSeen.getTime()) / 3_600_000;
  if (hours < 1) return 0.4;
  if (hours < 24) return 0.7;
  return 1.0;
}

/// Nobody watches fifteen films in an hour. This is what catches a real device being
/// driven by a script.
function rateFactor(votesLastHour: number): number {
  if (votesLastHour > 15) return 0.1;
  if (votesLastHour > 8) return 0.5;
  return 1.0;
}

/// Many devices behind one address is normal (a cinema's wifi, carrier NAT); a farm
/// looks the same shape, just bigger and faster. The tiers below start biting earlier
/// than a single screening's audience would ever hit — a sold-out 300-seat house voting
/// inside the same hour lands in the 0.5 tier, not zero, because a real audience is
/// exactly the false positive this can't afford. What it does kill is the next order of
/// magnitude: a hundred-plus votes from one address is not a full cinema, it's a script.
function ipFactor(votesFromIpLastHour: number): number {
  if (votesFromIpLastHour > 150) return 0.05;
  if (votesFromIpLastHour > 80) return 0.2;
  if (votesFromIpLastHour > 30) return 0.5;
  if (votesFromIpLastHour > 12) return 0.8;
  return 1.0;
}

export function computeTrust(params: {
  verdict: AttestVerdict;
  firstSeen: Date;
  now: Date;
  deviceAcceptedLastHour: number;
  ipAcceptedLastHour: number | null;
}): number {
  const trust = attestFactor(params.verdict) *
    ageFactor(params.firstSeen, params.now) *
    rateFactor(params.deviceAcceptedLastHour) *
    ipFactor(params.ipAcceptedLastHour ?? 0);

  return Math.min(1, Math.max(0, trust));
}
