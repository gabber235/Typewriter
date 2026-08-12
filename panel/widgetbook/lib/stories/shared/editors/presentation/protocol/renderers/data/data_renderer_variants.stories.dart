import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "[Shared]/Editors/Presentation protocol/Renderers/Data states";

final dataRendererVariantScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.conditional,
    name: "Conditional false branch",
    type: const BooleanType(),
    value: const BooleanValue(false),
    presentation: storyNode(
      "conditionalFalse",
      PresentationElement.conditional(
        condition: bindingExpression(rootBinding, const BooleanType()),
        whenTrue: storyNode(
          "trueBranch",
          PresentationElement.text("Visible when true".asStringLiteral),
        ),
        whenFalse: storyNode(
          "falseBranch",
          PresentationElement.text("Visible when false".asStringLiteral),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.repeated,
    name: "Custom repeated empty state",
    type: const ListType(element: StringType()),
    value: const ListValue([]),
    presentation: storyNode(
      "emptyRepeated",
      PresentationElement.repeated(
        source: bindingExpression(
          rootBinding,
          const ListType(element: StringType()),
        ),
        itemBindingId: const BindingId(1),
        template: storyNode(
          "repeatedTemplate",
          PresentationElement.text("Unused template".asStringLiteral),
        ),
        empty: storyNode(
          "customEmpty",
          PresentationElement.section(
            title: "No objectives yet".asStringLiteral,
            description: "This content comes from RepeatedElement.empty."
                .asStringLiteral,
            child: storyNode(
              "customEmptyText",
              PresentationElement.text(
                "Add the first objective when the quest is ready."
                    .asStringLiteral,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.typedField,
    name: "Mismatched typed field",
    type: const StringType(),
    value: const StringValue("Not a boolean"),
    presentation: storyNode(
      "mismatchedTypedField",
      const PresentationElement.typedField(
        binding: rootBinding,
        expectedType: BooleanType(),
      ),
    ),
  ),
];

@widgetbook.UseCase(
  name: "Conditional false",
  type: PresentationRendererStory,
  path: _path,
)
Widget conditionalFalseUseCase(BuildContext context) =>
    rendererStory(context, dataRendererVariantScenarios[0]);

@widgetbook.UseCase(
  name: "Custom repeated empty",
  type: PresentationRendererStory,
  path: _path,
)
Widget customRepeatedEmptyUseCase(BuildContext context) =>
    rendererStory(context, dataRendererVariantScenarios[1]);

@widgetbook.UseCase(
  name: "Mismatched typed field",
  type: PresentationRendererStory,
  path: _path,
)
Widget mismatchedTypedFieldUseCase(BuildContext context) =>
    rendererStory(context, dataRendererVariantScenarios[2]);
