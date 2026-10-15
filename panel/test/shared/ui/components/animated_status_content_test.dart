import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("label removal also removes its spacing", (tester) async {
    String? label;
    Future<void> build() => tester.pumpTestApp(
      child: Center(
        child: AnimatedStatusContent(
          icon: const Icon(
            Icons.inbox_outlined,
            key: ValueKey("inbox"),
            size: 18,
          ),
          label: label,
          compact: false,
        ),
      ),
    );
    await build();
    final emptyWidth = tester.getSize(find.byType(AnimatedStatusContent)).width;
    expect(emptyWidth, 18);
    label = "2 issues";
    await build();
    expect(
      tester.getSize(find.byType(AnimatedStatusContent)).width,
      greaterThan(emptyWidth),
    );
    label = null;
    await build();
    expect(find.text("2 issues"), findsNothing);
    expect(
      tester.getSize(find.byType(AnimatedStatusContent)).width,
      emptyWidth,
    );
  });

  testWidgets("compact layout drops outgoing labels during animation", (
    tester,
  ) async {
    var label = "Checking";
    var compact = false;
    Future<void> build() => tester.pumpTestApp(
      settle: false,
      child: Center(
        child: SizedBox(
          width: compact ? 24 : 200,
          child: AnimatedStatusContent(
            icon: const Icon(Icons.sync, key: ValueKey("sync"), size: 18),
            label: label,
            compact: compact,
          ),
        ),
      ),
    );
    await build();
    label = "2 issues";
    await build();
    expect(find.text("Checking"), findsOneWidget);
    expect(find.text("2 issues"), findsOneWidget);
    compact = true;
    await build();
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets("reduced motion replaces decorations immediately", (
    tester,
  ) async {
    var issue = false;
    Future<void> build() => tester.pumpTestApp(
      settle: false,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: Center(
            child: AnimatedStatusContent(
              compact: false,
              icon: Icon(
                issue ? Icons.error_outline : Icons.sync,
                key: ValueKey(issue),
                size: 18,
              ),
              label: issue ? "2 issues" : "Checking",
            ),
          ),
        ),
      ),
    );
    await build();
    issue = true;
    await build();
    expect(find.text("Checking"), findsNothing);
    expect(find.byIcon(Icons.sync), findsNothing);
    expect(find.text("2 issues"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
