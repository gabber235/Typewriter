import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/drivers/authoring/surface_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final class AuthoredGraphFixture {
  AuthoredGraphFixture({
    bool secondSource = false,
    bool scalarIncoming = false,
    bool ambiguousIncoming = false,
    bool ambiguousPages = false,
    bool candidateSearch = false,
  }) {
    skir.TypeTemplate named(String name) => skir.TypeTemplate.createNamed(
      definition: _type(name),
      arguments: const [],
    );
    skir.NamedTypeUse use(String name) =>
        skir.NamedTypeUse(definition: _type(name), arguments: const []);
    skir.PublishedType record(
      String name,
      Map<String, skir.TypeTemplate> fields,
    ) => declaredRecord(
      _type(name),
      fields: fields,
      placementField: fields.containsKey("placement")
          ? editorRootPath.field("placement")
          : null,
    );
    skir.EndpointDefinition endpoint(
      String id,
      String type,
      skir.EndpointSlot slot,
      skir.EndpointCardinality cardinality,
    ) => skir.EndpointDefinition(
      id: _endpoint(id),
      slot: slot,
      resource: skir.NamedTypeTemplate(
        definition: _type(type),
        arguments: const [],
      ),
      cardinality: cardinality,
      onDelete: skir.RelationDeletePolicy.clear,
    );
    skir.EndpointBindingTemplate binding(
      String id,
      String owner,
      String field,
      String target, {
      bool collection = false,
    }) => skir.EndpointBindingTemplate(
      endpoint: _endpoint(id),
      containingResource: skir.NamedTypeTemplate(
        definition: _type(owner),
        arguments: const [],
      ),
      valueOwner: _type(owner),
      relativePath: skir.RelativeFieldPattern(
        segments: [
          skir.FieldPatternSegment.createField(name: field),
          if (collection) skir.FieldPatternSegment.items,
        ],
      ),
      target: named(target),
      containsCollection: collection,
    );
    final snapshot = authoredCatalog(const []).snapshot.toMutable()
      ..types = [
        record("MoveInput", {
          "destination": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        }),
        record("LinkInput", {
          "target": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        }),
        record("OperationResourceOption", {
          "id": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          "label": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        }),
        record("Entry", {
          "page": named("PageRef"),
          "triggers": named("Triggers"),
          "incoming": named(scalarIncoming ? "IncomingRef" : "Incoming"),
          if (ambiguousIncoming) "incomingOther": named("IncomingRef"),
          "placement": skir.TypeTemplate.createNamed(
            definition: graphPlacementTypeRef,
            arguments: const [],
          ),
        }),
        record("Page", {
          "elements": named("Elements"),
          if (ambiguousPages) "elementsOther": named("Elements"),
        }),
        for (final definition in [
          ("PageRef", "entry.page", "Page"),
          ("ElementRef", "page.elements", "Entry"),
          ("TriggerRef", "trigger.source", "Entry"),
          ("IncomingRef", "trigger.target", "Entry"),
        ])
          declaredLink(
            _type(definition.$1),
            endpoint: definition.$2,
            target: named(definition.$3),
          ),
        for (final collection in [
          ("Elements", "ElementRef"),
          ("Triggers", "TriggerRef"),
          ("Incoming", "IncomingRef"),
        ])
          declaredCollection(_type(collection.$1), named(collection.$2)),
      ]
      ..relations = [
        skir.RelationContract(
          id: ownership,
          first: endpoint(
            "page.elements",
            "Page",
            skir.EndpointSlot.first,
            skir.EndpointCardinality.one,
          ),
          second: endpoint(
            "entry.page",
            "Entry",
            skir.EndpointSlot.second,
            skir.EndpointCardinality.many,
          ),
          families: [skir.resourceOwnershipFamily],
        ),
        skir.RelationContract(
          id: triggerRelation,
          first: endpoint(
            "trigger.source",
            "Entry",
            skir.EndpointSlot.first,
            skir.EndpointCardinality.many,
          ),
          second: endpoint(
            "trigger.target",
            "Entry",
            skir.EndpointSlot.second,
            skir.EndpointCardinality.many,
          ),
          families: const [],
        ),
      ]
      ..endpointBindings = [
        binding("entry.page", "Entry", "page", "Page"),
        binding("page.elements", "Page", "elements", "Entry", collection: true),
        if (ambiguousPages)
          binding(
            "page.elements",
            "Page",
            "elementsOther",
            "Entry",
            collection: true,
          ),
        binding(
          "trigger.source",
          "Entry",
          "triggers",
          "Entry",
          collection: true,
        ),
        if (ambiguousIncoming)
          binding("trigger.target", "Entry", "incomingOther", "Entry"),
        binding(
          "trigger.target",
          "Entry",
          "incoming",
          "Entry",
          collection: !scalarIncoming,
        ),
      ]
      ..capabilities = [
        for (final operation in fixtureOperations)
          skir.CapabilityDefinition.createAuthoring(
            capabilityId: skir.CapabilityId(value: operation),
            targets: fixtureOperationTargets,
            input: operation == "delete"
                ? null
                : skir.OperationInputDefinition(
                    type: skir.TypeUse.wrapNamed(
                      use(operation == "linkWith" ? "LinkInput" : "MoveInput"),
                    ),
                    presentation: null,
                  ),
          ),
        if (candidateSearch)
          skir.CapabilityDefinition.createSearch(
            capabilityId: moveCandidateSearch,
            requestType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
            resultType: skir.TypeUse.wrapNamed(use("OperationResourceOption")),
          ),
      ]
      ..resourceOperations = [
        for (final operation in fixtureOperations)
          skir.ResourceOperationDefinition(
            id: fixtureOperationId(operation),
            targets: fixtureOperationTargets,
            capability: skir.CapabilityId(value: operation),
            drop: switch (operation) {
              "moveToOwner" => skir.OperationDrop(
                input: editorRootPath.field("destination"),
                hint: "Move here",
              ),
              "linkWith" => skir.OperationDrop(
                input: editorRootPath.field("target"),
                hint: "Link",
              ),
              _ => null,
            },
            presentation: skir.OperationPresentation(
              inspector: skir.OperationInspector.wrapButton(
                operation == "delete"
                    ? skir.ButtonVariant.filled
                    : skir.ButtonVariant.outlined,
              ),
              shortcut: operation == "delete"
                  ? skir.OperationShortcut.delete
                  : null,
              label: {
                "moveToOwner": "Move to",
                "linkWith": "Link with",
                "delete": "Delete",
              }[operation]!,
              description: "Fixture operation",
              icon: "",
              group: operation == "delete"
                  ? skir.OperationGroup.destructive
                  : skir.OperationGroup.organize,
              order: operation == "linkWith" ? 20 : 10,
              tone: operation == "delete"
                  ? skir.HeaderActionTone.destructive
                  : skir.HeaderActionTone.neutral,
              confirmation: null,
            ),
          ),
      ];
    final catalog = CheckedEditorCatalog(snapshot.toFrozen());
    skir.DataValue sequence(String type, List<skir.ListItem> items) =>
        skir.DataValue.createNamed(
          actualType: use(type),
          payload: skir.DataValue.createListValue(items: items),
        );
    final sourceIds = [source, if (secondSource) second];
    skir.ValuePath membershipPath(skir.ResourceId id) => skir.ValuePath(
      segments: [
        skir.PathSegment.createField(name: "elements"),
        skir.PathSegment.createItem(id: skir.ItemId(value: id.value)),
      ],
    );
    skir.DataValue link(
      String endpoint,
      skir.ResourceId target,
      skir.ValuePath opposite,
    ) => skir.DataValue.createLink(
      endpoint: _endpoint(endpoint),
      target: skir.LinkTarget(resource: target, opposite: opposite),
    );
    skir.AuthoringResource resource(
      skir.ResourceId id,
      String type,
      List<skir.FieldValue> fields,
    ) => skir.AuthoringResource(
      id: id,
      content: skir.AuthoringRecord(
        configuration: skir.TypeSelection.wrapComplete(use(type)),
        fields: fields,
      ),
    );
    final resources = [
      for (final pair in [
        (page, sourceIds),
        (destination, [target]),
      ])
        resource(pair.$1, "Page", [
          if (ambiguousPages)
            skir.FieldValue(
              name: "elementsOther",
              value: sequence("Elements", const []),
            ),
          skir.FieldValue(
            name: "elements",
            value: sequence("Elements", [
              for (final id in pair.$2)
                skir.ListItem(
                  id: skir.ItemId(value: id.value),
                  value: link(
                    "page.elements",
                    id,
                    editorRootPath.field("page"),
                  ),
                ),
            ]),
          ),
        ]),
      for (final id in [...sourceIds, target])
        resource(id, "Entry", [
          skir.FieldValue(
            name: "page",
            value: link(
              "entry.page",
              id == target ? destination : page,
              membershipPath(id),
            ),
          ),
          skir.FieldValue(
            name: "triggers",
            value: sequence("Triggers", const []),
          ),
          skir.FieldValue(
            name: "incoming",
            value: scalarIncoming
                ? skir.DataValue.unfilled
                : sequence("Incoming", const []),
          ),
          if (ambiguousIncoming)
            skir.FieldValue(
              name: "incomingOther",
              value: skir.DataValue.unfilled,
            ),
          skir.FieldValue(
            name: "placement",
            value: Placement.graph(
              x: id == second ? 6 : 0,
              y: 0,
              width: 4,
              height: 1,
            ).toAuthoredValue(),
          ),
        ]),
    ];
    final document = AuthoringDocument(
      confirmedObservation: skir.AuthoringObservationId(value: "graph:saved"),
      catalog: catalog,
      entries: {for (final value in resources) value.id: value},
      links: [
        for (final id in [...sourceIds, target])
          skir.LinkProjection(
            contract: ownership,
            first: id == target ? destination : page,
            second: id,
            firstLocation: membershipPath(id),
            secondLocation: editorRootPath.field("page"),
          ),
      ],
    );
    this.document = document;
    drag = ResourceDrag(
      scope: scope,
      primary: AuthoringResourceIdentifier.inScope(scope, source),
      subjects: sourceIds,
    );
    memberships = {
      for (final id in sourceIds)
        id: skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: _endpoint("page.elements"),
            location: skir.ValueLocation(
              resource: page,
              path: membershipPath(id),
            ),
          ),
          source: page,
          target: skir.LinkTarget(
            resource: id,
            opposite: editorRootPath.field("page"),
          ),
        ),
    };
  }

  /// The search over Move to destinations, derived from its capability.
  static final moveCandidateSearch = skir.CapabilityId(
    value: "moveToOwner/candidates/destination",
  );

  /// An operation resource option row, as candidate searches return them.
  skir.DataValue option(skir.ResourceId id, String label) =>
      skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(
          definition: _type("OperationResourceOption"),
          arguments: const [],
        ),
        payload: skir.DataValue.createRecord(
          fields: [
            skir.FieldValue(
              name: "id",
              value: skir.DataValue.wrapStringValue(id.value),
            ),
            skir.FieldValue(
              name: "label",
              value: skir.DataValue.wrapStringValue(label),
            ),
          ],
        ),
      );

  final source = skir.ResourceId(value: "entry:source");
  final second = skir.ResourceId(value: "entry:second");
  final target = skir.ResourceId(value: "entry:target");
  final page = skir.ResourceId(value: "page:source");
  final destination = skir.ResourceId(value: "page:destination");
  final ownership = skir.RelationId(value: "membership");
  final triggerRelation = skir.RelationId(value: "triggers");

  /// The scope of the Realm [realm] seeds in [acme].
  final scope = AuthoringScope(
    organizationId: acme.organizationId,
    realmId: skir.recordId("realm_instance:graph"),
  );

  /// The saved document of the graph Realm.
  late final AuthoringDocument document;

  World? _world;

  World get _started =>
      _world ?? (throw StateError("Pump the panel with fixture.realm first"));

  /// The graph Realm, signed in as [ada] of [acme]: its saved [document],
  /// the drop candidates and operation previews this fixture answers.
  List<Trait> get realm => [
    signedIn(ada, organization: acme),
    _GraphRealm(this),
  ];

  /// The Realm double serving [document].
  FakeRealm get realmDouble => _started.requireRealm;

  /// The panel's editing of the graph Realm.
  RealmEditing get workspace =>
      _started.container.read(realmEditingProvider(scope));

  void _start(World world) {
    _world = world;
    world.requireRealm
      ..answerDropCandidates = dropCandidates
      ..answerPrepareAction = _prepare
      ..answerResourceOperations = (request) async =>
          skir.ResolveResourceOperationsResult.wrapResolved(
            skir.ResolvedResourceOperations(
              operations: [
                for (final operation
                    in document.catalog.snapshot.resourceOperations)
                  skir.ResolvedResourceOperation(
                    definition: operation,
                    availability: skir.OperationAvailability.enabled,
                  ),
              ],
            ),
          );
  }

  late final ResourceDrag drag;

  /// The page's membership occurrence of every source entry.
  late final Map<skir.ResourceId, skir.LinkOccurrence> memberships;
  bool mutable = true;

  final preparations = <skir.PrepareAuthoringActionRequest>[];

  /// Every drop candidate request, one per drag.
  final dropResolutions = <skir.ResolveDropCandidatesRequest>[];

  /// The authoring commands the graph Realm answers with.
  AuthoredResourceCommands get commands => realmDouble.commands;

  /// The fixture's answer to where dragged resources may land: pages accept
  /// a move of entries they do not own; entries accept a link from other
  /// entries. Records each request in [dropResolutions].
  Future<skir.ResolveDropCandidatesResult> dropCandidates(
    skir.ResolveDropCandidatesRequest request,
  ) async {
    dropResolutions.add(request);
    final subjects = request.invocation.targets.toSet();
    final document = workspace.document;
    final owners = {
      for (final subject in subjects) ...?document.relations.parents[subject],
    };
    return skir.ResolveDropCandidatesResult.wrapResolved([
      skir.DropCandidates(
        operation: fixtureOperationId("moveToOwner"),
        destinations: [
          for (final page in [page, destination])
            if (!owners.contains(page)) page,
        ],
        complete: true,
      ),
      skir.DropCandidates(
        operation: fixtureOperationId("linkWith"),
        destinations: [
          for (final entry in [source, second, target])
            if (!subjects.contains(entry) && document.entry(entry) != null)
              entry,
        ],
        complete: true,
      ),
    ]);
  }

  Future<skir.AuthoringActionResult> _prepare(
    skir.PrepareAuthoringActionRequest request,
  ) async {
    preparations.add(request);
    final field = request.capability.value == "linkWith"
        ? "target"
        : "destination";
    final identity = request.input?.authoredField(field)?.authoredString;
    if (request.capability.value != "delete" &&
        (identity == null || identity.isEmpty)) {
      return skir.AuthoringActionResult.createNeedsInput(
        invocationId: request.invocation.invocationId,
        inputRevision: request.inputRevision,
        normalizedInput: request.input,
        problems: [
          skir.OperationInputProblem(
            path: editorRootPath.field(field),
            code: "required",
            message: "Choose $field",
          ),
        ],
        choices: const [],
      );
    }
    final edit = AuthoringEdit.fromDocument(workspace.document);
    for (final resource in request.invocation.targets) {
      if (request.capability.value == "delete") {
        edit.delete(resource);
        continue;
      }
      final linking = request.capability.value == "linkWith";
      final path = linking
          ? skir.ValuePath(
              segments: [
                skir.PathSegment.createField(name: "triggers"),
                skir.PathSegment.createItem(
                  id: skir.ItemId(
                    value:
                        "fixture:${request.invocation.invocationId.value}:$resource",
                  ),
                ),
              ],
            )
          : editorRootPath.field("page");
      final targetId = skir.ResourceId(value: identity!);
      edit.connect(
        skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: _endpoint(linking ? "trigger.source" : "entry.page"),
            location: skir.ValueLocation(resource: resource, path: path),
          ),
          source: resource,
          target: skir.LinkTarget(resource: targetId, opposite: null),
        ),
        targetId,
      );
    }
    return skir.AuthoringActionResult.createPreview(
      invocationId: request.invocation.invocationId,
      inputRevision: request.inputRevision,
      edit: edit.prepare(),
      confirmation: null,
      selection: skir.OperationSelectionEffect.unchanged,
    );
  }
}

