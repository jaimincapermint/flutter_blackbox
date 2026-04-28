/// Severity levels for categorizing log messages.
enum LogLevel {
  /// Extremely detailed messages, usually for low-level debugging.
  verbose,

  /// Typical debug messages for development.
  debug,

  /// Descriptive messages about application state changes.
  info,

  /// Indicators of potential issues that are not yet errors.
  warning,

  /// Error messages for failed operations and crashes.
  error;

  String get label => switch (this) {
        LogLevel.verbose => 'VERBOSE',
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warning => 'WARN',
        LogLevel.error => 'ERROR',
      };

  /// ANSI color for terminal output (informational only).
  String get emoji => switch (this) {
        LogLevel.verbose => '⬜',
        LogLevel.debug => '🟦',
        LogLevel.info => '🟩',
        LogLevel.warning => '🟧',
        LogLevel.error => '🟥',
      };
}
