import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  final showcases = <String, Widget>{
    "foundation": const FoundationShowcase(),
    "controls": const ControlsShowcase(),
    "domain_colors": const DomainColorShowcase(),
  };

  for (final brightness in Brightness.values) {
    for (final entry in showcases.entries) {
      testWidgets("${entry.key} ${brightness.name}", (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view
          ..physicalSize = const Size(1200, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 900),
              devicePixelRatio: 1,
              textScaler: TextScaler.noScaling,
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: const ValueKey("design-system-golden"),
              child: FakeApp(
                locale: const Locale("en", "US"),
                themeMode: brightness == Brightness.light
                    ? ThemeMode.light
                    : ThemeMode.dark,
                child: entry.value,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await expectLater(
          find.byKey(const ValueKey("design-system-golden")),
          matchesGoldenFile("goldens/${entry.key}_${brightness.name}.png"),
        );
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
