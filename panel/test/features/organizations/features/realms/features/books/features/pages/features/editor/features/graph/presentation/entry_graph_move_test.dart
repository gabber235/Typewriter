import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("moves selected definition and no blueprint entries together", (
    tester,
  ) async {
    final definition = generateRandomEntryDefinition().copyWith(
      id: "definition",
      name: "Definition Entry",
      placement: const EntryPlacement(x: 0, y: 0, width: 2, height: 2),
    );
    final elements = [
      PageElement.entry(entry: PageEntry.definition(definition: definition)),
      PageElement.entry(
        entry: PageEntry.noBlueprint(
          id: "no_blueprint",
          name: "No Blueprint Entry",
          placement: const EntryPlacement(x: 3, y: 0, width: 2, height: 2),
          inwardLinks: const [],
          outwardLinks: const [],
        ),
      ),
    ];

    await tester.pumpTestApp(
      settle: false,
      overrides: [
        ...pageElementsProviderOverrides(overwriteElements: elements),
        ...entryProviderOverrides(definition: definition),
      ],
      child: const SizedBox(
        width: 800,
        height: 600,
        child: EntryGraph(pageId: "page"),
      ),
    );
    await tester.pumpAndSettle();

    final selectors = {
      for (final selector in tester.widgetList<Selector>(find.byType(Selector)))
        selector.selectableId.id: selector,
    };
    tester.container().read(selectionProvider.notifier).selectAll([
      const EntryIdentifier("definition"),
      const EntryIdentifier("no_blueprint"),
    ]);
    selectors["definition"]!.focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(tester.container().read(selectionProvider), [
      const EntryIdentifier("definition"),
      const EntryIdentifier("no_blueprint"),
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
    expect(placements["no_blueprint"]!.bounds.left, 200);
  });
}
