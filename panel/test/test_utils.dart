import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

import "package:flutter_test/flutter_test.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:test_screenshot/test_screenshot.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/app_required.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// Build a reusable test app with ProviderScope, ResponsiveBreakpoints, and MaterialApp.
///
/// - Wraps [child] with ResponsiveFramework breakpoints used throughout the app.
/// - Provides optional [shortcuts] and [actions] for keyboard testing.
/// - Applies [overrides] to the ProviderScope.
/// - Wraps [child] in [AppRequiredWidgets].
Widget testApp({
  required Widget child,
  List<Override> overrides = const [],
  Map<ShortcutActivator, Intent>? shortcuts,
  Map<Type, Action<Intent>>? actions,
}) {
  return Screenshotter(
    child: FakeApp(
      overrides: overrides,
      shortcuts: shortcuts,
      actions: actions,
      child: child,
    ),
  );
}

/// Extensions to simplify pumping common test app setups.
extension WidgetTesterAppX on WidgetTester {
  /// Pump [testApp] with the given [child], optionally settling the frame queue.
  Future<void> pumpTestApp({
    required Widget child,
    List<Override> overrides = const [],
    Map<ShortcutActivator, Intent>? shortcuts,
    Map<Type, Action<Intent>>? actions,
    bool settle = true,
  }) async {
    await pumpWidget(
      testApp(
        child: child,
        overrides: overrides,
        shortcuts: shortcuts,
        actions: actions,
      ),
    );
    if (settle) {
      await pumpAndSettle();
    }
  }

  /// Pump until all the asserts pass.
  Future<void> pumpUntil(
    FutureOr<void> Function() assering, {
    Duration duration = const Duration(milliseconds: 100),
    int maxAttempts = 1000,
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      try {
        await assering();
        return;
      } on TestFailure catch (_) {
        await pump(duration);
      }
    }
    await assering();
  }
}

void setupMocks() {
  setUpAll(registerFallbackValues);
}

/// Screenshot utilities for widget tests.
extension WidgetTesterScreenshotsX on WidgetTester {
  /// Captures a PNG screenshot to [directory]/[name].png.
  ///
  /// - If [finder] is provided, tries:
  ///   1) The render object of [finder] itself if it's a [RenderRepaintBoundary]
  ///   2) A descendant [RepaintBoundary]
  ///   3) An ancestor [RepaintBoundary]
  /// - If [finder] is null, captures the largest on-screen [RepaintBoundary] (typically the entire app).
  /// - Ensures the frame queue is settled before capturing.
  /// - Set [pixelRatio] for higher-resolution captures (default 3.0).
  /// - Set [directory] to customize the output folder (default "test_screenshots").
  ///
  /// Throws [StateError] if no [RenderRepaintBoundary] can be found.
  Future<void> captureScreenshot(
    String name, {
    String directory = "test_screenshots",
  }) async {
    await runAsync(() async {
      final dir = Directory(directory);
      await dir.create(recursive: true);
    });
    await screenshot(path: "$directory/${_sanitizeFileName(name)}.png");
  }
}

String _sanitizeFileName(String input) {
  final sanitized = input
      .trim()
      .snakeCase()
      .replaceAll(RegExp(r"[^\w\-\.\(\) ]+"), "_")
      .replaceAll(RegExp(r"\s+"), "_");
  if (sanitized.isEmpty) return "screenshot";
  return sanitized;
}
