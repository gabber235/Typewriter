import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/header_renderer/header_gallery.dart";

SemanticHeaderScenario generatedCompositeScenario() => (
  type: RecordType(
    fields: {
      "name": const TypeField(name: "name", type: StringType()),
      "enabled": const TypeField(name: "enabled", type: BooleanType()),
      "settings": TypeField(
        name: "settings",
        type: RecordType(
          fields: {
            "channel": const TypeField(name: "channel", type: StringType()),
            "volume": TypeField(
              name: "volume",
              type: IntegerType(
                width: IntegerWidth.signed32,
                minimum: BigInt.zero,
                maximum: BigInt.from(100),
              ),
            ),
          },
        ),
      ),
      "steps": TypeField(
        name: "steps",
        type: ListType(
          element: RecordType(
            fields: {
              "title": const TypeField(name: "title", type: StringType()),
              "delay": const TypeField(name: "delay", type: DurationType()),
            },
          ),
        ),
      ),
    },
  ),
  value: RecordValue({
    "name": const StringValue("Welcome sequence"),
    "enabled": const BooleanValue(true),
    "settings": RecordValue({
      "channel": const StringValue("dialogue"),
      "volume": IntegerValue(BigInt.from(80)),
    }),
    "steps": ListValue([
      RecordValue({
        "title": const StringValue("Greet the player"),
        "delay": const DurationValue(Duration(milliseconds: 250)),
      }),
      RecordValue({
        "title": const StringValue("Open the choices"),
        "delay": const DurationValue(Duration(milliseconds: 600)),
      }),
    ]),
  }),
  presentation: null,
  description:
      "Generated root records stay flat while nested records and collections receive compact collapsible headers.",
);

SemanticHeaderScenario listActionsScenario() => (
  type: ListType(element: _taskType),
  value: ListValue([
    _task("Welcome the player", true),
    _task("Show dialogue choices", false),
    _task("Start the cinematic", false),
  ]),
  presentation: null,
  description:
      "Use the collection header to append. Item headers expose drag reorder, duplicate, and remove actions.",
);

SemanticHeaderScenario mapActionsScenario() => (
  type: MapType(key: const StringType(), value: _taskType),
  value: MapValue([
    DataMapEntry(
      key: const StringValue("intro"),
      value: _task("Play the introduction", true),
    ),
    DataMapEntry(
      key: const StringValue("outro"),
      value: _task("Close the conversation", false),
    ),
  ]),
  presentation: null,
  description:
      "Map collection actions live in the outer header. Each entry has its rendered key, content, and removal shortcut.",
);

SemanticHeaderScenario mergedHeaderScenario() {
  const titleBinding = BindingReference(
    bindingId: BindingId(0),
    path: DataPath([FieldPathSegment("title")]),
  );
  return (
    type: RecordType(
      fields: {"title": const TypeField(name: "title", type: StringType())},
    ),
    value: RecordValue({"title": const StringValue("Opening scene")}),
    presentation: PresentationNode(
      id: "merged.outer",
      header: PresentationHeader(
        binding: titleBinding,
        title: "Scene title".asStringLiteral.asHeaderTitle,
        initiallyExpanded: true,
      ),
      element: TypedFieldElement(
        binding: titleBinding,
        expectedType: const StringType(),
        presentation: PresentationNode(
          id: "merged.inner",
          header: PresentationHeader(
            binding: titleBinding,
            description:
                "Both nodes resolve to one canonical binding.".asStringLiteral,
          ),
          element: const TextInputElement(
            control: BoundControl(binding: titleBinding),
            multiline: false,
          ),
        ),
      ),
    ),
    description:
        "Outer and inner metadata for the same canonical binding combine into one visual header.",
  );
}

final _taskType = RecordType(
  fields: {
    "title": const TypeField(name: "title", type: StringType()),
    "completed": const TypeField(name: "completed", type: BooleanType()),
  },
);

RecordValue _task(String title, bool completed) => RecordValue({
  "title": StringValue(title),
  "completed": BooleanValue(completed),
});
