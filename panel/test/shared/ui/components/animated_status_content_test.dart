import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("label removal also removes its spacing", (tester) async {
    final label = ValueNotifier<String?>(null);
    addTearDown(label.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: label,
          builder: (context, value, _) => AnimatedStatusContent(
            icon: const Icon(Icons.inbox_outlined, size: 18),
            label: value,
            compact: false,
          ),
        ),
      ),
    );
    double width() => tester.getSize(find.byType(AnimatedStatusContent)).width;
    final emptyWidth = width();
    expect(emptyWidth, 18);

    label.value = "2 issues";
    await panel.settle();
    expect(width(), greaterThan(emptyWidth));

    label.value = null;
    await panel.settle();
    expect(panel.shows("2 issues"), isFalse);
    expect(width(), emptyWidth);
  });

  testWidgets("compact layout drops outgoing labels during animation", (
    tester,
  ) async {
    final state = ValueNotifier((label: "Checking", compact: false));
    addTearDown(state.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: state,
          builder: (context, value, _) => SizedBox(
            width: value.compact ? 24 : 200,
            child: AnimatedStatusContent(
              icon: const Icon(Icons.sync, size: 18),
              label: value.label,
              compact: value.compact,
            ),
          ),
        ),
      ),
    );

    state.value = (label: "2 issues", compact: false);
    await tester.pump();
    expect(panel.shows("Checking"), isTrue);
    expect(panel.shows("2 issues"), isTrue);

    state.value = (label: "2 issues", compact: true);
    await tester.pump();
    expect(panel.shows("Checking"), isFalse);
    expect(panel.shows("2 issues"), isFalse);
    expect(tester.takeException(), isNull);
    await panel.settle();
  });

  testWidgets("reduced motion replaces decorations immediately", (
    tester,
  ) async {
    final issue = ValueNotifier(false);
    addTearDown(issue.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: ValueListenableBuilder(
              valueListenable: issue,
              builder: (context, value, _) => AnimatedStatusContent(
                compact: false,
                icon: Icon(
                  value ? Icons.error_outline : Icons.sync,
                  key: ValueKey(value),
                  size: 18,
                ),
                label: value ? "2 issues" : "Checking",
              ),
            ),
          ),
        ),
      ),
    );

    issue.value = true;
    await tester.pump();

    expect(panel.shows("Checking"), isFalse);
    expect(find.byIcon(Icons.sync), findsNothing);
    expect(panel.shows("2 issues"), isTrue);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
