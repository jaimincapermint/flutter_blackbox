import 'dart:async';
import 'dart:collection';

import 'package:flutter/scheduler.dart';

/// Monitors frame timing using [SchedulerBinding.addPersistentFrameCallback].
///
/// Collects the last [sampleSize] frame durations and exposes rolling
/// FPS, average frame time, and worst frame time as a [Stream].
class FpsMonitor {
  FpsMonitor({this.sampleSize = 60});

  final int sampleSize;

  final _frameDurations = ListQueue<double>(); // milliseconds
  Duration? _lastTimestamp;
  final _controller = StreamController<FpsSnapshot>.broadcast();
  bool _isRunning = false;
  bool _callbackRegistered = false;
  int _lastBroadcastMs = 0;

  // ── Public API ──────────────────────────────────────────────────────

  /// Broadcast stream of performance snapshots, emitted every 250ms.
  Stream<FpsSnapshot> get stream => _controller.stream;

  /// The most recent performance snapshot.
  FpsSnapshot get current => _buildSnapshot();

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    if (!_callbackRegistered) {
      _callbackRegistered = true;
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    }
  }

  void stop() {
    // SchedulerBinding has no removeFrameCallback — we gate via flag.
    _isRunning = false;
    _frameDurations.clear();
    _lastTimestamp = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  // ── Private ─────────────────────────────────────────────────────────

  void _onFrame(Duration timestamp) {
    if (!_isRunning || _controller.isClosed) return;

    if (_lastTimestamp != null) {
      final deltaMs = (timestamp - _lastTimestamp!).inMicroseconds / 1000.0;
      if (deltaMs > 0) {
        if (_frameDurations.length >= sampleSize) {
          _frameDurations.removeFirst();
        }
        _frameDurations.addLast(deltaMs);

        // Use frame timestamp for throttling — avoids DateTime.now() syscall.
        final nowMs = timestamp.inMilliseconds;
        if (nowMs - _lastBroadcastMs > 250) {
          _controller.add(_buildSnapshot());
          _lastBroadcastMs = nowMs;
        }
      }
    }
    _lastTimestamp = timestamp;
  }

  FpsSnapshot _buildSnapshot() {
    if (_frameDurations.isEmpty) {
      return const FpsSnapshot(
          fps: 0, avgFrameMs: 0, worstFrameMs: 0, samples: []);
    }
    final samples = _frameDurations.toList();
    final avgMs = samples.reduce((a, b) => a + b) / samples.length;
    final worstMs = samples.reduce((a, b) => a > b ? a : b);
    final fps = avgMs > 0 ? (1000 / avgMs).clamp(0, 120) : 0;
    return FpsSnapshot(
      fps: fps.toDouble(),
      avgFrameMs: avgMs,
      worstFrameMs: worstMs,
      samples: List.unmodifiable(samples),
    );
  }
}

/// Immutable snapshot of current FPS metrics.
class FpsSnapshot {
  const FpsSnapshot({
    required this.fps,
    required this.avgFrameMs,
    required this.worstFrameMs,
    required this.samples,
  });

  /// Computed frames per second.
  final double fps;

  /// Average frame duration in milliseconds.
  final double avgFrameMs;

  /// Duration of the slowest frame in the current window in milliseconds.
  final double worstFrameMs;

  /// Raw frame durations (ms) for the rolling window, oldest-first.
  final List<double> samples;

  /// Budget: 16.67ms at 60fps. Frames exceeding this are jank.
  static const double budgetMs = 16.67;

  bool get isJanky => avgFrameMs > budgetMs;
  int get jankyFrameCount => samples.where((s) => s > budgetMs).length;
}