const fixtureOperations = ["moveToOwner", "linkWith", "delete"];

final fixtureOperationTargets = skir.OperationTargets(
  subject: skir.ResourceTarget.anyResource,
  cardinality: skir.OperationCardinality.selection,
);

skir.ResourceOperationId fixtureOperationId(String operation) =>
    skir.ResourceOperationId(
      artifact: "typewriter",
      sourcePart: "main",
      declaration: "com.typewritermc.operations.$operation",
    );

skir.TypeDefinitionId _type(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "graph-test", name: name),
  revision: 1,
);
skir.EndpointId _endpoint(String value) => skir.EndpointId(value: value);

final class _GraphRealm extends Trait {
  const _GraphRealm(this.fixture);

  final AuthoredGraphFixture fixture;

  @override
  Slot get slot => Slot.realm;

  @override
  String get description => "AuthoredGraphFixture.realm";

  @override
  void applyTo(WorldBuilder world) {
    world
      ..realm = RealmSeed(name: "Graph", saved: fixture.document)
      ..onStart(fixture._start);
  }
}

/// Showing the graph Realm's page as an authored resources graph.
extension AuthoredGraphViews on AuthoredGraphFixture {
  /// Opens the graph Realm and shows the dragged primary resource as a lone
  /// item reading "Source" in the top left corner above it, unbound and
  /// free to change.
  Future<PanelDriver> showSourceItem(WidgetTester tester) async {
    final panel = await tester.pumpPanel(this.realm);
    await panel.showAbove(
      at: Alignment.topLeft,
      SizedBox(
        width: 160,
        height: 80,
        child: AuthoredResourceItem(
          identifier: drag.primary,
          resources: AuthoredResourcesContext(
            authoringScope: scope,
            binding: null,
            scope: PortablePresentationScope(
              bindings: const {},
              operations: testPortableOperations(),
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 10,
              ),
            ),
            canMutate: () => true,
          ),
          child: const Text("Source"),
        ),
      ),
    );
    return panel;
  }

  /// Opens the graph Realm and shows its page's entries on a graph above it,
  /// bound to [bound] or the page. [sidebar] adds a drop target for the
  /// destination beside the graph, and each of [linkFields] a link field
  /// target labeled by its key.
  Future<PanelDriver> showGraph(
    WidgetTester tester, {
    bool readOnly = false,
    bool sidebar = false,
    skir.ResourceId? bound,
    Map<String, skir.ResourceId> linkFields = const {},
    GraphMoveCommit? onMove,
    GraphResizeCommit? onResize,
    ValueNotifier<bool>? readOnlySource,
    Map<Type, Action<Intent>>? actions,
  }) async {
    final panel = await tester.pumpPanel(this.realm);
    final binding = workspace.attach(
      bound ?? this.page,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    final presentation = PortablePresentationScope(
      bindings: const {},
      operations: testPortableOperations(),
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
      readOnly: readOnly,
      resource: this.page,
    );
    final entries = graphEntries;
    await panel.showAbove(
      Actions(
        actions: actions ?? const {},
        child: SizedBox(
          width: 900,
          height: 600,
          child: Row(
            children: [
              if (sidebar)
                SizedBox(
                  width: 150,
                  child: ResourceDropTarget.at(
                    scope: scope,
                    destination: DropDestination.resource(destination),
                    builder: (context, hover) => const SizedBox(
                      key: ValueKey("destination"),
                      height: 80,
                      child: Text("Destination"),
                    ),
                  ),
                ),
              Expanded(
                child: AuthoredResourcesInteractions(
                  authoringScope: scope,
                  binding: binding,
                  child: HookBuilder(
                    builder: (context) {
                      useListenable(readOnlySource);
                      final currentScope = presentation.copyWith(
                        readOnly: readOnlySource?.value ?? readOnly,
                      );
                      final interactions =
                          PortableResourcesInteractionScope.maybeOf(context)!;
                      final view = PortableResourcesView(
                        members: entries,
                        scope: currentScope,
                        layout: PortableResourcesLayoutKind.graph,
                      );
                      final graph = interactions.layoutBuilder(
                        context,
                        view,
                        Graph(
                          data: GraphData(
                            cellSize: 50,
                            edges: const [],
                            elements: [
                              for (final (index, entry) in entries.indexed)
                                GraphElement(
                                  id: GraphIdentifier(entry.resource.value),
                                  x: index * 6,
                                  y: 0,
                                  width: 4,
                                  height: 1,
                                  builder: (context) =>
                                      interactions.itemBuilder(
                                        context,
                                        view,
                                        entry,
                                        Builder(
                                          builder: (context) => ColoredBox(
                                            key: ValueKey(entry.resource),
                                            color: Colors.red,
                                            child: Text(entry.resource.value),
                                          ),
                                        ),
                                      ),
                                ),
                            ],
                          ),
                          onElementsMoved: currentScope.readOnly
                              ? null
                              : onMove ?? (_) {},
                          onElementsResized: currentScope.readOnly
                              ? null
                              : onResize,
                        ),
                      );
                      if (linkFields.isEmpty) return graph;
                      return Column(
                        children: [
                          Expanded(child: graph),
                          for (final MapEntry(key: label, value: resource)
                              in linkFields.entries)
                            PortableResourcesInteractionScope.wrapLinkField(
                              context,
                              currentScope,
                              skir.ValueLocation(
                                resource: resource,
                                path: editorRootPath.field("triggers"),
                              ),
                              Semantics(
                                label: label,
                                container: true,
                                child: const SizedBox(height: 60, width: 300),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return panel;
  }

  /// The page's entries as a graph lists them, each labeled by its id.
  List<PortableResourceMember> get graphEntries => [
    for (final member in memberships.entries)
      PortableResourceMember(
        resource: member.key,
        occurrence: member.value,
        link: skir.DataValue.unfilled,
        resourceProjection: PortableResourceProjection(
          resource: member.key,
          configuration: workspace.document.resource(member.key)!.configuration,
          appearance: skir.ResourceAppearance(
            label: member.key.value,
            accent: const Color(0xff607d8b).toSkirColor(),
            icon: skir.Icon.wrapIconify("material-symbols:category"),
          ),
          value: skir.DataValue.wrapStringValue("fixture"),
        ),
        graph: const PortableGraphPlacement(x: 0, y: 0, width: 4, height: 1),
      ),
  ];

  /// Opens the graph Realm and shows the page's source entry, labeled
  /// "Source", on a graph beside a drop target labeled "Operation target" for
  /// [destination] or the fixture's destination, inside a drop target for
  /// [enclosing] when given. [resolve] answers the Realm's drop candidates;
  /// [visible] and [generation] hide the graph or rebuild it from scratch.
  Future<PanelDriver> showDropTarget(
    WidgetTester tester, {
    Future<skir.ResolveDropCandidatesResult> Function(
      skir.ResolveDropCandidatesRequest,
    )?
    resolve,
    ValueNotifier<bool>? visible,
    ValueNotifier<int>? generation,
    skir.ResourceId? destination,
    skir.ResourceId? enclosing,
  }) async {
    final panel = await tester.pumpPanel(this.realm);
    if (resolve != null) realmDouble.answerDropCandidates = resolve;
    final binding = workspace.attach(
      this.page,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    final pageScope = PortablePresentationScope(
      bindings: const {},
      operations: testPortableOperations(),
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
      resource: this.page,
    );
    final entries = [
      for (final member in memberships.entries)
        PortableResourceMember(
          resource: member.key,
          occurrence: member.value,
          link: skir.DataValue.unfilled,
          resourceProjection: PortableResourceProjection(
            resource: member.key,
            configuration: workspace.document
                .resource(member.key)!
                .configuration,
            appearance: skir.ResourceAppearance(
              label: "Source",
              accent: const Color(0xff607d8b).toSkirColor(),
              icon: skir.Icon.wrapIconify("material-symbols:category"),
            ),
            value: skir.DataValue.wrapStringValue("fixture"),
          ),
          graph: const PortableGraphPlacement(x: 0, y: 0, width: 4, height: 1),
        ),
    ];
    await panel.showAbove(
      SizedBox(
        width: 900,
        child: Row(
          children: [
            Expanded(
              child: HookBuilder(
                builder: (context) {
                  useListenable(visible);
                  useListenable(generation);
                  if (!(visible?.value ?? true)) return const SizedBox.shrink();
                  return ProviderScope(
                    key: ValueKey(generation?.value ?? 0),
                    child: AuthoredResourcesInteractions(
                      authoringScope: scope,
                      binding: binding,
                      child: Builder(
                        builder: (context) {
                          final interactions =
                              PortableResourcesInteractionScope.maybeOf(
                                context,
                              )!;
                          final view = PortableResourcesView(
                            members: entries,
                            scope: pageScope,
                            layout: PortableResourcesLayoutKind.graph,
                          );
                          return interactions.layoutBuilder(
                            context,
                            view,
                            SizedBox(
                              height: 300,
                              child: Graph(
                                data: GraphData(
                                  cellSize: 50,
                                  edges: const [],
                                  elements: [
                                    GraphElement(
                                      id: GraphIdentifier(source.value),
                                      x: 0,
                                      y: 0,
                                      width: 4,
                                      height: 1,
                                      builder: (context) =>
                                          interactions.itemBuilder(
                                            context,
                                            view,
                                            entries.first,
                                            const ColoredBox(
                                              color: Colors.blue,
                                              child: Text("Source"),
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                                onElementsMoved: (_) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 180,
              height: 100,
              child: _enclosedBy(
                enclosing,
                ResourceDropTarget.at(
                  scope: scope,
                  destination: DropDestination.resource(
                    destination ?? this.destination,
                  ),
                  canMutate: () => mutable,
                  builder: (_, hover) => Semantics(
                    label: "Operation target",
                    child: ColoredBox(
                      color: Colors.green,
                      child: Text(_hoverText(hover)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return panel;
  }

  /// Places [target] inside a padded drop target for [enclosing], when given.
  Widget _enclosedBy(skir.ResourceId? enclosing, Widget target) =>
      enclosing == null
      ? target
      : ResourceDropTarget.at(
          scope: scope,
          destination: DropDestination.resource(enclosing),
          canMutate: () => mutable,
          builder: (_, hover) => Column(
            children: [
              Text("enclosing ${_hoverText(hover)}"),
              Expanded(child: target),
            ],
          ),
        );

  String _hoverText(ResourceDropHover hover) => hover.accepted
      ? "accepted: ${hover.hint}"
      : hover.rejected
      ? "rejected"
      : "neutral";

  /// Answers drop candidates with [resolve], recording each request the
  /// way [dropCandidates] does.
  Future<skir.ResolveDropCandidatesResult> Function(
    skir.ResolveDropCandidatesRequest,
  )
  recording({
    required Future<skir.ResolveDropCandidatesResult> Function(
      skir.ResolveDropCandidatesRequest,
    )
    resolve,
  }) => (request) {
    dropResolutions.add(request);
    return resolve(request);
  };

  /// Starts dragging the "Source" entry of [showDropTarget] with [pointer].
  Future<TestGesture> startSourceDrag(
    WidgetTester tester, {
    int pointer = 1,
  }) async {
    final source = find.descendant(
      of: find.byType(Graph),
      matching: find.text("Source"),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(source),
      pointer: pointer,
    );
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    return gesture;
  }
}
