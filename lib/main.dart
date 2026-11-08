import 'package:diet_time/app/app.dart';
import 'package:flutter/material.dart';
import 'package:diet_time/core/performance/performance_trace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final startup = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PerformanceTrace.record('startup.first_frame', startup);
  });
  runApp(const ProviderScope(child: DietTimeApp()));
}
