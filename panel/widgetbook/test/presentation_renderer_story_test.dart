import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
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

  for (final scenario in scenarios) {
    testWidgets("renders ${scenario.name}", (tester) async {
      await tester.pumpWidget(
        PresentationRendererStory(scenario: scenario, width: 520),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("three tabs use the segmented selector and change locally", (
    tester,
  ) async {
    var storyBuilds = 0;
    final tabsScenario = layoutRendererScenarios.singleWhere(
      (scenario) => scenario.kind == RendererStoryKind.tabs,
    );

    await tester.pumpWidget(
      _BuildCounter(
        onBuild: () => storyBuilds++,
        child: PresentationRendererStory(scenario: tabsScenario, width: 520),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(CupertinoSlidingSegmentedControl<String>),
      findsOneWidget,
    );
    expect(find.byType(Dropdown<String>), findsNothing);
    expect(find.text("General settings"), findsOneWidget);

    await tester.tap(find.text("Advanced"));
    await tester.pumpAndSettle();

    expect(find.text("General settings"), findsNothing);
    expect(find.text("Advanced settings"), findsOneWidget);
    expect(storyBuilds, 1);
  });

  testWidgets("four tabs use the dropdown and change locally", (tester) async {
    var storyBuilds = 0;

    await tester.pumpWidget(
      _BuildCounter(
        onBuild: () => storyBuilds++,
        child: PresentationRendererStory(
          scenario: dropdownTabsRendererScenario,
          width: 520,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dropdown<String>), findsOneWidget);
    expect(find.byType(CupertinoSlidingSegmentedControl<String>), findsNothing);
    expect(find.text("General settings"), findsOneWidget);
    expect(
      tester.getSize(find.byType(InputFieldContainer)).width,
      tester.getSize(find.byType(EditorProtocolRenderer)).width,
    );

    tester.widget<Dropdown<String>>(find.byType(Dropdown<String>)).onSelected!(
      "history",
    );
    await tester.pumpAndSettle();

    expect(find.text("General settings"), findsNothing);
    expect(find.text("Change history"), findsOneWidget);
    expect(storyBuilds, 1);
  });

  testWidgets("enum input dropdown fills the editor width", (tester) async {
    final enumScenario = inputRendererScenarios.singleWhere(
      (scenario) => scenario.kind == RendererStoryKind.enumInput,
    );

    await tester.pumpWidget(
      PresentationRendererStory(scenario: enumScenario, width: 520),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dropdown<DataValue>), findsOneWidget);
    expect(
      tester.getSize(find.byType(InputFieldContainer)).width,
      tester.getSize(find.byType(EditorProtocolRenderer)).width,
    );
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

class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild, required this.child});

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}
