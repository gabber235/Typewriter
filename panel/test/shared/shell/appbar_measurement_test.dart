import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("measuring a responsive trigger preserves its focus and popup", (
    tester,
  ) async {
    final width = ValueNotifier<double>(240);
    final label = ValueNotifier("Publish saved changes");
    addTearDown(label.dispose);
    final focus = FocusNode();
    addTearDown(width.dispose);
    addTearDown(focus.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox.fromSize(
          size: desktopWindow,
          child: Align(
            alignment: Alignment.topRight,
            child: AnimatedBuilder(
              animation: Listenable.merge([width, label]),
              builder: (context, _) => MeasureThenAllocate(
                width: width.value,
                child: AnchoredPopup(
                  builder: (context, open) => AppBarControl.text(
                    focusNode: focus,
                    onPressed: open,
                    contentBuilder: (context, compact) => AnimatedStatusContent(
                      compact: compact,
                      icon: const Icon(
                        Icons.inbox_outlined,
                        key: ValueKey("inbox"),
                        size: 18,
                      ),
                      label: label.value,
                    ),
                    tooltip: "Realm inbox",
                    semanticLabel: "Realm inbox",
                  ),
                  popupBuilder: (context, close) => const SizedBox(
                    width: 280,
                    child: TextField(autofocus: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    label.value = "2 issues";
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(focus.hasFocus, isTrue);
    width.value = 48;
    await panel.settle();
    expect(focus.hasFocus, isTrue);
    expect(panel.shows("Publish saved changes"), isFalse);
    await panel.press(LogicalKeyboardKey.enter);
    tester.testTextInput.enterText("Retain this filter");
    for (final extent in [240.0, 48.0, 300.0]) {
      label.value = "${extent.round()} issues";
      await tester.pump();
      width.value = extent;
      await panel.settle();
      expect(panel.shows("Retain this filter"), isTrue);
      expect(tester.takeException(), isNull);
    }
  });
}
