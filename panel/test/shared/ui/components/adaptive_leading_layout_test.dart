import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("centers the center slot when space allows", (tester) async {
    final panel = await tester.showComponent(
      LabeledBox(
        "Layout",
        width: 300,
        height: 50,
        child: AdaptiveLeadingLayout(
          leading: LabeledBox("Leading", width: 100, height: 20),
          center: LabeledBox("Center", width: 60, height: 20),
        ),
      ),
    );

    expect(
      panel.boundsOf("Center").center.dx,
      panel.boundsOf("Layout").center.dx,
    );
  });

  for (final (gap, expected) in [(null, 8.0), (12.0, 12.0)]) {
    testWidgets(
      "places the center slot ${gap == null ? "the default" : "the configured"} "
      "gap after the leading slot when the midpoint would overlap",
      (tester) async {
        final leading = LabeledBox("Leading", width: 100, height: 20);
        final center = LabeledBox("Center", width: 40, height: 20);
        final panel = await tester.showComponent(
          SizedBox(
            width: 160,
            height: 50,
            child: gap == null
                ? AdaptiveLeadingLayout(leading: leading, center: center)
                : AdaptiveLeadingLayout(
                    gap: gap,
                    leading: leading,
                    center: center,
                  ),
          ),
        );

        expect(
          panel.boundsOf("Center").left,
          panel.boundsOf("Leading").right + expected,
        );
      },
    );
  }

  testWidgets("removes a hidden suffix from focus and semantics", (
    tester,
  ) async {
    final width = ValueNotifier(240.0);
    final suffixFocus = FocusNode();
    addTearDown(width.dispose);
    addTearDown(suffixFocus.dispose);
    final panel = await tester.showComponent(
      ValueListenableBuilder(
        valueListenable: width,
        builder: (context, value, child) => SizedBox(
          width: value,
          height: 50,
          child: AdaptiveLeadingLayout(
            leading: LabeledBox("Leading", width: 40, height: 20),
            center: LabeledBox("Center", width: 80, height: 20),
            suffix: TextButton(
              focusNode: suffixFocus,
              onPressed: () {},
              child: const Text("Suffix"),
            ),
          ),
        ),
      ),
    );
    suffixFocus.requestFocus();
    await panel.settle();
    expect(panel.focused, "Suffix");

    width.value = 130;
    await tester.pump();
    await tester.pump();

    expect(panel.focused, isNot("Suffix"));
    expect(find.semantics.byLabel("Suffix"), findsNothing);
  });

  testWidgets("keeps wide slots visible across unrelated rebuilds", (
    tester,
  ) async {
    final rebuild = ValueNotifier(0);
    addTearDown(rebuild.dispose);
    final panel = await tester.showComponent(
      ValueListenableBuilder(
        valueListenable: rebuild,
        builder: (context, value, child) => SizedBox(
          width: 300,
          height: 50,
          child: AdaptiveLeadingLayout(
            leading: LabeledBox("Leading", width: 40, height: 20),
            center: const Text("Center"),
            suffix: const Text("Suffix"),
          ),
        ),
      ),
    );
    expect(find.semantics.byLabel("Center"), findsOne);
    expect(find.semantics.byLabel("Suffix"), findsOne);

    rebuild.value = 1;
    await panel.settle();

    expect(find.semantics.byLabel("Center"), findsOne);
    expect(find.semantics.byLabel("Suffix"), findsOne);
  });

  testWidgets("derives its height inside a column", (tester) async {
    final panel = await tester.showComponent(
      SingleChildScrollView(
        child: SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledBox(
                "Layout",
                child: AdaptiveLeadingLayout(
                  padding: const EdgeInsets.all(8),
                  leading: LabeledBox("Leading", width: 36, height: 20),
                  center: const Text("Named tag"),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      panel.boundsOf("Layout").height,
      allOf(greaterThan(0), lessThan(tester.view.physicalSize.height)),
    );
    expect(find.text("Named tag"), findsOneWidget);
  });

  testWidgets("rejects an unbounded host", (tester) async {
    await tester.showComponent(
      const Row(
        children: [
          AdaptiveLeadingLayout(leading: SizedBox(width: 20, height: 20)),
        ],
      ),
    );

    expect(tester.takeException(), isFlutterError);
  });
}
