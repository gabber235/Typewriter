import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

final _namedValue = storyTypeRef("NamedValue");
final _animal = storyTypeRef("Animal");
final _dog = storyTypeRef("Dog");
final _cat = storyTypeRef("Cat");

final inputRendererScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.textInput,
    name: "Text input",
    type: const StringType(maximumLength: 240),
    value: const StringValue("Describe what happens when the quest begins."),
    presentation: storyNode(
      "textInput",
      PresentationElement.textInput(
        control: storyControl("Description"),
        placeholder: "Enter a description".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.numericInput,
    name: "Numeric input",
    type: IntegerType(
      width: IntegerWidth.unsigned8,
      minimum: BigInt.one,
      maximum: BigInt.from(100),
    ),
    value: IntegerValue(BigInt.from(42)),
    presentation: storyNode(
      "numericInput",
      PresentationElement.numericInput(storyControl("Required level")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.toggleInput,
    name: "Toggle input",
    type: const BooleanType(),
    value: const BooleanValue(true),
    presentation: storyNode(
      "toggleInput",
      PresentationElement.toggleInput(storyControl("Enabled")),
      header: PresentationHeader(
        binding: rootBinding,
        title: "Enabled".asStringLiteral,
        description:
            "Boolean controls live inside the compact header.".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.selectInput,
    name: "Select input",
    type: const StringType(),
    value: const StringValue("story"),
    presentation: storyNode(
      "selectInput",
      PresentationElement.selectInput(
        control: storyControl("Quest category"),
        allowCustomValue: true,
        options: [
          SelectOption(
            id: "story",
            label: "Story".asStringLiteral,
            value: "story".asStringLiteral,
          ),
          SelectOption(
            id: "daily",
            label: "Daily".asStringLiteral,
            value: "daily".asStringLiteral,
          ),
        ],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.sliderInput,
    name: "Slider input",
    type: const FloatType(width: FloatWidth.float64, minimum: 0, maximum: 1),
    value: const FloatValue(0.65),
    presentation: storyNode(
      "sliderInput",
      PresentationElement.sliderInput(
        control: storyControl("Intensity"),
        minimum: floatLiteral(0),
        maximum: floatLiteral(1),
        divisions: integerLiteral(20),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.dateTimeInput,
    name: "Date and time input",
    type: const TimestampType(),
    value: TimestampValue(DateTime.utc(2026, 8, 12, 18, 30)),
    presentation: storyNode(
      "dateTimeInput",
      PresentationElement.dateTimeInput(
        control: storyControl("Available from"),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.durationInput,
    name: "Duration input",
    type: const DurationType(),
    value: const DurationValue(Duration(minutes: 5)),
    presentation: storyNode(
      "durationInput",
      PresentationElement.durationInput(storyControl("Delay")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.colorInput,
    name: "Color input",
    type: NamedType(standardTypeRefs.color),
    value: IntegerValue(BigInt.from(0xFF7C4DFF)),
    presentation: storyNode(
      "colorInput",
      PresentationElement.colorInput(control: storyControl("Accent color")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.iconInput,
    name: "Icon input",
    type: const StringType(),
    value: const StringValue("mdi:map-marker-star"),
    presentation: storyNode(
      "iconInput",
      PresentationElement.iconInput(storyControl("Icon")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.bytesInput,
    name: "Bytes input",
    type: const BytesType(),
    value: storyBytes,
    presentation: storyNode(
      "bytesInput",
      PresentationElement.bytesInput(storyControl("Payload")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.enumInput,
    name: "Enum input",
    type: const EnumType(
      valueType: StringType(),
      values: [StringValue("easy"), StringValue("normal"), StringValue("hard")],
    ),
    value: const StringValue("normal"),
    presentation: storyNode(
      "enumInput",
      PresentationElement.enumInput(storyControl("Difficulty")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.namedInput,
    name: "Named input",
    type: NamedType(_namedValue),
    value: const StringValue("custom:quest-value"),
    definitions: [
      TypeDefinition(
        id: _namedValue,
        kind: NominalTypeKind.concrete,
        representation: const StringType(),
      ),
    ],
    presentation: storyNode(
      "namedInput",
      PresentationElement.namedInput(storyControl("Named value")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.listInput,
    name: "List input",
    type: const ListType(element: StringType()),
    value: const ListValue([
      StringValue("Find the guide"),
      StringValue("Open the gate"),
    ]),
    presentation: storyNode(
      "listInput",
      PresentationElement.listInput(control: storyControl("Objectives")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.mapInput,
    name: "Map input",
    type: const MapType(key: StringType(), value: StringType()),
    value: const MapValue([
      DataMapEntry(key: StringValue("intro"), value: StringValue("Welcome")),
      DataMapEntry(key: StringValue("outro"), value: StringValue("Farewell")),
    ]),
    presentation: storyNode(
      "mapInput",
      PresentationElement.mapInput(control: storyControl("Messages")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.recordInput,
    name: "Record input",
    type: const RecordType(
      fields: {
        "title": TypeField(name: "title", type: StringType()),
        "enabled": TypeField(name: "enabled", type: BooleanType()),
      },
    ),
    value: RecordValue({
      "title": StringValue("Village introduction"),
      "enabled": BooleanValue(true),
    }),
    presentation: storyNode(
      "recordInput",
      PresentationElement.recordInput(control: storyControl("Quest settings")),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.polymorphicInput,
    name: "Polymorphic input",
    type: NamedType(_animal),
    value: PolymorphicValue(
      concreteType: _dog,
      value: RecordValue({"name": const StringValue("Rufus")}),
    ),
    definitions: [
      TypeDefinition(id: _animal, kind: NominalTypeKind.openAbstract),
      TypeDefinition(
        id: _dog,
        kind: NominalTypeKind.concrete,
        representation: const RecordType(
          fields: {"name": TypeField(name: "name", type: StringType())},
        ),
        parents: [_animal],
      ),
      TypeDefinition(
        id: _cat,
        kind: NominalTypeKind.concrete,
        representation: const RecordType(
          fields: {"name": TypeField(name: "name", type: StringType())},
        ),
        parents: [_animal],
      ),
    ],
    presentation: storyNode(
      "polymorphicInput",
      PresentationElement.polymorphicInput(
        control: storyControl("Companion"),
        concreteTypes: [
          ConcreteTypePresentation(type: _dog, label: "Dog".asStringLiteral),
          ConcreteTypePresentation(type: _cat, label: "Cat".asStringLiteral),
        ],
      ),
    ),
  ),
];
