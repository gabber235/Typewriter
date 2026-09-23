import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("AdaptiveLeadingLayout", () {
    testWidgets("positions center at the widget midpoint when space allows", (
      tester,
    ) async {
      const centerKey = ValueKey("center");

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              height: 50,
              child: AdaptiveLeadingLayout(
                leading: SizedBox(width: 100, height: 20),
                center: SizedBox(key: centerKey, width: 60, height: 20),
              ),
            ),
          ),
        ),
      );

      final layoutCenter = tester.getCenter(find.byType(AdaptiveLeadingLayout));
      final centerCenter = tester.getCenter(find.byKey(centerKey));

      expect(centerCenter.dx, layoutCenter.dx);
    });

    testWidgets("positions center after leading when midpoint would overlap", (
      tester,
    ) async {
      const leadingKey = ValueKey("leading");
      const centerKey = ValueKey("center");

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: AdaptiveLeadingLayout(
                leading: SizedBox(key: leadingKey, width: 100, height: 20),
                center: SizedBox(key: centerKey, width: 40, height: 20),
              ),
            ),
          ),
        ),
      );

      final leadingRight = tester.getTopRight(find.byKey(leadingKey)).dx;
      final centerLeft = tester.getTopLeft(find.byKey(centerKey)).dx;

      expect(centerLeft, leadingRight + 8);
    });

    testWidgets("uses the configured gap", (tester) async {
      const leadingKey = ValueKey("leading");
      const centerKey = ValueKey("center");

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: AdaptiveLeadingLayout(
                gap: 12,
                leading: SizedBox(key: leadingKey, width: 100, height: 20),
                center: SizedBox(key: centerKey, width: 40, height: 20),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byKey(centerKey)).dx,
        tester.getTopRight(find.byKey(leadingKey)).dx + 12,
      );
    });

    testWidgets("removes a hidden suffix from focus and semantics", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final width = ValueNotifier(240.0);
      final suffixFocus = FocusNode();
      addTearDown(() {
        width.dispose();
        suffixFocus.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ValueListenableBuilder(
              valueListenable: width,
              builder: (context, value, child) => SizedBox(
                width: value,
                height: 50,
                child: AdaptiveLeadingLayout(
                  leading: const SizedBox(width: 40, height: 20),
                  center: const SizedBox(width: 80, height: 20),
                  suffix: TextButton(
                    focusNode: suffixFocus,
                    onPressed: () {},
                    child: const Text("Suffix"),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      suffixFocus.requestFocus();
      await tester.pump();
      expect(suffixFocus.hasFocus, isTrue);

      width.value = 130;
      await tester.pump();
      await tester.pump();

      expect(suffixFocus.hasFocus, isFalse);
      expect(find.semantics.byLabel("Suffix"), findsNothing);
      semantics.dispose();
    });

    testWidgets("keeps wide slots visible across unrelated rebuilds", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final rebuild = ValueNotifier(0);
      addTearDown(rebuild.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder(
            valueListenable: rebuild,
            builder: (context, value, child) => SizedBox(
              width: 300,
              height: 50,
              child: AdaptiveLeadingLayout(
                leading: const SizedBox(width: 40, height: 20),
                center: const Text("Center"),
                suffix: const Text("Suffix"),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel("Center"), findsOne);
      expect(find.semantics.byLabel("Suffix"), findsOne);
      semantics.dispose();

      rebuild.value = 1;
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel("Center"), findsOne);
      expect(find.semantics.byLabel("Suffix"), findsOne);
    });

    testWidgets("rejects an unbounded host", (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              AdaptiveLeadingLayout(leading: SizedBox(width: 20, height: 20)),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isFlutterError);
    });
  });
}
