/// Abstract adapter for any key-value storage backend.
///
/// Implement this for your storage solution and pass it to
/// `BlackBox.setup(storageAdapters: [...])`.
///
/// ## Privacy & Sensitive Data
///
/// By default, keys matching common sensitive patterns (password, token,
/// secret, pin, etc.) are **automatically redacted** in the Storage panel.
/// Values are replaced with `••••••••` and cannot be copied or edited.
///
/// Customize this by overriding [sensitiveKeyPatterns]:
///
/// ```dart
/// class MyStorageAdapter implements BlackBoxStorageAdapter {
///   @override
///   List<String> get sensitiveKeyPatterns => [
///     ...BlackBoxStorageAdapter.defaultSensitivePatterns,
///     'api_key',        // your custom patterns
///     'credit_card',
///   ];
///   // ...
/// }
/// ```
///
/// Or disable redaction entirely:
/// ```dart
/// @override
/// List<String> get sensitiveKeyPatterns => [];
/// ```
///
/// Built-in: [SharedPrefsStorageAdapter]
abstract class BlackBoxStorageAdapter {
  /// Human-readable name shown in the Storage panel tab header.
  /// e.g. "SharedPreferences", "SecureStorage", "GetStorage", "Hive"
  String get name;

  /// Patterns used to detect sensitive keys that should be redacted.
  ///
  /// A key is considered sensitive if it **contains** any of these patterns
  /// (case-insensitive). Override to add custom patterns or disable.
  ///
  /// Default patterns cover: password, token, secret, pin, auth, key, bearer,
  /// credential, session, cookie, api_key, private, otp, cvv, ssn.
  List<String> get sensitiveKeyPatterns => defaultSensitivePatterns;

  /// Default set of patterns that match most sensitive storage keys.
  static const defaultSensitivePatterns = [
    'password',
    'passwd',
    'pass_',
    'token',
    'secret',
    'pin',
    'auth',
    'bearer',
    'credential',
    'session',
    'cookie',
    'api_key',
    'apikey',
    'private',
    'otp',
    'cvv',
    'ssn',
    'encryption',
    'biometric',
    'fingerprint',
    'face_id',
    'refresh_token',
    'access_token',
    'jwt',
  ];

  /// Checks if a key matches any sensitive pattern.
  bool isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return sensitiveKeyPatterns.any(
      (pattern) => lowerKey.contains(pattern.toLowerCase()),
    );
  }

  /// Reads all currently stored key-value pairs from the backend.
  Future<Map<String, dynamic>> readAll();

  /// Writes (or overwrites) a value for the given [key].
  Future<void> write(String key, dynamic value);

  /// Deletes a single [key] from storage.
  Future<void> delete(String key);

  /// Deletes all data managed by this adapter.
  Future<void> clear();
}
