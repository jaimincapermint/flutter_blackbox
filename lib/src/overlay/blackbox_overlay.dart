import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../blackbox.dart';
import 'blackbox_trigger.dart';
import 'panels/log_panel.dart';
import 'panels/network_panel.dart';
import 'panels/performance_panel.dart';
import 'panels/rebuild_panel.dart';
import 'panels/search_panel.dart';
import 'panels/socket_panel.dart';
import 'panels/storage_panel.dart';
import 'panels/device_panel.dart';
import 'panels/qa_panel.dart';

/// Wrap your [MaterialApp] (or [CupertinoApp]) with this widget.
///
/// It inserts a transparent [Overlay] above your app's Navigator so
/// the debug panel never interferes with routing, back gestures, or
/// bottom sheets.
///
/// ```dart
/// runApp(BlackBoxOverlay(child: const MyApp()));
/// ```
class BlackBoxOverlay extends StatefulWidget {
  /// Creates an overlay wrapper.
  const BlackBoxOverlay({super.key, required this.child});

  /// The root application widget (usually your [MaterialApp]).
  final Widget child;

  @override
  State<BlackBoxOverlay> createState() => _BlackBoxOverlayState();
}

class _BlackBoxOverlayState extends State<BlackBoxOverlay>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  final _repaintKey = GlobalKey();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  // Shake detection.
  // Full shake detection requires sensors_plus (blackbox_sensors companion).
  // onShakeDetected() is the hook called by that companion package.
  // Without it, use BlackBoxTrigger.floatingButton() or BlackBoxTrigger.hotkey().
  // static const _shakeGravity = 9.8;
  DateTime _lastShake = DateTime.now();

  /// Entry point for shake detection from blackbox_sensors companion.
  void onShakeDetected() {
    final now = DateTime.now();
    if (now.difference(_lastShake).inMilliseconds < 1000) return;
    _lastShake = now;
    _toggle();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    BlackBox.instance.registerOverlayCallbacks(
      open: _open,
      close: _close,
    );

    _setupTrigger();
  }

  void _setupTrigger() {
    final trigger = BlackBox.instance.trigger;
    switch (trigger) {
      case HotkeyTrigger(:final key, :final ctrl, :final shift):
        HardwareKeyboard.instance.addHandler(_handleKey(key, ctrl, shift));
      case ShakeTrigger():
      // Full shake requires sensors_plus via blackbox_sensors companion.
      // Call state.onShakeDetected() from your accelerometer listener.
      case FloatingButtonTrigger():
      case NoneTrigger():
    }
  }

  KeyEventCallback _handleKey(LogicalKeyboardKey key, bool ctrl, bool shift) {
    return (KeyEvent event) {
      if (event is! KeyDownEvent) return false;
      final ctrlHeld = HardwareKeyboard.instance.isControlPressed;
      final shiftHeld = HardwareKeyboard.instance.isShiftPressed;
      if (event.logicalKey == key &&
          (!ctrl || ctrlHeld) &&
          (!shift || shiftHeld)) {
        _toggle();
        return true;
      }
      return false;
    };
  }

  void _open() {
    if (_isVisible) return;
    setState(() => _isVisible = true);
    _animController.forward();
  }

  void _close() {
    _animController.reverse().then((_) {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  void _toggle() => _isVisible ? _close() : _open();

  /// Captures a screenshot of the app content (before the overlay).
  Future<List<int>?> _captureScreen() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final data = await image.toByteData(format: ImageByteFormat.png);
      return data?.buffer.asUint8List().toList();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!BlackBox.instance.isEnabled) return widget.child;

    final trigger = BlackBox.instance.trigger;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // ── App content wrapped in RepaintBoundary for screenshots ──
          RepaintBoundary(
            key: _repaintKey,
            child: widget.child,
          ),

          // ── Floating button trigger ──────────────────────────────────
          if (trigger is FloatingButtonTrigger)
            Positioned(
              right: 16,
              bottom: 80,
              child: _FloatingTriggerButton(onTap: _toggle),
            ),

          // ── Debug overlay panel ──────────────────────────────────────
          if (_isVisible)
            Positioned.fill(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  _close();
                },
                child: HeroControllerScope.none(
                  child: Navigator(
                    onGenerateRoute: (_) => PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (context, _, __) => FadeTransition(
                        opacity: _fadeAnimation,
                        child: _BlackBoxPanel(
                            onClose: _close, captureScreen: _captureScreen),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel shell with tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _BlackBoxPanel extends StatefulWidget {
  const _BlackBoxPanel({
    required this.onClose,
    required this.captureScreen,
  });

  final VoidCallback onClose;
  final Future<List<int>?> Function() captureScreen;

  @override
  State<_BlackBoxPanel> createState() => _BlackBoxPanelState();
}

class _BlackBoxPanelState extends State<_BlackBoxPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (icon: Icons.wifi, label: 'Network'),
    (icon: Icons.article_outlined, label: 'Logs'),
    (icon: Icons.speed, label: 'Perf'),
    (icon: Icons.refresh, label: 'Rebuilds'),
    (icon: Icons.storage_outlined, label: 'Storage'),
    (icon: Icons.power, label: 'Socket IO'),
    (icon: Icons.phone_android, label: 'Device'),
    (icon: Icons.bug_report_outlined, label: 'QA'),
    (icon: Icons.search, label: 'Search'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              _PanelHeader(
                tabController: _tabController,
                tabs: _tabs,
                onClose: widget.onClose,
              ),
              const SizedBox(height: 8),
              // ── Tab content ──────────────────────────────────────────
              Expanded(
                child: _PanelCard(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const NetworkPanel(),
                      const LogPanel(),
                      const PerformancePanel(),
                      const RebuildPanel(),
                      const StoragePanel(),
                      const SocketPanel(),
                      const DevicePanel(),
                      QaPanel(captureScreen: widget.captureScreen),
                      const SearchPanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.tabController,
    required this.tabs,
    required this.onClose,
  });

  final TabController tabController;
  final List<({IconData icon, String label})> tabs;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const _BlackBoxBadge(),
                const Spacer(),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            tabAlignment: TabAlignment.start,
            tabs: tabs.map((t) {
              final isQa = t.label == 'QA';
              return StreamBuilder<List<dynamic>>(
                stream: isQa
                    ? BlackBox.instance.crashStore.stream
                    : const Stream<List<dynamic>>.empty(),
                initialData:
                    isQa ? BlackBox.instance.crashStore.entries : <dynamic>[],
                builder: (context, snapshot) {
                  final hasCrash = isQa && ((snapshot.data ?? []).isNotEmpty);
                  return Tab(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(t.icon, size: 16),
                        if (hasCrash)
                          Positioned(
                            right: -4,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('CRASH',
                                  style: TextStyle(
                                      fontSize: 6,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                    text: t.label,
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _BlackBoxBadge extends StatelessWidget {
  const _BlackBoxBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'BlackBox',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _FloatingTriggerButton extends StatelessWidget {
  const _FloatingTriggerButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
      ),
    );
  }
}
