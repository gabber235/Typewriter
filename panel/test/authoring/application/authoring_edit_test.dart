import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// One untyped record with a title and a list of items, as the Realm saved
/// it.
final listRecord = authoredDoc([
  authoredRecord("resource:1", {
    "title": textValue("original"),
    "items": typedTextList(["first"]),
  }),
], generation: skir.CatalogGeneration(value: "catalog:1"));
final titleAt = valueAt("resource:1", ["title"]);
final itemsAt = valueAt("resource:1", ["items"]);

void main() {
  test("expression edits enroll reads only after the mutation succeeds", () {
    final draft = listRecord.edit;
    final read = titleAt;

    final rejected = draft.stageExpressionEdit([read], (_) => false);
    expect(rejected, isFalse);
    expect(draft.resources, listRecord.edit.resources);
    // The saved content after another author changed its title.
    final remote = listRecord.edit
      ..set(titleAt, skir.DataValue.wrapStringValue("remote"));
    expect(
      remote.currentFacts.conflicts(draft.prepare().expectations),
      isEmpty,
      reason: "A rejected expression edit depends on nothing it read",
    );

    final accepted = draft.stageExpressionEdit(
      [read],
      (branch) =>
          branch.set(titleAt, skir.DataValue.wrapStringValue("changed"))
              is PortablePathValue,
    );
    expect(accepted, isTrue);
    expect(draft.valueAt(read), skir.DataValue.wrapStringValue("changed"));
    expect(
      draft,
      refusedAfter(
        (remote) => remote.set(read, skir.DataValue.wrapStringValue("remote")),
        saved: () => listRecord.edit,
      ),
    );
  });

  test("staged reads retain the first original observation", () {
    final draft = listRecord.edit;

    final updated = draft.set(
      titleAt,
      skir.DataValue.wrapStringValue("changed"),
    );
    expect(updated, isA<PortablePathValue<skir.AuthoringRecord>>());
    final read = draft.read(titleAt);

    expect(
      (read as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("changed"),
    );
    expect(
      draft,
      refusedAfter(
        (remote) =>
            remote.set(titleAt, skir.DataValue.wrapStringValue("remote")),
        saved: () => listRecord.edit,
      ),
    );
  });

  test("prepares one immutable server verified edit request", () {
    final draft = listRecord.edit
      ..set(titleAt, skir.DataValue.wrapStringValue("changed"));

    final prepared = draft.prepare();
    draft.set(titleAt, skir.DataValue.wrapStringValue("later"));

    expect(prepared.catalog, draft.generation);
    final saved = listRecord.edit..applyPrepared(prepared);
    expect(saved.valueAt(titleAt), skir.DataValue.wrapStringValue("changed"));
  });

  test("isolated edit forks never mutate the session baseline", () {
    final draft = listRecord.edit;
    final first = draft.fork();
    final second = draft.fork();

    first.set(titleAt, skir.DataValue.wrapStringValue("first"));
    second.set(titleAt, skir.DataValue.wrapStringValue("second"));

    expect(draft.intents, isEmpty);
    expect(
      (draft.read(titleAt) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("original"),
    );
    expect(first.intents, hasLength(1));
    expect(second.intents, hasLength(1));
    expect(
      (first.read(titleAt) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("first"),
    );
    expect(
      (second.read(titleAt) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("second"),
    );
  });

  test("forks preserve staged history and isolate later changes", () {
    final draft = listRecord.edit
      ..set(titleAt, skir.DataValue.wrapStringValue("first"));
    final branch = draft.fork()
      ..set(titleAt, skir.DataValue.wrapStringValue("second"));

    expect(
      (branch.read(titleAt) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("second"),
    );
    expect(
      (draft.read(titleAt) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("first"),
    );
  });

  test("cancelled creation discards its isolated resource and intents", () {
    final draft = listRecord.edit;
    final created = skir.ResourceId(value: "resource:created");
    final record = listRecord.state.resources.single.content;
    final staged = draft.fork()
      ..createPrepared(
        created,
        skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(record),
          findings: const [],
        ),
      );

    expect(staged.resource(created), record);
    expect(staged.intents, hasLength(1));
    expect(draft.resource(created), isNull);
    expect(draft.intents, isEmpty);
  });

  test("planning a reference to a shared Book leaves the prepared page and "
      "its finding untouched", () {
    final fixture = PageCreationFixture();
    final staged = fixture.draft.fork()
      ..createPrepared(
        fixture.page,
        skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(fixture.pageRecord),
          findings: [
            skir.InitializationDiagnostic(
              field: null,
              code: "detail",
              message: "Preparation detail",
              relativePath: editorRootPath.field("name"),
            ),
          ],
        ),
      );
    final resourcesBefore = staged.resources;
    final linksBefore = staged.links;
    final reference = staged.resolveSingleLink(
      fixture.page,
      "book",
      fixture.book,
    );
    expect(reference.connection.target, fixture.book);
    expect(staged.resources, resourcesBefore);
    expect(staged.links, linksBefore);
    expect(fixture.draft.resource(fixture.page), isNull);
    expect(
      staged.initializationFindings.single.evidence.appliesTo(
        staged.toDocument(),
      ),
      isTrue,
    );
  });

  test("counterpart resolution distinguishes direct, ambiguous, collection and invalid", () {
    final fixture = PageCreationFixture();
    final checked = fixture.draft.catalog!;
    final pageConfiguration = skir.TypeSelection.wrapComplete(
      fixture.sequenceUse,
    );
    final pageEndpoint = skir.EndpointId(value: "page.book");
    expect(
      checked.resolveScalarCounterpart(
        configuration: pageConfiguration,
        resource: fixture.page,
        endpoint: pageEndpoint,
      ),
      ResourceCounterpartResolution.resolved(
        skir.ValueLocation(
          resource: fixture.page,
          path: editorRootPath.field("book"),
        ),
      ),
    );
    final ambiguous = PageCreationFixture(ambiguous: true);
    expect(
      ambiguous.draft.catalog!.resolveScalarCounterpart(
        configuration: pageConfiguration,
        resource: ambiguous.page,
        endpoint: pageEndpoint,
      ),
      isA<ResourceCounterpartChoiceRequired>(),
    );
    expect(
      checked.resolveScalarCounterpart(
        configuration: fixture.draft.resource(fixture.book)!.configuration,
        resource: fixture.book,
        endpoint: fixture.bookEndpoint,
      ),
      isA<ResourceCounterpartChoiceRequired>(),
    );
    expect(
      checked.resolveScalarCounterpart(
        configuration: pageConfiguration,
        resource: fixture.page,
        endpoint: skir.EndpointId(value: "unknown"),
      ),
      isA<InvalidResourceCounterpart>(),
    );
    expect(
      checked.resolveScalarCounterpart(
        configuration: pageConfiguration,
        resource: fixture.page,
        endpoint: fixture.bookEndpoint,
      ),
      isA<InvalidResourceCounterpart>(),
    );
  });

  test("ambiguous inverse requires an explicit location without mutating", () {
    final fixture = PageCreationFixture(ambiguous: true);
    final staged = fixture.draft.fork()
      ..createPrepared(
        fixture.page,
        skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(fixture.pageRecord),
          findings: const [],
        ),
      );
    final source = skir.ValueLocation(
      resource: fixture.book,
      path: skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "pages"),
          skir.PathSegment.createItem(id: skir.ItemId(value: "new:page")),
        ],
      ),
    );
    final plan = (staged.linkPlans(
      catalog: staged.catalog!,
      source: source,
    ) as PortableLinkPlanReady).plans.single;
    final target = plan.targets.singleWhere(
      (choice) => choice.resource == fixture.page,
    );
    final before = staged.intents.toList();
    expect(
      () => staged.resolveReference(
        catalog: staged.catalog!,
        plan: plan,
        target: target,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          "actionable choice",
          contains("explicitly"),
        ),
      ),
    );
    expect(staged.intents, before);
    expect(fixture.draft.intents, isEmpty);
  });

  test("page creation inserts its book slot before connecting", () {
    final fixture = PageCreationFixture();
    final staged = fixture.draft.fork()
      ..createPrepared(
        fixture.page,
        skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(fixture.pageRecord),
          findings: const [],
        ),
      );
    final reference = staged.resolveSingleLink(
      fixture.page,
      "book",
      fixture.book,
    );
    final item = (reference.materializations.single as ReferenceValueInsertion)
        .intent
        .item
        .id;
    staged.applyResolvedReference(reference);

    final bookLink = switch (staged.read(
      skir.ValueLocation(
        resource: fixture.book,
        path: skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "pages"),
            skir.PathSegment.createItem(id: item),
          ],
        ),
      ),
    )) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    expect(bookLink?.target.resource, fixture.page);
    final pageBook = switch (staged.read(
      skir.ValueLocation(
        resource: fixture.page,
        path: editorRootPath.field("book"),
      ),
    )) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    expect(pageBook?.target.resource, fixture.book);
    expect(
      staged,
      refusedAfter(
        (remote) => remote.insert(
          authoredFieldLocation(fixture.book, ["pages"]),
          null,
          skir.ListItem(
            id: skir.ItemId(value: "remote"),
            value: skir.DataValue.unfilled,
          ),
        ),
        saved: () => PageCreationFixture().draft,
      ),
    );
  });

  test("commit rejection reports each located value problem", () {
    final response = skir.CommitPreparedEditResponse.wrapRejectedError([
      skir.ValueProblem(
        location: skir.ValueLocation(
          resource: skir.ResourceId(value: "page:created"),
          path: skir.ValuePath(
            segments: [
              skir.PathSegment.createField(name: "book"),
              skir.PathSegment.createItem(id: skir.ItemId(value: "page:item")),
            ],
          ),
        ),
        code: "item_missing",
      ),
    ]);

    expect(
      response.rejectionMessage,
      "The Realm rejected this edit: item_missing at page:created:book.page:item",
    );
  });

  test("a write to a missing value is refused once someone else set it", () {
    final draft = listRecord.edit;
    final at = skir.ValueLocation(
      resource: skir.ResourceId(value: "resource:1"),
      path: editorRootPath.field("count"),
    );
    draft.set(at, skir.DataValue.wrapInteger("3"));
    expect(
      draft,
      refusedAfter(
        (remote) => remote.set(at, skir.DataValue.wrapInteger("5")),
        saved: () => listRecord.edit,
      ),
    );
  });

  test("ordered collection edits keep their item ids and list type", () {
    final draft = listRecord.edit;
    final inserted = skir.ListItem(
      id: skir.ItemId(value: "inserted"),
      value: skir.DataValue.wrapStringValue("second"),
    );

    draft
      ..insert(itemsAt, skir.ItemId(value: "first"), inserted)
      ..move(itemsAt, inserted.id, null)
      ..remove(itemsAt, skir.ItemId(value: "first"));

    final value =
        (draft.read(itemsAt) as PortablePathValue<skir.DataValue>).value
            as skir.DataValue_namedWrapper;
    expect(
      value.value.actualType,
      listTypeOf(skir.TypeUse.wrapScalar(skir.ScalarKind.text)),
    );
    final list = value.value.payload as skir.DataValue_listValueWrapper;
    expect(list.value.items.map((item) => item.id), [inserted.id]);
  });

  test("insert materializes an Unfilled collection from checked shape", () {
    final fixture = CollectionRepairFixture();
    final item = skir.ListItem(
      id: skir.ItemId(value: "item:text"),
      value: fixture.draft.defaultValue(
        skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      ),
    );

    final result = fixture.draft.insert(fixture.texts, null, item);

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    final value = switch (fixture.draft.read(fixture.texts)) {
      PortablePathValue(value: final value) => value,
      _ => null,
    };
    expect(value?.authoredActualType, fixture.textSet);
    expect(value?.authoredItems?.single.id, item.id);
    expect(value?.authoredItems?.single.value.authoredString, "");
    expect(fixture.draft.intents, [isA<skir.EditIntent_insertWrapper>()]);
  });

  test("a prepared collection item is readable and its findings are located "
      "inside it", () {
    final fixture = CollectionRepairFixture();
    final item = skir.ItemId(value: "item:record");
    final selection = skir.TypeSelection.wrapComplete(fixture.itemType);
    final request = skir.ValuePreparationRequest(
      catalog: fixture.draft.generation,
      target: skir.PreparationTarget.wrapRecord(selection),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
    );
    final prepared = skir.PreparedValue(
      content: skir.PreparedContent.wrapRecord(
        skir.AuthoringRecord(
          configuration: selection,
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue("prepared"),
            ),
          ],
        ),
      ),
      findings: [
        skir.InitializationDiagnostic(
          field: skir.FieldOwner(
            definition: fixture.itemType.definition,
            name: "name",
          ),
          code: "default_capture_failed",
          message: "The item default could not be captured",
          relativePath: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "name")],
          ),
        ),
      ],
    );

    final result = fixture.draft.insertPrepared(
      fixture.records,
      null,
      item,
      request,
      prepared,
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    final inserted = fixture.draft.valueAt(
      skir.ValueLocation(
        resource: fixture.records.resource,
        path: skir.ValuePath(
          segments: [
            ...fixture.records.path.segments,
            skir.PathSegment.createItem(id: item),
            skir.PathSegment.createField(name: "name"),
          ],
        ),
      ),
    );
    expect(inserted, skir.DataValue.wrapStringValue("prepared"));
    expect(
      fixture.draft.initializationFindings.single.location.path,
      skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "records"),
          skir.PathSegment.createItem(id: item),
          skir.PathSegment.createField(name: "name"),
        ],
      ),
    );
  });

  test("a missing nested parent records no write intent", () {
    final draft = listRecord.edit;
    final nested = skir.ValueLocation(
      resource: skir.ResourceId(value: "resource:1"),
      path: skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "style"),
          skir.PathSegment.createField(name: "bold"),
        ],
      ),
    );

    final result = draft.set(nested, skir.DataValue.wrapBoolean(true));

    expect(result, isA<PortablePathUnavailable<skir.AuthoringRecord>>());
    expect(draft.intents, isEmpty);
  });

  test("a write is refused once its resource was deleted or retyped", () {
    final draft = listRecord.edit
      ..set(titleAt, skir.DataValue.wrapStringValue("changed"));

    expect(
      draft,
      refusedAfter(
        (remote) => remote.delete(skir.ResourceId(value: "resource:1")),
        saved: () => listRecord.edit,
      ),
    );
    expect(
      draft,
      refusedAfter((remote) {
        final record = remote.resource(skir.ResourceId(value: "resource:1"))!;
        remote
          ..delete(skir.ResourceId(value: "resource:1"))
          ..create(
            skir.ResourceId(value: "resource:1"),
            skir.AuthoringRecord(
              configuration: skir.TypeSelection.wrapComplete(
                listTypeOf(skir.TypeUse.wrapScalar(skir.ScalarKind.text)),
              ),
              fields: record.fields,
            ),
          );
      }, saved: () => listRecord.edit),
    );
  });

  test("nullable clear writes null while required clear writes unfilled", () {
    final draft = listRecord.edit
      ..clear(
        titleAt,
        expected: skir.TypeUse.createNullable(
          value: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        ),
      );
    expect(draft.valueAt(titleAt), skir.DataValue.null_);

    draft.clear(
      titleAt,
      expected: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
    );
    expect(draft.valueAt(titleAt), skir.DataValue.unfilled);
  });

  test("a connection is refused once its target was deleted or its source "
      "relinked", () {
    final fixture = RelationEditFixture();
    fixture.draft.connect(
      fixture.occurrence,
      fixture.newTarget,
      counterpart: skir.CounterpartChoice.wrapExisting(fixture.counterpart),
    );
    expect(fixture.draft.links.single.second, fixture.newTarget);
    expect(
      fixture.draft,
      refusedAfter(
        (remote) => remote.delete(fixture.newTarget),
        saved: () => RelationEditFixture().draft,
      ),
    );
    expect(
      fixture.draft,
      refusedAfter(
        (remote) => remote.disconnect(fixture.occurrence),
        saved: () => RelationEditFixture().draft,
      ),
    );
    fixture.draft.disconnect(fixture.occurrence);
    expect(fixture.draft.links, isEmpty);
  });

  for (final reverse in [false, true]) {
    test("a collection link from the ${reverse ? 'counterpart' : 'source'} is "
        "refused once the owner's collection changed", () {
      final fixture = PageCreationFixture();
      final edit = fixture.draft..create(fixture.page, fixture.pageRecord);
      final parent = authoredFieldLocation(fixture.book, ["pages"]);
      final item = skir.ItemId(value: "slot:new");
      edit.insert(
        parent,
        null,
        skir.ListItem(id: item, value: skir.DataValue.unfilled),
      );
      final bookAt = skir.ValueLocation(
        resource: fixture.book,
        path: skir.ValuePath(
          segments: [
            ...parent.path.segments,
            skir.PathSegment.createItem(id: item),
          ],
        ),
      );
      final pageAt = authoredFieldLocation(fixture.page, ["book"]);
      final bookOccurrence = skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: fixture.bookEndpoint,
          location: bookAt,
        ),
        source: fixture.book,
        target: skir.LinkTarget(resource: fixture.page, opposite: pageAt.path),
      );
      final pageOccurrence = skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: skir.EndpointId(value: "page.book"),
          location: pageAt,
        ),
        source: fixture.page,
        target: skir.LinkTarget(resource: fixture.book, opposite: bookAt.path),
      );
      edit.connect(
        reverse ? pageOccurrence : bookOccurrence,
        reverse ? fixture.book : fixture.page,
        counterpart: skir.CounterpartChoice.wrapExisting(
          reverse ? bookOccurrence : pageOccurrence,
        ),
      );
      expect(
        edit,
        refusedAfter(
          (remote) => remote.insert(
            parent,
            null,
            skir.ListItem(
              id: skir.ItemId(value: "remote"),
              value: skir.DataValue.unfilled,
            ),
          ),
          saved: () => PageCreationFixture().draft,
        ),
      );
      expect(
        edit
            .resource(fixture.book)!
            .authoredField("pages")!
            .authoredItems!
            .single
            .value
            .authoredLink!
            .target
            .resource,
        fixture.page,
      );
    });
  }

  test("a collection disconnect is refused once the collection changed", () {
    final draft = listRecord.edit;
    final item = skir.ValueLocation(
      resource: skir.ResourceId(value: "resource:1"),
      path: skir.ValuePath(
        segments: [
          ...itemsAt.path.segments,
          skir.PathSegment.createItem(id: skir.ItemId(value: "first")),
        ],
      ),
    );
    final occurrence = skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(
        endpoint: skir.EndpointId(value: "test.source"),
        location: item,
      ),
      source: skir.ResourceId(value: "resource:1"),
      target: skir.LinkTarget(
        resource: skir.ResourceId(value: "resource:2"),
        opposite: null,
      ),
    );

    draft.disconnect(occurrence);

    expect(
      draft,
      refusedAfter(
        (remote) => remote.insert(
          itemsAt,
          null,
          skir.ListItem(
            id: skir.ItemId(value: "remote"),
            value: skir.DataValue.wrapStringValue("remote"),
          ),
        ),
        saved: () => listRecord.edit,
      ),
    );
  });

  test(
    "retarget keeps one staged occurrence and leaves its baseline intact",
    () {
      final fixture = RelationEditFixture();
      final branch = fixture.draft.fork()
        ..connect(
          fixture.occurrence,
          fixture.newTarget,
          counterpart: skir.CounterpartChoice.wrapExisting(fixture.counterpart),
        );

      expect(fixture.draft.links.single.second.value, "resource:original");
      expect(
        branch,
        refusedAfter(
          (remote) => remote.delete(fixture.originalOpposite.resource),
          saved: () => RelationEditFixture().draft,
        ),
      );
      expect(branch.links, hasLength(1));
      expect(branch.links.single.first, fixture.occurrence.source);
      expect(branch.links.single.second, fixture.newTarget);
      expect(
        (branch.read(fixture.occurrence.id.location)
                as PortablePathValue<skir.DataValue>)
            .value
            .authoredLink
            ?.target
            .resource,
        fixture.newTarget,
      );
      expect(
        (branch.read(
          fixture.originalOpposite,
        ) as PortablePathValue<skir.DataValue>).value,
        skir.DataValue.unfilled,
      );
      expect(
        (branch.read(fixture.newOpposite) as PortablePathValue<skir.DataValue>)
            .value
            .authoredLink
            ?.target
            .resource,
        fixture.occurrence.source,
      );

      branch.disconnect(fixture.occurrence);

      expect(branch.links, isEmpty);
      expect(
        (branch.read(
          fixture.occurrence.id.location,
        ) as PortablePathValue<skir.DataValue>).value,
        skir.DataValue.unfilled,
      );
      expect(
        (fixture.draft.read(fixture.occurrence.id.location)
                as PortablePathValue<skir.DataValue>)
            .value
            .authoredLink
            ?.target
            .resource
            .value,
        "resource:original",
      );
    },
  );

  test("a deletion is refused once its linked source was relinked", () {
    final fixture = RelationEditFixture();
    final deleted = fixture.occurrence.target.resource;
    final branch = fixture.draft.fork()..delete(deleted);

    expect(branch.resource(deleted), isNull);
    expect(branch.links, isEmpty);
    expect(
      branch,
      refusedAfter(
        (remote) => remote.disconnect(fixture.occurrence),
        saved: () => RelationEditFixture().draft,
      ),
    );
  });

  test("a cascading deletion removes the counterpart and is refused once "
      "the counterpart changed", () {
    final fixture = RelationEditFixture(
      firstDelete: skir.RelationDeletePolicy.cascade,
      includeOppositeLocation: false,
    );
    final cascaded = fixture.occurrence.target.resource;
    final branch = fixture.draft.fork()..delete(fixture.occurrence.source);

    expect(branch.resource(cascaded), isNull);
    expect(
      branch,
      refusedAfter(
        (remote) => remote.delete(cascaded),
        saved: () => RelationEditFixture(
          firstDelete: skir.RelationDeletePolicy.cascade,
          includeOppositeLocation: false,
        ).draft,
      ),
    );
  });

  test("retarget clears an earlier opposite in the same target", () {
    final fixture = RelationEditFixture();
    final branch = fixture.draft.fork()
      ..connect(
        fixture.occurrence,
        fixture.newTarget,
        counterpart: skir.CounterpartChoice.wrapExisting(fixture.counterpart),
      )
      ..connect(
        fixture.occurrence,
        fixture.newTarget,
        counterpart: skir.CounterpartChoice.wrapExisting(
          fixture.alternateCounterpart,
        ),
      );

    expect(
      (branch.read(
        fixture.newOpposite,
      ) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.unfilled,
    );
    expect(
      (branch.read(fixture.alternateOpposite)
              as PortablePathValue<skir.DataValue>)
          .value
          .authoredLink
          ?.target
          .resource,
      fixture.occurrence.source,
    );
    expect(branch.links.single.secondLocation, fixture.alternateOpposite.path);
  });

  test("nested write prepares the containing field default", () async {
    final fixture = ParentFieldFixture();

    final result = await fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
      (request) async => ParentFieldFixture.preparedStyle(request, bold: true),
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    expect(
      fixture.draft.valueAt(fixture.bold),
      skir.DataValue.wrapBoolean(true),
    );
    expect(
      fixture.draft.valueAt(fixture.repetitions),
      skir.DataValue.wrapInteger("3"),
    );
  });

  test("nested parent uses the containing field prepared default", () async {
    final fixture = ParentFieldFixture(nullableStyle: true);
    final styleUse = skir.NamedTypeUse(
      definition: testTypeId("Style"),
      arguments: const [],
    );
    final requests = <skir.ValuePreparationRequest>[];

    final result = await fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
      (request) async {
        requests.add(request);
        return preparedRecord(request, [
          skir.FieldValue(
            name: "style",
            value: skir.DataValue.createNamed(
              actualType: styleUse,
              payload: skir.DataValue.createRecord(
                fields: [
                  skir.FieldValue(
                    name: "bold",
                    value: skir.DataValue.wrapBoolean(true),
                  ),
                  skir.FieldValue(
                    name: "repetitions",
                    value: skir.DataValue.unfilled,
                  ),
                ],
              ),
            ),
          ),
        ]);
      },
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    expect(requests, hasLength(1), reason: "No child fallback is prepared");
    expect(requests.single.recordSuppliedFields, isEmpty);
    expect(
      (requests.single.recordSelection as skir.TypeSelection_completeWrapper)
          .value
          .definition,
      testTypeId("Action"),
    );
    final style =
        fixture.draft
                .resource(fixture.repetitions.resource)!
                .authoredField("style")!
            as skir.DataValue_namedWrapper;
    final fields =
        (style.value.payload as skir.DataValue_recordWrapper).value.fields;
    expect(
      fields.singleWhere((field) => field.name == "bold").value,
      skir.DataValue.wrapBoolean(true),
    );
    expect(
      fields.singleWhere((field) => field.name == "repetitions").value,
      skir.DataValue.wrapInteger("3"),
    );
    expect(
      fixture.draft,
      refusedAfter(
        (remote) => remote.set(
          authoredFieldLocation(fixture.repetitions.resource, ["style"]),
          skir.DataValue.null_,
        ),
        saved: () => ParentFieldFixture(nullableStyle: true).draft,
      ),
    );
  });

  test("failed preparation can be explicitly evaluated again", () async {
    final fixture = ParentFieldFixture(nullableStyle: true);
    final requests = <skir.ValuePreparationRequest>[];

    Future<skir.PreparedValue> fail(
      skir.ValuePreparationRequest request,
    ) async {
      requests.add(request);
      throw StateError("temporary failure");
    }

    await expectLater(
      fixture.draft.setWithInitialization(
        fixture.repetitions,
        skir.DataValue.wrapInteger("3"),
        fail,
      ),
      throwsStateError,
    );
    final result = await fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
      (request) async {
        requests.add(request);
        return ParentFieldFixture.preparedStyle(request, bold: true);
      },
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    expect(requests, hasLength(2));
    expect(requests[1].recordSelection, requests[0].recordSelection);
  });

  test("a later deliberate initialization evaluates again", () async {
    final fixture = ParentFieldFixture(nullableStyle: true);
    final requests = <skir.ValuePreparationRequest>[];
    Future<skir.PreparedValue> prepare(
      skir.ValuePreparationRequest request,
    ) async {
      requests.add(request);
      return ParentFieldFixture.preparedStyle(request, bold: true);
    }

    await fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
      prepare,
    );
    final style = skir.ValueLocation(
      resource: fixture.repetitions.resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "style")],
      ),
    );
    expect(
      fixture.draft.set(style, skir.DataValue.null_),
      isA<PortablePathValue<skir.AuthoringRecord>>(),
    );
    await fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("4"),
      prepare,
    );

    expect(requests, hasLength(2));
    expect(requests[1].recordSelection, requests[0].recordSelection);
  });

  test(
    "prepared parent work is discarded when the final path is absent",
    () async {
      final fixture = ParentFieldFixture(
        nullableStyle: true,
        includeItems: true,
      );
      final style = skir.ValueLocation(
        resource: fixture.repetitions.resource,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "style")],
        ),
      );
      final missingChild = skir.ValueLocation(
        resource: fixture.repetitions.resource,
        path: skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "style"),
            skir.PathSegment.createField(name: "items"),
            skir.PathSegment.createItem(id: skir.ItemId(value: "missing")),
            skir.PathSegment.createField(name: "value"),
          ],
        ),
      );

      final result = await fixture.draft.setWithInitialization(
        missingChild,
        skir.DataValue.wrapStringValue("changed"),
        (request) async => ParentFieldFixture.preparedStyle(
          request,
          bold: true,
          includeItems: true,
        ),
      );

      expect(result, isA<PortablePathUnavailable<skir.AuthoringRecord>>());
      expect(fixture.draft.intents, isEmpty);
      expect(
        (fixture.draft.read(style) as PortablePathValue<skir.DataValue>).value,
        skir.DataValue.unfilled,
      );
    },
  );

  test("concurrent draft change prevents prepared parent adoption", () async {
    final fixture = ParentFieldFixture(nullableStyle: true);
    final response = Completer<skir.PreparedValue>();
    late skir.ValuePreparationRequest preparationRequest;
    final pending = fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
      (request) {
        preparationRequest = request;
        return response.future;
      },
    );
    final concurrent = skir.ResourceId(value: "resource:concurrent");
    fixture.draft.create(
      concurrent,
      skir.AuthoringRecord(
        configuration: skir.TypeSelection.wrapComplete(
          skir.NamedTypeUse(
            definition: testTypeId("Action"),
            arguments: const [],
          ),
        ),
        fields: const [],
      ),
    );
    response.complete(
      ParentFieldFixture.preparedStyle(preparationRequest, bold: true),
    );

    final result = await pending;
    expect(result, isA<PortablePathUnavailable<skir.AuthoringRecord>>());
    expect(fixture.draft.resource(concurrent), isNotNull);
    expect(
      fixture.draft
          .resource(fixture.repetitions.resource)!
          .authoredField("style"),
      skir.DataValue.unfilled,
    );
  });

  test("a field default that fails to capture shows its finding until the "
      "explicit write supersedes it", () async {
    final fixture = ParentFieldFixture(nullableStyle: true);
    var invocation = 0;
    final result = await fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
      (request) async {
        invocation++;
        if (invocation == 1) {
          return skir.PreparedValue(
            content: skir.PreparedContent.wrapRecord(
              skir.AuthoringRecord(
                configuration: request.recordSelection,
                fields: [
                  skir.FieldValue(
                    name: "style",
                    value: skir.DataValue.unfilled,
                  ),
                ],
              ),
            ),
            findings: [
              skir.InitializationDiagnostic(
                field: skir.FieldOwner(
                  definition: testTypeId("Action"),
                  name: "style",
                ),
                code: "default_capture_failed",
                message: "The default could not be captured",
                relativePath: skir.ValuePath(
                  segments: [skir.PathSegment.createField(name: "style")],
                ),
              ),
            ],
          );
        }
        return skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(
            skir.AuthoringRecord(
              configuration: request.recordSelection,
              fields: [
                skir.FieldValue(
                  name: "bold",
                  value: skir.DataValue.wrapBoolean(false),
                ),
                skir.FieldValue(
                  name: "repetitions",
                  value: skir.DataValue.unfilled,
                ),
                skir.FieldValue(
                  name: "bytes",
                  value: skir.DataValue.wrapBytes(skir.ByteString.empty),
                ),
                skir.FieldValue(
                  name: "duration",
                  value: skir.DataValue.createDuration(
                    value: skir.Duration(milliseconds: 0),
                  ),
                ),
                skir.FieldValue(
                  name: "timestamp",
                  value: skir.DataValue.unfilled,
                ),
              ],
            ),
          ),
          findings: [
            skir.InitializationDiagnostic(
              field: skir.FieldOwner(
                definition: testTypeId("Style"),
                name: "repetitions",
              ),
              code: "default_capture_failed",
              message: "The default could not be captured",
              relativePath: skir.ValuePath(
                segments: [skir.PathSegment.createField(name: "repetitions")],
              ),
            ),
          ],
        );
      },
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    expect(
      fixture.draft.valueAt(fixture.repetitions),
      skir.DataValue.wrapInteger("3"),
    );
    expect(
      fixture.draft.initializationFindings.last.location.path,
      skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "style"),
          skir.PathSegment.createField(name: "repetitions"),
        ],
      ),
    );
    expect(
      fixture.draft.initializationFindings.last.diagnostic.message,
      "The default could not be captured",
    );
    expect(
      fixture.draft.initializationFindings.last.evidence.appliesTo(
        fixture.draft.toDocument(),
      ),
      isFalse,
      reason: "The explicit leaf write supersedes the value that preparation assessed",
    );
  });

  test("failed collection child write rolls back parent materialization", () {
    final fixture = ParentFieldFixture(includeItems: true);
    final style = skir.ValueLocation(
      resource: fixture.repetitions.resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "style")],
      ),
    );
    final missingChild = skir.ValueLocation(
      resource: fixture.repetitions.resource,
      path: skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "style"),
          skir.PathSegment.createField(name: "items"),
          skir.PathSegment.createItem(id: skir.ItemId(value: "missing")),
          skir.PathSegment.createField(name: "value"),
        ],
      ),
    );

    final result = fixture.draft.set(
      missingChild,
      skir.DataValue.wrapStringValue("changed"),
    );

    expect(result, isA<PortablePathUnavailable<skir.AuthoringRecord>>());
    expect(fixture.draft.intents, isEmpty);
    expect(fixture.draft.expectations, isEmpty);
    expect(
      (fixture.draft.read(style) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.unfilled,
    );
  });

  test("local defaults never synthesize a concrete record", () {
    final fixture = ParentFieldFixture();
    expect(
      fixture.draft.defaultValue(
        skir.TypeUse.wrapNamed(
          skir.NamedTypeUse(
            definition: testTypeId("Style"),
            arguments: const [],
          ),
        ),
      ),
      skir.DataValue.unfilled,
    );
  });

  test("ordinary scalar defaults remain local", () {
    final fixture = ParentFieldFixture();
    expect(
      fixture.draft.defaultValue(
        skir.TypeUse.wrapScalar(skir.ScalarKind.bytes),
      ),
      skir.DataValue.wrapBytes(skir.ByteString.empty),
    );
    expect(
      fixture.draft.defaultValue(
        skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
      ),
      skir.DataValue.createDuration(value: skir.Duration(milliseconds: 0)),
    );
    expect(
      fixture.draft.defaultValue(
        skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
      ),
      skir.DataValue.unfilled,
    );
  });
}
