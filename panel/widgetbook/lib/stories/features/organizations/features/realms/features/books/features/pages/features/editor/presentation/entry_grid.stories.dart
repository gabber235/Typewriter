part of "entry.stories.dart";

Widget entryNodeMultipleEntriesStory(BuildContext context) {
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
    _storyEntry("quest", "Main Quest", smallWidth, smallHeight),
    _storyEntry("npc", "Village Elder", smallWidth, smallHeight),
    _storyEntry(
      "dialogue",
      "Welcome Message",
      bigWidth,
      bigHeight,
      deprecated: true,
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
              for (final definition in definitions)
                SizedBox(
                  width: definition.placement.width * entryGraphCellSize,
                  height: definition.placement.height * entryGraphCellSize,
                  child: EntryNode(
                    entry: PageEntry.definition(definition: definition),
                  ),
                ),
              SizedBox(
                width: bigWidth * entryGraphCellSize,
                height: bigHeight * entryGraphCellSize,
                child: EntryNode(
                  entry: PageEntry.reference(
                    id: "external-entry",
                    name: "External Entry",
                    elementDefinition: _elementDefinition(
                      id: "external-elementDefinition",
                      name: "External",
                      description: "An external entry",
                      color: safeColors.randomOrNull()!,
                      icon: "fa-solid:external-link-alt",
                    ),
                    pageId: "other-page",
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

EntryDefinition _storyEntry(
  String id,
  String name,
  int width,
  int height, {
  bool deprecated = false,
}) => EntryDefinition(
  id: "$id-entry",
  name: name,
  elementDefinition: _elementDefinition(
    id: "$id-elementDefinition",
    name: id.formatted,
    description: "A $id entry",
    color: safeColors.randomOrNull()!,
    icon: "fa-solid:star",
    deprecated: deprecated,
  ),
  placement: EntryPlacement(x: 0, y: 0, width: width, height: height),
  data: RecordValue(const {}),
  inwardEdges: const [],
  outwardEdges: const [],
);

ElementDefinition _elementDefinition({
  required String id,
  required String name,
  required String description,
  required Color color,
  required String icon,
  bool deprecated = false,
}) => ElementDefinition(
  rootType: ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "widgetbook", name: id),
    revision: 1,
  ),
  name: name,
  description: description,
  color: color,
  icon: IconValue.iconify(icon),
  deprecation: deprecated
      ? const ElementDeprecation(reason: "This entry type is deprecated")
      : null,
);
