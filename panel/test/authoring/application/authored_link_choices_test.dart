import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("concrete endpoint binding replaces the ancestor at the same path", () {
    final fixture = LinkChoicesFixture();
    final original = fixture.catalog.snapshot;
    final base = testTypeId("Node");
    final child = testTypeId("NarrowNode");
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
        publishedType(
          child,
          representation: node.definition.representation,
          parents: [ancestor],
          fields: node.effectiveFields,
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
            definition: testTypeId("Wrapper"),
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
    final fixture = LinkChoicesFixture(abstractWrapper: true);
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
    final fixture = LinkChoicesFixture(abstractWrapper: true);
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
    final fixture = LinkChoicesFixture(abstractWrapper: true);
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
      final fixture = LinkChoicesFixture(
        abstractWrapper: true,
        nestedCollection: true,
      );
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
    final fixture = LinkChoicesFixture(
      abstractWrapper: true,
      nestedCollection: true,
    );
    final source = skir.ValueLocation(
      resource: fixture.existingTarget,
      path: fixture.nestedLinkPath,
    );
    final world = testWorld(adaServing(fixture.draft.toDocument()));
    final binding = await world.mountEditing(tester, source.resource);
    await tester.pumpWidget(
      fixture.linkControl(world: world, binding: binding, source: source),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.tooltip("Add link"));
    await tester.pumpAndSettle();
    await tester.tap(
      linkChoice(fixture.source.resource, "Use the declared counterpart"),
    );
    await tester.pumpAndSettle();
    final saving = binding.save();
    await tester.pumpAndSettle();
    await saving;
    await tester.pump();
    final saved = world.requireRealm.document;
    expect(saved.links.single.first, fixture.source.resource);
    expect(saved.links.single.second, fixture.existingTarget);
    expect(fixture.backLinks(saved, fixture.existingTarget), [
      fixture.source.resource,
    ]);
  });

  testWidgets("normal link editing appends to an inverse in a selected form", (
    tester,
  ) async {
    final fixture = LinkChoicesFixture(
      abstractWrapper: true,
      nestedCollection: true,
    );
    final world = testWorld(adaServing(fixture.draft.toDocument()));
    final binding = await world.mountEditing(tester, fixture.source.resource);
    await tester.pumpWidget(
      fixture.linkControl(world: world, binding: binding),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.tooltip("Choose linked resource"));
    await tester.pumpAndSettle();
    await tester.tap(
      linkChoice(fixture.existingTarget, "Add counterpart to wrapper / back"),
    );
    await tester.pumpAndSettle();
    final saving = binding.save();
    await tester.pumpAndSettle();
    await saving;
    await tester.pump();
    final saved = world.requireRealm.document;
    expect(saved.links.single.second, fixture.existingTarget);
    expect(fixture.backLinks(saved, fixture.existingTarget), [
      fixture.source.resource,
    ]);
  });

  test("opposite applied target rejects a forward compatible resource", () {
    final fixture = LinkChoicesFixture(incompatibleInverse: true);
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
    final fixture = LinkChoicesFixture(directCollection: true);
    fixture.draft.set(
      skir.ValueLocation(
        resource: fixture.existingTarget,
        path: editorRootPath.field("wrapper"),
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
    final items = fixture.draft
        .resource(fixture.existingTarget)!
        .authoredField("wrapper")!
        .authoredItems!;
    expect(items.map((item) => item.value.authoredLink?.target.resource), [
      fixture.source.resource,
    ]);
  });

  test("resolved collection inverse reserves one exact occurrence", () {
    final fixture = LinkChoicesFixture(directCollection: true);
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
    final fixture = LinkChoicesFixture();
    final result = fixture.catalog.resolveScalarCounterpart(
      configuration: fixture.draft.resource(fixture.emptyTarget)!.configuration,
      resource: fixture.emptyTarget,
      endpoint: skir.EndpointId(value: "test.target"),
    );
    expect(result, isA<ResourceCounterpartChoiceRequired>());
    expect(fixture.draft.intents, isEmpty);
  });

  test("offers existing and new nested counterpart locations", () {
    final fixture = LinkChoicesFixture();

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
    expect(
      creatable.creatable.single.containing.path,
      editorRootPath.field("wrapper"),
    );
    expect(creatable.creatable.single.selection, fixture.wrapperSelection);
  });

  test("stages a prepared nested counterpart and its reciprocal link", () {
    final fixture = LinkChoicesFixture();
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
        path: editorRootPath.field("wrapper"),
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
  });

  testWidgets("link input hands its location to the link field builder", (
    tester,
  ) async {
    final fixture = LinkChoicesFixture();
    final wrapped = await fixture.showWrappedLinkControl(
      tester,
      wrap: (control) => Semantics(label: "Wrapped link field", child: control),
    );
    expect(wrapped, everyElement(fixture.source));
    expect(wrapped, isNotEmpty);
    expect(
      find.descendant(
        of: find.bySemanticsLabel("Wrapped link field"),
        matching: find.tooltip("Choose linked resource"),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    "read only link input is never offered to the link field builder",
    (tester) async {
      final fixture = LinkChoicesFixture();
      final wrapped = await fixture.showWrappedLinkControl(
        tester,
        readOnly: true,
      );
      expect(wrapped, isEmpty);
      expect(find.tooltip("Choose linked resource"), findsOneWidget);
    },
  );

  testWidgets(
    "link input preserves cancellation and chooses an exact location",
    (tester) async {
      final fixture = LinkChoicesFixture();
      final world = testWorld(adaServing(fixture.draft.toDocument()));
      final binding = await world.mountEditing(tester, fixture.source.resource);
      await tester.pumpWidget(
        fixture.linkControl(world: world, binding: binding),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.tooltip("Choose linked resource"));
      await tester.pumpAndSettle();
      await tester.tap(find.tooltip("Close"));
      await tester.pumpAndSettle();
      expect(binding.dirty, isFalse);

      await tester.tap(find.tooltip("Choose linked resource"));
      await tester.pumpAndSettle();
      await tester.tap(
        linkChoice(fixture.existingTarget, "Use wrapper / back"),
      );
      await tester.pumpAndSettle();

      final saving = binding.save();
      await tester.pumpAndSettle();
      await saving;
      await tester.pump();
      final saved = world.requireRealm.document;
      expect(saved.links.single.second, fixture.existingTarget);
      expect(saved.links.single.secondLocation, fixture.nestedLinkPath);
      expect(
        saved
            .valueAt(
              authoredFieldLocation(fixture.existingTarget, [
                "wrapper",
                "back",
              ]),
            )
            ?.authoredLink
            ?.target
            .resource,
        fixture.source.resource,
      );
    },
  );

  testWidgets("link input prepares and chooses a new nested counterpart", (
    tester,
  ) async {
    final fixture = LinkChoicesFixture();
    final world = testWorld(adaServing(fixture.draft.toDocument()));
    final binding = await world.mountEditing(tester, fixture.source.resource);
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
      fixture.linkControl(
        world: world,
        binding: binding,
        prepareValue: (value) async {
          request = value;
          return prepared;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.tooltip("Choose linked resource"));
    await tester.pumpAndSettle();
    await tester.tap(
      linkChoice(fixture.emptyTarget, "Create counterpart in wrapper"),
    );
    await tester.pumpAndSettle();

    expect(request?.recordSelection, fixture.wrapperSelection);
    final saving = binding.save();
    await tester.pumpAndSettle();
    await saving;
    await tester.pump();
    final saved = world.requireRealm.document;
    expect(saved.links.single.second, fixture.emptyTarget);
    expect(
      saved
          .valueAt(
            authoredFieldLocation(fixture.emptyTarget, ["wrapper", "back"]),
          )
          ?.authoredLink
          ?.target
          .resource,
      fixture.source.resource,
    );
    expect(
      saved
          .resource(fixture.emptyTarget)!
          .authoredField("wrapper")!
          .authoredField("label")!
          .authoredString,
      "prepared",
    );
    expect(saved.links.single.secondLocation, fixture.nestedLinkPath);
  });
}
