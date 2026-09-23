import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "moves selected definition and no elementDefinition entries together",
    (tester) async {
      final organizationId = recordId("organization:test");
      final realmId = recordId("service:test");
      final generated = generateRandomEntryDefinition();
      final definition = generated.copyWith(
        id: "definition",
        data: generated.data.withField(
          "name",
          const StringValue("Definition Entry"),
        ),
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
          ...authoringSessionMockOverrides(),
          organizationIdProvider.overrideWithValue(organizationId),
          realmIdProvider.overrideWithValue(realmId),
          selectedProvider.overrideWithValue(const AsyncData([])),
          ...pageElementsProviderOverrides(
            state: DisplayState.fewItems,
            elements: elements,
          ),
          decodedRealmDocumentValuesProvider.overrideWith(
            (ref, _) => ref
                .watch(pageElementsProvider(organizationId, realmId, "page"))
                .when(
                  data: (value) => AsyncData(
                    AuthoringValue(value: {"page": value}, revision: 1),
                  ),
                  error: AsyncError.new,
                  loading: AsyncLoading.new,
                ),
          ),
          ...entryProviderOverrides(definition: definition),
          pageDocumentHealthProvider(
            organizationId,
            realmId,
            skir.ResourceId(value: "page"),
          ).overrideWithValue(null),
        ],
        child: const SizedBox(
          width: 800,
          height: 600,
          child: EntryGraph(pageId: "page"),
        ),
      );
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(GraphSurfaceChild).evaluate().length == 2) break;
      }
      expect(find.byType(GraphSurfaceChild), findsNWidgets(2));

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
