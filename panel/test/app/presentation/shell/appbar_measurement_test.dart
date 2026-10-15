import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

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
    await tester.pumpTestApp(
      child: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: AnimatedBuilder(
            animation: Listenable.merge([width, label]),
            builder: (context, _) => _MeasureThenAllocate(
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
    );
    focus.requestFocus();
    await tester.pump();
    final button = tester.element(find.byType(TextButton));
    final popup = tester.element(find.byType(AnchoredPopup));
    label.value = "2 issues";
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(focus.hasFocus, isTrue);
    width.value = 48;
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(tester.element(find.byType(TextButton)), same(button));
    expect(find.text("Publish saved changes"), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "Retain this filter");
    final field = tester.element(find.byType(TextField));
    for (final extent in [240.0, 48.0, 300.0]) {
      label.value = "${extent.round()} issues";
      await tester.pump();
      width.value = extent;
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(AnchoredPopup)), same(popup));
      expect(tester.element(find.byType(TextField)), same(field));
      expect(find.text("Retain this filter"), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

class _MeasureThenAllocate extends SingleChildRenderObjectWidget {
  const _MeasureThenAllocate({required this.width, required super.child});
  final double width;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasure(width);
  @override
  void updateRenderObject(BuildContext context, _RenderMeasure renderObject) {
    renderObject
      ..width = width
      ..markNeedsLayout();
  }
}

class _RenderMeasure extends RenderProxyBox {
  _RenderMeasure(this.width);
  double width;
  @override
  void performLayout() {
    child!.layout(const BoxConstraints(maxHeight: 48), parentUsesSize: true);
    child!.layout(BoxConstraints.tight(Size(width, 48)), parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }
}
