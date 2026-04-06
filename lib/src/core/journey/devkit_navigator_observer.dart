import 'package:flutter/widgets.dart';

import '../../blackbox.dart';
import 'journey_event.dart';
import 'journey_store.dart';

class BlackBoxNavigatorObserver extends NavigatorObserver {
  BlackBoxNavigatorObserver(this._store);
  final JourneyStore _store;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!BlackBox.instance.isEnabled) return;
    _store.record(RouteEvent(DateTime.now(),
        route: route.settings.name ?? route.runtimeType.toString()));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!BlackBox.instance.isEnabled) return;
    _store.record(RouteEvent(DateTime.now(),
        route: 'popped ${route.settings.name ?? route.runtimeType}'));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (!BlackBox.instance.isEnabled) return;
    if (newRoute != null) {
      _store.record(RouteEvent(DateTime.now(),
          route:
              'replaced with ${newRoute.settings.name ?? newRoute.runtimeType}'));
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!BlackBox.instance.isEnabled) return;
    _store.record(RouteEvent(DateTime.now(),
        route: 'removed ${route.settings.name ?? route.runtimeType}'));
  }
}
