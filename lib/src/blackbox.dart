import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'adapters/http/devkit_http_adapter.dart';
import 'adapters/log/devkit_log_adapter.dart';
import 'adapters/log/print_log_adapter.dart';
import 'adapters/socket/blackbox_socket_adapter.dart';
import 'adapters/storage/blackbox_storage_adapter.dart';
import 'core/rebuild/rebuild_store.dart';
import 'core/crash/crash_entry.dart';
import 'core/crash/crash_store.dart';
import 'core/journey/devkit_navigator_observer.dart';
import 'core/journey/journey_event.dart';
import 'core/journey/journey_store.dart';
import 'core/log/log_entry.dart';
import 'core/log/log_level.dart';
import 'core/log/log_store.dart';
import 'core/network/mock_engine.dart';
import 'core/network/mock_response.dart';
import 'core/network/network_store.dart';
import 'core/performance/fps_monitor.dart';
import 'core/report/devkit_device_info.dart';
import 'core/report/devkit_report.dart';
import 'core/socket/socket_event.dart';
import 'core/socket/socket_store.dart';
import 'overlay/devkit_trigger.dart';

/// Central singleton that owns all BlackBox stores and wires adapters.
///
/// Call [BlackBox.setup] once in [main] before [runApp].
///
/// ```dart
/// void main() {
///   BlackBox.setup(
///     httpAdapters: [DioBlackBoxAdapter(dio)],
///     trigger: BlackBoxTrigger.shake(),
///   );
///   runApp(BlackBoxOverlay(child: const MyApp()));
/// }
/// ```
class BlackBox {
  BlackBox._();

  static final BlackBox _instance = BlackBox._();

  static BlackBox get instance => _instance;

  // ── Internal stores ──────────────────────────────────────────────────

  final logStore = LogStore();
  final networkStore = NetworkStore();
  final mockEngine = MockEngine();
  final fpsMonitor = FpsMonitor();
  final crashStore = CrashStore();
  final journeyStore = JourneyStore();
  final socketStore = SocketStore();
  final rebuildStore = RebuildStore();

  // ── Storage adapters ──────────────────────────────────────────────────

  final List<BlackBoxStorageAdapter> _storageAdapters = [];

  List<BlackBoxStorageAdapter> get storageAdapters =>
      List.unmodifiable(_storageAdapters);

  // ── Rebuild tracking state ────────────────────────────────────────────

  bool _autoRebuildTracking = false;
  DebugPrintCallback? _originalDebugPrint;

  bool get isAutoRebuildTrackingEnabled => _autoRebuildTracking;

  static final journeyObserver =
      BlackBoxNavigatorObserver(_instance.journeyStore);

  // ── Configuration ────────────────────────────────────────────────────

  bool _enabled = kDebugMode;
  bool _redactSensitiveData = true;
  BlackBoxTrigger _trigger = const BlackBoxTrigger.shake();
  final List<BlackBoxHttpAdapter> _httpAdapters = [];
  final List<BlackBoxSocketAdapter> _socketAdapters = [];
  BlackBoxLogAdapter? _logAdapter;
  FlutterExceptionHandler? _originalFlutterError;
  bool Function(Object, StackTrace)? _originalPlatformError;

  bool get isEnabled => _enabled;

  /// Whether sensitive storage keys are redacted in the overlay.
  /// Defaults to `true` — sensitive values show as `••••••••`.
  bool get redactSensitiveData => _redactSensitiveData;
  BlackBoxTrigger get trigger => _trigger;
  List<BlackBoxHttpAdapter> get httpAdapters =>
      List.unmodifiable(_httpAdapters);

  // ── Overlay callback (set by BlackBoxOverlay widget) ───────────────────

  VoidCallback? _openOverlay;
  VoidCallback? _closeOverlay;

  void registerOverlayCallbacks({
    required VoidCallback open,
    required VoidCallback close,
  }) {
    _openOverlay = open;
    _closeOverlay = close;
  }

  // ── Public static API ────────────────────────────────────────────────

