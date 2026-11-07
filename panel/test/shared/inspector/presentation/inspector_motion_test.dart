import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("reduced motion: the inspector appears at once", (tester) async {
    final panel = await tester.pumpPanel(
      const [reducedMotion],
      at: const PanelLocation.component(
        SizedBox(
          width: 1600,
          height: 800,
          child: InspectorScaffold(child: SizedBox.expand()),
        ),
      ),
    );

    panel.container.read(selectionProvider.notifier).selectAll([
      TestSelectableIdentifier(id: "test-item"),
    ]);
    await tester.pump();
    await tester.pump();

    expect(panel.inspector.rect.width, closeTo(kInspectorDefaultSize, 1));
    // One frame for the layout that follows the selection; nothing moves.
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
