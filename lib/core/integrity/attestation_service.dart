import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the platform concluded about this device and build.
///
/// The names match the server's `devices.attest_verdict` values, but the client's copy
/// is only ever a hint sent along for logging — the server re-derives the verdict by
/// verifying the token itself, and treats an unverified token as [unavailable].
enum AttestationVerdict {
  /// The platform issued a token. Whether it means anything is the server's call.
  genuine('genuine'),

  /// The platform could not answer: a simulator, an old OS, a build that did not come
  /// from the store. Reduced weight, not zero — a demo on a simulator must still work.
  unavailable('unavailable'),

  /// The platform answered, and the answer was no: an emulator, a rooted device, a
  /// patched binary.
  failed('failed');

  const AttestationVerdict(this.wireName);

  final String wireName;

  static AttestationVerdict fromWire(String? value) => switch (value) {
    'genuine' => genuine,
    'failed' => failed,
    // Unknown values fall through rather than throwing: a newer native side must not
    // break an older Dart one.
    _ => unavailable,
  };
}

class Attestation {
  const Attestation({required this.verdict, required this.token});

  static const Attestation unavailable = Attestation(
    verdict: AttestationVerdict.unavailable,
    token: null,
  );

  final AttestationVerdict verdict;

  /// The platform-issued token: an App Attest assertion on iOS, a Play Integrity token
  /// on Android. Opaque here; only the server can say what it is worth.
  final String? token;
}

/// Asks the platform to vouch for this build, binding the answer to a server-issued
/// nonce so the result cannot be replayed.
///
/// Everything this class returns is untrusted by design. It exists so the server has
/// something to verify, not so the client can decide anything.
class AttestationService {
  AttestationService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('stingers/integrity');

  final MethodChannel _channel;

  Future<Attestation> attest(String nonce) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('attest', {
        'nonce': nonce,
      });
      if (result == null) return Attestation.unavailable;
      return Attestation(
        verdict: AttestationVerdict.fromWire(result['verdict'] as String?),
        token: result['token'] as String?,
      );
    } on MissingPluginException {
      // No native implementation on this platform yet. Expected, not an error.
      return Attestation.unavailable;
    } on PlatformException catch (e) {
      debugPrint('attestation unavailable: ${e.code} ${e.message}');
      return Attestation.unavailable;
    }
  }
}
