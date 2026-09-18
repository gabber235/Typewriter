part of "route.stories.dart";

const _storyEntryIcon = IconValue.svg(
  "<svg viewBox=\"0 0 24 24\"><path d=\"M4 4h16v16H4z\"/></svg>",
);

List<PageElement> graphPageStoryElements({
  required int count,
  required GraphDirection direction,
}) {
  final definitions = [
    for (var index = 0; index < count; index++)
      EntryDefinition(
        id: "graph_entry_$index",
        elementDefinition: ElementDefinition(
          rootType: ResolvedTypeRef(
            id: fixtureDeclaredTypeId("widgetbook:graphEntry"),
            revision: 1,
          ),
          name: "Graph Entry",
          description: "Deterministic Widgetbook graph entry",
          icon: _storyEntryIcon,
          color: safeColors[index % safeColors.length],
        ),
        placement: const EntryPlacement(x: 0, y: 0, width: 4, height: 2),
        data: RecordValue({
          "id": StringValue("graph_entry_$index"),
          "name": StringValue("Graph Entry ${index + 1}"),
          "priority": IntegerValue(BigInt.from(index)),
          "weight": FloatValue(index + 0.5),
          "enabled": BooleanValue(index.isEven),
        }),
        inwardEdges: const [],
        outwardEdges: const [],
      ),
  ];
  return [
    for (final definition in layoutGraphEntries(
      definitions,
      direction: direction,
    ))
      PageElement.entry(entry: PageEntry.definition(definition: definition)),
  ];
}

RealmPageDefinition graphPageStoryDefinition(
  GraphDirection direction,
  List<PageElement> elements,
) => RealmPageDefinition(
  kind: const PageKindRef(id: "widgetbook.graph", revision: 1),
  name: "Graph",
  description: "Widgetbook graph page",
  icon: _storyEntryIcon,
  color: safeColors.first,
  editor: RealmPageEditor.graph(
    direction: direction,
    nodeTypes: _roleTypes<DefinitionPageEntry>(elements),
  ),
  originArtifactId: "widgetbook",
  sourcePart: "page-story",
);

RealmPageDefinition timelinePageStoryDefinition(List<PageElement> elements) =>
    RealmPageDefinition(
      kind: const PageKindRef(id: "widgetbook.timeline", revision: 1),
      name: "Timeline",
      description: "Widgetbook timeline page",
      icon: _storyEntryIcon,
      color: safeColors[1],
      editor: RealmPageEditor.timeline(
        trackTypes: _roleTypes<DefinitionPageEntry>(elements),
        segmentTypes: _roleTypes<Segment>(elements),
        keyframeTypes: _roleTypes<Keyframe>(elements),
      ),
      originArtifactId: "widgetbook",
      sourcePart: "page-story",
    );

List<ResolvedTypeRef> _roleTypes<T>(List<PageElement> elements) => {
  for (final element in elements)
    if (element case PageElementEntry(entry: final entry) when entry is T)
      (entry as DefinitionPageEntry).definition.elementDefinition.rootType
    else if (element case PageElementCue(:final cue) when cue is T)
      cue.elementDefinition.rootType,
}.toList();

RealmEditorCatalogState pageStoryCatalog(
  ResolvedTypeRef rootType,
  List<PageElement> elements,
) {
  final value = _rootValues(elements)[rootType];
  return RealmEditorCatalogState.ready(
    RealmEditorCatalogSnapshot(
      catalog: TypeCatalog([
        TypeDefinition(
          id: rootType,
          kind: NominalTypeKind.concrete,
          representation: value == null
              ? RecordType(fields: {})
              : _recordType(value),
        ),
      ]),
      generation: const CatalogGeneration("widgetbook"),
    ),
  );
}

RealmEditorCatalogState pageStoryPageCatalog(
  RealmPageDefinition pageDefinition,
  List<PageElement> elements,
) {
  final elementDefinitions = [
    for (final element in elements)
      switch (element) {
        PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
          definition.elementDefinition,
        PageElementCue(:final cue) => cue.elementDefinition,
        _ => null,
      },
  ].nonNulls;
  return RealmEditorCatalogState.ready(
    RealmEditorCatalogSnapshot(
      catalog: TypeCatalog([
        for (final entry in _rootValues(elements).entries)
          TypeDefinition(
            id: entry.key,
            kind: NominalTypeKind.concrete,
            representation: _recordType(entry.value),
          ),
      ]),
      generation: const CatalogGeneration("widgetbook"),
      elements: {
        for (final definition in elementDefinitions)
          definition.typeId.uuid: RealmElementCatalogEntry(
            originArtifactId: "widgetbook",
            sourcePart: "page-story",
            definition: DiscoveredElementDefinition(
              id: definition.typeId.uuid,
              type: definition.rootType,
              name: definition.name,
              description: definition.description,
              icon: definition.icon,
              color: definition.color,
              availability: const ElementAvailability.always(),
            ),
            eligible: true,
            available: true,
          ),
      },
      pageCatalog: RealmPageCatalog(
        definitions: {pageDefinition.kind: pageDefinition},
      ),
    ),
  );
}

Map<ResolvedTypeRef, RecordValue> _rootValues(List<PageElement> elements) {
  final values = <ResolvedTypeRef, RecordValue>{};
  for (final element in elements) {
    switch (element) {
      case PageElementEntry(entry: DefinitionPageEntry(:final definition)):
        values[definition.elementDefinition.rootType] = definition.data;
      case PageElementCue(:final cue):
        values[cue.elementDefinition.rootType] = cue.data;
      default:
        break;
    }
  }
  return values;
}

RecordType _recordType(RecordValue value) => RecordType(
  fields: {
    for (final field in value.fields.entries)
      field.key: TypeField(name: field.key, type: _valueType(field.value)),
  },
);

TypeExpression _valueType(DataValue value) => switch (value) {
  UnitValue() => const UnitType(),
  BooleanValue() => const BooleanType(),
  IntegerValue() => const IntegerType(width: IntegerWidth.signed64),
  FloatValue() => const FloatType(width: FloatWidth.float64),
  DecimalValue() => const DecimalType(),
  StringValue() => const StringType(),
  BytesValue() => const BytesType(),
  TimestampValue() => const TimestampType(),
  DurationValue() => const DurationType(),
  RecordValue() => _recordType(value),
  ListValue(:final values) => ListType(
    element: values.isEmpty ? const AnyType() : _valueType(values.first),
  ),
  MapValue(:final entries) => MapType(
    key: entries.isEmpty ? const AnyType() : _valueType(entries.first.key),
    value: entries.isEmpty ? const AnyType() : _valueType(entries.first.value),
  ),
  PolymorphicValue(:final concreteType) => NamedType(concreteType),
  ReferenceValue() => const AnyType(),
};
