import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  test("offers existing and new nested counterpart locations", () {
    final fixture = _fixture();

    final result = portableLinkPlans(
      draft: fixture.draft,
      catalog: fixture.catalog,
      source: fixture.source,
    );

    final plans = (result as PortableLinkPlanReady).plans;
    expect(plans, hasLength(1));
    final existing = plans.single.targets.singleWhere(
      (target) => target.resource == fixture.existingTarget,
    );
    expect(existing.automaticCounterpart, isFalse);
    expect(existing.existing, hasLength(1));
    expect(existing.existing.single.id.location.path, fixture.nestedLinkPath);
    expect(existing.creatable, isEmpty);

    final creatable = plans.single.targets.singleWhere(
      (target) => target.resource == fixture.emptyTarget,
    );
    expect(creatable.automaticCounterpart, isFalse);
    expect(creatable.existing, isEmpty);
    expect(creatable.creatable, hasLength(1));
    expect(creatable.creatable.single.containing.path, _fieldPath("wrapper"));
    expect(creatable.creatable.single.selection, fixture.wrapperSelection);
  });

  test("stages a prepared nested counterpart and its reciprocal link", () {
    final fixture = _fixture();
    final plan = (portableLinkPlans(
      draft: fixture.draft,
      catalog: fixture.catalog,
      source: fixture.source,
    ) as PortableLinkPlanReady).plans.single;
    final target = plan.targets.singleWhere(
      (candidate) => candidate.resource == fixture.emptyTarget,
    );
    final slot = target.creatable.single;
    final prepared = skir.PreparedValue(
      content: skir.PreparedContent.wrapRecord(
        skir.AuthoringRecord(
          configuration: fixture.wrapperSelection,
          fields: [
            skir.FieldValue(name: "back", value: skir.DataValue.unfilled),
            skir.FieldValue(
              name: "label",
              value: skir.DataValue.wrapStringValue("captured default"),
            ),
          ],
        ),
      ),
      findings: const [],
    );

    fixture.draft.connect(
      plan.source,
      target.resource,
      counterpart: skir.CounterpartChoice.createNew(
        containing: slot.containing,
        prepared: prepared,
      ),
    );

    final wrapper = switch (fixture.draft.read(
      skir.ValueLocation(
        resource: fixture.emptyTarget,
        path: _fieldPath("wrapper"),
      ),
    )) {
      PortablePathValue(value: final value) => value,
      _ => throw TestFailure("Expected a staged wrapper"),
    };
    expect(wrapper.authoredActualType, fixture.wrapperUse);
    expect(wrapper.authoredField("label")?.authoredString, "captured default");
    expect(
      wrapper.authoredField("back")?.authoredLink?.target.resource,
      fixture.source.resource,
    );
    expect(fixture.draft.links.single.secondLocation, fixture.nestedLinkPath);
    final intent = fixture.draft.intents.single;
    expect(intent, isA<skir.EditIntent_connectRelationWrapper>());
    final connect = (intent as skir.EditIntent_connectRelationWrapper).value;
    expect(connect.counterpart, isA<skir.CounterpartChoice_newWrapper>());
    final decoded = skir.EditIntent.serializer.fromBytes(
      skir.EditIntent.serializer.toBytes(intent),
    );
    final decodedConnect =
        (decoded as skir.EditIntent_connectRelationWrapper).value;
    final decodedCounterpart =
        (decodedConnect.counterpart! as skir.CounterpartChoice_newWrapper)
            .value;
    expect(
      [
        decodedConnect.source.source,
        decodedConnect.source.id.location.resource,
        decodedConnect.source.target.resource,
        decodedConnect.target,
        decodedCounterpart.containing.resource,
      ].map((resource) => resource.value),
      everyElement(isNotEmpty),
    );
    expect(decodedConnect.source.target.resource, target.resource);
  });

  testWidgets("link input preserves cancellation and chooses an exact location", (
    tester,
  ) async {
    final fixture = _fixture();
    final editing = _LinkWorkspace(fixture.draft, fixture.source.resource);
    await tester.pumpWidget(_linkControl(fixture, editing: editing));

    await tester.tap(find.byTooltip("Choose linked resource"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Close"));
    await tester.pumpAndSettle();
    expect(editing.workspace.state.groups, isEmpty);

    await tester.tap(find.byTooltip("Choose linked resource"));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey(
          "link.target.${fixture.existingTarget.value}.existing.wrapper / back",
        ),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(editing.binding.save());
    await tester.pump();
    final intent =
        editing.transport.requests.single.edit.intents.single
            as skir.EditIntent_connectRelationWrapper;
    expect(
      intent.value.counterpart,
      isA<skir.CounterpartChoice_existingWrapper>(),
    );
    final counterpart =
        (intent.value.counterpart! as skir.CounterpartChoice_existingWrapper)
            .value;
    expect(intent.value.target, fixture.existingTarget);
    expect(counterpart.id.location.resource, fixture.existingTarget);
    expect(counterpart.id.location.path, fixture.nestedLinkPath);
    expect(
      editing.workspace.document.links.single.secondLocation,
      fixture.nestedLinkPath,
    );
  });

  testWidgets("link input prepares and chooses a new nested counterpart", (
    tester,
  ) async {
    final fixture = _fixture();
    final editing = _LinkWorkspace(fixture.draft, fixture.source.resource);
    final prepared = skir.PreparedValue(
      content: skir.PreparedContent.wrapRecord(
        skir.AuthoringRecord(
          configuration: fixture.wrapperSelection,
          fields: [
            skir.FieldValue(name: "back", value: skir.DataValue.unfilled),
            skir.FieldValue(
              name: "label",
              value: skir.DataValue.wrapStringValue("prepared"),
            ),
          ],
        ),
      ),
      findings: const [],
    );
    skir.ValuePreparationRequest? request;
    await tester.pumpWidget(
      _linkControl(
        fixture,
        editing: editing,
        prepareValue: (value) async {
          request = value;
          return prepared;
        },
      ),
    );

    await tester.tap(find.byTooltip("Choose linked resource"));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey("link.target.${fixture.emptyTarget.value}.new.wrapper"),
      ),
    );
    await tester.pumpAndSettle();

    expect(request?.recordSelection, fixture.wrapperSelection);
    unawaited(editing.binding.save());
    await tester.pump();
    final intent =
        editing.transport.requests.single.edit.intents.single
            as skir.EditIntent_connectRelationWrapper;
    final counterpart = intent.value.counterpart;
    expect(counterpart, isA<skir.CounterpartChoice_newWrapper>());
    final created = (counterpart! as skir.CounterpartChoice_newWrapper).value;
    expect(created.prepared, prepared);
    expect(intent.value.target, fixture.emptyTarget);
    expect(
      created.containing,
      skir.ValueLocation(
        resource: fixture.emptyTarget,
        path: _fieldPath("wrapper"),
      ),
    );
    expect(
      editing.workspace.document.links.single.secondLocation,
      fixture.nestedLinkPath,
    );
  });
}