  /// Initialise BlackBox. Call once in [main].
  static void setup({
    List<BlackBoxHttpAdapter> httpAdapters = const [],
    List<BlackBoxSocketAdapter> socketAdapters = const [],
    BlackBoxLogAdapter? logAdapter,
    List<BlackBoxStorageAdapter> storageAdapters = const [],
    BlackBoxTrigger trigger = const BlackBoxTrigger.shake(),
    List<String> ignoredRebuildWidgets = const [],
    bool? enabled,

    /// When `true` (default), keys matching sensitive patterns
    /// (password, token, secret, etc.) are redacted in the Storage panel.
    /// Set to `false` only for internal/dev-only builds.
    bool redactSensitiveData = true,
  }) {
    final dk = _instance;
    dk._enabled = enabled ?? kDebugMode;
    dk._redactSensitiveData = redactSensitiveData;
    dk._trigger = trigger;
    if (ignoredRebuildWidgets.isNotEmpty) {
      _ignoredWidgets.addAll(ignoredRebuildWidgets);
    }

    if (!dk._enabled) return;

    // ── Log adapter ────────────────────────────────────────────────────
    final la = logAdapter ?? PrintLogAdapter();
    dk._logAdapter = la;
    la.onLogCallback = (entry) => dk.logStore.add(entry);
    la.attach();

    // ── HTTP adapters ──────────────────────────────────────────────────
    for (final adapter in httpAdapters) {
      adapter.onRequestCallback = dk.networkStore.onRequest;
      adapter.onResponseCallback = dk.networkStore.onResponse;
      adapter.interceptCallback = dk.mockEngine.intercept;
      adapter.attach();
      dk._httpAdapters.add(adapter);
    }

    // ── Journey tracking for API calls ─────────────────────────────────
    dk.networkStore.stream.listen((entries) {
      if (entries.isNotEmpty) {
        final last = entries.last;
        if (last.response != null) {
          dk.journeyStore.record(ApiEvent(
            DateTime.now(),
            method: last.request.method,
            url: last.request.url,
            statusCode: last.response!.statusCode,
          ));
        }
      }
    });

    // ── Storage adapters ────────────────────────────────────────────────
    dk._storageAdapters.addAll(storageAdapters);

    // ── Socket adapters ─────────────────────────────────────────────────
    for (final adapter in socketAdapters) {
      adapter.onEventCallback = dk.socketStore.onEvent;
      adapter.attach();
      dk._socketAdapters.add(adapter);
    }

    // ── FPS monitor ────────────────────────────────────────────────────
    dk.fpsMonitor.start();

    // ── Crash handling ─────────────────────────────────────────────────
    dk._hookCrashHandlers();
  }

