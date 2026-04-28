// ignore_for_file: avoid_print
import 'dart:io';
import 'package:yaml/yaml.dart';

/// CLI tool: `dart run flutter_blackbox:init`
///
/// Reads the user's pubspec.yaml, detects which HTTP/storage/socket
/// libraries they already use, and prints the exact imports and
/// setup boilerplate they need.
///
/// In a future monorepo release, this will also auto-add companion
/// packages (flutter_blackbox_dio, etc.) via `flutter pub add`.
void main(List<String> args) async {
  final showHelp = args.contains('--help') || args.contains('-h');
  final generateFile = args.contains('--generate') || args.contains('-g');

  if (showHelp) {
    _printHelp();
    return;
  }

  print('');
  print('  🐞 BlackBox Init — Auto-detecting your dependencies...');
  print('');

  // ── 1. Read the user's pubspec.yaml ──────────────────────────────────
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print(
        '  ❌ No pubspec.yaml found. Run this from your Flutter project root.');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final yaml = loadYaml(content) as YamlMap;
  final deps = yaml['dependencies'] as YamlMap? ?? YamlMap();
  final devDeps = yaml['dev_dependencies'] as YamlMap? ?? YamlMap();
  final allDeps = <String>{
    ...deps.keys.cast<String>(),
    ...devDeps.keys.cast<String>()
  };

  // ── 2. Check flutter_blackbox is present ─────────────────────────────
  if (!allDeps.contains('flutter_blackbox')) {
    print('  ⚠️  flutter_blackbox not found in pubspec.yaml.');
    print('  Run: flutter pub add flutter_blackbox');
    print('');
    exit(1);
  }

  // ── 3. Detect matching libraries → adapter imports ───────────────────
  final detections = <_Detection>[];

  // HTTP clients
  if (allDeps.contains('dio')) {
    detections.add(const _Detection(
      library: 'dio',
      importPath: "import 'package:flutter_blackbox/adapters/dio.dart';",
      setupLine: 'httpAdapters: [DioBlackBoxAdapter(dio)]',
      description: 'Dio HTTP client',
    ));
  }
  if (allDeps.contains('http')) {
    detections.add(const _Detection(
      library: 'http',
      importPath: "import 'package:flutter_blackbox/adapters/http.dart';",
      setupLine: 'httpAdapters: [HttpBlackBoxAdapter(client)]',
      description: 'HTTP package',
    ));
  }

  // Socket
  if (allDeps.contains('socket_io_client')) {
    detections.add(const _Detection(
      library: 'socket_io_client',
      importPath: "import 'package:flutter_blackbox/adapters/socket_io.dart';",
      setupLine: 'socketAdapters: [SocketIOBlackBoxAdapter(socket)]',
      description: 'Socket.IO client',
    ));
  }

  // Storage
  if (allDeps.contains('shared_preferences')) {
    detections.add(const _Detection(
      library: 'shared_preferences',
      importPath:
          "import 'package:flutter_blackbox/adapters/shared_prefs.dart';",
      setupLine: 'storageAdapters: [SharedPrefsStorageAdapter()]',
      description: 'SharedPreferences',
    ));
  }

  // ── 4. Report findings ───────────────────────────────────────────────
  final allLibs = ['dio', 'http', 'socket_io_client', 'shared_preferences'];
  final detectedLibs = detections.map((d) => d.library).toSet();

  for (final lib in allLibs) {
    if (detectedLibs.contains(lib)) {
      final d = detections.firstWhere((det) => det.library == lib);
      print('  ✅ Found $lib → ${d.description}');
    } else {
      print('  ⬚  $lib → not found, skipping');
    }
  }

  print('');

  if (detections.isEmpty) {
    print('  ℹ️  No supported libraries detected.');
    print(
        '  BlackBox will work with core features: logs, crashes, performance,');
    print('  rebuild tracking, journey, and QA reports.');
    print('');
    print(
        '  Add a network library (dio or http) to enable network inspection.');
    print('');
    exit(0);
  }

  // ── 5. Print setup boilerplate ───────────────────────────────────────
  print('  ✨ ${detections.length} adapter(s) detected!\n');
  _printSetupCode(detections);

  // ── 6. Optionally generate a setup file ──────────────────────────────
  if (generateFile) {
    _generateSetupFile(detections);
  } else {
    print('');
    print(
        '  💡 Tip: Run with --generate to create a blackbox_setup.dart file:');
    print('     dart run flutter_blackbox:init --generate');
    print('');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Detection {
  const _Detection({
    required this.library,
    required this.importPath,
    required this.setupLine,
    required this.description,
  });
  final String library;
  final String importPath;
  final String setupLine;
  final String description;
}

void _printSetupCode(List<_Detection> detections) {
  print('  ┌─────────────────────────────────────────────────────────┐');
  print('  │  Add to your main.dart:                                 │');
  print('  └─────────────────────────────────────────────────────────┘');
  print('');
  print("  import 'package:flutter/foundation.dart';");
  print("  import 'package:flutter_blackbox/flutter_blackbox.dart';");
  for (final d in detections) {
    print('  ${d.importPath}');
  }
  print('');
  print('  void main() {');
  print('    BlackBox.setup(');
  for (final d in detections) {
    print('      ${d.setupLine},');
  }
  print('      trigger: const BlackBoxTrigger.floatingButton(),');
  print('      enabled: kDebugMode,');
  print('    );');
  print('    runApp(const BlackBoxOverlay(child: MyApp()));');
  print('  }');
}

void _generateSetupFile(List<_Detection> detections) {
  final buffer = StringBuffer();
  buffer.writeln(
      '// Auto-generated by: dart run flutter_blackbox:init --generate');
  buffer.writeln('// Feel free to modify this file to match your needs.');
  buffer.writeln('');
  buffer.writeln("import 'package:flutter/foundation.dart';");
  buffer.writeln("import 'package:flutter_blackbox/flutter_blackbox.dart';");
  for (final d in detections) {
    buffer.writeln(d.importPath);
  }

  // Add Dio import if needed
  if (detections.any((d) => d.library == 'dio')) {
    buffer.writeln("import 'package:dio/dio.dart';");
  }

  buffer.writeln('');
  buffer.writeln('/// Call this in your main() before runApp().');
  buffer.writeln('///');
  buffer.writeln('/// ```dart');
  buffer.writeln('/// void main() {');
  buffer.writeln('///   setupBlackBox(dio: myDio);');
  buffer.writeln('///   runApp(const BlackBoxOverlay(child: MyApp()));');
  buffer.writeln('/// }');
  buffer.writeln('/// ```');

  // Build function signature
  final params = <String>[];
  if (detections.any((d) => d.library == 'dio')) {
    params.add('required Dio dio');
  }

  buffer.writeln('void setupBlackBox({${params.join(', ')}}) {');
  buffer.writeln('  BlackBox.setup(');
  for (final d in detections) {
    buffer.writeln('    ${d.setupLine},');
  }
  buffer.writeln('    logAdapter: PrintLogAdapter(),');
  buffer.writeln('    trigger: const BlackBoxTrigger.floatingButton(),');
  buffer.writeln('    enabled: kDebugMode,');
  buffer.writeln('  );');
  buffer.writeln('}');

  const outputPath = 'lib/blackbox_setup.dart';
  final file = File(outputPath);

  if (file.existsSync()) {
    print('');
    print('  ⚠️  $outputPath already exists. Skipping file generation.');
    print('  Delete the file and re-run to regenerate.');
    return;
  }

  file.writeAsStringSync(buffer.toString());
  print('');
  print('  📝 Generated: $outputPath');
  print('');
  print('  Usage in main.dart:');
  print("    import 'package:flutter_blackbox/flutter_blackbox.dart';");
  print("    import 'blackbox_setup.dart';");
  print('');
  print('    void main() {');
  if (detections.any((d) => d.library == 'dio')) {
    print('      setupBlackBox(dio: myDio);');
  } else {
    print('      setupBlackBox();');
  }
  print('      runApp(const BlackBoxOverlay(child: MyApp()));');
  print('    }');
  print('');
}

void _printHelp() {
  print('');
  print('  🐞 BlackBox Init');
  print('  ─────────────────────────────────────────────');
  print('');
  print('  Auto-detects your project dependencies and generates');
  print('  the correct BlackBox setup code.');
  print('');
  print('  Usage:');
  print('    dart run flutter_blackbox:init              Detect & print setup');
  print(
      '    dart run flutter_blackbox:init --generate   Also create blackbox_setup.dart');
  print('    dart run flutter_blackbox:init --help       Show this help');
  print('');
  print('  Supported libraries:');
  print('    • dio              → DioBlackBoxAdapter');
  print('    • http             → HttpBlackBoxAdapter');
  print('    • socket_io_client → SocketIOBlackBoxAdapter');
  print('    • shared_preferences → SharedPrefsStorageAdapter');
  print('');
}
