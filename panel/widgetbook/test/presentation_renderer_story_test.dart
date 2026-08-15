import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/content/content_renderer.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/data/data_renderer.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/data/data_renderer_variants.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/input/input_renderer_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/input/input_renderer_variants.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/interaction/interaction_renderer.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/interaction/interaction_renderer_variants.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/layout/layout_renderer_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";

void main() {
  final primaryScenarios = [
    ...contentRendererScenarios,
    ...dataRendererScenarios,
    ...inputRendererScenarios,
    ...interactionRendererScenarios,
    ...layoutRendererScenarios,
  ];
  final scenarios = [
    ...primaryScenarios,
    customRepeatedEmptyScenario,
    ...dataRendererVariantScenarios,
    ...inputRendererVariantScenarios,
    ...interactionRendererVariantScenarios,
  ];

  test("every concrete renderer has one primary Widgetbook scenario", () {
    expect(
      primaryScenarios.map((scenario) => scenario.kind).toSet(),
      RendererStoryKind.values.toSet(),
    );
    expect(primaryScenarios, hasLength(RendererStoryKind.values.length));

    for (final scenario in primaryScenarios) {
      expect(
        scenario.presentation.element.rendererStoryKind,
        scenario.kind,
        reason: scenario.name,
      );
    }
  });

  test("every renderer story starts with a valid typed value", () {
    for (final scenario in scenarios) {
      final registry = TypeRegistry(TypeCatalog(scenario.definitions));
      expect(
        scenario.value.validateAgainst(scenario.type, registry: registry),
        isEmpty,
        reason: scenario.name,
      );
    }
  });

  testWidgets("conditional story changes branches inside the canvas", (
    tester,
  ) async {
    await tester.pumpWidget(
      PresentationRendererStory(
        scenario: conditionalRendererScenario,
        width: 520,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Timed dialogue"), findsOneWidget);
    expect(find.text("Text"), findsOneWidget);
    expect(find.text("Typing duration"), findsOneWidget);
    expect(find.text("Wait duration"), findsOneWidget);
    expect(find.text("Allow skip"), findsOneWidget);
    expect(find.text("Timed dialogue hidden"), findsNothing);

    await tester.enterText(
      find.byType(EditableText).first,
      "Meet me beside the old watchtower at dusk.",
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text("Timed dialogue"), findsNothing);
    expect(find.text("Timed dialogue hidden"), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text("Timed dialogue"), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      "Meet me beside the old watchtower at dusk.",
    );
  });

  testWidgets("focused story controls expose their contextual action", (
    tester,
  ) async {
    final textInputScenario = inputRendererScenarios.singleWhere(
      (scenario) => scenario.kind == RendererStoryKind.textInput,
    );

    await tester.pumpWidget(
      PresentationRendererStory(scenario: textInputScenario, width: 520),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(find.text("Focus Input"), findsOneWidget);
  });

  testWidgets("three tabs change their visible local content", (tester) async {
    final tabsScenario = layoutRendererScenarios.singleWhere(
      (scenario) => scenario.kind == RendererStoryKind.tabs,
    );

    await tester.pumpWidget(
      PresentationRendererStory(scenario: tabsScenario, width: 520),
    );
    await tester.pumpAndSettle();

    expect(find.text("General settings"), findsOneWidget);

    await tester.tap(find.text("Advanced"));
    await tester.pumpAndSettle();

    expect(find.text("General settings"), findsNothing);
    expect(find.text("Advanced settings"), findsOneWidget);
  });

  testWidgets("four tabs change their visible local content", (tester) async {
    await tester.pumpWidget(
      PresentationRendererStory(
        scenario: dropdownTabsRendererScenario,
        width: 520,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("General settings"), findsOneWidget);

    await tester.tap(find.text("General"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("History").last);
    await tester.pumpAndSettle();

    expect(find.text("General settings"), findsNothing);
    expect(find.text("Change history"), findsOneWidget);
  });

  testWidgets("unavailable realm actions expose their diagnostic", (
    tester,
  ) async {
    await tester.pumpWidget(
      PresentationRendererStory(
        scenario: interactionRendererVariantScenarios[1],
        width: 520,
      ),
    );

    await tester.tap(find.text("Invoke unavailable action"));
    await tester.pump();

    expect(find.text("Realm actions are unavailable"), findsOneWidget);
  });
}