final class _LinkWorkspace {
  _LinkWorkspace(AuthoringEdit operation, skir.ResourceId resource) {
    final document = operation.toDocument();
    transport = ScriptedAuthoringTransport(AsyncData(document));
    workspace = AuthoringWorkspace(transport: transport, initial: document);
    binding = workspace.attach(
      resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
  }
  late final ScriptedAuthoringTransport transport;
  late final AuthoringWorkspace workspace;
  late final AuthoringBinding binding;
}

Widget _linkControl(
  ({
    AuthoringEdit draft,
    CheckedEditorCatalog catalog,
    skir.ValueLocation source,
    skir.ResourceId existingTarget,
    skir.ResourceId emptyTarget,
    skir.ValuePath nestedLinkPath,
    skir.NamedTypeUse wrapperUse,
    skir.TypeSelection wrapperSelection,
  })
  fixture, {
  required _LinkWorkspace editing,
  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue,
}) {
  final root = skir.ExpressionBindingId(value: "configured_value");
  final record = fixture.draft.resource(fixture.source.resource)!;
  final budget = skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100);
  final host = AuthoredPresentationHost(
    resource: fixture.source.resource,
    source: editing.workspace.document,
    material: skir.PresentationMaterial.defaultInstance,
    role: skir.PresentationRole.editor,
    budget: budget,
    capabilities: const PortablePresentationCapabilities(),
    prepareValue: prepareValue,
    edit: editing.binding,
  );
  addTearDown(host.dispose);
  return testApp(
    child: Scaffold(
      body: PortablePresentationNodeRenderer(
        node: skir.PresentationNode(
          nodeId: "link",
          properties: skir.PresentationProperties.defaultInstance,
          element: skir.PresentationElement.wrapLinkInput(
            skir.LinkControl(
              control: skir.BoundControl(
                binding: skir.BindingRef(
                  bindingId: root,
                  path: fixture.source.path,
                ),
                label: null,
                description: null,
                prefix: null,
                semanticLabel: null,
              ),
              allowReorder: false,
              candidatePolicy: null,
              rejectionDisplay: skir.LinkRejectionDisplay.disabled,
              sourceId: null,
            ),
          ),
          header: null,
        ),
        scope: PortablePresentationScope(
          bindings: {
            root: PortableExpressionBinding(
              value: skir.DataValue.createRecord(fields: record.fields),
              location: skir.ValueLocation(
                resource: fixture.source.resource,
                path: skir.ValuePath(segments: const []),
              ),
            ),
          },
          budget: budget,
          catalog: fixture.catalog,
          host: host,
        ),
      ),
    ),
  );
}

