import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "moves selected definition and no elementDefinition entries together",
    (tester) async {
      final organizationId = recordId("organization:test");
      final realmId = recordId("service:test");
      final definition = generateRandomEntryDefinition().copyWith(
        id: "definition",
        name: "Definition Entry",
        placement: const EntryPlacement(x: 0, y: 0, width: 2, height: 2),
      );
      final elements = [
        PageElement.entry(entry: PageEntry.definition(definition: definition)),
        PageElement.entry(
          entry: PageEntry.missingElementDefinition(
            id: "missing_definition",
            name: "Missing Element Definition Entry",
            placement: const EntryPlacement(x: 3, y: 0, width: 2, height: 2),
            inwardLinks: const [],
            outwardLinks: const [],
          ),
        ),
      ];

      await tester.pumpTestApp(
        settle: false,
        overrides: [
          organizationIdProvider.overrideWithValue(organizationId),
          realmIdProvider.overrideWithValue(realmId),
          ...pageElementsProviderOverrides(overwriteElements: elements),
          ...entryProviderOverrides(definition: definition),
          pageDocumentHealthProvider(
            organizationId,
            realmId,
            recordId("page:page"),
          ).overrideWithValue(null),
        ],
        child: const SizedBox(
          width: 800,
          height: 600,
          child: EntryGraph(pageId: "page"),
        ),
      );
      await tester.pumpAndSettle();

      final selectors = {
        for (final selector in tester.widgetList<Selector>(
          find.byType(Selector),
        ))
          selector.selectableId.id: selector,
      };
      tester.container().read(selectionProvider.notifier).selectAll([
        const EntryIdentifier("definition"),
        const EntryIdentifier("missing_definition"),
      ]);
      selectors["definition"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(tester.container().read(selectionProvider), [
        const EntryIdentifier("definition"),
        const EntryIdentifier("missing_definition"),
      ]);

      Actions.invoke(
        selectors["definition"]!.focusNode.context!,
        const GraphMoveIntent(direction: TraversalDirection.right),
      );
      await tester.pumpAndSettle();

      final placements = {
        for (final child in tester.widgetList<GraphSurfaceChild>(
          find.byType(GraphSurfaceChild),
        ))
          child.placed.id.id: child.placed,
      };
      expect(placements["definition"]!.bounds.left, 50);
      expect(placements["missing_definition"]!.bounds.left, 200);
    },
  );
}
