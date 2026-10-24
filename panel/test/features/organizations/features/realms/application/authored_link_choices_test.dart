import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  test("concrete endpoint binding replaces the ancestor at the same path", () {
    final fixture = _fixture();
    final original = fixture.catalog.snapshot;
    final base = _definition("Node");
    final child = _definition("NarrowNode");
    final node = original.types.singleWhere(
      (type) => type.definition.id == base,
    );
    final ancestor = skir.NamedTypeTemplate(
      definition: base,
      arguments: const [],
    );
    final binding = original.endpointBindings.first;
    final snapshot = original.toMutable()
      ..types = [
        ...original.types,
        skir.PublishedType(
          searchKey: null,
          placementField: null,
          display: defaultTypeDisplay(""),
          definition: skir.TypeDefinition(
            id: child,
            parameters: const [],
            representation: node.definition.representation,
            parents: [ancestor],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: node.effectiveFields,
          ancestorTemplates: [ancestor],
        ),
      ]
      ..endpointBindings = [
        ...original.endpointBindings,
        skir.EndpointBindingTemplate(
          endpoint: binding.endpoint,
          containingResource: skir.NamedTypeTemplate(
            definition: child,
            arguments: const [],
          ),
          valueOwner: child,
          relativePath: binding.relativePath,
          target: skir.TypeTemplate.createNamed(
            definition: _definition("Wrapper"),
            arguments: const [],
          ),
          containsCollection: false,
        ),
      ];
    final catalog = CheckedEditorCatalog(snapshot.toFrozen());
    final selected = catalog
        .endpointBindings(catalog.beginSelection(child))
        .where((candidate) => candidate.template.endpoint == binding.endpoint)
        .toList();
    expect(selected, hasLength(1));
    expect(selected.single.template.containingResource.definition, child);
    expect(
      catalog.selectionMatches(
        catalog.beginSelection(base),
        selected.single.target,
      ),
      isFalse,
    );
  });

  test("a selected abstract form supplies its own reference endpoint", () {
    final fixture = _fixture(abstractWrapper: true);
    final source = skir.ValueLocation(
      resource: fixture.existingTarget,
      path: fixture.nestedLinkPath,
    );
    final record = fixture.draft.resource(source.resource)!;
    expect(
      fixture.catalog.valueTypeAt(
        record.configuration,
        source.path,
        value: skir.DataValue.createRecord(fields: record.fields),
      ),
      isNotNull,
    );
    final result = fixture.draft.linkPlans(
      catalog: fixture.catalog,
      source: source,
    );
    expect(result, isA<PortableLinkPlanReady>());
    final plan = (result as PortableLinkPlanReady).plans.single;
    expect(plan.source.id.endpoint.value, "test.target");
    expect(
      plan.targets.any((target) => target.resource == fixture.source.resource),
      isTrue,
    );
  });

  test("an unselected abstract counterpart requires a form choice", () {
    final fixture = _fixture(abstractWrapper: true);
    final plan = (fixture.draft.linkPlans(
      catalog: fixture.catalog,
      source: fixture.source,
    ) as PortableLinkPlanReady).plans.single;
    final target = plan.targets.singleWhere(
      (target) => target.resource == fixture.emptyTarget,
    );
    expect(target.automaticCounterpart, isFalse);
    expect(target.existing, isEmpty);
    expect(target.disabledReason, contains("Select a form at wrapper"));
    expect(
      () => fixture.draft.resolveReference(
        catalog: fixture.catalog,
        plan: plan,
        target: target,
      ),
      throwsStateError,
    );
    expect(fixture.draft.links, isEmpty);
  });

  test("a selected abstract inverse retains its exact counterpart path", () {
    final fixture = _fixture(abstractWrapper: true);
    final plan = (fixture.draft.linkPlans(
      catalog: fixture.catalog,
      source: fixture.source,
    ) as PortableLinkPlanReady).plans.single;
    final target = plan.targets.singleWhere(
      (target) => target.resource == fixture.existingTarget,
    );
    expect(target.automaticCounterpart, isFalse);
    expect(target.existing.single.id.location.path, fixture.nestedLinkPath);
    final reference = fixture.draft.resolveReference(
      catalog: fixture.catalog,
      plan: plan,
      target: target,
      counterpart: skir.CounterpartChoice.wrapExisting(target.existing.single),
    );
    fixture.draft.applyResolvedReference(reference);
    expect(fixture.draft.links.single.secondLocation, fixture.nestedLinkPath);
    final locations = fixture.catalog
        .referenceLocations(fixture.draft.resource(fixture.existingTarget)!)
        .toList();
    expect(
      locations
          .where((location) => location.endpoint.value == "test.target")
          .single
          .path,
      fixture.nestedLinkPath,
    );
  });

  test(
    "an empty inverse collection in a selected form reserves an exact item",
    () {
      final fixture = _fixture(abstractWrapper: true, nestedCollection: true);
      final plan = (fixture.draft.linkPlans(
        catalog: fixture.catalog,
        source: fixture.source,
      ) as PortableLinkPlanReady).plans.single;
      final target = plan.targets.singleWhere(
        (target) => target.resource == fixture.existingTarget,
      );
      expect(target.automaticCounterpart, isFalse);
      expect(target.existing, isEmpty);
      expect(target.collections.single.path, fixture.nestedLinkPath);
      final reference = fixture.draft.resolveReference(
        catalog: fixture.catalog,
        plan: plan,
        target: target,
        collection: target.collections.single,
      );
      fixture.draft.applyResolvedReference(reference);
      final opposite =
          (reference.connection.counterpart!
                  as skir.CounterpartChoice_existingWrapper)
              .value;
      expect(
        fixture.draft.links.single.secondLocation,
        opposite.id.location.path,
      );
      expect(
        opposite.id.location.path.segments.length,
        fixture.nestedLinkPath.segments.length + 1,
      );
    },
  );

  testWidgets("normal link collections use the selected concrete source form", (
    tester,
  ) async {
    final fixture = _fixture(abstractWrapper: true, nestedCollection: true);
    final source = skir.ValueLocation(
      resource: fixture.existingTarget,
      path: fixture.nestedLinkPath,
    );
    final editing = _LinkWorkspace(fixture.draft, source.resource);
    await tester.pumpWidget(
      _linkControl(fixture, editing: editing, source: source),
    );
    await tester.tap(find.byTooltip("Add link"));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey("link.target.${fixture.source.resource.value}.automatic"),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(editing.binding.save());
    await tester.pump();
    final connection = editing.transport.requests.single.edit.intents
        .whereType<skir.EditIntent_connectRelationWrapper>()
        .single
        .value;
    expect(connection.source.id.endpoint.value, "test.target");
    expect(connection.source.id.location.path.segments, hasLength(3));
    expect(
      editing.workspace.document.links.single.first,
      fixture.source.resource,
    );
  });

  testWidgets("normal link editing appends to an inverse in a selected form", (
    tester,
  ) async {
    final fixture = _fixture(abstractWrapper: true, nestedCollection: true);
    final editing = _LinkWorkspace(fixture.draft, fixture.source.resource);
    await tester.pumpWidget(_linkControl(fixture, editing: editing));
    await tester.tap(find.byTooltip("Choose linked resource"));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey(
          "link.target.${fixture.existingTarget.value}.append.wrapper / back",
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(editing.binding.save());
    await tester.pump();
    final intents = editing.transport.requests.single.edit.intents;
    expect(intents.whereType<skir.EditIntent_insertWrapper>(), hasLength(1));
    final connection = intents
        .whereType<skir.EditIntent_connectRelationWrapper>()
        .single
        .value;
    final inverse =
        (connection.counterpart! as skir.CounterpartChoice_existingWrapper)
            .value;
    expect(
      editing.workspace.document.links.single.secondLocation,
      inverse.id.location.path,
    );
  });

  test("opposite applied target rejects a forward compatible resource", () {
    final fixture = _fixture(incompatibleInverse: true);
    final result = fixture.draft.linkPlans(
      catalog: fixture.catalog,
      source: fixture.source,
    );
    final plans = (result as PortableLinkPlanReady).plans;
    expect(plans.single.targets, isNotEmpty);
    for (final target in plans.single.targets) {
      expect(target.automaticCounterpart, isFalse);
      expect(target.existing, isEmpty);
      expect(target.creatable, isEmpty);
      expect(target.disabledReason, contains("does not accept"));
    }
  });

  test("an unfinished direct inverse collection receives a reserved item", () {
    final fixture = _fixture(directCollection: true);
    fixture.draft.set(
      skir.ValueLocation(
        resource: fixture.existingTarget,
        path: _fieldPath("wrapper"),
      ),
      skir.DataValue.unfilled,
    );
    final plan = (fixture.draft.linkPlans(
      catalog: fixture.catalog,
      source: fixture.source,
    ) as PortableLinkPlanReady).plans.single;
    final target = plan.targets.singleWhere(
      (candidate) => candidate.resource == fixture.existingTarget,
    );
    final reference = fixture.draft.resolveReference(
      catalog: fixture.catalog,
      plan: plan,
      target: target,
    );
    fixture.draft.applyResolvedReference(reference);
    expect(fixture.draft.links.single.secondLocation, isNotNull);
    expect(reference.materializations, hasLength(1));
  });

  test("resolved collection inverse reserves one exact occurrence", () {
    final fixture = _fixture(directCollection: true);
    final plan = (fixture.draft.linkPlans(
      catalog: fixture.catalog,
      source: fixture.source,
    ) as PortableLinkPlanReady).plans.single;
    final target = plan.targets.singleWhere(
      (target) => target.resource == fixture.emptyTarget,
    );
    final reference = fixture.draft.resolveReference(
      catalog: fixture.catalog,
      plan: plan,
      target: target,
    );
    final insertion =
        (reference.materializations.single as ReferenceValueInsertion).intent;
    final opposite =
        (reference.connection.counterpart!
                as skir.CounterpartChoice_existingWrapper)
            .value;
    expect(
      opposite.id.location.path.segments.last,
      skir.PathSegment.createItem(id: insertion.item.id),
    );
    fixture.draft.applyResolvedReference(reference);
    final items = fixture.draft
        .resource(fixture.emptyTarget)!
        .authoredField("wrapper")!
        .authoredItems!
        .toList();
    expect(items.single.id, insertion.item.id);
    expect(
      items.single.value.authoredLink!.target.resource,
      fixture.source.resource,
    );
    final staged = fixture.draft.intents
        .whereType<skir.EditIntent_connectRelationWrapper>()
        .single
        .value;
    expect(staged.counterpart, reference.connection.counterpart);
    final repeatedPlan = (fixture.draft.linkPlans(
      catalog: fixture.catalog,
      source: fixture.source,
    ) as PortableLinkPlanReady).plans.single;
    final repeatedTarget = repeatedPlan.targets.singleWhere(
      (choice) => choice.resource == fixture.emptyTarget,
    );
    final repeated = fixture.draft.resolveReference(
      catalog: fixture.catalog,
      plan: repeatedPlan,
      target: repeatedTarget,
    );
    expect(repeated.materializations, isEmpty);
    expect(
      (repeated.connection.counterpart!
              as skir.CounterpartChoice_existingWrapper)
          .value
          .id,
      opposite.id,
    );
  });

  test("automatic counterpart resolution leaves nested identity to explicit choice", () {
    final fixture = _fixture();
    final result = fixture.catalog.resolveScalarCounterpart(
      configuration: fixture.draft.resource(fixture.emptyTarget)!.configuration,
      resource: fixture.emptyTarget,
      endpoint: skir.EndpointId(value: "test.target"),
    );
    expect(result, isA<ResourceCounterpartChoiceRequired>());
    expect(fixture.draft.intents, isEmpty);
  });

  test("offers existing and new nested counterpart locations", () {
    final fixture = _fixture();

    final result = fixture.draft.linkPlans(
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
    final plan = (fixture.draft.linkPlans(
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

  testWidgets("link input hands its location to the link field builder", (
    tester,
  ) async {
    final fixture = _fixture();
    final editing = _LinkWorkspace(fixture.draft, fixture.source.resource);
    final wrapped = <skir.ValueLocation>[];
    await tester.pumpWidget(
      _linkControl(
        fixture,
        editing: editing,
        linkFieldBuilder: (context, location, control) {
          wrapped.add(location);
          return KeyedSubtree(
            key: const ValueKey("link.field"),
            child: control,
          );
        },
      ),
    );
    expect(wrapped, everyElement(fixture.source));
    expect(wrapped, isNotEmpty);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey("link.field")),
        matching: find.byTooltip("Choose linked resource"),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    "read only link input is never offered to the link field builder",
    (tester) async {
      final fixture = _fixture();
      final editing = _LinkWorkspace(fixture.draft, fixture.source.resource);
      final wrapped = <skir.ValueLocation>[];
      await tester.pumpWidget(
        _linkControl(
          fixture,
          editing: editing,
          readOnly: true,
          linkFieldBuilder: (context, location, control) {
            wrapped.add(location);
            return control;
          },
        ),
      );
      expect(wrapped, isEmpty);
      expect(find.byTooltip("Choose linked resource"), findsOneWidget);
    },
  );

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
    final intent = editing.transport.requests.single.edit.intents
        .whereType<skir.EditIntent_connectRelationWrapper>()
        .single;
    final counterpart = intent.value.counterpart;
    expect(counterpart, isA<skir.CounterpartChoice_existingWrapper>());
    final created =
        (counterpart! as skir.CounterpartChoice_existingWrapper).value;
    expect(intent.value.target, fixture.emptyTarget);
    expect(
      created.id.location,
      skir.ValueLocation(
        resource: fixture.emptyTarget,
        path: fixture.nestedLinkPath,
      ),
    );
    expect(
      editing.workspace.document
          .resource(fixture.emptyTarget)!
          .authoredField("wrapper")!
          .authoredField("label")!
          .authoredString,
      "prepared",
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
    workspace = RealmEditing(
      persistence: transport.persistence,
      submissions: _workSession(),
      initial: document,
    );
    binding = workspace.attach(
      resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
  }
  late final ScriptedAuthoringTransport transport;
  late final RealmEditing workspace;
  late final RealmEditingBinding binding;
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
  skir.ValueLocation? source,
  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue,
  Widget Function(BuildContext, skir.ValueLocation, Widget)? linkFieldBuilder,
  bool readOnly = false,
}) {
  source ??= fixture.source;
  final root = skir.ExpressionBindingId(value: "configured_value");
  final record = fixture.draft.resource(source.resource)!;
  final budget = skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100);
  final host = AuthoredPresentationHost(
    resource: source.resource,
    source: editing.workspace.document,
    material: skir.PresentationMaterial.defaultInstance,
    role: skir.PresentationRole.workspace,
    budget: budget,
    capabilities: const PortablePresentationCapabilities(),
    prepareValue: prepareValue,
    edit: editing.binding,
  );
  addTearDown(host.dispose);
  return testApp(
    child: Scaffold(
      body: PortableResourcesInteractionScope(
        itemBuilder: (context, view, member, child) => child,
        layoutBuilder: (context, view, child) => child,
        linkFieldBuilder: linkFieldBuilder,
        child: PortablePresentationNodeRenderer(
          node: skir.PresentationNode(
            nodeId: "link",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.wrapLinkInput(
              skir.LinkControl(
                control: skir.BoundControl(
                  binding: skir.BindingRef(bindingId: root, path: source.path),
                  label: null,
                  description: null,
                  prefix: null,
                  semanticLabel: null,
                ),
                allowReorder: false,
                candidatePolicy: null,
                rejectionDisplay: skir.LinkRejectionDisplay.disabled,
                sourceId: null,
                appearance: null,
                content: null,
                inputAppearance: null,
                inputContent: null,
                popup: null,
              ),
            ),
            header: null,
          ),
          scope: PortablePresentationScope(
            operations: testPortableOperations(),
            bindings: {
              root: PortableExpressionBinding(
                value: skir.DataValue.createRecord(fields: record.fields),
                location: skir.ValueLocation(
                  resource: source.resource,
                  path: skir.ValuePath(segments: const []),
                ),
              ),
            },
            budget: budget,
            catalog: fixture.catalog,
            host: host,
            readOnly: readOnly,
          ),
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
_fixture({
  bool incompatibleInverse = false,
  bool directCollection = false,
  bool abstractWrapper = false,
  bool nestedCollection = false,
}) {
  final generation = skir.CatalogGeneration(value: "catalog:links");
  final node = _definition("Node");
  final wrapper = _definition("Wrapper");
  final abstractForm = _definition("AbstractWrapper");
  final sourceLink = _definition("SourceLink");
  final targetLink = _definition("TargetLink");
  final links = _definition("Links");
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
    searchKey: null,
    placementField: null,
    display: defaultTypeDisplay(""),
    definition: definition,
    status: skir.DeclarationStatus.ready,
    effectiveFields: fields,
    ancestorTemplates: definition.parents,
  );
  final sourceLinkTemplate = skir.TypeTemplate.createNamed(
    definition: sourceLink,
    arguments: const [],
  );
  final wrapperTemplate = skir.TypeTemplate.createNamed(
    definition: abstractWrapper ? abstractForm : wrapper,
    arguments: const [],
  );
  final targetLinkTemplate = skir.TypeTemplate.createNamed(
    definition: targetLink,
    arguments: const [],
  );
  final linksTemplate = skir.TypeTemplate.createNamed(
    definition: links,
    arguments: const [],
  );
  final textTemplate = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final snapshot = skir.EditorCatalogWireSnapshot(
    resourceDisplays: const [],
    resourceOperations: const [],
    generation: generation,
    types: [
      if (abstractWrapper)
        published(
          skir.TypeDefinition(
            id: abstractForm,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: const [],
              abstract_: true,
            ),
            parents: const [],
          ),
          const [],
        ),
      published(
        skir.TypeDefinition(
          id: links,
          parameters: const [],
          representation: skir.RepresentationTemplate.createSequence(
            item: targetLinkTemplate,
            kind: skir.CollectionKind.list,
          ),
          parents: const [],
        ),
        const [],
      ),
      published(
        skir.TypeDefinition(
          id: node,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              declaration(sourceField, sourceLinkTemplate),
              declaration(
                wrapperField,
                directCollection ? linksTemplate : wrapperTemplate,
              ),
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
            type: directCollection ? linksTemplate : wrapperTemplate,
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
              declaration(
                backField,
                nestedCollection ? linksTemplate : targetLinkTemplate,
              ),
              declaration(labelField, textTemplate),
            ],
            abstract_: false,
          ),
          parents: abstractWrapper
              ? [
                  skir.NamedTypeTemplate(
                    definition: abstractForm,
                    arguments: const [],
                  ),
                ]
              : const [],
        ),
        [
          skir.EffectiveFieldTemplate(
            key: "back",
            owner: backField,
            type: nestedCollection ? linksTemplate : targetLinkTemplate,
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
              target: incompatibleInverse && link.$1 == targetLink
                  ? wrapperTemplate
                  : nodeTemplate,
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
          cardinality: (directCollection || nestedCollection)
              ? skir.EndpointCardinality.many
              : skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        second: skir.EndpointDefinition(
          id: targetEndpoint,
          slot: skir.EndpointSlot.second,
          resource: skir.NamedTypeTemplate(
            definition: node,
            arguments: const [],
          ),
          cardinality: (directCollection || nestedCollection)
              ? skir.EndpointCardinality.one
              : skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: const [],
      ),
    ],
    realmRoot: skir.TypeDefinitionId.defaultInstance,
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],

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
      if (!abstractWrapper)
        skir.EndpointBindingTemplate(
          endpoint: targetEndpoint,
          containingResource: skir.NamedTypeTemplate(
            definition: node,
            arguments: const [],
          ),
          valueOwner: directCollection ? node : wrapper,
          relativePath: skir.RelativeFieldPattern(
            segments: [
              skir.FieldPatternSegment.createField(name: "wrapper"),
              if (directCollection)
                skir.FieldPatternSegment.items
              else
                skir.FieldPatternSegment.createField(name: "back"),
            ],
          ),
          target: incompatibleInverse ? wrapperTemplate : nodeTemplate,
          containsCollection: directCollection,
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
          skir.FieldValue(
            name: "wrapper",
            value: directCollection
                ? skir.DataValue.createNamed(
                    actualType: skir.NamedTypeUse(
                      definition: links,
                      arguments: const [],
                    ),
                    payload: skir.DataValue.createListValue(items: const []),
                  )
                : wrapperValue,
          ),
        ],
      );
  final authored = skir.AuthoringState(
    confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
    generation: generation,
    resources: [
      skir.AuthoringResource(
        id: source,
        content: record(skir.DataValue.unfilled),
      ),
      skir.AuthoringResource(
        id: existingTarget,
        content: record(
          skir.DataValue.createNamed(
            actualType: wrapperUse,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "back",
                  value: nestedCollection
                      ? skir.DataValue.createNamed(
                          actualType: skir.NamedTypeUse(
                            definition: links,
                            arguments: const [],
                          ),
                          payload: skir.DataValue.createListValue(
                            items: const [],
                          ),
                        )
                      : skir.DataValue.unfilled,
                ),
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

ScopedWorkSession _workSession() {
  final session = ScopedWorkSession();
  addTearDown(session.dispose);
  return session;
}
