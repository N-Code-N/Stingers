package com.example.stingers

import android.annotation.SuppressLint
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Native half of the `stingers/integrity` channel.
///
/// `installId` is `ANDROID_ID`, which since Android 8.0 is scoped to the app's signing
/// key and therefore survives an uninstall and reinstall while staying different for
/// every app on the device. That survival is the point: votes are counted per device
/// because an anonymous account can be minted in a loop (PROJECT_PLAN.md §6, layer 5).
///
/// `attest` is not implemented. Play Integrity needs a Play Console app and a cloud
/// project number, and a server able to exchange the token with Google; until that
/// exists the Dart side treats the missing method as `unavailable`, which is a designed
/// state, not a failure.
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "stingers/integrity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installId" -> result.success(installId())
                    else -> result.notImplemented()
                }
            }
    }

    /// Returns null rather than throwing; the Dart side has its own fallback and must
    /// not break on a device that reports no id at all.
    @SuppressLint("HardwareIds")
    private fun installId(): String? =
        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
            ?.takeIf { it.isNotBlank() && it != "9774d56d682e549c" }
    // That literal is a known bad value: a firmware bug made a large number of
    // devices report it, so treating it as an identity would merge them all.
}
