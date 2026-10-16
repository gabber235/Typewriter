import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final class AuthoredGraphFixture {
  AuthoredGraphFixture({
    bool secondSource = false,
    bool scalarIncoming = false,
    bool ambiguousIncoming = false,
    bool ambiguousPages = false,
  }) {
    skir.TypeTemplate named(String name) => skir.TypeTemplate.createNamed(
      definition: _type(name),
      arguments: const [],
    );
    skir.NamedTypeUse use(String name) =>
        skir.NamedTypeUse(definition: _type(name), arguments: const []);
    skir.PublishedType published(
      String name,
      skir.RepresentationTemplate representation, {
      List<skir.EffectiveFieldTemplate> fields = const [],
    }) => skir.PublishedType(
      display: null,
      definition: skir.TypeDefinition(
        id: _type(name),
        parameters: const [],
        representation: representation,
        parents: const [],
      ),
      status: skir.DeclarationStatus.ready,
      effectiveFields: fields,
      ancestorTemplates: const [],
    );
    skir.PublishedType record(
      String name,
      Map<String, skir.TypeTemplate> fields,
    ) => published(
      name,
      skir.RepresentationTemplate.createRecord(
        abstract_: false,
        fields: [
          for (final field in fields.entries)
            skir.FieldDeclaration(
              owner: skir.FieldOwner(definition: _type(name), name: field.key),
              type: field.value,
              overrides: const [],
              hasConstructorDefault: false,
            ),
        ],
      ),
      fields: [
        for (final field in fields.entries)
          skir.EffectiveFieldTemplate(
            key: field.key,
            owner: skir.FieldOwner(definition: _type(name), name: field.key),
            type: field.value,
            rules: const [],
          ),
      ],
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
    final snapshot = receivedEditorCatalogWireSnapshot().toMutable()
      ..types = [
        record("MoveInput", {
          "destination": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        }),
        record("LinkInput", {
          "target": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
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
          published(
            definition.$1,
            skir.RepresentationTemplate.createLink(
              endpoint: _endpoint(definition.$2),
              target: named(definition.$3),
            ),
          ),
        for (final collection in [
          ("Elements", "ElementRef"),
          ("Triggers", "TriggerRef"),
          ("Incoming", "IncomingRef"),
        ])
          published(
            collection.$1,
            skir.RepresentationTemplate.createSequence(
              item: named(collection.$2),
              kind: skir.CollectionKind.list,
            ),
          ),
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
          families: [skir.RelationFamilyId(value: "resource.ownership")],
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
      ];
    snapshot.capabilities = [
      for (final operation in ["moveToPage", "linkWith", "delete"])
        skir.CapabilityDefinition.createAuthoring(
          capabilityId: skir.CapabilityId(value: operation),
          targets: skir.OperationTargets.contributedSelection,
          input: operation == "delete"
              ? null
              : skir.OperationInputDefinition(
                  type: skir.TypeUse.wrapNamed(
                    use(operation == "linkWith" ? "LinkInput" : "MoveInput"),
                  ),
                  presentation: null,
                ),
        ),
    ];
    snapshot.resourceOperations = [
      for (final operation in ["moveToPage", "linkWith", "delete"])
        skir.ResourceOperationDefinition(
          id: (resourceDeleteOperationId.toMutable()..local = operation)
              .toFrozen(),
          targets: skir.OperationTargets.contributedSelection,
          presentation: skir.OperationPresentation(
            label: {
              "moveToPage": "Move to page",
              "linkWith": "Link with",
              "delete": "Delete",
            }[operation]!,
            description: "Fixture operation",
            icon: "",
            group: skir.OperationGroup.edit,
            order: 0,
            tone: skir.HeaderActionTone.neutral,
            confirmation: null,
          ),
          action: skir.EditorAction.createAuthoring(
            capability: skir.CapabilityId(value: operation),
            targets: skir.ExpressionNode.createRead(
              binding: skir.ExpressionBindingId(value: "context:selection"),
              path: editorRootPath,
            ),
            initialInput: null,
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
      definition: skir.ResourceDefinitionId(value: type),
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
    transport = ScriptedAuthoringTransport(AsyncData(document));
    final work = ScopedWorkSession();
    workspace = RealmEditing(
      persistence: transport.persistence,
      submissions: work,
      initial: document,
    );
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
    addTearDown(work.dispose);
    group = AuthoringResourceDragGroup(
      primary: AuthoringResourceIdentifier.inScope(scope, source),
      memberships: {
        for (final id in sourceIds)
          AuthoringResourceIdentifier.inScope(scope, id): skir.LinkOccurrence(
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
      },
    );
  }

  final source = skir.ResourceId(value: "entry:source");
  final second = skir.ResourceId(value: "entry:second");
  final target = skir.ResourceId(value: "entry:target");
  final page = skir.ResourceId(value: "page:source");
  final destination = skir.ResourceId(value: "page:destination");
  final ownership = skir.RelationId(value: "membership");
  final triggerRelation = skir.RelationId(value: "triggers");
  final scope = AuthoringScope(
    organizationId: skir.RecordId(
      table: "organization",
      key: skir.RecordIdKey.wrapString("organization"),
    ),
    realmId: skir.RecordId(
      table: "realm",
      key: skir.RecordIdKey.wrapString("realm"),
    ),
  );
  late final RealmEditing workspace;
  late final ScriptedAuthoringTransport transport;
  late final AuthoringResourceDragGroup group;
  bool mutable = true;

  final preparations = <skir.PrepareAuthoringActionRequest>[];

  AuthoredResourceCommands get commands {
    final base = fixtureAuthoringCommands(transport);
    return AuthoredResourceCommands(
      previewTypeArguments: base.previewTypeArguments,
      prepareTypeArguments: base.prepareTypeArguments,
      prepareStep: base.prepareStep,
      prepareValue: (request) async {
        if (request.target case skir.PreparationTarget_valueWrapper(
          :final value,
        )) {
          final named = workspace.document.catalog.namedUse(value)!;
          return skir.PreparedValue(
            findings: const [],
            content: skir.PreparedContent.wrapValue(
              request.suppliedValue ??
                  skir.DataValue.createNamed(
                    actualType: named,
                    payload: skir.DataValue.createRecord(
                      fields: [
                        for (final field in workspace.document.catalog.fields(
                          skir.TypeSelection.wrapComplete(named),
                        ))
                          skir.FieldValue(
                            name: field.template.key,
                            value: workspace.document.defaultValue(field.type),
                          ),
                      ],
                    ),
                  ),
            ),
          );
        }
        return base.prepareValue(request);
      },
      invokeCommand: base.invokeCommand,
      search: base.search,
      watchSearch: base.watchSearch,
      reload: base.reload,
      resolveResourceOperations: (request) async =>
          skir.ResolveResourceOperationsResult.wrapResolved(
            skir.ResolvedResourceOperations(
              primaryOperation: null,
              operations: [
                for (final operation
                    in workspace.document.catalog.snapshot.resourceOperations)
                  skir.ResolvedResourceOperation(
                    definition: operation,
                    availability: skir.OperationAvailability.enabled,
                  ),
              ],
            ),
          ),
      prepareAuthoringAction: _prepare,
    );
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

skir.TypeDefinitionId _type(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "graph-test", name: name),
  revision: 1,
);
skir.EndpointId _endpoint(String value) => skir.EndpointId(value: value);
