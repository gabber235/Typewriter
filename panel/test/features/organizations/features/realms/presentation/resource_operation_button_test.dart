import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

const _icon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"> '
    '<path fill="currentColor" d="M4 4h16v16H4z"/></svg>';

void main() {
  for (final (variant, buttonType) in [
    (skir.ButtonVariant.filled, FilledButton),
    (skir.ButtonVariant.outlined, OutlinedButton),
    (skir.ButtonVariant.text, TextButton),
  ]) {
    testWidgets(
      "${variant.kind.name} retains icons and tone in both surfaces",
      (tester) async {
        final presentation = skir.OperationPresentation(
          inspector: skir.OperationInspector.wrapButton(variant),
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
        await tester.pumpTestApp(
          child: Consumer(
            builder: (context, ref, _) => Center(
              child: ContextMenuRegion(
                items: [operation.menuItem(ref)],
                child: operation.inspectorButton(const []),
              ),
            ),
          ),
        );
        final buttonFinder = find.byType(buttonType);
        expect(buttonFinder, findsOneWidget);
        expect(tester.widget<Icones>(find.byType(Icones)).icon, _icon);
        final scheme = Theme.of(tester.element(buttonFinder)).colorScheme;
        final button = tester.widget<ButtonStyleButton>(buttonFinder);
        final foreground = variant == skir.ButtonVariant.filled
            ? scheme.onError
            : scheme.error;
        expect(button.style!.foregroundColor!.resolve({}), foreground);
        expect(
          IconTheme.of(tester.element(find.byType(Icones))).color,
          foreground,
        );
        if (variant == skir.ButtonVariant.filled) {
          expect(button.style!.backgroundColor!.resolve({}), scheme.error);
        }
        if (variant == skir.ButtonVariant.outlined) {
          expect(button.style!.side!.resolve({})!.color, scheme.error);
        }

        await tester.tap(buttonFinder, buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();
        final menu = tester.widget<MenuItemButton>(find.byType(MenuItemButton));
        expect(menu.leadingIcon, isA<Icones>());
        expect((menu.leadingIcon! as Icones).icon, _icon);
        expect(menu.style!.foregroundColor!.resolve({}), scheme.error);
        expect(menu.style!.iconColor!.resolve({}), scheme.error);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      "${variant.kind.name} keeps keyboard activation and disabled reasons",
      (tester) async {
        var invocations = 0;
        Future<void> pump({String? disabledReason}) => tester.pumpTestApp(
          child: Center(
            child: SizedBox(
              width: 160,
              child: ResourceOperationButton(
                presentation: skir.OperationPresentation(
                  inspector: skir.OperationInspector.wrapButton(variant),
                  shortcut: null,
                  label: "An operation with a long label",
                  description: "Run this operation",
                  icon: _icon,
                  group: skir.OperationGroup.destructive,
                  order: 0,
                  confirmation: null,
                  tone: skir.HeaderActionTone.destructive,
                ),
                disabledReason: disabledReason,
                onInvoke: () => invocations++,
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
        final button = tester.widget<ButtonStyleButton>(
          find.byType(buttonType),
        );
        expect(button.onPressed, isNull);
        expect(find.byTooltip("This view is read only"), findsOneWidget);
        await tester.tap(find.byType(buttonType));
        await tester.pumpAndSettle();
        expect(invocations, 1);
        final scheme = Theme.of(tester.element(find.byType(buttonType)))
            .colorScheme;
        expect(
          IconTheme.of(tester.element(find.byType(Icones))).color,
          scheme.onSurface.withValues(alpha: 0.38),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
