import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "shared/editors/presentation/protocol/renderers/input_states";

final inputRendererVariantScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.textInput,
    name: "Single line text input",
    type: const StringType(maximumLength: 80),
    value: const StringValue("A short quest title"),
    presentation: storyNode(
      "singleLineTextInput",
      PresentationElement.textInput(
        control: storyControl("Title"),
        multiline: false,
        placeholder: "Enter a title".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.textInput,
    name: "Empty text input",
    type: const StringType(),
    value: const StringValue(""),
    presentation: storyNode(
      "emptyTextInput",
      PresentationElement.textInput(
        control: storyControl("Description"),
        placeholder: "Describe the objective".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.numericInput,
    name: "Decimal input",
    type: const DecimalType(minimum: "-1000.0", maximum: "1000.0", scale: 2),
    value: DecimalValue("12.50"),
    presentation: storyNode(
      "decimalInput",
      PresentationElement.numericInput(storyControl("Reward multiplier")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.toggleInput,
    name: "Unchecked toggle",
    type: const BooleanType(),
    value: const BooleanValue(false),
    presentation: storyNode(
      "uncheckedToggle",
      PresentationElement.toggleInput(storyControl("Repeatable")),
      header: PresentationHeader(
        binding: rootBinding,
        title: "Repeatable".asStringLiteral.asHeaderTitle,
        description: "Allow players to repeat this quest.".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.toggleInput,
    name: "Disabled toggle",
    type: const BooleanType(),
    value: const BooleanValue(true),
    presentation: storyNode(
      "disabledToggle",
      PresentationElement.toggleInput(storyControl("Published")),
      properties: PresentationProperties(
        enabledIf: literal(const BooleanType(), const BooleanValue(false)),
      ),
      header: PresentationHeader(
        binding: rootBinding,
        title: "Published".asStringLiteral.asHeaderTitle,
        description: "This setting is controlled by the realm.".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.listInput,
    name: "Empty list",
    type: const ListType(element: StringType()),
    value: const ListValue([]),
    presentation: storyNode(
      "emptyList",
      PresentationElement.listInput(control: storyControl("Objectives")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.listInput,
    name: "Nested list items",
    type: const ListType(
      element: RecordType(
        fields: {
          "name": TypeField(name: "name", type: StringType()),
          "required": TypeField(name: "required", type: BooleanType()),
        },
      ),
    ),
    value: ListValue([
      RecordValue({
        "name": const StringValue("Speak to the guide"),
        "required": const BooleanValue(true),
      }),
      RecordValue({
        "name": const StringValue("Find the shortcut"),
        "required": const BooleanValue(false),
      }),
    ]),
    presentation: storyNode(
      "nestedList",
      PresentationElement.listInput(control: storyControl("Objectives")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.listInput,
    name: "Locked collection actions",
    type: const ListType(element: StringType()),
    value: const ListValue([StringValue("Fixed objective")]),
    presentation: storyNode(
      "lockedList",
      PresentationElement.listInput(
        control: storyControl("Inherited objectives"),
        allowAdd: false,
        allowRemove: false,
        allowReorder: false,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.mapInput,
    name: "Empty map",
    type: const MapType(key: StringType(), value: StringType()),
    value: const MapValue([]),
    presentation: storyNode(
      "emptyMap",
      PresentationElement.mapInput(control: storyControl("Translations")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.numericInput,
    name: "Text prefix without a title",
    type: const IntegerType(width: IntegerWidth.signed32),
    value: IntegerValue(BigInt.from(3)),
    presentation: storyNode(
      "textPrefixNumericInput",
      PresentationElement.numericInput(
        storyControl(
          null,
          prefix: storyNode(
            "textPrefixNumericInput.prefix",
            PresentationElement.text("X".asStringLiteral),
          ),
          semanticLabel: "X position",
        ),
      ),
    ),
  ),
];

@widgetbook.UseCase(
  name: "Single line text",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget singleLineTextInputUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[0]);

@widgetbook.UseCase(
  name: "Empty text",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget emptyTextInputUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[1]);

@widgetbook.UseCase(name: "Decimal", type: EditorProtocolRenderer, path: _path)
Widget decimalInputUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[2]);

@widgetbook.UseCase(
  name: "Unchecked toggle",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget uncheckedToggleUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[3]);

@widgetbook.UseCase(
  name: "Disabled toggle",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget disabledToggleUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[4]);

@widgetbook.UseCase(
  name: "Empty list",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget emptyListUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[5]);

@widgetbook.UseCase(
  name: "Nested list",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget nestedListUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[6]);

@widgetbook.UseCase(
  name: "Locked list actions",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget lockedListActionsUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[7]);

@widgetbook.UseCase(
  name: "Empty map",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget emptyMapUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[8]);

@widgetbook.UseCase(
  name: "Text prefix without title",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget textPrefixNumericInputUseCase(BuildContext context) =>
    rendererStory(context, inputRendererVariantScenarios[9]);