  void _hookCrashHandlers() {
    _originalFlutterError = FlutterError.onError;
    _originalPlatformError = PlatformDispatcher.instance.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      if (_enabled) {
        crashStore.add(CrashEntry(
          id: 'crash_${DateTime.now().microsecondsSinceEpoch}',
          message: details.exceptionAsString(),
          stackTrace: details.stack,
          library: details.library,
          timestamp: DateTime.now(),
          isFlutterError: true,
        ));
        BlackBox.log(
          details.exceptionAsString(),
          level: LogLevel.error,
          tag: 'Crash',
          error: details.exception,
          stackTrace: details.stack,
        );
        scheduleMicrotask(() => BlackBox.open());
      }
      _originalFlutterError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (_enabled) {
        crashStore.add(CrashEntry(
          id: 'crash_${DateTime.now().microsecondsSinceEpoch}',
          message: error.toString(),
          stackTrace: stack,
          timestamp: DateTime.now(),
          isFlutterError: false,
        ));
        BlackBox.log(
          error.toString(),
          level: LogLevel.error,
          tag: 'Crash',
          error: error,
          stackTrace: stack,
        );
        scheduleMicrotask(() => BlackBox.open());
      }
      _originalPlatformError?.call(error, stack);
      return false;
    };
  }

  // ── Logging ──────────────────────────────────────────────────────────

  static void log(
    String message, {
    LogLevel level = LogLevel.debug,
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_instance._enabled) return;
    final entry = LogEntry(
      id: 'dk_${DateTime.now().microsecondsSinceEpoch}',
      level: level,
      message: message,
      timestamp: DateTime.now(),
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
    _instance.logStore.add(entry);

    final tagStr = tag != null ? '[$tag] ' : '';
    final dataStr = data != null ? ' | Data: $data' : '';
    final errStr = error != null ? ' | Error: $error' : '';
    dev.log('[${level.name.toUpperCase()}] $tagStr$message$dataStr$errStr',
        name: 'BlackBox');
  }

  // ── Rebuild tracking ────────────────────────────────────────────────

  /// Start automatic rebuild tracking for ALL widgets.
  /// Uses Flutter's `debugPrintRebuildDirtyWidgets` (debug mode only).
  static void startRebuildTracking() {
    if (!kDebugMode) return;
    final dk = _instance;
    dk._autoRebuildTracking = true;
    debugPrintRebuildDirtyWidgets = true;

    dk._originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null &&
          (message.startsWith('Rebuilding ') ||
              message.startsWith('Building '))) {
        // Flutter's format: "Rebuilding WidgetName(dirty)"
        final name = _parseWidgetName(message);
        if (name != null) {
          dk.rebuildStore.record(name);
        }
        // Suppress the log from printing to the IDE console to prevent extreme spam
        return;
      }
      dk._originalDebugPrint?.call(message ?? '', wrapWidth: wrapWidth ?? 100);
    };
  }

  /// Stop automatic rebuild tracking.
  static void stopRebuildTracking() {
    final dk = _instance;
    dk._autoRebuildTracking = false;
    debugPrintRebuildDirtyWidgets = false;
    if (dk._originalDebugPrint != null) {
      debugPrint = dk._originalDebugPrint!;
      dk._originalDebugPrint = null;
    }
  }

  static final _ignoredWidgets = <String>{
    'Text', 'Container', 'Padding', 'SizedBox', 'Column', 'Row', 'Align',
    'Center', 'Positioned', 'Expanded', 'Flexible', 'Stack', 'ListView',
    'GestureDetector', 'InkWell', 'ConstrainedBox', 'DecoratedBox', 'Theme',
    'Opacity', 'Transform', 'ClipRRect', 'ClipOval', 'ClipPath', 'ClipRect',
    'IgnorePointer', 'AbsorbPointer', 'RepaintBoundary', 'FittedBox',
    'FractionallySizedBox', 'LayoutBuilder', 'Builder', 'StatefulBuilder',
    'StreamBuilder', 'FutureBuilder', 'ValueListenableBuilder',
    'AnimatedBuilder', 'Icon', 'Image', 'RichText', 'DefaultTextStyle',
    'MediaQuery', 'Directionality', 'Visibility', 'Scaffold', 'AppBar',
    'BottomNavigationBar', 'FloatingActionButton', 'Drawer', 'GridView',
    'SingleChildScrollView', 'CustomScrollView', 'SliverToBoxAdapter',
    'SliverList', 'SliverGrid', 'Card', 'Divider', 'ListTile', 'Placeholder',
    'Tooltip', 'SafeArea', 'Hero', 'Material', 'Ink', 'AnimatedContainer',
    'AnimatedPadding', 'AnimatedOpacity', 'AnimatedCrossFade',
    'AnimatedSwitcher', 'AnimatedSize', 'AnimatedPositioned', 'Wrap',
    'Flow', 'Table', 'PageView', 'Scrollbar', 'RefreshIndicator', 'Navigator',
    'Overlay', 'FocusScope', 'KeyedSubtree', 'Semantics', 'MergeSemantics',
    'ExcludeSemantics', 'ColoredBox', 'FractionalTranslation', 'RotatedBox',
    'BackdropFilter', 'PhysicalModel', 'PhysicalShape', 'CustomPaint',
    'Offstage', 'TickerMode', 'Focus', 'FocusNode', 'FocusTraversalGroup',
    'UnmanagedRestorationScope', 'RestorationScope', 'NotificationListener',
    'ScrollConfiguration', 'Scrollable', 'MouseRegion', 'Listener',
    'SemanticsDebugger', 'AnimatedTheme', 'IconTheme', 'ColorFiltered',
    'AnimatedDefaultTextStyle', 'PrimaryScrollController', 'SharedAppData',
    'MatrixTransition', 'Consumer', 'Provider', 'Selector', 'BlocBuilder',
    'BlocProvider', 'BlocListener', 'BlocConsumer', 'GetBuilder', 'Obx',
    'AutomaticKeepAlive', 'KeepAlive', 'Viewport', 'ShrinkWrappingViewport',
    'SliverPadding', 'RawScrollbar', 'RawGestureDetector', 'ScrollSemantics',
    'ScrollBehavior', 'GlowingOverscrollIndicator',
    'OverscrollIndicatorNotification',
    // 60fps Animators & deep framework listeners
    'LinearProgressIndicator', 'CircularProgressIndicator',
    'CupertinoActivityIndicator',
    'StretchingOverscrollIndicator', 'ListenableBuilder', 'Actions',
    'TweenAnimationBuilder',
    'AnimatedWidget', 'RotationTransition', 'ScaleTransition', 'SizeTransition',
    // Internal Overlay/Blackbox widgets (to prevent infinite loops)
    'BlackBoxOverlay', 'DevkitOverlay', 'RebuildTrackerWidget',
    '_RebuildTrackerWidgetState',
    'TouchEater', 'Draggable', 'PositionedTransition', 'SlideTransition',
    // Riverpod internal widgets
    'ConsumerWidget', 'HookConsumerWidget', 'StatefulHookConsumerWidget',
  };

  static String? _parseWidgetName(String message) {
    // Flutter debug output: "Rebuilding MyWidget(dirty, state: _MyWidgetState#abc12)"
    final match =
        RegExp(r'(?:Building|Rebuilding)\s+(\w+)\(').firstMatch(message.trim());
    if (match != null) {
      final name = match.group(1)!;
      // Filter out framework-internal or noisy widgets
      if (name.startsWith('_') || _ignoredWidgets.contains(name)) {
        return null;
      }
      return name;
    }
    return null;
  }

  // ── Socket IO ──────────────────────────────────────────────────────────

  /// Manually log a socket event.
  ///
  /// Prefer using [BlackBoxSocketAdapter] (e.g. `SocketIOBlackBoxAdapter`)
  /// which captures events automatically without code changes.
  ///
  /// This method is provided as a **fallback** for socket libraries that
  /// don't have a built-in adapter yet.
  static void logSocketEvent(
    String eventName,
    dynamic data, {
    SocketDirection direction = SocketDirection.incoming,
  }) {
    if (!_instance._enabled) return;
    final event = SocketEvent(
      id: 'soc_${DateTime.now().microsecondsSinceEpoch}',
      eventName: eventName,
      data: data,
      timestamp: DateTime.now(),
      direction: direction,
    );
    _instance.socketStore.onEvent(event);
  }

  // ── Network mocking ───────────────────────────────────────────────────

  /// Register a mock rule. Active immediately — no restart needed.
  static String mock({
    required Object pattern,
    String method = '*',
    required MockResponse response,
  }) {
    return _instance.mockEngine.addRule(
      pattern: pattern,
      method: method,
      response: response,
    );
  }

  static void removeMock(String id) => _instance.mockEngine.removeRule(id);

  // ── Overlay control ───────────────────────────────────────────────────

  static void open() => _instance._openOverlay?.call();
  static void close() => _instance._closeOverlay?.call();
  static void toggle() {
    // Toggled by the overlay widget itself via isVisible state
    _instance._openOverlay?.call();
  }

  // ── Report ────────────────────────────────────────────────────────────

  /// Build a [BlackBoxReport] from current store state.
  static Future<BlackBoxReport> buildReport({
    String? bugTitle,
    BugSeverity severity = BugSeverity.medium,
    String? notes,
    List<int>? screenshotPngBytes,
  }) async {
    final dk = _instance;
    return BlackBoxReport(
      bugTitle: bugTitle,
      severity: severity,
      timestamp: DateTime.now(),
      appInfo: await _appInfo(),
      deviceInfo: await _getDeviceInfo(),
      userJourney: dk.journeyStore.numberedSteps,
      failedRequests: dk.networkStore.entries
          .where((e) => e.response != null && e.response!.statusCode >= 400)
          .map((e) => {
                'request': e.request.toJson(),
                'response': e.response!.toJson(),
              })
          .toList(),
      logs: dk.logStore.toJson(),
      networkRequests: dk.networkStore.toJson(),
      socketEvents: dk.socketStore.toJson(),
      crashes: dk.crashStore.toJson(),
      screenshotPngBytes: screenshotPngBytes,
      notes: notes,
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────

  static void dispose() {
    final dk = _instance;

    if (dk._originalFlutterError != null) {
      FlutterError.onError = dk._originalFlutterError;
    }
    if (dk._originalPlatformError != null) {
      PlatformDispatcher.instance.onError = dk._originalPlatformError;
    }

    dk._logAdapter?.detach();
    for (final a in dk._httpAdapters) {
      a.detach();
    }
    for (final a in dk._socketAdapters) {
      a.detach();
    }
    dk.fpsMonitor.dispose();
    dk.logStore.dispose();
    dk.networkStore.dispose();
    dk.crashStore.dispose();
    dk.socketStore.dispose();
    dk.rebuildStore.dispose();
    dk.journeyStore.clear();
    dk._httpAdapters.clear();
    dk._socketAdapters.clear();
    dk._storageAdapters.clear();
    BlackBox.stopRebuildTracking();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static Future<Map<String, String>> _appInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return {
        'appName': info.appName,
        'packageName': info.packageName,
        'version': info.version,
        'buildNumber': info.buildNumber,
      };
    } catch (_) {
      return {'error': 'Failed to fetch package info'};
    }
  }

  // ── Device Info Parsing ───────────────────────────────────────────────

  static BlackBoxDeviceInfo? _cachedDeviceInfo;

  static Future<BlackBoxDeviceInfo> _getDeviceInfo() async {
    return _cachedDeviceInfo ??= await _fetchDeviceInfo();
  }

  static Future<BlackBoxDeviceInfo> _fetchDeviceInfo() async {
    if (kIsWeb) {
      return BlackBoxDeviceInfo(
        platform: 'web',
        osVersion: 'Unknown',
        deviceModel: 'Browser',
        networkType: 'unknown',
        locale: ui.PlatformDispatcher.instance.locale.toString(),
        timezone: DateTime.now().timeZoneName,
        screenSize: 'Unknown',
        pixelRatio: 1.0,
        brightness: 'Unknown',
      );
    }

    final deviceInfo = DeviceInfoPlugin();
    final connectivity = Connectivity();

    String osVersion = 'Unknown';
    String deviceModel = 'Unknown';
    String? cpuArch;
    int? androidSdkInt;
    int? totalRamMb;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        osVersion =
            'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        cpuArch = androidInfo.supportedAbis.isNotEmpty
            ? androidInfo.supportedAbis.first
            : null;
        androidSdkInt = androidInfo.version.sdkInt;
        // Approximation, androidInfo.systemFeatures doesn't explicitly expose RAM memory cleanly
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceModel = iosInfo.name;
      }
    } catch (_) {}

    String netType = 'unknown';
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        netType = 'wifi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        netType = 'mobile';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        netType = 'ethernet';
      } else if (connectivityResult.contains(ConnectivityResult.none)) {
        netType = 'none';
      } else {
        netType = connectivityResult.first.name;
      }
    } catch (_) {}

    final window = ui.PlatformDispatcher.instance.views.first;
    final size = window.physicalSize / window.devicePixelRatio;

    return BlackBoxDeviceInfo(
      platform: defaultTargetPlatform.name,
      osVersion: osVersion,
      deviceModel: deviceModel,
      cpuArch: cpuArch,
      androidSdkInt: androidSdkInt,
      totalRamMb: totalRamMb,
      availableRamMb: null,
      networkType: netType,
      batteryPercent: null,
      isCharging: null,
      locale: ui.PlatformDispatcher.instance.locale.toString(),
      timezone: DateTime.now().timeZoneName,
      screenSize:
          '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)} dp',
      pixelRatio: window.devicePixelRatio,
      brightness: ui.PlatformDispatcher.instance.platformBrightness.name,
    );
  }
}
