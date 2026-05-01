import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'adapters/http/blackbox_http_adapter.dart';
import 'adapters/log/blackbox_log_adapter.dart';
import 'adapters/log/print_log_adapter.dart';
import 'adapters/socket/blackbox_socket_adapter.dart';
import 'adapters/storage/blackbox_storage_adapter.dart';
import 'core/report/package_info_impl.dart'
    if (dart.library.html) 'core/report/package_info_stub.dart'
    if (dart.library.js_interop) 'core/report/package_info_stub.dart';
import 'core/report/platform_info_impl.dart'
    if (dart.library.html) 'core/report/platform_info_stub.dart'
    if (dart.library.js_interop) 'core/report/platform_info_stub.dart';
import 'core/rebuild/rebuild_store.dart';
import 'core/crash/crash_entry.dart';
import 'core/crash/crash_store.dart';
import 'core/journey/blackbox_navigator_observer.dart';
import 'core/journey/journey_event.dart';
import 'core/journey/journey_store.dart';
import 'core/log/log_entry.dart';
import 'core/log/log_level.dart';
import 'core/log/log_store.dart';
import 'core/network/mock_engine.dart';
import 'core/network/mock_response.dart';
import 'core/network/network_store.dart';
import 'core/performance/fps_monitor.dart';
import 'core/report/blackbox_device_info.dart';
import 'core/report/blackbox_report.dart';
import 'core/socket/socket_event.dart';
import 'core/socket/socket_store.dart';
import 'overlay/blackbox_trigger.dart';

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

  /// Store for recorded log entries.
  final logStore = LogStore();

  /// Store for intercepted network requests.
  final networkStore = NetworkStore();

  /// Engine for mocking network responses based on URL patterns.
  final mockEngine = MockEngine();

  /// Monitor for tracking FPS and frame performance.
  final fpsMonitor = FpsMonitor();

  /// Store for captured platform and Flutter crashes.
  final crashStore = CrashStore();

  /// Store for user navigation and interaction journey.
  final journeyStore = JourneyStore();

  /// Store for intercepted Socket.IO events.
  final socketStore = SocketStore();

  /// Store for widget rebuild counts and tracking state.
  final rebuildStore = RebuildStore();

  // ── Storage adapters ──────────────────────────────────────────────────

  final List<BlackBoxStorageAdapter> _storageAdapters = [];

  // ── Rebuild tracking state ────────────────────────────────────────────

  bool _autoRebuildTracking = false;
  DebugPrintCallback? _originalDebugPrint;

  /// Whether the overlay is globally enabled.
  /// When `false`, [setup] and [BlackBoxOverlay] become no-ops.
  bool get isEnabled => _enabled;

  /// Whether the auto-rebuild tracking is currently active.
  bool get isAutoRebuildTrackingEnabled => _autoRebuildTracking;

  /// A [NavigatorObserver] that logs navigation events to the [journeyStore].
  /// Add this to your [MaterialApp.navigatorObservers].
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

  /// Whether sensitive storage keys are redacted in the overlay.
  /// Defaults to `true` — sensitive values show as `••••••••`.
  bool get redactSensitiveData => _redactSensitiveData;

  /// Registered storage adapters (e.g., SharedPreferences, Hive).
  List<BlackBoxStorageAdapter> get storageAdapters =>
      List.unmodifiable(_storageAdapters);

  /// Current trigger used to open the overlay.
  BlackBoxTrigger get trigger => _trigger;

  /// Registered network adapters (e.g., Dio, dart:http).
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

  /// Configures and initializes the BlackBox singleton.
  ///
  /// [httpAdapters] - List of [BlackBoxHttpAdapter] to intercept network calls (Dio, http).
  /// [socketAdapters] - List of [BlackBoxSocketAdapter] to intercept Socket.IO events.
  /// [logAdapter] - The adapter used to capture logs. Defaults to [PrintLogAdapter].
  /// [storageAdapters] - List of [BlackBoxStorageAdapter] to inspect app storage.
  /// [trigger] - How to open the overlay. Defaults to [BlackBoxTrigger.shake].
  /// [ignoredRebuildWidgets] - List of widget names to exclude from rebuild tracking.
  /// [enabled] - If the library should be active. Defaults to [kDebugMode].
  /// [redactSensitiveData] - Whether to mask sensitive keys in storage panels.
  static void setup({
    List<BlackBoxHttpAdapter> httpAdapters = const [],
    List<BlackBoxSocketAdapter> socketAdapters = const [],
    BlackBoxLogAdapter? logAdapter,
    List<BlackBoxStorageAdapter> storageAdapters = const [],
    BlackBoxTrigger trigger = const BlackBoxTrigger.shake(),
    List<String> ignoredRebuildWidgets = const [],
    bool? enabled,
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

  /// Logs a custom message to the BlackBox log store.
  ///
  /// [message] - The log message.
  /// [level] - Importance of the log (debug, info, warning, error).
  /// [tag] - Optional category for filtering (e.g., 'Auth', 'UI').
  /// [data] - Optional metadata map.
  /// [error] - Associated error object.
  /// [stackTrace] - Associated stack trace.
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

  /// Removes a mock rule by its ID.
  static void removeMock(String id) => _instance.mockEngine.removeRule(id);

  // ── Overlay control ───────────────────────────────────────────────────

  /// Programmatically opens the BlackBox overlay.
  static void open() => _instance._openOverlay?.call();

  /// Programmatically closes the BlackBox overlay.
  static void close() => _instance._closeOverlay?.call();

  /// Programmatically toggles the BlackBox overlay visibility.
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
      appInfo: await _appInfo() ?? {},
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

  static Future<Map<String, String>?> _appInfo() async {
    return await getPackageInfo();
  }

  // ── Device Info Parsing ───────────────────────────────────────────────

  static BlackBoxDeviceInfo? _cachedDeviceInfo;

  static Future<BlackBoxDeviceInfo> _getDeviceInfo() async {
    return _cachedDeviceInfo ??= await _fetchDeviceInfo();
  }

  static Future<BlackBoxDeviceInfo> _fetchDeviceInfo() async {
    return await fetchPlatformDeviceInfo();
  }
}
