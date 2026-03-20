class CrashEntry {
  CrashEntry({
    required this.id,
    required this.message,
    this.stackTrace,
    this.library,
    required this.timestamp,
    required this.isFlutterError,
  });

  final String id;
  final String message;
  final StackTrace? stackTrace;
  final String? library;
  final DateTime timestamp;
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
