import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _icon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"> '
    '<path fill="currentColor" d="M4 4h16v16H4z"/></svg>';

void main() {
  for (final (declared, face) in [
    (skir.OperationEmphasis.filled, ButtonFace.filled),
    (skir.OperationEmphasis.outline, ButtonFace.outlined),
    (skir.OperationEmphasis.flat, ButtonFace.quiet),
  ]) {
    testWidgets(
      "${declared.kind.name} shows the declared icon on the button and in "
      "the context menu",
      (tester) async {
        final presentation = skir.OperationPresentation(
          inspector: skir.OperationInspector.shown,
          emphasis: declared,
          shortcut: skir.OperationShortcut.delete,
          label: "Delete",
          description: "Delete the selected resources",
          icon: _icon,
          group: skir.OperationGroup.destructive,
          order: 0,
          confirmation: null,
          tone: skir.HeaderActionTone.destructive,
        );
        final operation = ResourceSelectionOperation(
          scope: AuthoringScope(
            organizationId: skir.recordId("organization:appearance"),
            realmId: skir.recordId("realm:appearance"),
          ),
          invocation: skir.OperationInvocation(
            invocationId: skir.InvocationId(value: "appearance"),
            catalog: skir.CatalogGeneration(value: "appearance"),
            targets: [skir.ResourceId(value: "book:appearance")],
            origin: skir.OperationOrigin(
              container: null,
              occurrences: const [],
            ),
          ),
          operation: skir.ResolvedResourceOperation(
            definition: skir.ResourceOperationDefinition(
              id: skir.ResourceOperationId(
                artifact: "typewriter",
                sourcePart: "main",
                declaration: "com.typewritermc.operations.Delete",
              ),
              presentation: presentation,
              targets: skir.OperationTargets(
                subject: skir.ResourceTarget.anyResource,
                cardinality: skir.OperationCardinality.selection,
              ),
              capability: skir.CapabilityId(value: "operations:Delete"),
              drop: null,
            ),
            availability: skir.OperationAvailability.enabled,
          ),
        );
        await tester.pumpPanel(
          const [],
          at: PanelLocation.component(
            Consumer(
              builder: (context, ref, _) => ContextMenuRegion(
                items: [operation.menuItem(ref)],
                child: operation.inspectorButton(
                  const [],
                  emphasis: operation.emphasis,
                ),
              ),
            ),
          ),
        );
        final buttonFinder = find.byWidgetPredicate(
          (widget) => widget is Button && widget.face == face,
        );
        expect(buttonFinder, findsOneWidget);
        expect(
          semanticsButton("Delete").getSemanticsData().hint,
          "Destructive",
        );
        expect(tester.widget<Icones>(find.byType(Icones)).icon, _icon);
        await tester.tap(buttonFinder, buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();
        // The button and the menu entry both show the declared icon.
        expect(
          tester.widgetList<Icones>(find.byType(Icones)).map((i) => i.icon),
          [_icon, _icon],
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      "${declared.kind.name} keeps keyboard activation and disabled reasons",
      (tester) async {
        var invocations = 0;
        Future<void> pump({
          String? disabledReason,
          skir.HeaderActionTone tone = skir.HeaderActionTone.destructive,
        }) => tester.pumpPanel(
          const [],
          at: PanelLocation.component(
            SizedBox(
              width: 160,
              child: ResourceOperationButton(
                presentation: skir.OperationPresentation(
                  inspector: skir.OperationInspector.shown,
                  emphasis: declared,
                  shortcut: null,
                  label: "An operation with a long label",
                  description: "Run this operation",
                  icon: _icon,
                  group: skir.OperationGroup.destructive,
                  order: 0,
                  confirmation: null,
                  tone: tone,
                ),
                disabledReason: disabledReason,
                command: ActionShortcut(
                  id: "resource_operation_button_test",
                  label: "An operation with a long label",
                  description: "Run this operation",
                  activators: const [],
                  priority: 0,
                  show: false,
                  run: ActionRun.press((_) => invocations++),
                ),
              ),
            ),
          ),
        );
        await pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(invocations, 1);
        expect(tester.takeException(), isNull);

        await pump(disabledReason: "This view is read only");
        final button = semanticsButton("An operation with a long label");
        expect(button.isEnabled, isFalse);
        expect(find.tooltip("This view is read only"), findsOneWidget);
        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is Button && widget.face == face,
          ),
        );
        await tester.pumpAndSettle();
        expect(invocations, 1);

        await pump(tone: skir.HeaderActionTone.neutral);
        expect(
          semanticsButton("An operation with a long label")
              .getSemanticsData()
              .hint,
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
