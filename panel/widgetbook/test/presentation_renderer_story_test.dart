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
