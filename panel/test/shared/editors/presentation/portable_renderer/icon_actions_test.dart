import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "an icon action shows progress until it settles and runs only once",
    (tester) async {
      final reveal = Completer<PortablePresentationWriteResult>();
      var runs = 0;
      final host = BoundPresentationHost(
        catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
        root: () => presentationNode(
          "reveal",
          skir.PresentationElement.createIconButton(
            icon: textLiteral("mdi:eye"),
            semanticLabel: textLiteral("Reveal"),
            action: skir.EditorAction.createNavigate(
              resource: textLiteral("book:route"),
              mode: skir.ResourceNavigationMode.reveal,
            ),
            appearance: null,
          ),
        ),
        bindings: const [],
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        capabilities: PortablePresentationCapabilities(
          resourceAction: (action, context) {
            runs++;
            return reveal.future;
          },
        ),
      );
      addTearDown(host.dispose);
      final panel = await tester.showPresentationHost(host);

      await panel.activateWithKeyboard(find.tooltip("Reveal"));
      await tester.pump(const Duration(milliseconds: 300));

      expect(panel.shows("Loading"), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.tooltip("Reveal"), warnIfMissed: false);
      await tester.pump();
      reveal.complete(const PortablePresentationWriteApplied());
      await panel.settle();

      expect(panel.shows("Loading"), isFalse);
      expect(runs, 1);
    },
  );
}
