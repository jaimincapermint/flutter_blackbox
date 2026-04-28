/// Represents a captured exception or crash.
class CrashEntry {
  CrashEntry({
    required this.id,
    required this.message,
    this.stackTrace,
    this.library,
    required this.timestamp,
    required this.isFlutterError,
  });

  /// Unique identifier for the crash report.
  final String id;

  /// The recorded error message or exception description.
  final String message;

  /// The stack trace captured at the time of the error.
  final StackTrace? stackTrace;

  /// The library where the error originated (if known).
  final String? library;

  /// When the error occurred.
  final DateTime timestamp;

  /// Whether this was a Flutter framework error ([FlutterError]).
  final bool isFlutterError;

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'stackTrace': stackTrace?.toString(),
        'library': library,
        'timestamp': timestamp.toIso8601String(),
        'isFlutterError': isFlutterError,
      };
}
