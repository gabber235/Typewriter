import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

part "entry_grid_story.dart";

@widgetbook.UseCase(name: "Multiple Entries Grid", type: EntryNode)
Widget entryNodeMultipleEntriesUseCase(BuildContext context) =>
    entryNodeMultipleEntriesStory(context);

@widgetbook.UseCase(name: "Definition Entry", type: EntryNode)
Widget entryNodeDefinitionUseCase(BuildContext context) {
  final definition = EntryDefinition(
    id: "test-entry-id",
    name: "Test Entry",
    elementDefinition: _elementDefinition(
      id: "test-elementDefinition",
      name: "Test Blueprint",
      description: "A test elementDefinition for the story",
      color: safeColors.randomOrNull()!,
      icon: "fa-solid:star",
    ),
    placement: EntryPlacement(
      x: 0,
      y: 0,
      width: context.knobs.int.slider(
        label: "Width",
        initialValue: 4,
        min: 1,
        max: 10,
      ),
      height: context.knobs.int.slider(
        label: "Height",
        initialValue: 1,
        min: 1,
        max: 10,
      ),
    ),
    data: RecordValue({
      "name": const StringValue("Test Entry"),
      "value": IntegerValue(BigInt.from(42)),
    }),
    inwardEdges: const [],
    outwardEdges: const [],
    metadata: const [],
  );

  return FakeApp(
    child: GraphDrag(
      draggingInsideGraph: ValueNotifier(false),
      child: Center(
        child: SizedBox(
          width: definition.placement.width * entryGraphCellSize,
          height: definition.placement.height * entryGraphCellSize,
          child: EntryNode(entry: PageEntry.definition(definition: definition)),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Deprecated Definition Entry", type: EntryNode)
Widget entryNodeDeprecatedDefinitionUseCase(BuildContext context) {
  final definition = EntryDefinition(
    id: "deprecated-entry-id",
    name: "Deprecated Entry",
    elementDefinition: _elementDefinition(
      id: "deprecated-elementDefinition",
      name: "Deprecated Blueprint",
      description: "A deprecated elementDefinition for the story",
      color: safeColors.randomOrNull()!,
      icon: "fa-solid:exclamation-triangle",
      deprecated: true,
    ),
    placement: EntryPlacement(
      x: 0,
      y: 0,
      width: context.knobs.int.slider(
        label: "Width",
        initialValue: 4,
        min: 1,
        max: 10,
      ),
      height: context.knobs.int.slider(
        label: "Height",
        initialValue: 1,
        min: 1,
        max: 10,
      ),
    ),
    data: RecordValue({"name": const StringValue("Deprecated Entry")}),
    inwardEdges: const [],
    outwardEdges: const [],
    metadata: const [],
  );

  return FakeApp(
    child: GraphDrag(
      draggingInsideGraph: ValueNotifier(false),
      child: Center(
        child: SizedBox(
          width: definition.placement.width * entryGraphCellSize,
          height: definition.placement.height * entryGraphCellSize,
          child: EntryNode(entry: PageEntry.definition(definition: definition)),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Reference Entry", type: EntryNode)
Widget entryNodeReferenceUseCase(BuildContext context) {
  final elementDefinition = _elementDefinition(
    id: "reference-elementDefinition",
    name: "Reference Blueprint",
    description: "A elementDefinition for reference entries",
    color: safeColors.randomOrNull()!,
    icon: "fa-solid:link",
  );

  final width = context.knobs.int.slider(
    label: "Reference Width",
    initialValue: 5,
    min: 1,
    max: 10,
  );
  final height = context.knobs.int.slider(
    label: "Reference Height",
    initialValue: 1,
    min: 1,
    max: 10,
  );

  return FakeApp(
    child: Center(
      child: SizedBox(
        width: width * entryGraphCellSize,
        height: height * entryGraphCellSize,
        child: EntryNode(
          entry: PageEntry.reference(
            id: "reference-entry-id",
            name: "Referenced Entry",
            elementDefinition: elementDefinition,
            pageId: "other-page-id",
            metadata: const [],
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Nonexistent Entry", type: EntryNode)
Widget entryNodeNonexistentUseCase(BuildContext context) {
  final width = context.knobs.int.slider(
    label: "Nonexistent Width",
    initialValue: 4,
    min: 1,
    max: 10,
  );
  final height = context.knobs.int.slider(
    label: "Nonexistent Height",
    initialValue: 1,
    min: 1,
    max: 10,
  );

  return FakeApp(
    child: Center(
      child: SizedBox(
        width: width * entryGraphCellSize,
        height: height * entryGraphCellSize,
        child: EntryNode(
          entry: const PageEntry.nonexistent(id: "missing-entry-id"),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Missing Element Definition", type: EntryNode)
Widget entryNodeMissingElementDefinitionUseCase(BuildContext context) {
  final placement = EntryPlacement(
    x: 0,
    y: 0,
    width: context.knobs.int.slider(
      label: "Width",
      initialValue: 4,
      min: 1,
      max: 10,
    ),
    height: context.knobs.int.slider(
      label: "Height",
      initialValue: 1,
      min: 1,
      max: 10,
    ),
  );
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: placement.width * entryGraphCellSize,
        height: placement.height * entryGraphCellSize,
        child: EntryNode(
          entry: PageEntry.missingElementDefinition(
            id: "no-elementDefinition-entry-id",
            name: "Entry Without Element Definition",
            placement: placement,
            inwardLinks: const [],
            outwardLinks: const [],
            metadata: const [],
          ),
        ),
      ),
    ),
  );
}
