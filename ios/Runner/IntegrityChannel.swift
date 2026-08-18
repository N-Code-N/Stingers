import Flutter
import Foundation
import Security

/// Native half of the `stingers/integrity` channel.
///
/// `installId` is a UUID kept in the Keychain, because the Keychain survives the app
/// being deleted and reinstalled. That is the whole point: an anonymous account can be
/// minted in a loop, so votes are counted per device, and a device identity worth
/// counting has to outlive a reinstall (PROJECT_PLAN.md §6, layer 5).
///
/// `attest` is not implemented. App Attest needs a real team id and a server able to
/// validate Apple's certificate chain; until that exists the Dart side treats the
/// missing method as `unavailable`, which is a designed state, not a failure.
enum IntegrityChannel {
  static let name = "stingers/integrity"

  private static let keychainService = "com.example.stingers.install"
  private static let keychainAccount = "install_id"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: name,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "installId":
        result(installId())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Reads the stored id, creating one on first launch. Returns nil rather than
  /// throwing — the Dart side has its own fallback and must not be broken by a
  /// Keychain that is unavailable (for example while the device is still locked).
  static func installId() -> String? {
    if let existing = readKeychain() { return existing }

    let generated = UUID().uuidString
    return writeKeychain(generated) ? generated : nil
  }

  private static func readKeychain() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data,
      let value = String(data: data, encoding: .utf8),
      !value.isEmpty
    else { return nil }

    return value
  }

  private static func writeKeychain(_ value: String) -> Bool {
    let attributes: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount,
      kSecValueData as String: Data(value.utf8),
      // Stays on this device only. Syncing it to iCloud would hand every device the
      // same identity, which is precisely the thing being counted.
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    SecItemDelete(attributes as CFDictionary)
    return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
  }
}
