import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Graph workspace", type: AuthoredResourceEditor)
Widget pageGraphWorkspaceUseCase(BuildContext context) =>
    const FakeApp(child: PageWorkspaceStory(timeline: false));

@widgetbook.UseCase(name: "Timeline workspace", type: AuthoredResourceEditor)
Widget pageTimelineWorkspaceUseCase(BuildContext context) =>
    const FakeApp(child: PageWorkspaceStory(timeline: true));

final class PageWorkspaceStory extends StatefulWidget {
  const PageWorkspaceStory({
    required this.timeline,
    this.onDraftChanged,
    this.onResourceSelected,
    super.key,
  });

  final bool timeline;
  final ValueChanged<AuthoredDraft>? onDraftChanged;
  final ValueChanged<skir.ResourceId>? onResourceSelected;

  @override
  State<PageWorkspaceStory> createState() => _PageWorkspaceStoryState();
}

final class _PageWorkspaceStoryState extends State<PageWorkspaceStory> {
  late final _PageFixture _fixture = _pageFixture();
  late skir.ResourceId _selected = _fixture.firstEntry;

  @override
  Widget build(BuildContext context) {
    final workspace = skir.PresentationNode(
      nodeId: widget.timeline ? "page.timeline" : "page.graph",
      properties: skir.PresentationProperties.defaultInstance,
      element: widget.timeline
          ? skir.PresentationElement.createPageTimeline(
              control: _fixture.control,
            )
          : skir.PresentationElement.createPageGraph(
              control: _fixture.control,
              direction: skir.PageGraphDirection.leftToRight,
      ),
      header: null,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timeline ? "Timeline page" : "Graph page"),
      ),
      body: Row(
        children: [
          Expanded(
            child: PortablePresentationNodeRenderer(
              node: workspace,
              scope: PortablePresentationScope(
                bindings: {
                  configuredValueBindingId: PortableExpressionBinding(
                    value: skir.DataValue.createRecord(
                      fields: _fixture.draft.resource(_fixture.page)!.fields,
                    ),
                    location: skir.ValueLocation(
                      resource: _fixture.page,
                      path: skir.ValuePath(segments: const []),
                    ),
                  ),
                },
                budget: _budget,
                setBinding: (_, _) {},
                authoring: AuthoredDraftAuthoringDocument(_fixture.draft),
                catalog: _fixture.catalog,
                resource: _fixture.page,
                role: skir.PresentationRole.editor,
                openResource: (resource) {
                  setState(() => _selected = resource);
                  widget.onResourceSelected?.call(resource);
                },
                onDraftChanged: () {
                  setState(() {});
                  widget.onDraftChanged?.call(_fixture.draft);
                },
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
                  key: ValueKey(_selected.value),
                  resource: _selected,
                  draft: _fixture.draft,
                  catalog: _fixture.catalog,
                  role: skir.PresentationRole.inspector,
                  budget: _budget,
                  onChanged: (_) => setState(() {}),
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
  final AuthoredDraft draft;
  final CheckedEditorCatalog catalog;
  final skir.BoundControl control;
}

_PageFixture _pageFixture() {
  final generation = skir.CatalogGeneration(value: "catalog:page_story");
  final pageType = _qualified("Page");
  final entryType = _qualified("Entry");
  final cueType = _qualified("Cue");
  final graphPlacementType = _qualified("GraphPlacement");
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
  final snapshot = skir.EditorCatalogWireSnapshot(
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
        families: [skir.RelationFamilyId(value: "resource.ownership")],
      ),
    ],
    resourceDefinitions: [
      skir.AuthoringResourceDefinition(
        id: skir.ResourceDefinitionId(value: "typewriter.cue"),
        root: cueType,
        navigationHandler: "story.cue",
      ),
    ],
    presentations: [for (final item in inspectorPresentations) item.$1],
    presentationMaterials: [for (final item in inspectorPresentations) item.$2],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final catalog = CheckedEditorCatalog(snapshot);
  final resources = [
    _resource(page, "story.page", pageType, {
      "elements": skir.DataValue.unfilled,
    }),
    _resource(firstEntry, "story.entry", entryType, {
      "name": skir.DataValue.wrapStringValue("Introduction"),
      "placement": _namedRecord(graphPlacementType, {
        "x": skir.DataValue.wrapInteger("1"),
        "y": skir.DataValue.wrapInteger("1"),
        "width": skir.DataValue.wrapInteger("4"),
        "height": skir.DataValue.wrapInteger("2"),
      }),
    }),
    _resource(secondEntry, "story.entry", entryType, {
      "name": skir.DataValue.wrapStringValue("Reward"),
      "placement": _namedRecord(graphPlacementType, {
        "x": skir.DataValue.wrapInteger("7"),
        "y": skir.DataValue.wrapInteger("4"),
        "width": skir.DataValue.wrapInteger("4"),
        "height": skir.DataValue.wrapInteger("2"),
      }),
    }),
    _resource(cue, "typewriter.cue", cueType, {
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
  final draft = AuthoredDraft.fromSnapshot(
    skir.AuthoringSnapshot(
      snapshot: skir.SnapshotId(value: "realm:page_story"),
      generation: generation,
      resources: resources,
      links: links,
      findings: const [],
      findingsToken: skir.FindingsToken(value: "findings:page_story"),
      observations: const [],
      absentInputToken: skir.InputToken(value: "absent"),
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
      display: null,
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
          abstract_: false,
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
      provider: id,
      target: target,
      role: skir.PresentationRole.inspector,
      layout: skir.PresentationNode(
        nodeId: "$name.fields",
        properties: skir.PresentationProperties.defaultInstance,
        element: skir.PresentationElement.createRemainingFields(
          excluded: const [],
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
  String definition,
  skir.TypeDefinitionId type,
  Map<String, skir.DataValue> fields,
) => skir.AuthoringResource(
  id: id,
  definition: skir.ResourceDefinitionId(value: definition),
  content: skir.AuthoringRecord(
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
