import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "[Shared]/Editors/Presentation protocol/Renderers/Data";
const _itemBinding = BindingReference(bindingId: BindingId(1));

final dataRendererScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.diagnostic,
    name: "Diagnostic",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "diagnostic",
      PresentationElement.diagnostic([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message:
              "This value cannot be displayed using the requested renderer.",
        ),
      ]),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.defaultPresentation,
    name: "Default presentation",
    type: const StringType(),
    value: const StringValue("Generated control"),
    presentation: storyNode(
      "defaultPresentation",
      const PresentationElement.defaultPresentation(binding: rootBinding),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.typedField,
    name: "Typed field",
    type: const StringType(),
    value: const StringValue("Typed field value"),
    presentation: storyNode(
      "typedField",
      const PresentationElement.typedField(
        binding: rootBinding,
        expectedType: StringType(),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.conditional,
    name: "Conditional",
    type: const BooleanType(),
    value: const BooleanValue(true),
    presentation: storyNode(
      "conditional",
      PresentationElement.conditional(
        condition: bindingExpression(rootBinding, const BooleanType()),
        whenTrue: storyNode(
          "conditionTrue",
          PresentationElement.badge(
            label: "Condition is true".asStringLiteral,
            tone: "success",
          ),
        ),
        whenFalse: storyNode(
          "conditionFalse",
          PresentationElement.badge(
            label: "Condition is false".asStringLiteral,
            tone: "neutral",
          ),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.repeated,
    name: "Repeated",
    type: const ListType(element: StringType()),
    value: const ListValue([
      StringValue("Meet the guide"),
      StringValue("Find the hidden path"),
      StringValue("Return to the village"),
    ]),
    presentation: storyNode(
      "repeated",
      PresentationElement.repeated(
        source: bindingExpression(
          rootBinding,
          const ListType(element: StringType()),
        ),
        itemBindingId: const BindingId(1),
        template: storyNode(
          "repeatedItem",
          PresentationElement.card(
            storyNode(
              "repeatedText",
              PresentationElement.text(
                bindingExpression(_itemBinding, const StringType()),
              ),
            ),
          ),
        ),
        empty: storyNode(
          "repeatedEmpty",
          PresentationElement.text("No objectives configured".asStringLiteral),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.scopedBinding,
    name: "Scoped binding",
    type: const StringType(),
    value: const StringValue("Value from a scoped alias"),
    presentation: storyNode(
      "scopedBinding",
      PresentationElement.scopedBinding(
        binding: rootBinding,
        scopeBindingId: const BindingId(1),
        child: storyNode(
          "scopedText",
          PresentationElement.text(
            bindingExpression(_itemBinding, const StringType()),
          ),
        ),
      ),
    ),
  ),
];

@widgetbook.UseCase(
  name: "Diagnostic",
  type: PresentationRendererStory,
  path: _path,
)
Widget diagnosticRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[0]);

@widgetbook.UseCase(
  name: "Default presentation",
  type: PresentationRendererStory,
  path: _path,
)
Widget defaultPresentationRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[1]);

@widgetbook.UseCase(
  name: "Typed field",
  type: PresentationRendererStory,
  path: _path,
)
Widget typedFieldRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[2]);

@widgetbook.UseCase(
  name: "Conditional",
  type: PresentationRendererStory,
  path: _path,
)
Widget conditionalRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[3]);

@widgetbook.UseCase(
  name: "Repeated",
  type: PresentationRendererStory,
  path: _path,
)
Widget repeatedRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[4]);

@widgetbook.UseCase(
  name: "Scoped binding",
  type: PresentationRendererStory,
  path: _path,
)
Widget scopedBindingRendererUseCase(BuildContext context) =>
    rendererStory(context, dataRendererScenarios[5]);
