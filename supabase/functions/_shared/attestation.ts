// Device attestation — the layer that proves a request came from an unmodified build of
// this app on real hardware.
//
// The one rule this file exists to enforce:
//
//   **A token that has not been verified server-side never yields 'genuine'.**
//
// The client reports what its platform told it. That report is worth nothing on its own
// — the attacker owns the binary and can send any string they like. The verdict below is
// derived from verifying the token against Apple or Google, or it is 'unavailable'.
//
// STATUS: the two verification calls are not implemented, because each needs credentials
// that do not exist yet:
//
//   * Android — Play Integrity: decoding a token is a call to
//     `playintegrity.googleapis.com/v1/{package}:decodeIntegrityToken`, authorised by a
//     GCP service account. Needs a Play Console app and a service-account key.
//     The verdict comes from `deviceIntegrity.deviceRecognitionVerdict`:
//     `MEETS_DEVICE_INTEGRITY` -> genuine; an empty list (an emulator, a rooted phone)
//     -> failed.
//
//   * iOS — App Attest: verifying an assertion means parsing the CBOR attestation
//     object, validating Apple's certificate chain against their root, checking the
//     nonce hash and the app id, then tracking the key's counter. Needs the team id and
//     bundle id, and it is not code worth writing blind.
//
// Until then every device lands on 'unavailable', which is worth 0.3 weight rather than
// 1.0 (see trust.ts). That is the designed behaviour for "attestation could not answer",
// so the app is fully functional and honestly weighted in the meantime — it just cannot
// yet tell an emulator apart from an old iPhone.

import type { AttestVerdict } from './trust.ts';

export interface AttestationClaim {
  /// What the client says its platform concluded. Logged, never trusted.
  claimedVerdict: string | null;
  /// The platform-issued token, to be verified against Apple or Google.
  token: string | null;
  /// The nonce the token should be bound to.
  nonce: string;
}

export async function verifyAttestation(
  platform: string,
  claim: AttestationClaim,
): Promise<AttestVerdict> {
  if (!claim.token) return 'unavailable';

  switch (platform) {
    case 'android':
      return await verifyPlayIntegrity(claim);
    case 'ios':
      return await verifyAppAttest(claim);
    default:
      return 'unavailable';
  }
}

function verifyPlayIntegrity(_claim: AttestationClaim): Promise<AttestVerdict> {
  if (!Deno.env.get('PLAY_INTEGRITY_SERVICE_ACCOUNT')) {
    return Promise.resolve('unavailable');
  }
  // Deliberately not implemented against absent credentials — see the note above.
  console.warn('Play Integrity verification is not implemented; treating as unavailable');
  return Promise.resolve('unavailable');
}

function verifyAppAttest(_claim: AttestationClaim): Promise<AttestVerdict> {
  if (!Deno.env.get('APP_ATTEST_TEAM_ID')) return Promise.resolve('unavailable');
  console.warn('App Attest verification is not implemented; treating as unavailable');
  return Promise.resolve('unavailable');
}
