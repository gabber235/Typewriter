import "package:flutter/material.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/widgets/app/components/entry.dart";
import "package:typewriter_panel/widgets/app/components/graph/entry_graph.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Definition Entry", type: EntryNode)
Widget entryNodeDefinitionUseCase(BuildContext context) {
  final definition = EntryDefinition(
    id: "test-entry-id",
    name: "Test Entry",
    blueprint: EntryBlueprint(
      id: "test-blueprint",
      name: "Test Blueprint",
      description: "A test blueprint for the story",
      extension: "basic",
      dataBlueprint: ObjectBlueprint(
        fields: {
          "name": DataBlueprint.string(defaultValue: "Test"),
          "value": DataBlueprint.integer(defaultValue: 42),
        },
      ),
      color: safeColors.randomOrNull()!,
      icon: "fa-solid:star",
      tags: ["test", "example"],
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
    data: DynamicData({"name": "Test Entry", "value": 42}),
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
    blueprint: EntryBlueprint(
      id: "deprecated-blueprint",
      name: "Deprecated Blueprint",
      description: "A deprecated blueprint for the story",
      extension: "basic",
      dataBlueprint: ObjectBlueprint(
        fields: {"name": DataBlueprint.string(defaultValue: "Deprecated")},
      ),
      color: safeColors.randomOrNull()!,
      icon: "fa-solid:exclamation-triangle",
      tags: const ["deprecated"],
      modifiers: const [
        EntryModifier.deprecated(reason: "This entry type is deprecated"),
      ],
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
    data: DynamicData({"name": "Deprecated Entry"}),
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
  final blueprint = EntryBlueprint(
    id: "reference-blueprint",
    name: "Reference Blueprint",
    description: "A blueprint for reference entries",
    extension: "basic",
    dataBlueprint: ObjectBlueprint(fields: const {}),
    color: safeColors.randomOrNull()!,
    icon: "fa-solid:link",
    tags: const ["reference"],
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
            blueprint: blueprint,
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

@widgetbook.UseCase(name: "No Blueprint Entry", type: EntryNode)
Widget entryNodeNoBlueprintUseCase(BuildContext context) {
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
          entry: PageEntry.noBlueprint(
            id: "no-blueprint-entry-id",
            name: "Entry Without Blueprint",
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

@widgetbook.UseCase(name: "Multiple Entries Grid", type: EntryNode)
Widget entryNodeMultipleEntriesUseCase(BuildContext context) {
  // Knobs for small entries (e.g., Quest and NPC)
  final smallWidth = context.knobs.int.slider(
    label: "Small Width",
    initialValue: 4,
    min: 1,
    max: 10,
  );
  final smallHeight = context.knobs.int.slider(
    label: "Small Height",
    initialValue: 1,
    min: 1,
    max: 10,
  );

  // Knobs for big entries (e.g., Dialogue and External Reference)
  final bigWidth = context.knobs.int.slider(
    label: "Big Width",
    initialValue: 4,
    min: 1,
    max: 10,
  );
  final bigHeight = context.knobs.int.slider(
    label: "Big Height",
    initialValue: 2,
    min: 1,
    max: 10,
  );

  final definitions = [
    EntryDefinition(
      id: "quest-entry",
      name: "Main Quest",
      blueprint: EntryBlueprint(
        id: "quest-blueprint",
        name: "Quest",
        description: "A quest entry",
        extension: "quest",
        dataBlueprint: ObjectBlueprint(fields: const {}),
        color: safeColors.randomOrNull()!,
        icon: "fa-solid:flag",
        tags: const ["quest"],
      ),
      placement: EntryPlacement(
        x: 0,
        y: 0,
        width: smallWidth,
        height: smallHeight,
      ),
      data: DynamicData(const {}),
      inwardEdges: const [],
      outwardEdges: const [],
      metadata: const [],
    ),
    EntryDefinition(
      id: "npc-entry",
      name: "Village Elder",
      blueprint: EntryBlueprint(
        id: "npc-blueprint",
        name: "NPC",
        description: "A non-player character",
        extension: "npc",
        dataBlueprint: ObjectBlueprint(fields: const {}),
        color: safeColors.randomOrNull()!,
        icon: "fa-solid:user",
        tags: const ["npc"],
      ),
      placement: EntryPlacement(
        x: 0,
        y: 0,
        width: smallWidth,
        height: smallHeight,
      ),
      data: DynamicData(const {}),
      inwardEdges: const [],
      outwardEdges: const [],
      metadata: const [],
    ),
    EntryDefinition(
      id: "dialogue-entry",
      name: "Welcome Message",
      blueprint: EntryBlueprint(
        id: "dialogue-blueprint",
        name: "Dialogue",
        description: "A dialogue entry",
        extension: "dialogue",
        dataBlueprint: ObjectBlueprint(fields: const {}),
        color: safeColors.randomOrNull()!,
        icon: "fa-solid:comment",
        tags: const ["dialogue"],
        modifiers: const [
          EntryModifier.deprecated(reason: "This entry type is deprecated"),
        ],
      ),
      placement: EntryPlacement(x: 0, y: 0, width: bigWidth, height: bigHeight),
      data: DynamicData(const {}),
      inwardEdges: const [],
      outwardEdges: const [],
      metadata: const [],
    ),
  ];

  return FakeApp(
    child: Center(
      child: GraphDrag(
        draggingInsideGraph: ValueNotifier(false),
        child: SizedBox(
          width: 9 * entryGraphCellSize,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final def in definitions)
                SizedBox(
                  width: def.placement.width * entryGraphCellSize,
                  height: def.placement.height * entryGraphCellSize,
                  child: EntryNode(
                    entry: PageEntry.definition(definition: def),
                  ),
                ),
              SizedBox(
                width: bigWidth * entryGraphCellSize,
                height: bigHeight * entryGraphCellSize,
                child: EntryNode(
                  entry: PageEntry.reference(
                    id: "external-entry",
                    name: "External Entry",
                    blueprint: EntryBlueprint(
                      id: "external-blueprint",
                      name: "External",
                      description: "An external entry",
                      extension: "basic",
                      dataBlueprint: ObjectBlueprint(fields: const {}),
                      color: safeColors.randomOrNull()!,
                      icon: "fa-solid:external-link-alt",
                      tags: const ["external"],
                    ),
                    pageId: "other-page",
                    metadata: const [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
