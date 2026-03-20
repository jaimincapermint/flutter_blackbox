import 'dart:async';
import 'package:flutter/gestures.dart';

import '../../devkit.dart';
import 'journey_event.dart';

mixin BlackBoxGestureObserver on GestureBinding {
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (!BlackBox.instance.isEnabled) return;
    if (event is PointerUpEvent) {
      final dx = event.position.dx.toStringAsFixed(0);
      final dy = event.position.dy.toStringAsFixed(0);
      scheduleMicrotask(() {
        BlackBox.instance.journeyStore.record(
          TapEvent(DateTime.now(), location: '($dx, $dy)'),
        );
      });
    }
  }
}
