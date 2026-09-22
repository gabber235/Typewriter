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
  elementCreationSlot: const AuthoringCreationSlotId("widgetbook:graph"),
  originArtifactId: "widgetbook",
  sourcePart: "page-story",
  presentationSubject: _catalogSubject(referenceResourceTypes.pageKind),
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
      elementCreationSlot: const AuthoringCreationSlotId("widgetbook:timeline"),
      originArtifactId: "widgetbook",
      sourcePart: "page-story",
      presentationSubject: _catalogSubject(referenceResourceTypes.pageKind),
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
    receivedRealmEditorCatalog(
      generation: const CatalogGeneration("widgetbook"),
      definitions: [
        ..._pageStoryReferenceDefinitions(_pageStoryPlaceholderValue),
        ..._pageStoryPlacementDefinitions,
        TypeDefinition(
          id: rootType,
          kind: NominalTypeKind.concrete,
          parents: [referenceResourceTypes.element],
          representation: value == null
              ? RecordType(fields: {})
              : _recordType(value),
        ),
      ],
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
  final rootValues = _rootValues(elements);
  final pageValue = _pageStoryValue(pageDefinition);
  return RealmEditorCatalogState.ready(
    receivedRealmEditorCatalog(
      generation: const CatalogGeneration("widgetbook"),
      definitions: [
        ..._pageStoryReferenceDefinitions(pageValue),
        ..._pageStoryPlacementDefinitions,
        for (final entry in rootValues.entries)
          TypeDefinition(
            id: entry.key,
            kind: NominalTypeKind.concrete,
            parents: [referenceResourceTypes.element],
            representation: _recordType(entry.value),
            rolePresentations: {
              PresentationRole.graphNode: _storyRoleId(entry.key),
              PresentationRole.inspectorHeader: _storyRoleId(entry.key),
            },
          ),
      ],
      presentations: {
        for (final entry in rootValues.entries)
          _storyRoleId(entry.key): PresentationDefinition(
            id: _storyRoleId(entry.key),
            inputs: [
              PresentationInputParameter(
                id: const BindingId(0),
                name: "content",
                type: NamedType(entry.key),
              ),
            ],
            primaryInput: const BindingId(0),
            root: PresentationNode(
              id: "${entry.key.id.displayName}.subject",
              element: TextElement(
                TypedExpression(
                  resultType: const StringType(),
                  expression: BindingExpression(
                    const BindingReference(
                      bindingId: BindingId(0),
                      path: DataPath([FieldPathSegment("name")]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      },
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
            presentationSubject: _catalogSubject(definition.rootType),
            eligible: true,
            available: true,
          ),
      },
      pageCatalog: RealmPageCatalog(
        definitions: {pageDefinition.kind: pageDefinition},
      ),
      resourceDefinitions: {
        CoreResourceDefinitionIds.page: RealmResourceDefinition(
          id: CoreResourceDefinitionIds.page,
          acceptedRoot: NamedType(referenceResourceTypes.page),
        ),
        CoreResourceDefinitionIds.element: RealmResourceDefinition(
          id: CoreResourceDefinitionIds.element,
          acceptedRoot: NamedType(referenceResourceTypes.element),
        ),
      },
    ),
  );
}

PresentationId _storyRoleId(ResolvedTypeRef type) => PresentationId(
  namespace: "widgetbook",
  name: "${type.id.displayName}.subject",
);

AuthoringSubjectProjection pageStorySubjectProjection(
  RealmPageDefinition pageDefinition,
  List<PageElement> elements,
  AuthoringSubjectScope scope,
) {
  final catalog = pageStoryPageCatalog(pageDefinition, elements).snapshot!;
  final definitions = {
    for (final element in elements)
      if (element case PageElementEntry(
        entry: DefinitionPageEntry(:final definition),
      ))
        skir.ResourceId(value: definition.id): definition,
  };
  return AuthoringSubjectProjection(
    catalog: catalog,
    generation: catalog.generation,
    sequence: 1,
    subjects: {
      for (final id in scope.resources.keys)
        if (definitions[id] case final definition?)
          id: (
            content: TypedValueEnvelope(
              rootType: definition.elementDefinition.rootType,
              rootValue: definition.data,
            ),
            descriptor: TypedValueEnvelope(
              rootType: definition.elementDefinition.rootType,
              rootValue: RecordValue({}),
            ),
            identityEnvelope: TypedValueEnvelope(
              rootType: definition.elementDefinition.rootType,
              rootValue: RecordValue({}),
            ),
            identity: (
              id: id,
              owner: skir.ResourceId(value: "page:example-page-id"),
            ),
          ),
    },
    collections: const {},
    diagnostics: const [],
  );
}

TypedCatalogPresentationSubject _catalogSubject(ResolvedTypeRef type) => (
  target: type,
  descriptor: TypedValueEnvelope(rootType: type, rootValue: RecordValue({})),
  identity: TypedValueEnvelope(rootType: type, rootValue: RecordValue({})),
);

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

RecordValue _pageStoryValue(RealmPageDefinition definition) => RecordValue({
  "book": ReferenceValue(skir.ResourceId(value: "book:example-book-id")),
  "name": const StringValue("Example"),
  "kind": RecordValue({
    "id": StringValue(definition.kind.id),
    "revision": IntegerValue(BigInt.from(definition.kind.revision)),
  }),
  "chapter": const StringValue(""),
  "priority": IntegerValue(BigInt.zero),
});

List<TypeDefinition> _pageStoryReferenceDefinitions(RecordValue pageValue) => [
  for (final definition in referenceResourceTypes.definitions)
    if (definition.id != referenceResourceTypes.page &&
        definition.id != referenceResourceTypes.element)
      definition,
  TypeDefinition(
    id: referenceResourceTypes.page,
    kind: NominalTypeKind.concrete,
    parents: [referenceResourceTypes.referenceable],
    representation: _recordType(pageValue),
  ),
  TypeDefinition(
    id: referenceResourceTypes.element,
    kind: NominalTypeKind.openAbstract,
    parents: [referenceResourceTypes.referenceable],
  ),
];

final _pageStoryPlaceholderValue = RecordValue({
  "book": ReferenceValue(skir.ResourceId(value: "book:example-book-id")),
  "name": const StringValue("Example"),
  "kind": RecordValue({
    "id": const StringValue("widgetbook.placeholder"),
    "revision": IntegerValue(BigInt.one),
  }),
  "chapter": const StringValue(""),
  "priority": IntegerValue(BigInt.zero),
});

final _pageStoryPlacementDefinitions = <TypeDefinition>[
  TypeDefinition(id: placementRootTypeRef, kind: NominalTypeKind.openAbstract),
  _placementDefinition(graphPlacementTypeRef, const [
    "x",
    "y",
    "width",
    "height",
  ]),
  _placementDefinition(timelineEntryPlacementTypeRef, const ["trackIndex"]),
  _placementDefinition(timelineSegmentPlacementTypeRef, const [
    "startFrame",
    "endFrame",
  ]),
  _placementDefinition(timelineKeyframePlacementTypeRef, const ["frame"]),
];

TypeDefinition _placementDefinition(
  ResolvedTypeRef type,
  List<String> fields,
) => TypeDefinition(
  id: type,
  kind: NominalTypeKind.concrete,
  parents: [placementRootTypeRef],
  representation: RecordType(
    fields: {
      for (final field in fields)
        field: TypeField(
          name: field,
          type: const IntegerType(width: IntegerWidth.signed32),
        ),
    },
  ),
);

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