({
  AuthoringEdit draft,
  CheckedEditorCatalog catalog,
  skir.ValueLocation source,
  skir.ResourceId existingTarget,
  skir.ResourceId emptyTarget,
  skir.ValuePath nestedLinkPath,
  skir.NamedTypeUse wrapperUse,
  skir.TypeSelection wrapperSelection,
})
_fixture() {
  final generation = skir.CatalogGeneration(value: "catalog:links");
  final node = _definition("Node");
  final wrapper = _definition("Wrapper");
  final sourceLink = _definition("SourceLink");
  final targetLink = _definition("TargetLink");
  final sourceEndpoint = skir.EndpointId(value: "test.source");
  final targetEndpoint = skir.EndpointId(value: "test.target");
  final nodeTemplate = skir.TypeTemplate.createNamed(
    definition: node,
    arguments: const [],
  );
  final nodeUse = skir.NamedTypeUse(definition: node, arguments: const []);
  final wrapperUse = skir.NamedTypeUse(
    definition: wrapper,
    arguments: const [],
  );
  final wrapperSelection = skir.TypeSelection.wrapComplete(wrapperUse);
  final sourceField = skir.FieldOwner(definition: node, name: "source");
  final wrapperField = skir.FieldOwner(definition: node, name: "wrapper");
  final backField = skir.FieldOwner(definition: wrapper, name: "back");
  final labelField = skir.FieldOwner(definition: wrapper, name: "label");
  skir.FieldDeclaration declaration(
    skir.FieldOwner owner,
    skir.TypeTemplate type,
  ) => skir.FieldDeclaration(
    owner: owner,
    type: type,
    overrides: const [],
    hasConstructorDefault: false,
  );
  skir.PublishedType published(
    skir.TypeDefinition definition,
    List<skir.EffectiveFieldTemplate> fields,
  ) => skir.PublishedType(
    display: null,
    definition: definition,
    status: skir.DeclarationStatus.ready,
    effectiveFields: fields,
    ancestorTemplates: const [],
  );
  final sourceLinkTemplate = skir.TypeTemplate.createNamed(
    definition: sourceLink,
    arguments: const [],
  );
  final wrapperTemplate = skir.TypeTemplate.createNamed(
    definition: wrapper,
    arguments: const [],
  );
  final targetLinkTemplate = skir.TypeTemplate.createNamed(
    definition: targetLink,
    arguments: const [],
  );
  final textTemplate = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final snapshot = skir.EditorCatalogWireSnapshot(
    generation: generation,
    types: [
      published(
        skir.TypeDefinition(
          id: node,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              declaration(sourceField, sourceLinkTemplate),
              declaration(wrapperField, wrapperTemplate),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        [
          skir.EffectiveFieldTemplate(
            key: "source",
            owner: sourceField,
            type: sourceLinkTemplate,
            rules: const [],
          ),
          skir.EffectiveFieldTemplate(
            key: "wrapper",
            owner: wrapperField,
            type: wrapperTemplate,
            rules: const [],
          ),
        ],
      ),
      published(
        skir.TypeDefinition(
          id: wrapper,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              declaration(backField, targetLinkTemplate),
              declaration(labelField, textTemplate),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        [
          skir.EffectiveFieldTemplate(
            key: "back",
            owner: backField,
            type: targetLinkTemplate,
            rules: const [],
          ),
          skir.EffectiveFieldTemplate(
            key: "label",
            owner: labelField,
            type: textTemplate,
            rules: const [],
          ),
        ],
      ),
      for (final link in [
        (sourceLink, sourceEndpoint),
        (targetLink, targetEndpoint),
      ])
        published(
          skir.TypeDefinition(
            id: link.$1,
            parameters: const [],
            representation: skir.RepresentationTemplate.createLink(
              endpoint: link.$2,
              target: nodeTemplate,
            ),
            parents: const [],
          ),
          const [],
        ),
    ],
    relations: [
      skir.RelationContract(
        id: skir.RelationId(value: "test.links"),
        first: skir.EndpointDefinition(
          id: sourceEndpoint,
          slot: skir.EndpointSlot.first,
          resource: skir.NamedTypeTemplate(
            definition: node,
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        second: skir.EndpointDefinition(
          id: targetEndpoint,
          slot: skir.EndpointSlot.second,
          resource: skir.NamedTypeTemplate(
            definition: node,
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: const [],
      ),
    ],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: [
      skir.EndpointBindingTemplate(
        endpoint: sourceEndpoint,
        containingResource: skir.NamedTypeTemplate(
          definition: node,
          arguments: const [],
        ),
        valueOwner: node,
        relativePath: skir.RelativeFieldPattern(
          segments: [skir.FieldPatternSegment.createField(name: "source")],
        ),
        target: nodeTemplate,
        containsCollection: false,
      ),
      skir.EndpointBindingTemplate(
        endpoint: targetEndpoint,
        containingResource: skir.NamedTypeTemplate(
          definition: node,
          arguments: const [],
        ),
        valueOwner: wrapper,
        relativePath: skir.RelativeFieldPattern(
          segments: [
            skir.FieldPatternSegment.createField(name: "wrapper"),
            skir.FieldPatternSegment.createField(name: "back"),
          ],
        ),
        target: nodeTemplate,
        containsCollection: false,
      ),
    ],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final source = skir.ResourceId(value: "resource:source");
  final existingTarget = skir.ResourceId(value: "resource:existing");
  final emptyTarget = skir.ResourceId(value: "resource:empty");
  skir.AuthoringRecord record(skir.DataValue wrapperValue) =>
      skir.AuthoringRecord(
        configuration: skir.TypeSelection.wrapComplete(nodeUse),
        fields: [
          skir.FieldValue(name: "source", value: skir.DataValue.unfilled),
          skir.FieldValue(name: "wrapper", value: wrapperValue),
        ],
      );
  final authored = skir.AuthoringState(
    generation: generation,
    resources: [
      skir.AuthoringResource(
        id: source,
        definition: skir.ResourceDefinitionId(value: "test.node"),
        content: record(skir.DataValue.unfilled),
      ),
      skir.AuthoringResource(
        id: existingTarget,
        definition: skir.ResourceDefinitionId(value: "test.node"),
        content: record(
          skir.DataValue.createNamed(
            actualType: wrapperUse,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(name: "back", value: skir.DataValue.unfilled),
                skir.FieldValue(
                  name: "label",
                  value: skir.DataValue.wrapStringValue("existing"),
                ),
              ],
            ),
          ),
        ),
      ),
      skir.AuthoringResource(
        id: emptyTarget,
        definition: skir.ResourceDefinitionId(value: "test.node"),
        content: record(skir.DataValue.unfilled),
      ),
    ],
    links: const [],
    findings: const [],
  );
  final checked = CheckedEditorCatalog(snapshot);
  return (
    draft: AuthoringEdit.fromState(authored, catalog: checked),
    catalog: checked,
    source: skir.ValueLocation(resource: source, path: _fieldPath("source")),
    existingTarget: existingTarget,
    emptyTarget: emptyTarget,
    nestedLinkPath: skir.ValuePath(
      segments: [
        skir.PathSegment.createField(name: "wrapper"),
        skir.PathSegment.createField(name: "back"),
      ],
    ),
    wrapperUse: wrapperUse,
    wrapperSelection: wrapperSelection,
  );
}

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

skir.ValuePath _fieldPath(String name) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]);
