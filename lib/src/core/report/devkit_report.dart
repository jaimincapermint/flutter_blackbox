import 'devkit_device_info.dart';

/// A complete QA report bundle — screenshot + logs + network + device info.
class BlackBoxReport {
  const BlackBoxReport({
    this.bugTitle,
    required this.severity,
    required this.timestamp,
    required this.appInfo,
    required this.deviceInfo,
    required this.socketEvents,
    required this.userJourney,
    required this.failedRequests,
    required this.logs,
    required this.networkRequests,
    required this.crashes,
    this.screenshotPngBytes,
    this.notes,
  });

  final String? bugTitle;
  final BugSeverity severity;

  final DateTime timestamp;
  final Map<String, String> appInfo;
  final BlackBoxDeviceInfo deviceInfo;
  final List<Map<String, dynamic>> socketEvents;
  final List<String> userJourney;
  final List<Map<String, dynamic>> failedRequests;
  final List<Map<String, dynamic>> logs;
  final List<Map<String, dynamic>> networkRequests;
  final List<Map<String, dynamic>> crashes;

  /// Raw PNG bytes from RepaintBoundary.toImage().
  final List<int>? screenshotPngBytes;

  /// Optional tester notes typed in the QA panel.
  final String? notes;

  Map<String, dynamic> toJson() => {
        'bugTitle': bugTitle,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'app': appInfo,
        'device': deviceInfo.toJson(),
        'socketEvents': socketEvents,
        'userJourney': userJourney,
        'failedRequests': failedRequests,
        'logs': logs,
        'networkRequests': networkRequests,
        'crashes': crashes,
        'hasScreenshot': screenshotPngBytes != null,
        'notes': notes,
        // screenshot is omitted from JSON (too large); shared separately
      };

  String toMarkdown() => '''
## ${bugTitle ?? 'Bug Report'} [${severity.name.toUpperCase()}]

**Reported:** ${timestamp.toIso8601String()}
**Device:** ${deviceInfo.deviceModel} — ${deviceInfo.osVersion}
**Network:** ${deviceInfo.networkType}
**App:** v${appInfo['version']} (build ${appInfo['buildNumber']})

### Steps to reproduce
${userJourney.join('\n')}

### Failed requests
${failedRequests.map((r) {
        final req = r['request'] as Map?;
        final res = r['response'] as Map?;
        return '- ${req?['method']} ${req?['url']} → ${res?['statusCode']} (${res?['durationMs']}ms)';
      }).join('\n')}

### Crashes
${crashes.isEmpty ? 'None' : crashes.map((c) => '- ${c['message']}').join('\n')}

${notes != null && notes!.isNotEmpty ? '### Notes\n$notes\n' : ''}
''';

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('=== BlackBox QA Report ===')
      ..writeln('Title: ${bugTitle ?? 'N/A'} [${severity.name.toUpperCase()}]')
      ..writeln('Generated: ${timestamp.toIso8601String()}');

    //if (notes != null && notes!.isNotEmpty) {
    //  buf.writeln('Notes: $notes');
    //}

    buf
      ..writeln()
      ..writeln('--- App ---');
    appInfo.forEach((k, v) => buf.writeln('$k: $v'));
    buf
      ..writeln()
      ..writeln('--- Device ---');
    deviceInfo.toJson().forEach((k, v) => buf.writeln('$k: $v'));
    buf
      ..writeln()
      ..writeln('--- Socket IO (${socketEvents.length}) ---');
    for (final e in socketEvents) {
      buf.writeln('[${e['direction']}] ${e['timestamp']} ${e['eventName']}');
    }
    buf
      ..writeln()
      ..writeln('--- Logs (${logs.length}) ---');
    for (final l in logs) {
      buf.writeln('[${l['level']}] ${l['timestamp']} ${l['message']}');
    }
    buf
      ..writeln()
      ..writeln('--- Network (${networkRequests.length}) ---');
    for (final n in networkRequests) {
      final req = n['request'] as Map?;
      final res = n['response'] as Map?;
      if (req != null) {
        buf.writeln(
          '${req['method']} ${req['url']} → '
          '${res?['statusCode'] ?? 'pending'} '
          '(${res?['durationMs'] ?? '?'}ms)',
        );
      }
    }
    if (notes != null && notes!.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('--- Notes ---')
        ..writeln(notes);
    }
    return buf.toString();
  }
}

enum BugSeverity { critical, high, medium, low }
