import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import 'integrity_channel.dart';

/// Who the *device* is — which, for counting votes, matters more than who the user is.
///
/// An anonymous account is free to mint, so the account cannot be the unit of counting.
/// A device identity that survives a reinstall can still be reset by a factory wipe, but
/// it raises the cost of a farm from "a loop" to "a drawer full of phones", and that is
/// the whole aim (PROJECT_PLAN.md §6, layer 5).
///
/// Three sources, in descending order of how hard they are to forge:
///  1. the native channel — Keychain UUID on iOS, `ANDROID_ID` on Android, both of which
///     outlive an uninstall;
///  2. a random id persisted in the local database, which does not;
///  3. a per-process id, if even the database is unavailable.
///
/// The server never trusts this value on its own — it is a key, not a credential.
/// Attestation (phase 6) is what makes claiming someone else's id pointless.
class InstallIdentity {
  InstallIdentity({required AppDatabase db, MethodChannel? channel})
    : _db = db,
      _channel = channel ?? integrityChannel;

  final AppDatabase _db;
  final MethodChannel _channel;

  String? _cached;

  /// `kIsWeb` is checked first on purpose: in a browser `defaultTargetPlatform` reports
  /// the *host* OS, so Safari on an iPhone would claim to be iOS — and an iOS build is
  /// exactly what a browser cannot attest to.
  String get platform => kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'ios',
          TargetPlatform.android => 'android',
          TargetPlatform.macOS => 'macos',
          TargetPlatform.windows => 'windows',
          TargetPlatform.linux => 'linux',
          TargetPlatform.fuchsia => 'fuchsia',
        };

  Future<String> installId() async {
    final cached = _cached;
    if (cached != null) return cached;

    // Never logged, not even in debug. It is the key the server counts votes by, so a
    // copy of it in a console, a screenshot or a CI log is a copy of this device's vote.
    return _cached = await _resolve();
  }

  Future<String> _resolve() async {
    final native = await _fromPlatform();
    if (native != null && native.length >= 8) return native;

    final stored = await _db.readSetting(SettingKeys.installId);
    if (stored != null && stored.length >= 8) return stored;

    final generated = _randomId();
    await _db.writeSetting(SettingKeys.installId, generated);
    return generated;
  }

  /// Absent until the native side lands in phase 6; a missing implementation is the
  /// expected case, not an error.
  Future<String?> _fromPlatform() async {
    try {
      return await _channel.invokeMethod<String>('installId');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static String _randomId() {
    final random = Random.secure();
    return List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
  }
}
