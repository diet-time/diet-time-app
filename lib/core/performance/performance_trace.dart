import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

/// Opt in on profile/release builds with --dart-define=PERFORMANCE_TRACE=true.
/// Labels must be static: never include tokens, phone numbers or customer IDs.
abstract final class PerformanceTrace {
  static const enabled = bool.fromEnvironment('PERFORMANCE_TRACE');

  static void record(String operation, Stopwatch watch, {String? outcome}) {
    if (!enabled) return;
    developer.log(
      '$operation duration_us=${watch.elapsedMicroseconds}'
      '${outcome == null ? '' : ' outcome=$outcome'}',
      name: 'diet_time.performance',
    );
    developer.Timeline.instantSync(
      operation,
      arguments: {
        'duration_us': watch.elapsedMicroseconds,
        'outcome': ?outcome,
      },
    );
  }

  static Future<T> measure<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    final watch = Stopwatch()..start();
    try {
      final result = await action();
      record(operation, watch, outcome: 'success');
      return result;
    } catch (_) {
      record(operation, watch, outcome: 'failure');
      rethrow;
    }
  }
}

/// Call only when successful data (including a valid empty state) is rendered.
mixin FirstContentTrace<T extends StatefulWidget> on State<T> {
  final Stopwatch _contentWatch = Stopwatch()..start();
  bool _contentFrameQueued = false;

  void traceFirstContent(String screen, {required bool ready}) {
    if (!PerformanceTrace.enabled || !ready || _contentFrameQueued) return;
    _contentFrameQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PerformanceTrace.record('$screen.first_content_frame', _contentWatch);
      }
    });
  }
}

/// Records navigation-to-first-frame. Data-ready timings are separate so a
/// skeleton is never reported as meaningful content.
class PerformanceNavigatorObserver extends NavigatorObserver {
  void _frame(Route<dynamic>? route) {
    if (!PerformanceTrace.enabled || route == null) return;
    final watch = Stopwatch()..start();
    // GoRouter page names are route templates; do not log arguments or URLs.
    final name = route.settings.name ?? route.runtimeType.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceTrace.record('navigation.$name.first_frame', watch);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _frame(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _frame(previousRoute);
}
