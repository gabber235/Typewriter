import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/semantic_header_action_scenarios.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/semantic_header_gallery.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/semantic_header_scenarios.dart";

void main() {
  test("every semantic header story starts with a valid typed value", () {
    final scenarios = [
      generatedCompositeScenario(),
      listActionsScenario(),
      mapActionsScenario(),
      mergedHeaderScenario(),
      actionOverflowScenario(),
      actionStatesScenario(),
    ];

    for (final scenario in scenarios) {
      expect(
        scenario.value.validateAgainst(scenario.type),
        isEmpty,
        reason: scenario.description,
      );
    }
  });

  testWidgets("the list story exposes working semantic actions", (
    tester,
  ) async {
    await tester.pumpWidget(
      SemanticHeaderGallery(scenario: listActionsScenario(), width: 560),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip("Add item"), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));

    await tester.tap(find.byTooltip("Add item"));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_handle), findsNWidgets(4));
    expect(find.text("Item 4"), findsOneWidget);
  });

  testWidgets("the map story exposes collection and entry actions", (
    tester,
  ) async {
    await tester.pumpWidget(
      SemanticHeaderGallery(scenario: mapActionsScenario(), width: 560),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip("Add entry"), findsOneWidget);
    expect(find.byTooltip("Remove entry"), findsNWidgets(2));
    expect(find.text("intro"), findsOneWidget);
    expect(find.text("outro"), findsOneWidget);
  });

  testWidgets("the overflow story confirms its destructive action", (
    tester,
  ) async {
    await tester.pumpWidget(
      SemanticHeaderGallery(scenario: actionOverflowScenario(), width: 320),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip("More actions"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Archive"));
    await tester.pumpAndSettle();

    expect(find.text("Archive quest?"), findsOneWidget);
    expect(
      find.text("The quest will no longer be available to players."),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, "Archive"));
    await tester.pumpAndSettle();

    final values = tester
        .widgetList<TextFormField>(
          find.byType(TextFormField, skipOffstage: false),
        )
        .map((field) => field.controller?.text ?? field.initialValue)
        .toList();
    expect(values, contains("Archived quest"));
  });
}
