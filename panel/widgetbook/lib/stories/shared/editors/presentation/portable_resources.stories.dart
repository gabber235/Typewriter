import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Page workspace", type: PortableResourcesHost)
Widget resourcesWorkspaceUseCase(BuildContext context) {
  final layout = context.knobs.object.segmented(
    label: "Layout",
    options: const ["Graph", "Timeline"],
    initialOption: "Graph",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      ResourcesWorkspaceStory(
        key: ValueKey(layout),
        timeline: layout == "Timeline",
        configured: context.knobs.boolean(label: "Configured appearance"),
      ),
    ),
  );
}

/// A page laying out its elements as a graph or a timeline, with the inspector
/// of the element the user opened beside it.
///
/// Edits go through a [RealmEditing] over a [FakeRealm], the same save path a
/// Realm surface uses, so moving or editing an element keeps the change.
final class ResourcesWorkspaceStory extends HookConsumerWidget {
  const ResourcesWorkspaceStory({
    required this.timeline,
    this.configured = false,
    super.key,
  });

  final bool timeline;

  /// Whether the page overrides the layout's cell size, spacing and colors.
  final bool configured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixture = useMemoized(_pageFixture);
    final realm = useMemoized(
      () => FakeRealm(
        scope: AuthoringScope(
          organizationId: skir.recordId("organization:story"),
          realmId: skir.recordId("realm_instance:story"),
        ),
        name: "Story",
        document: fixture.draft.toDocument(),
      ),
    );
    final submissions = useMemoized(ScopedWorkSession.new);
    final workspace = useMemoized(
      () => RealmEditing(
        persistence: realm.persistence,
        submissions: submissions,
        initial: realm.document,
      ),
    );
    final operations = useMemoized(PortableOperationResults.new);
    final binding = useMemoized(() => workspace.attach(fixture.page));
    final host = useMemoized(
      () => AuthoredPresentationHost(
        resource: fixture.page,
        source: workspace.document,
        material: skir.PresentationMaterial.defaultInstance,
        role: skir.PresentationRole.workspace,
        budget: _budget,
        capabilities: const PortablePresentationCapabilities(),
        edit: binding,
      ),
    );
    useEffect(
      () => () {
        operations.dispose();
        host.dispose();
        binding.detach();
        workspace.dispose();
        submissions.dispose();
        unawaited(realm.close());
      },
      const [],
    );
    useListenable(workspace);
    // The inspector shows the element the user selected last, or the one
    // they opened, as the inspector beside a Realm surface does.
    final opened = useState(fixture.firstEntry);
    final selection = ref.watch(selectionProvider);
    final shown =
        selection
            .whereType<AuthoringResourceIdentifier>()
            .lastOrNull
            ?.resourceId ??
        opened.value;
    final inspector = useMemoized(() => workspace.attach(shown), [shown]);
    useEffect(() => inspector.detach, [inspector]);
    host.update(
      source: workspace.document,
      capabilities: const PortablePresentationCapabilities(),
      available: true,
      readOnly: false,
    );
    final node = skir.PresentationNode(
      nodeId: timeline ? "page.timeline" : "page.graph",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createResources(
        control: fixture.control,
        layout: timeline
            ? skir.ResourcesLayout.createTimeline(
                appearance: configured ? _timelineAppearance : null,
              )
            : skir.ResourcesLayout.createGraph(
                direction: skir.GraphDirection.leftToRight,
                appearance: configured ? _graphAppearance : null,
              ),
        order: null,
        itemBinding: declareNamedBinding(
          "resources.item",
          skir.TypeTemplate.unknown,
        ),
      ),
      header: null,
    );
    return SizedBox.expand(
      child: Row(
        children: [
          Expanded(
            // The interactions a Realm surface installs, so elements drag
            // and drop as they do there.
            child: AuthoredResourcesInteractions(
              authoringScope: realm.scope,
              binding: binding,
              child: PortablePresentationNodeRenderer(
                node: node,
                scope: PortablePresentationScope(
                  operations: operations,
                  bindings: {
                    configuredValueBindingId: PortableExpressionBinding(
                      value: skir.DataValue.createRecord(
                        fields: workspace.document
                            .resource(fixture.page)!
                            .fields,
                      ),
                      location: skir.ValueLocation(
                        resource: fixture.page,
                        path: skir.ValuePath(segments: const []),
                      ),
                    ),
                  },
                  budget: _budget,
                  catalog: fixture.catalog,
                  queries: PortableExpressionQueries(
                    catalog: fixture.catalog,
                    authored: workspace.document,
                  ),
                  resource: fixture.page,
                  role: skir.PresentationRole.workspace,
                  host: host,
                  openResource: (resource) => opened.value = resource,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AuthoredResourceEditor(
                  key: ValueKey(shown.value),
                  resource: shown,
                  document: workspace.document,
                  edit: inspector,
                  role: skir.PresentationRole.inspector,
                  budget: _budget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _budget = skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000);

final class _PageFixture {
  const _PageFixture({
    required this.page,
    required this.firstEntry,
    required this.draft,
    required this.catalog,
    required this.control,
  });

  final skir.ResourceId page;
  final skir.ResourceId firstEntry;
  final AuthoringEdit draft;
  final CheckedEditorCatalog catalog;
  final skir.BoundControl control;
}

_PageFixture _pageFixture() {
  final generation = skir.CatalogGeneration(value: "catalog:page_story");
  final pageType = _qualified("Page");
  final entryType = _qualified("Entry");
  final cueType = _qualified("Cue");
  final graphPlacementType = graphPlacementTypeRef;
  final segmentPlacementType = skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "54e38e56871243d2ae747ed6c0083381",
    ),
    revision: 1,
  );
  final page = skir.ResourceId(value: "page:story");
  final firstEntry = skir.ResourceId(value: "entry:introduction");
  final secondEntry = skir.ResourceId(value: "entry:reward");
  final cue = skir.ResourceId(value: "cue:dialogue");
  final pageRelation = skir.RelationId(value: "story.page_elements");
  final graphRelation = skir.RelationId(value: "story.entry_path");
  final ownershipRelation = skir.RelationId(value: "story.entry_cues");
  final pageEndpoint = skir.EndpointId(value: "story.page.elements");
  final entryEndpoint = skir.EndpointId(value: "story.entry.page");
  final ownerEndpoint = skir.EndpointId(value: "story.entry.cues");
  final cueEndpoint = skir.EndpointId(value: "story.cue.owner");
  final nameField = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final integerField = skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
  );
  final pageFields = [_Field("elements", nameField)];
  final graphPlacementFields = [
    _Field("x", integerField),
    _Field("y", integerField),
    _Field("width", integerField),
    _Field("height", integerField),
  ];
  final segmentPlacementFields = [
    _Field("startFrame", integerField),
    _Field("endFrame", integerField),
  ];
  final entryFields = [
    _Field("name", nameField),
    _Field(
      "placement",
      skir.TypeTemplate.createNamed(
        definition: graphPlacementType,
        arguments: const [],
      ),
    ),
  ];
  final cueFields = [
    _Field("name", nameField),
    _Field(
      "placement",
      skir.TypeTemplate.createNamed(
        definition: segmentPlacementType,
        arguments: const [],
      ),
    ),
  ];
  final inspectorPresentations = [
    _inspector(entryType, "entry.inspector"),
    _inspector(cueType, "cue.inspector"),
  ];
  final snapshot = skir.EditorCatalog(
    resourceDisplays: [
      for (final type in [entryType, cueType])
        nameResourceDisplay(
          skir.TypeTemplate.createNamed(definition: type, arguments: const []),
        ),
    ],
    resourceOperations: const [],
    generation: generation,
    types: [
      _published(pageType, pageFields),
      _published(entryType, entryFields),
      _published(cueType, cueFields),
      _published(graphPlacementType, graphPlacementFields),
      _published(segmentPlacementType, segmentPlacementFields),
    ],
    relations: [
      _relation(
        id: pageRelation,
        first: _endpoint(
          pageEndpoint,
          skir.EndpointSlot.first,
          pageType,
          skir.EndpointCardinality.one,
        ),
        second: _endpoint(
          entryEndpoint,
          skir.EndpointSlot.second,
          entryType,
          skir.EndpointCardinality.many,
        ),
      ),
      _relation(
        id: graphRelation,
        first: _endpoint(
          skir.EndpointId(value: "story.entry.next"),
          skir.EndpointSlot.first,
          entryType,
          skir.EndpointCardinality.many,
        ),
        second: _endpoint(
          skir.EndpointId(value: "story.entry.previous"),
          skir.EndpointSlot.second,
          entryType,
          skir.EndpointCardinality.many,
        ),
      ),
      skir.RelationContract(
        id: ownershipRelation,
        first: _endpoint(
          ownerEndpoint,
          skir.EndpointSlot.first,
          entryType,
          skir.EndpointCardinality.one,
        ),
        second: _endpoint(
          cueEndpoint,
          skir.EndpointSlot.second,
          cueType,
          skir.EndpointCardinality.many,
        ),
        families: [skir.resourceOwnershipFamily],
      ),
    ],
    realmRoot: skir.TypeDefinitionId.defaultInstance,
    presentations: [for (final item in inspectorPresentations) item.$1],
    presentationMaterials: [for (final item in inspectorPresentations) item.$2],
    configuration: const [],
    diagnostics: const [],

    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final catalog = CheckedEditorCatalog(snapshot);
  final resources = [
    _resource(page, pageType, {"elements": skir.DataValue.unfilled}),
    _resource(firstEntry, entryType, {
      "name": skir.DataValue.wrapStringValue("Introduction"),
      "placement": _namedRecord(graphPlacementType, {
        "x": skir.DataValue.wrapInteger("1"),
        "y": skir.DataValue.wrapInteger("1"),
        "width": skir.DataValue.wrapInteger("4"),
        "height": skir.DataValue.wrapInteger("2"),
      }),
    }),
    _resource(secondEntry, entryType, {
      "name": skir.DataValue.wrapStringValue("Reward"),
      "placement": _namedRecord(graphPlacementType, {
        "x": skir.DataValue.wrapInteger("7"),
        "y": skir.DataValue.wrapInteger("4"),
        "width": skir.DataValue.wrapInteger("4"),
        "height": skir.DataValue.wrapInteger("2"),
      }),
    }),
    _resource(cue, cueType, {
      "name": skir.DataValue.wrapStringValue("Welcome dialogue"),
      "placement": _namedRecord(segmentPlacementType, {
        "startFrame": skir.DataValue.wrapInteger("12"),
        "endFrame": skir.DataValue.wrapInteger("72"),
      }),
    }),
  ];
  final links = [
    skir.LinkProjection(
      contract: pageRelation,
      first: page,
      second: firstEntry,
      firstLocation: _itemPath("elements", "introduction"),
      secondLocation: null,
    ),
    skir.LinkProjection(
      contract: pageRelation,
      first: page,
      second: secondEntry,
      firstLocation: _itemPath("elements", "reward"),
      secondLocation: null,
    ),
    skir.LinkProjection(
      contract: graphRelation,
      first: firstEntry,
      second: secondEntry,
      firstLocation: _fieldPath("next"),
      secondLocation: _fieldPath("previous"),
    ),
    skir.LinkProjection(
      contract: ownershipRelation,
      first: firstEntry,
      second: cue,
      firstLocation: _itemPath("cues", "dialogue"),
      secondLocation: _fieldPath("owner"),
    ),
  ];
  final draft = AuthoringEdit.fromState(
    skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: generation,
      resources: resources,
      links: links,
      findings: const [],
    ),
    catalog: catalog,
  );
  return _PageFixture(
    page: page,
    firstEntry: firstEntry,
    draft: draft,
    catalog: catalog,
    control: skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: configuredValueBindingId,
        path: _fieldPath("elements"),
      ),
      label: null,
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
  );
}

final class _Field {
  const _Field(this.name, this.type);

  final String name;
  final skir.TypeTemplate type;
}

skir.TypeDefinitionId _qualified(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "widgetbook", name: name),
  revision: 1,
);

skir.PublishedType _published(skir.TypeDefinitionId id, List<_Field> fields) =>
    skir.PublishedType(
      name: "",
      searchKey: null,
      placementField: fields.any((field) => field.name == "placement")
          ? editorRootPath.field("placement")
          : null,
      display: defaultTypeDisplay(""),
      definition: skir.TypeDefinition(
        id: id,
        parameters: const [],
        representation: skir.RepresentationTemplate.createRecord(
          fields: [
            for (final field in fields)
              skir.FieldDeclaration(
                owner: skir.FieldOwner(definition: id, name: field.name),
                type: field.type,
                overrides: const [],
                hasConstructorDefault: false,
              ),
          ],
          form: skir.RecordForm.concrete,
        ),
        parents: const [],
      ),
      status: skir.DeclarationStatus.ready,
      effectiveFields: [
        for (final field in fields)
          skir.EffectiveFieldTemplate(
            key: field.name,
            owner: skir.FieldOwner(definition: id, name: field.name),
            type: field.type,
            rules: const [],
          ),
      ],
      ancestorTemplates: const [],
    );

(skir.PresentationDescriptor, skir.PresentationMaterial) _inspector(
  skir.TypeDefinitionId definition,
  String name,
) {
  final id = skir.PresentationId(namespace: "widgetbook", name: name);
  final target = skir.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  return (
    skir.PresentationDescriptor(
      id: id,
      owner: skir.DeclarationOwner.defaultInstance,
      target: target,
      roles: [skir.PresentationRole.inspector],
      priority: 0,
    ),
    skir.PresentationMaterial(
      inheritableNodes: const [],

      provider: id,
      target: target,
      role: skir.PresentationRole.inspector,
      layout: skir.PresentationNode(
        nodeId: "$name.fields",
        properties: skir.PresentationProperties.defaultInstance,
        element: skir.PresentationElement.createRemainingFields(
          excluded: const [],
          excludedParts: const [],
        ),
        header: null,
      ),
      dependencies: skir.PresentationDependencies.defaultInstance,
      subject: skir.TypeTemplate.createNamed(
        definition: definition,
        arguments: const [],
      ),
    ),
  );
}

skir.EndpointDefinition _endpoint(
  skir.EndpointId id,
  skir.EndpointSlot slot,
  skir.TypeDefinitionId resource,
  skir.EndpointCardinality cardinality,
) => skir.EndpointDefinition(
  id: id,
  slot: slot,
  resource: skir.NamedTypeTemplate(definition: resource, arguments: const []),
  cardinality: cardinality,
  onDelete: skir.RelationDeletePolicy.restrict,
);

skir.RelationContract _relation({
  required skir.RelationId id,
  required skir.EndpointDefinition first,
  required skir.EndpointDefinition second,
}) => skir.RelationContract(
  id: id,
  first: first,
  second: second,
  families: const [],
);

skir.AuthoringResource _resource(
  skir.ResourceId id,
  skir.TypeDefinitionId type,
  Map<String, skir.DataValue> fields,
) => skir.AuthoringResource(
  id: id,
  content: skir.AuthoringRecord(
    types: const [],
    configuration: skir.TypeSelection.createComplete(
      definition: type,
      arguments: const [],
    ),
    fields: [
      for (final entry in fields.entries)
        skir.FieldValue(name: entry.key, value: entry.value),
    ],
  ),
);

skir.DataValue _namedRecord(
  skir.TypeDefinitionId type,
  Map<String, skir.DataValue> fields,
) => skir.DataValue.createNamed(
  actualType: skir.NamedTypeUse(definition: type, arguments: const []),
  payload: skir.DataValue.createRecord(
    fields: [
      for (final entry in fields.entries)
        skir.FieldValue(name: entry.key, value: entry.value),
    ],
  ),
);

skir.ValuePath _fieldPath(String name) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]);

skir.ValuePath _itemPath(String field, String item) => skir.ValuePath(
  segments: [
    skir.PathSegment.createField(name: field),
    skir.PathSegment.createItem(id: skir.ItemId(value: item)),
  ],
);

final _accent = skir.PresentationColor.wrapValue(
  skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger("${0xff7354bf}")),
);

final _graphAppearance =
    (skir.ResourceGraphAppearance.mutable()
          ..cellSize = numberLiteral(60)
          ..edgeColor = _accent
          ..cardPadding = skir.PresentationInsets.wrapAll(8))
        .toFrozen();

final _timelineAppearance =
    (skir.ResourceTimelineAppearance.mutable()
          ..rulerHeight = 44
          ..trackPadding = 6
          ..laneHeight = 40
          ..laneGap = 12
          ..headerPadding = 8
          ..gridMajorColor = _accent)
        .toFrozen();
