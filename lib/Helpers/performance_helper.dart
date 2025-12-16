import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Performance helper utilities for optimizing app performance
class PerformanceHelper {
  /// Debounce a function call
  static Timer? _debounceTimer;

  static void debounce({
    required VoidCallback action,
    Duration delay = const Duration(milliseconds: 800),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }

  /// Throttle a function call to limit execution frequency
  static DateTime? _lastThrottleTime;

  static void throttle({
    required VoidCallback action,
    Duration duration = const Duration(milliseconds: 16), // ~60fps
  }) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      action();
    }
  }

  /// Run heavy computation in isolate to avoid blocking UI
  static Future<T> runInIsolate<T>(
    T Function() computation,
  ) async {
    return compute((_) => computation(), null);
  }

  /// Batch multiple setState calls into one
  static void batchUpdate(VoidCallback updates) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updates();
    });
  }

  /// Cancel all timers
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastThrottleTime = null;
  }
}

/// Mixin for optimizing list performance
mixin ListPerformanceOptimization {
  /// Get optimal item extent for list items
  double get itemExtent => 70.0;

  /// Whether to use automatic keep alive
  bool get wantKeepAlive => true;

  /// Cache extent multiplier
  double get cacheExtent => 500.0;
}
