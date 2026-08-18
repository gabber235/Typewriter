import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

extension LoadingButtonWidgetTesterX on WidgetTester {
  Future<void> pumpLoadingButtonApp({required Widget child}) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await pumpAndSettle();
  }

  Future<void> pumpUntil(
    FutureOr<void> Function() assertion, {
    Duration duration = const Duration(milliseconds: 100),
    int maxAttempts = 1000,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await assertion();
        return;
      } on TestFailure catch (_) {
        await pump(duration);
      }
    }
    await assertion();
  }
}
