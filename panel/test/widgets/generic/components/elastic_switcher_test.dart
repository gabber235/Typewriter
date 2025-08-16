import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/elastic_switcher.dart";

import "../../../test_utils.dart";

void main() {
  group("ElasticSwitcher", () {
    testWidgets("switches children with animation", (tester) async {
      const firstKey = ValueKey("first");
      const secondKey = ValueKey("second");

      final mode = ValueNotifier<bool>(false);

      final first = SizedBox(
        key: firstKey,
        width: 40,
        height: 24,
        child: const ColoredBox(color: Colors.red),
      );
      final second = SizedBox(
        key: secondKey,
        width: 140,
        height: 48,
        child: const ColoredBox(color: Colors.green),
      );

      await tester.pumpTestApp(
        child: AnimatedBuilder(
          animation: mode,
          builder: (_, __) => ElasticSwitcher(
            child: mode.value ? second : first,
          ),
        ),
      );

      expect(find.byKey(firstKey), findsOneWidget);
      expect(find.byKey(secondKey), findsNothing);

      mode.value = true;
      await tester.pump();

      expect(find.byKey(firstKey), findsOneWidget);
      expect(find.byKey(secondKey), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byKey(firstKey), findsNothing);
      expect(find.byKey(secondKey), findsOneWidget);
    });

    testWidgets("animates size between children", (tester) async {
      const firstKey = ValueKey("first");
      const secondKey = ValueKey("second");

      const smallWidth = 40.0;
      const smallHeight = 24.0;
      const largeWidth = 140.0;
      const largeHeight = 48.0;

      final mode = ValueNotifier<bool>(false);

      final first = SizedBox(
        key: firstKey,
        width: smallWidth,
        height: smallHeight,
        child: const ColoredBox(color: Colors.red),
      );
      final second = SizedBox(
        key: secondKey,
        width: largeWidth,
        height: largeHeight,
        child: const ColoredBox(color: Colors.green),
      );

      await tester.pumpTestApp(
        child: AnimatedBuilder(
          animation: mode,
          builder: (_, __) => ElasticSwitcher(
            child: mode.value ? second : first,
          ),
        ),
      );

      final switcherFinder = find.byType(AnimatedSize);

      final initialSize = tester.getSize(switcherFinder);
      expect(initialSize.width, smallWidth);
      expect(initialSize.height, smallHeight);

      mode.value = true;
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 100));
      final midSize = tester.getSize(switcherFinder);
      expect(midSize.width, greaterThan(smallWidth));
      expect(midSize.width, lessThan(largeWidth));
      expect(midSize.height, greaterThan(smallHeight));
      expect(midSize.height, lessThan(largeHeight));

      await tester.pump(const Duration(milliseconds: 1000));
      final finalSize = tester.getSize(switcherFinder);
      expect(finalSize.width, closeTo(largeWidth, 0.01));
      expect(finalSize.height, closeTo(largeHeight, 0.01));
    });
  });
}
