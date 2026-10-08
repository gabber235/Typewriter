import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  test("offers existing and new nested counterpart locations", () {
    final fixture = _fixture();

    final result = portableLinkPlans(
      draft: AuthoredDraftAuthoringDocument(fixture.draft),
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
      draft: AuthoredDraftAuthoringDocument(fixture.draft),
      catalog: fixture.catalog,
      source: fixture.source,
    ) as PortableLinkPlanReady).plans.single;
    final target = plan.targets.singleWhere(
      (candidate) => candidate.resource == fixture.emptyTarget,
    );
    final slot = target.creatable.single;
    final prepared = catalog.PreparedCreation(
      record: types.AuthoringRecord(
        configuration: fixture.wrapperSelection,
        fields: [
          types.FieldValue(name: "back", value: types.DataValue.unfilled),
          types.FieldValue(
            name: "label",
            value: types.DataValue.wrapStringValue("captured default"),
          ),
        ],
      ),
      findings: const [],
    );

    fixture.draft.connect(
      plan.source,
      target.resource,
      counterpart: authoring.CounterpartChoice.createNew(
        containing: slot.containing,
        prepared: prepared,
      ),
    );

    final wrapper = switch (fixture.draft.read(
      types.ValueLocation(
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
    expect(intent, isA<authoring.EditIntent_connectRelationWrapper>());
    final connect =
        (intent as authoring.EditIntent_connectRelationWrapper).value;
    expect(connect.counterpart, isA<authoring.CounterpartChoice_newWrapper>());
    final decoded = authoring.EditIntent.serializer.fromBytes(
      authoring.EditIntent.serializer.toBytes(intent),
    );
    final decodedConnect =
        (decoded as authoring.EditIntent_connectRelationWrapper).value;
    final decodedCounterpart =
        (decodedConnect.counterpart! as authoring.CounterpartChoice_newWrapper)
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
    await tester.pumpWidget(_linkControl(fixture));

    await tester.tap(find.byTooltip("Choose linked resource"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Close"));
    await tester.pumpAndSettle();
    expect(fixture.draft.intents, isEmpty);

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

    final intent =
        fixture.draft.intents.single
            as authoring.EditIntent_connectRelationWrapper;
    expect(
      intent.value.counterpart,
      isA<authoring.CounterpartChoice_existingWrapper>(),
    );
    final counterpart =
        (intent.value.counterpart! as authoring.CounterpartChoice_existingWrapper)
            .value;
    expect(intent.value.target, fixture.existingTarget);
    expect(counterpart.id.location.resource, fixture.existingTarget);
    expect(counterpart.id.location.path, fixture.nestedLinkPath);
    expect(fixture.draft.links.single.secondLocation, fixture.nestedLinkPath);
  });

  testWidgets("link input prepares and chooses a new nested counterpart", (
    tester,
  ) async {
    final fixture = _fixture();
    final prepared = catalog.PreparedCreation(
      record: types.AuthoringRecord(
        configuration: fixture.wrapperSelection,
        fields: [
          types.FieldValue(name: "back", value: types.DataValue.unfilled),
          types.FieldValue(
            name: "label",
            value: types.DataValue.wrapStringValue("prepared"),
          ),
        ],
      ),
      findings: const [],
    );
    catalog.InitializationRequest? request;
    await tester.pumpWidget(
      _linkControl(
        fixture,
        prepareCreation: (value) async {
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

    expect(request?.type, fixture.wrapperSelection);
    final intent =
        fixture.draft.intents.single
            as authoring.EditIntent_connectRelationWrapper;
    final counterpart = intent.value.counterpart;
    expect(counterpart, isA<authoring.CounterpartChoice_newWrapper>());
    final created =
        (counterpart! as authoring.CounterpartChoice_newWrapper).value;
    expect(created.prepared, prepared);
    expect(intent.value.target, fixture.emptyTarget);
    expect(
      created.containing,
      types.ValueLocation(
        resource: fixture.emptyTarget,
        path: _fieldPath("wrapper"),
      ),
    );
    expect(fixture.draft.links.single.secondLocation, fixture.nestedLinkPath);
  });
}

Widget _linkControl(
  ({
    AuthoredDraft draft,
    CheckedEditorCatalog catalog,
    types.ValueLocation source,
    types.ResourceId existingTarget,
    types.ResourceId emptyTarget,
    types.ValuePath nestedLinkPath,
    types.NamedTypeUse wrapperUse,
    types.TypeSelection wrapperSelection,
  })
  fixture, {
  Future<catalog.PreparedCreation> Function(catalog.InitializationRequest)?
  prepareCreation,
}) {
  final root = types.ExpressionBindingId(value: "configured_value");
  final record = fixture.draft.resource(fixture.source.resource)!;
  return testApp(
    child: Scaffold(
      body: PortablePresentationNodeRenderer(
        node: presentation.PresentationNode(
          nodeId: "link",
          properties: presentation.PresentationProperties.defaultInstance,
          element: presentation.PresentationElement.wrapLinkInput(
            presentation.LinkControl(
              control: presentation.BoundControl(
                binding: binding.BindingRef(
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
              rejectionDisplay: presentation.LinkRejectionDisplay.disabled,
              sourceId: null,
            ),
          ),
          header: null,
        ),
        scope: PortablePresentationScope(
          bindings: {
            root: PortableExpressionBinding(
              value: types.DataValue.createRecord(fields: record.fields),
              location: types.ValueLocation(
                resource: fixture.source.resource,
                path: types.ValuePath(segments: const []),
              ),
            ),
          },
          budget: expression.EvaluationBudget(
            maxSteps: 100,
            maxCollectionItems: 100,
          ),
          setBinding: (_, _) {},
          authoring: AuthoredDraftAuthoringDocument(fixture.draft),
          catalog: fixture.catalog,
          prepareCreation: prepareCreation,
        ),
      ),
    ),
  );
}

({
  AuthoredDraft draft,
  CheckedEditorCatalog catalog,
  types.ValueLocation source,
  types.ResourceId existingTarget,
  types.ResourceId emptyTarget,
  types.ValuePath nestedLinkPath,
  types.NamedTypeUse wrapperUse,
  types.TypeSelection wrapperSelection,
})
_fixture() {
  final generation = types.CatalogGeneration(value: "catalog:links");
  final node = _definition("Node");
  final wrapper = _definition("Wrapper");
  final sourceLink = _definition("SourceLink");
  final targetLink = _definition("TargetLink");
  final sourceEndpoint = types.EndpointId(value: "test.source");
  final targetEndpoint = types.EndpointId(value: "test.target");
  final nodeTemplate = types.TypeTemplate.createNamed(
    definition: node,
    arguments: const [],
  );
  final nodeUse = types.NamedTypeUse(definition: node, arguments: const []);
  final wrapperUse = types.NamedTypeUse(
    definition: wrapper,
    arguments: const [],
  );
  final wrapperSelection = types.TypeSelection.wrapComplete(wrapperUse);
  final sourceField = types.FieldOwner(definition: node, name: "source");
  final wrapperField = types.FieldOwner(definition: node, name: "wrapper");
  final backField = types.FieldOwner(definition: wrapper, name: "back");
  final labelField = types.FieldOwner(definition: wrapper, name: "label");
  types.FieldDeclaration declaration(
    types.FieldOwner owner,
    types.TypeTemplate type,
  ) => types.FieldDeclaration(
    owner: owner,
    type: type,
    overrides: const [],
    hasConstructorDefault: false,
  );
  catalog.PublishedType published(
    types.TypeDefinition definition,
    List<catalog.EffectiveFieldTemplate> fields,
  ) => catalog.PublishedType(
    display: null,
    definition: definition,
    status: catalog.DeclarationStatus.ready,
    effectiveFields: fields,
    ancestorTemplates: const [],
  );
  final sourceLinkTemplate = types.TypeTemplate.createNamed(
    definition: sourceLink,
    arguments: const [],
  );
  final wrapperTemplate = types.TypeTemplate.createNamed(
    definition: wrapper,
    arguments: const [],
  );
  final targetLinkTemplate = types.TypeTemplate.createNamed(
    definition: targetLink,
    arguments: const [],
  );
  final textTemplate = types.TypeTemplate.wrapScalar(types.ScalarKind.text);
  final snapshot = catalog.EditorCatalogWireSnapshot(
    generation: generation,
    types: [
      published(
        types.TypeDefinition(
          id: node,
          parameters: const [],
          representation: types.RepresentationTemplate.createRecord(
            fields: [
              declaration(sourceField, sourceLinkTemplate),
              declaration(wrapperField, wrapperTemplate),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        [
          catalog.EffectiveFieldTemplate(
            key: "source",
            owner: sourceField,
            type: sourceLinkTemplate,
            rules: const [],
          ),
          catalog.EffectiveFieldTemplate(
            key: "wrapper",
            owner: wrapperField,
            type: wrapperTemplate,
            rules: const [],
          ),
        ],
      ),
      published(
        types.TypeDefinition(
          id: wrapper,
          parameters: const [],
          representation: types.RepresentationTemplate.createRecord(
            fields: [
              declaration(backField, targetLinkTemplate),
              declaration(labelField, textTemplate),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        [
          catalog.EffectiveFieldTemplate(
            key: "back",
            owner: backField,
            type: targetLinkTemplate,
            rules: const [],
          ),
          catalog.EffectiveFieldTemplate(
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
          types.TypeDefinition(
            id: link.$1,
            parameters: const [],
            representation: types.RepresentationTemplate.createLink(
              endpoint: link.$2,
              target: nodeTemplate,
            ),
            parents: const [],
          ),
          const [],
        ),
    ],
    relations: [
      catalog.RelationContract(
        id: types.RelationId(value: "test.links"),
        first: catalog.EndpointDefinition(
          id: sourceEndpoint,
          slot: catalog.EndpointSlot.first,
          resource: types.NamedTypeTemplate(
            definition: node,
            arguments: const [],
          ),
          cardinality: catalog.EndpointCardinality.one,
          onDelete: catalog.RelationDeletePolicy.clear,
        ),
        second: catalog.EndpointDefinition(
          id: targetEndpoint,
          slot: catalog.EndpointSlot.second,
          resource: types.NamedTypeTemplate(
            definition: node,
            arguments: const [],
          ),
          cardinality: catalog.EndpointCardinality.many,
          onDelete: catalog.RelationDeletePolicy.clear,
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
      catalog.EndpointBindingTemplate(
        endpoint: sourceEndpoint,
        containingResource: types.NamedTypeTemplate(
          definition: node,
          arguments: const [],
        ),
        valueOwner: node,
        relativePath: types.RelativeFieldPattern(
          segments: [types.FieldPatternSegment.createField(name: "source")],
        ),
        target: nodeTemplate,
        containsCollection: false,
      ),
      catalog.EndpointBindingTemplate(
        endpoint: targetEndpoint,
        containingResource: types.NamedTypeTemplate(
          definition: node,
          arguments: const [],
        ),
        valueOwner: wrapper,
        relativePath: types.RelativeFieldPattern(
          segments: [
            types.FieldPatternSegment.createField(name: "wrapper"),
            types.FieldPatternSegment.createField(name: "back"),
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
  final source = types.ResourceId(value: "resource:source");
  final existingTarget = types.ResourceId(value: "resource:existing");
  final emptyTarget = types.ResourceId(value: "resource:empty");
  types.AuthoringRecord record(types.DataValue wrapperValue) =>
      types.AuthoringRecord(
        configuration: types.TypeSelection.wrapComplete(nodeUse),
        fields: [
          types.FieldValue(name: "source", value: types.DataValue.unfilled),
          types.FieldValue(name: "wrapper", value: wrapperValue),
        ],
      );
  final authored = authoring.AuthoringState(
    generation: generation,
    resources: [
      authoring.AuthoringResource(
        id: source,
        definition: catalog.ResourceDefinitionId(value: "test.node"),
        content: record(types.DataValue.unfilled),
      ),
      authoring.AuthoringResource(
        id: existingTarget,
        definition: catalog.ResourceDefinitionId(value: "test.node"),
        content: record(
          types.DataValue.createNamed(
            actualType: wrapperUse,
            payload: types.DataValue.createRecord(
              fields: [
                types.FieldValue(name: "back", value: types.DataValue.unfilled),
                types.FieldValue(
                  name: "label",
                  value: types.DataValue.wrapStringValue("existing"),
                ),
              ],
            ),
          ),
        ),
      ),
      authoring.AuthoringResource(
        id: emptyTarget,
        definition: catalog.ResourceDefinitionId(value: "test.node"),
        content: record(types.DataValue.unfilled),
      ),
    ],
    links: const [],
    findings: const [],
  );
  final checked = CheckedEditorCatalog(snapshot);
  return (
    draft: AuthoredDraft.fromState(authored, catalog: checked),
    catalog: checked,
    source: types.ValueLocation(resource: source, path: _fieldPath("source")),
    existingTarget: existingTarget,
    emptyTarget: emptyTarget,
    nestedLinkPath: types.ValuePath(
      segments: [
        types.PathSegment.createField(name: "wrapper"),
        types.PathSegment.createField(name: "back"),
      ],
    ),
    wrapperUse: wrapperUse,
    wrapperSelection: wrapperSelection,
  );
}

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

types.ValuePath _fieldPath(String name) =>
    types.ValuePath(segments: [types.PathSegment.createField(name: name)]);
