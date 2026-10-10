import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("expression edits enroll reads only after the mutation succeeds", () {
    final fixture = _fixture();
    final read = PortableExpressionRead(
      skir.ExpressionBindingId(value: "configured_value"),
      fixture.title.path,
      location: fixture.title,
    );

    final rejected = fixture.draft.stageExpressionEdit([read], (_) => false);
    expect(rejected, isFalse);
    expect(fixture.draft.intents, isEmpty);
    expect(fixture.draft.expectations, isEmpty);

    final accepted = fixture.draft.stageExpressionEdit(
      [read],
      (branch) =>
          branch.set(fixture.title, skir.DataValue.wrapStringValue("changed"))
              is PortablePathValue,
    );
    expect(accepted, isTrue);
    expect(fixture.draft.intents, hasLength(1));
    expect(fixture.draft.expectations, contains(fixture.titleObservation));
  });

  test("staged reads retain the first original observation", () {
    final fixture = _fixture();
    final draft = fixture.draft;

    final updated = draft.set(
      fixture.title,
      skir.DataValue.wrapStringValue("changed"),
    );
    expect(updated, isA<PortablePathValue<skir.AuthoringRecord>>());
    final read = draft.read(fixture.title);

    expect(
      (read as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("changed"),
    );
    expect(draft.expectations, contains(fixture.titleObservation));
    expect(
      draft.expectations.where(
        (observation) =>
            _factKey(observation) == _factKey(fixture.titleObservation),
      ),
      hasLength(1),
    );
  });

  test("prepares one immutable server verified edit request", () {
    final fixture = _fixture();
    fixture.draft.set(fixture.title, skir.DataValue.wrapStringValue("changed"));

    final prepared = fixture.draft.prepare();
    fixture.draft.set(fixture.title, skir.DataValue.wrapStringValue("later"));

    expect(prepared.catalog, fixture.draft.generation);
    expect(prepared.expectations, contains(fixture.titleObservation));
    expect(prepared.intents, hasLength(1));
  });

  test("isolated edit forks never mutate the session baseline", () {
    final fixture = _fixture();
    final first = fixture.draft.fork();
    final second = fixture.draft.fork();

    first.set(fixture.title, skir.DataValue.wrapStringValue("first"));
    second.set(fixture.title, skir.DataValue.wrapStringValue("second"));

    expect(fixture.draft.intents, isEmpty);
    expect(
      (fixture.draft.read(
        fixture.title,
      ) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("original"),
    );
    expect(first.intents, hasLength(1));
    expect(second.intents, hasLength(1));
    expect(
      (first.read(fixture.title) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("first"),
    );
    expect(
      (second.read(fixture.title) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("second"),
    );
  });

  test("forks preserve staged history and isolate later changes", () {
    final fixture = _fixture();
    fixture.draft.set(fixture.title, skir.DataValue.wrapStringValue("first"));
    final evidence = fixture.draft.expectations.toList(growable: false);
    final branch = fixture.draft.fork()
      ..set(fixture.title, skir.DataValue.wrapStringValue("second"));

    expect(branch.intents, hasLength(2));
    expect(branch.expectations, containsAll(evidence));
    expect(
      (branch.read(fixture.title) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("second"),
    );
    expect(fixture.draft.intents, hasLength(1));
    expect(
      (fixture.draft.read(
        fixture.title,
      ) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("first"),
    );
  });

  test("cancelled creation discards its isolated resource and intents", () {
    final fixture = _fixture();
    final created = skir.ResourceId(value: "resource:created");
    final record = fixture.snapshot.resources.single.content;
    final staged = fixture.draft.fork()
      ..createPreparedResource(
        request: ResourceCreationRequest(
          id: created,
          initializationId: skir.InitializationRequestId(value: "create:1"),
          definition: skir.ResourceDefinitionId(value: "test.resource"),
          configuration: record.configuration,
        ),
        prepared: skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(record),
          findings: const [],
        ),
      );

    expect(staged.resource(created), record);
    expect(staged.intents, hasLength(1));
    expect(fixture.draft.resource(created), isNull);
    expect(fixture.draft.intents, isEmpty);
  });

  test("page creation inserts its book slot before connecting", () {
    final fixture = _pageCreationFixture();
    final item = skir.ItemId(value: "page:item");
    final staged = fixture.draft.fork()
      ..createPreparedResource(
        request: ResourceCreationRequest(
          id: fixture.page,
          initializationId: skir.InitializationRequestId(value: "create:page"),
          definition: fixture.pageResource,
          configuration: skir.TypeSelection.wrapComplete(fixture.sequenceUse),
          connections: [
            ResourceCreationConnection.collection(
              source: fixture.book,
              endpoint: fixture.bookEndpoint,
              containing: _fieldPath("pages"),
              item: item,
            ),
          ],
        ),
        prepared: skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(fixture.pageRecord),
          findings: const [],
        ),
      );

    expect(staged.intents, [
      isA<skir.EditIntent_createResourceWrapper>(),
      isA<skir.EditIntent_insertWrapper>(),
      isA<skir.EditIntent_connectRelationWrapper>(),
    ]);
    final insert = (staged.intents[1] as skir.EditIntent_insertWrapper).value;
    expect(insert.at.resource, fixture.book);
    expect(insert.at.path, _fieldPath("pages"));
    expect(insert.item.id, item);
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
      skir.ValueLocation(resource: fixture.page, path: _fieldPath("book")),
    )) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    expect(pageBook?.target.resource, fixture.book);
    final encoded = skir.PreparedEdit.serializer.toBytes(staged.prepare());
    final decoded = skir.PreparedEdit.serializer.fromBytes(encoded);
    expect(decoded.intents, hasLength(3));
    final pageBookLocation = skir.ValueLocation(
      resource: fixture.page,
      path: _fieldPath("book"),
    );
    expect(
      decoded.expectations.map(_factKey),
      containsAll({
        ("exists", fixture.page),
        (
          "configuration",
          skir.ValueLocation(
            resource: fixture.page,
            path: skir.ValuePath(segments: const []),
          ),
        ),
        ("configuration", pageBookLocation),
        ("value", pageBookLocation),
      }),
    );
  });

  test("page creation materializes an omitted direct reciprocal field", () {
    final fixture = _pageCreationFixture();
    final withoutBook = skir.AuthoringRecord(
      configuration: fixture.pageRecord.configuration,
      fields: fixture.pageRecord.fields.where((field) => field.name != "book"),
    );
    final staged = fixture.draft.fork()
      ..createPreparedResource(
        request: ResourceCreationRequest(
          id: fixture.page,
          initializationId: skir.InitializationRequestId(value: "create:page"),
          definition: fixture.pageResource,
          configuration: skir.TypeSelection.wrapComplete(fixture.sequenceUse),
          connections: [
            ResourceCreationConnection.collection(
              source: fixture.book,
              endpoint: fixture.bookEndpoint,
              containing: _fieldPath("pages"),
              item: skir.ItemId(value: "page:item"),
            ),
          ],
        ),
        prepared: skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(withoutBook),
          findings: const [],
        ),
      );

    final pageBook = switch (staged.read(
      skir.ValueLocation(resource: fixture.page, path: _fieldPath("book")),
    )) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    expect(pageBook?.target.resource, fixture.book);
  });

  test("commit rejection reports each located value problem", () {
    final response = skir.CommitPreparedEditResponse.wrapResult(
      skir.CommitResult.wrapRejected([
        skir.ValueProblem(
          location: skir.ValueLocation(
            resource: skir.ResourceId(value: "page:created"),
            path: skir.ValuePath(
              segments: [
                skir.PathSegment.createField(name: "book"),
                skir.PathSegment.createItem(
                  id: skir.ItemId(value: "page:item"),
                ),
              ],
            ),
          ),
          code: "item_missing",
        ),
      ]),
    );

    expect(
      response.rejectionMessage,
      "The Realm rejected this edit: item_missing at page:created:book.page:item",
    );
  });

  test("a missing value is an explicit null expectation", () {
    final fixture = _fixture();
    final at = skir.ValueLocation(
      resource: fixture.resource,
      path: _fieldPath("count"),
    );
    fixture.draft.set(at, skir.DataValue.wrapInteger("3"));
    expect(
      fixture.draft.expectations,
      contains(skir.EditExpectation.createValue(at: at, expected: null)),
    );
  });

  test("ordered collection edits preserve tags and intent order", () {
    final fixture = _fixture();
    final draft = fixture.draft;
    final inserted = skir.ListItem(
      id: skir.ItemId(value: "inserted"),
      value: skir.DataValue.wrapStringValue("second"),
    );

    draft
      ..insert(fixture.items, fixture.firstItem, inserted)
      ..move(fixture.items, inserted.id, null)
      ..remove(fixture.items, fixture.firstItem);

    expect(draft.intents, [
      isA<skir.EditIntent_insertWrapper>(),
      isA<skir.EditIntent_moveWrapper>(),
      isA<skir.EditIntent_removeWrapper>(),
    ]);
    final value =
        (draft.read(fixture.items) as PortablePathValue<skir.DataValue>).value
            as skir.DataValue_namedWrapper;
    expect(value.value.actualType, fixture.listType);
    final list = value.value.payload as skir.DataValue_listValueWrapper;
    expect(list.value.items.map((item) => item.id), [inserted.id]);
  });

  test("insert materializes an Unfilled collection from checked shape", () {
    final fixture = _collectionRepairFixture();
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

  test(
    "prepared collection insertion keeps one intent and located findings",
    () {
      final fixture = _collectionRepairFixture();
      final item = skir.ItemId(value: "item:record");
      final selection = skir.TypeSelection.wrapComplete(fixture.itemType);
      final request = skir.ValuePreparationRequest(
        id: skir.InitializationRequestId(value: "prepare:item"),
        catalog: fixture.draft.generation,
        target: skir.PreparationTarget.wrapRecord(selection),
        suppliedValue: skir.DataValue.createRecord(fields: const []),
        intentHash: "item:record",
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
      expect(fixture.draft.intents, [isA<skir.EditIntent_insertWrapper>()]);
      expect(
        fixture.draft.initializationFindings.single.relativePath,
        skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "records"),
            skir.PathSegment.createItem(id: item),
            skir.PathSegment.createField(name: "name"),
          ],
        ),
      );
    },
  );

  test("a missing nested parent records no write intent", () {
    final fixture = _fixture();
    final nested = skir.ValueLocation(
      resource: fixture.resource,
      path: skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "style"),
          skir.PathSegment.createField(name: "bold"),
        ],
      ),
    );

    final result = fixture.draft.set(nested, skir.DataValue.wrapBoolean(true));

    expect(result, isA<PortablePathUnavailable<skir.AuthoringRecord>>());
    expect(fixture.draft.intents, isEmpty);
  });

  test("writes capture existence and configuration at every ancestor", () {
    final fixture = _fixture();

    fixture.draft.set(fixture.title, skir.DataValue.wrapStringValue("changed"));

    final identities = fixture.draft.expectations.map(_factKey).toSet();
    expect(
      identities,
      containsAll({
        ("exists", fixture.resource),
        (
          "configuration",
          skir.ValueLocation(
            resource: fixture.resource,
            path: skir.ValuePath(segments: const []),
          ),
        ),
        ("value", fixture.title),
      }),
    );
  });

  test("nullable clear writes null while required clear writes unfilled", () {
    final fixture = _fixture();

    fixture.draft.clear(
      fixture.title,
      expected: skir.TypeUse.createNullable(
        value: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      ),
    );
    final nullable = fixture.draft.intents.last;
    expect(
      (nullable as skir.EditIntent_setValueWrapper).value.value,
      skir.DataValue.null_,
    );

    fixture.draft.clear(
      fixture.title,
      expected: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
    );
    final required = fixture.draft.intents.last;
    expect(
      (required as skir.EditIntent_setValueWrapper).value.value,
      skir.DataValue.unfilled,
    );
  });

  test("relation edits capture endpoint and incoming graph evidence", () {
    final fixture = _relationFixture();
    fixture.draft.connect(
      fixture.occurrence,
      fixture.newTarget,
      counterpart: skir.CounterpartChoice.wrapExisting(fixture.counterpart),
    );
    final relation = skir.RelationId(value: "test.relation");
    expect(
      fixture.draft.expectations.map(_factKey),
      containsAll([
        ("value", fixture.occurrence.id.location),
        ("exists", fixture.newTarget),
        ("links", fixture.occurrence.source, relation),
        ("links", fixture.newTarget, relation),
      ]),
    );
    expect(fixture.draft.links.single.second, fixture.newTarget);
    fixture.draft.disconnect(fixture.occurrence);
    expect(fixture.draft.links, isEmpty);
  });

  for (final reverse in [false, true]) {
    test(
      "collection relation ${reverse ? 'counterparts' : 'sources'} capture parent order evidence",
      () {
        final fixture = _pageCreationFixture();
        final edit = fixture.draft
          ..create(
            fixture.page,
            fixture.pageRecord,
            definition: fixture.pageResource,
          );
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
          target: skir.LinkTarget(
            resource: fixture.page,
            opposite: pageAt.path,
          ),
        );
        final pageOccurrence = skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: skir.EndpointId(value: "page.book"),
            location: pageAt,
          ),
          source: fixture.page,
          target: skir.LinkTarget(
            resource: fixture.book,
            opposite: bookAt.path,
          ),
        );
        edit.connect(
          reverse ? pageOccurrence : bookOccurrence,
          reverse ? fixture.book : fixture.page,
          counterpart: skir.CounterpartChoice.wrapExisting(
            reverse ? bookOccurrence : pageOccurrence,
          ),
        );
        expect(
          edit.expectations.map(_factKey),
          containsAll([("value", parent), ("configuration", parent)]),
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
      },
    );
  }

  test("collection relation disconnects capture parent order evidence", () {
    final fixture = _fixture();
    final item = skir.ValueLocation(
      resource: fixture.resource,
      path: skir.ValuePath(
        segments: [
          ...fixture.items.path.segments,
          skir.PathSegment.createItem(id: fixture.firstItem),
        ],
      ),
    );
    final occurrence = skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(
        endpoint: skir.EndpointId(value: "test.source"),
        location: item,
      ),
      source: fixture.resource,
      target: skir.LinkTarget(
        resource: skir.ResourceId(value: "resource:2"),
        opposite: null,
      ),
    );

    fixture.draft.disconnect(occurrence);

    final identities = fixture.draft.expectations.map(_factKey).toSet();
    expect(
      identities,
      containsAll({
        ("value", item),
        ("configuration", fixture.items),
        ("value", fixture.items),
        ("value", fixture.items),
      }),
    );
  });

  test(
    "retarget keeps one staged occurrence and leaves its baseline intact",
    () {
      final fixture = _relationFixture();
      final branch = fixture.draft.fork()
        ..connect(
          fixture.occurrence,
          fixture.newTarget,
          counterpart: skir.CounterpartChoice.wrapExisting(fixture.counterpart),
        );

      expect(fixture.draft.links.single.second.value, "resource:original");
      expect(
        branch.expectations.map(_factKey),
        contains((
          "links",
          fixture.originalOpposite.resource,
          fixture.draft.links.single.contract,
        )),
      );
      expect(branch.links, hasLength(1));
      expect(branch.links.single.first, fixture.occurrence.source);
      expect(branch.links.single.second, fixture.newTarget);
      expect(
        branch.links.single.firstLocation,
        fixture.occurrence.id.location.path,
      );
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

  test("delete enrolls exact relation and counterpart evidence", () {
    final fixture = _relationFixture();
    final deleted = fixture.occurrence.target.resource;
    final relation = fixture.draft.links.single.contract;
    final branch = fixture.draft.fork()..delete(deleted);
    final identities = branch.expectations.map(_factKey).toSet();

    expect(branch.resource(deleted), isNull);
    expect(branch.links, isEmpty);
    expect(branch.intents.single, isA<skir.EditIntent_deleteResourceWrapper>());
    expect(
      identities,
      containsAll({
        ("links", fixture.occurrence.source, relation),

        ("links", deleted, relation),
        ("exists", fixture.occurrence.source),
        (
          "configuration",
          skir.ValueLocation(
            resource: fixture.occurrence.source,
            path: skir.ValuePath(segments: const []),
          ),
        ),
        ("configuration", fixture.occurrence.id.location),
        ("value", fixture.occurrence.id.location),
      }),
    );
    expect(identities, isNot(contains(("links", fixture.newTarget, relation))));
  });

  test("cascade deletion observes an undeclared counterpart resource", () {
    final fixture = _relationFixture(
      firstDelete: skir.RelationDeletePolicy.cascade,
      includeOppositeLocation: false,
    );
    final cascaded = fixture.occurrence.target.resource;
    final branch = fixture.draft.fork()..delete(fixture.occurrence.source);
    final identities = branch.expectations.map(_factKey).toSet();

    expect(
      identities,
      containsAll({
        ("exists", cascaded),
        (
          "configuration",
          skir.ValueLocation(
            resource: cascaded,
            path: skir.ValuePath(segments: const []),
          ),
        ),
      }),
    );
  });

  test("retarget clears an earlier opposite in the same target", () {
    final fixture = _relationFixture();
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

  test("nested write materializes the captured containing field default", () {
    final fixture = _parentFixture(capturedStyle: true);

    final result = fixture.draft.set(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    expect(fixture.draft.intents, hasLength(2));
    final parent =
        (fixture.draft.intents.first as skir.EditIntent_setValueWrapper)
                .value
                .value
            as skir.DataValue_namedWrapper;
    final payload = parent.value.payload as skir.DataValue_recordWrapper;
    expect(
      payload.value.fields.singleWhere((field) => field.name == "bold").value,
      skir.DataValue.wrapBoolean(true),
    );
    final identities = fixture.draft.expectations.map(_factKey).toSet();
    expect(
      identities,
      contains((
        "configuration",
        skir.ValueLocation(
          resource: fixture.repetitions.resource,
          path: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "style")],
          ),
        ),
      )),
    );
  });

  test("nullable nested parent materializes before the child write", () {
    final fixture = _parentFixture(capturedStyle: true, nullableStyle: true);

    final result = fixture.draft.set(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    expect(fixture.draft.intents, hasLength(2));
  });

  test("dynamic parent uses the containing field prepared default", () async {
    final fixture = _parentFixture(
      capturedStyle: false,
      dynamicStyle: true,
      nullableStyle: true,
    );
    final styleUse = skir.NamedTypeUse(
      definition: _definition("Style"),
      arguments: const [],
    );
    skir.ValuePreparationRequest? observed;

    final result = await fixture.draft.setWithInitialization(
      fixture.repetitions,
      skir.DataValue.wrapInteger("3"),
      (request) async {
        observed = request;
        return skir.PreparedValue(
          content: skir.PreparedContent.wrapRecord(
            skir.AuthoringRecord(
              configuration: request.recordSelection,
              fields: [
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
              ],
            ),
          ),
          findings: const [],
        );
      },
    );

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    expect(observed, isNotNull);
    expect(observed!.recordSuppliedFields, isEmpty);
    expect(
      (observed!.recordSelection as skir.TypeSelection_completeWrapper)
          .value
          .definition,
      _definition("Action"),
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
      fixture.draft.expectations,
      contains(
        skir.EditExpectation.createValue(
          at: skir.ValueLocation(
            resource: fixture.repetitions.resource,
            path: skir.ValuePath(segments: const []),
          ),
          expected: skir.DataValue.createRecord(
            fields: fixture.snapshot.resources.single.content.fields,
          ),
        ),
      ),
    );
    expect(
      fields.singleWhere((field) => field.name == "repetitions").value,
      skir.DataValue.wrapInteger("3"),
    );
    expect(fixture.draft.intents, hasLength(2));
  });

  test(
    "dynamic containing type prepares its field before a startup child",
    () async {
      final fixture = _parentFixture(
        capturedStyle: false,
        dynamicContaining: true,
        nullableStyle: true,
      );
      final requests = <skir.ValuePreparationRequest>[];

      final result = await fixture.draft.setWithInitialization(
        fixture.repetitions,
        skir.DataValue.wrapInteger("3"),
        (request) async {
          requests.add(request);
          return _preparedContainingStyle(request, bold: true);
        },
      );

      expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
      expect(requests, hasLength(1));
      expect(
        (requests.single.recordSelection as skir.TypeSelection_completeWrapper)
            .value
            .definition,
        _definition("Action"),
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
    },
  );

  test(
    "prepared containing defaults retain original sibling evidence",
    () async {
      final fixture = _parentFixture(
        capturedStyle: false,
        dynamicContaining: true,
        nullableStyle: true,
      );
      final root = skir.ValueLocation(
        resource: fixture.repetitions.resource,
        path: skir.ValuePath(segments: const []),
      );

      final result = await fixture.draft.setWithInitialization(
        fixture.repetitions,
        skir.DataValue.wrapInteger("3"),
        (request) async => _preparedContainingStyle(request, bold: true),
      );

      expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
      expect(
        fixture.draft.expectations,
        contains(
          skir.EditExpectation.createValue(
            at: root,
            expected: skir.DataValue.createRecord(
              fields: fixture.snapshot.resources.single.content.fields,
            ),
          ),
        ),
      );
    },
  );

  test(
    "prepared parent request keeps one operation identity across retry",
    () async {
      final fixture = _parentFixture(
        capturedStyle: false,
        dynamicContaining: true,
        nullableStyle: true,
      );
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
          return _preparedContainingStyle(request, bold: true);
        },
      );

      expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
      expect(requests, hasLength(2));
      expect(requests[1].id, requests[0].id);
      expect(requests[1].intentHash, requests[0].intentHash);
    },
  );

  test(
    "a later deliberate initialization uses a fresh operation identity",
    () async {
      final fixture = _parentFixture(
        capturedStyle: false,
        dynamicContaining: true,
        nullableStyle: true,
      );
      final requests = <skir.ValuePreparationRequest>[];
      Future<skir.PreparedValue> prepare(
        skir.ValuePreparationRequest request,
      ) async {
        requests.add(request);
        return _preparedContainingStyle(request, bold: true);
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
      expect(requests[1].id, isNot(requests[0].id));
    },
  );

  test(
    "prepared parent work is discarded when the final path is absent",
    () async {
      final fixture = _parentFixture(
        capturedStyle: false,
        dynamicContaining: true,
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
        (request) async =>
            _preparedContainingStyle(request, bold: true, includeItems: true),
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
    final fixture = _parentFixture(
      capturedStyle: false,
      dynamicContaining: true,
      nullableStyle: true,
    );
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
            definition: _definition("Action"),
            arguments: const [],
          ),
        ),
        fields: const [],
      ),
    );
    response.complete(_preparedContainingStyle(preparationRequest, bold: true));

    final result = await pending;
    expect(result, isA<PortablePathUnavailable<skir.AuthoringRecord>>());
    expect(fixture.draft.resource(concurrent), isNotNull);
    expect(fixture.draft.intents, hasLength(1));
  });

  test("field scoped capture findings preserve an unfinished parent", () async {
    final fixture = _parentFixture(
      capturedStyle: false,
      dynamicContaining: true,
      dynamicStyle: true,
      nullableStyle: true,
    );
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
                  definition: _definition("Action"),
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
                definition: _definition("Style"),
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
    expect(invocation, 2);
    expect(fixture.draft.intents, hasLength(2));
    expect(
      fixture.draft.initializationFindings.last.relativePath,
      skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "style"),
          skir.PathSegment.createField(name: "repetitions"),
        ],
      ),
    );
    expect(
      formatPortableInitializationDiagnostic(
        fixture.draft.initializationFindings.last,
      ),
      "style.repetitions: The default could not be captured",
    );
  });

  test("failed collection child write rolls back parent materialization", () {
    final fixture = _parentFixture(capturedStyle: false, includeItems: true);
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

  test("uncaptured constructor defaults remain unfilled", () {
    final fixture = _parentFixture(capturedStyle: false);

    fixture.draft.set(fixture.bold, skir.DataValue.wrapBoolean(true));

    final parent =
        (fixture.draft.intents.first as skir.EditIntent_setValueWrapper)
                .value
                .value
            as skir.DataValue_namedWrapper;
    final payload = parent.value.payload as skir.DataValue_recordWrapper;
    expect(
      payload.value.fields
          .singleWhere((field) => field.name == "repetitions")
          .value,
      skir.DataValue.unfilled,
    );
  });

  test("inherited captured defaults use their declaration owner", () {
    final fixture = _parentFixture(capturedStyle: false, inheritedBold: true);

    fixture.draft.set(fixture.repetitions, skir.DataValue.wrapInteger("3"));

    final parent =
        (fixture.draft.intents.first as skir.EditIntent_setValueWrapper)
                .value
                .value
            as skir.DataValue_namedWrapper;
    final payload = parent.value.payload as skir.DataValue_recordWrapper;
    expect(
      payload.value.fields.singleWhere((field) => field.name == "bold").value,
      skir.DataValue.wrapBoolean(true),
    );
  });

  test("ordinary scalar defaults match Realm initialization", () {
    final fixture = _parentFixture(capturedStyle: false);

    fixture.draft.set(fixture.bold, skir.DataValue.wrapBoolean(true));

    final parent =
        (fixture.draft.intents.first as skir.EditIntent_setValueWrapper)
                .value
                .value
            as skir.DataValue_namedWrapper;
    final payload = parent.value.payload as skir.DataValue_recordWrapper;
    skir.DataValue field(String name) =>
        payload.value.fields.singleWhere((field) => field.name == name).value;

    expect(field("bytes"), isA<skir.DataValue_bytesWrapper>());
    expect(
      (field("bytes") as skir.DataValue_bytesWrapper).value,
      skir.ByteString.empty,
    );
    expect(field("duration"), isA<skir.DataValue_durationWrapper>());
    expect(
      (field(
        "duration",
      ) as skir.DataValue_durationWrapper).value.value.milliseconds,
      0,
    );
    expect(field("timestamp"), skir.DataValue.unfilled);
  });
}

({
  AuthoringEdit draft,
  skir.ValueLocation bold,
  skir.ValueLocation repetitions,
  skir.AuthoringState snapshot,
})
_parentFixture({
  required bool capturedStyle,
  bool dynamicContaining = false,
  bool dynamicStyle = false,
  bool inheritedBold = false,
  bool nullableStyle = false,
  bool includeItems = false,
  String generation = "catalog:parents",
}) {
  final root = _definition("Action");
  final style = _definition("Style");
  final baseStyle = _definition("BaseStyle");
  final rootUse = skir.NamedTypeUse(definition: root, arguments: const []);
  final styleUse = skir.NamedTypeUse(definition: style, arguments: const []);
  final styleOwner = skir.FieldOwner(definition: root, name: "style");
  final boldOwner = skir.FieldOwner(
    definition: inheritedBold ? baseStyle : style,
    name: "bold",
  );
  final repetitionsOwner = skir.FieldOwner(
    definition: style,
    name: "repetitions",
  );
  final bytesOwner = skir.FieldOwner(definition: style, name: "bytes");
  final durationOwner = skir.FieldOwner(definition: style, name: "duration");
  final timestampOwner = skir.FieldOwner(definition: style, name: "timestamp");
  final itemsOwner = skir.FieldOwner(definition: style, name: "items");
  final list = _definition("List");
  final styleTemplate = skir.TypeTemplate.wrapNamed(
    skir.NamedTypeTemplate(definition: style, arguments: const []),
  );
  final declaredStyleTemplate = nullableStyle
      ? skir.TypeTemplate.createNullable(value: styleTemplate)
      : styleTemplate;
  final styleValue = skir.DataValue.createNamed(
    actualType: styleUse,
    payload: skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(name: "bold", value: skir.DataValue.wrapBoolean(true)),
        skir.FieldValue(name: "repetitions", value: skir.DataValue.unfilled),
      ],
    ),
  );
  final catalogSnapshot = skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: generation),
    types: [
      skir.PublishedType(
        display: null,
        definition: skir.TypeDefinition(
          id: root,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              skir.FieldDeclaration(
                owner: styleOwner,
                type: declaredStyleTemplate,
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
          skir.EffectiveFieldTemplate(
            key: "style",
            owner: styleOwner,
            type: declaredStyleTemplate,
            rules: const [],
          ),
        ],
        ancestorTemplates: const [],
      ),
      skir.PublishedType(
        display: null,
        definition: skir.TypeDefinition(
          id: style,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              if (!inheritedBold)
                skir.FieldDeclaration(
                  owner: boldOwner,
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              skir.FieldDeclaration(
                owner: repetitionsOwner,
                type: skir.TypeTemplate.wrapScalar(
                  skir.ScalarKind.createInteger(
                    width: skir.IntegerWidth.signedThirtyTwo,
                  ),
                ),
                overrides: const [],
                hasConstructorDefault: true,
              ),
              skir.FieldDeclaration(
                owner: bytesOwner,
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.bytes),
                overrides: const [],
                hasConstructorDefault: false,
              ),
              skir.FieldDeclaration(
                owner: durationOwner,
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.duration),
                overrides: const [],
                hasConstructorDefault: false,
              ),
              skir.FieldDeclaration(
                owner: timestampOwner,
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.timestamp),
                overrides: const [],
                hasConstructorDefault: false,
              ),
              if (includeItems)
                skir.FieldDeclaration(
                  owner: itemsOwner,
                  type: skir.TypeTemplate.wrapNamed(
                    skir.NamedTypeTemplate(
                      definition: list,
                      arguments: const [],
                    ),
                  ),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
            ],
            abstract_: false,
          ),
          parents: inheritedBold
              ? [
                  skir.NamedTypeTemplate(
                    definition: baseStyle,
                    arguments: const [],
                  ),
                ]
              : const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: [
          skir.EffectiveFieldTemplate(
            key: "bold",
            owner: boldOwner,
            type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
            rules: const [],
          ),
          skir.EffectiveFieldTemplate(
            key: "repetitions",
            owner: repetitionsOwner,
            type: skir.TypeTemplate.wrapScalar(
              skir.ScalarKind.createInteger(
                width: skir.IntegerWidth.signedThirtyTwo,
              ),
            ),
            rules: const [],
          ),
          skir.EffectiveFieldTemplate(
            key: "bytes",
            owner: bytesOwner,
            type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.bytes),
            rules: const [],
          ),
          skir.EffectiveFieldTemplate(
            key: "duration",
            owner: durationOwner,
            type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.duration),
            rules: const [],
          ),
          skir.EffectiveFieldTemplate(
            key: "timestamp",
            owner: timestampOwner,
            type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.timestamp),
            rules: const [],
          ),
          if (includeItems)
            skir.EffectiveFieldTemplate(
              key: "items",
              owner: itemsOwner,
              type: skir.TypeTemplate.wrapNamed(
                skir.NamedTypeTemplate(definition: list, arguments: const []),
              ),
              rules: const [],
            ),
        ],
        ancestorTemplates: inheritedBold
            ? [
                skir.NamedTypeTemplate(
                  definition: baseStyle,
                  arguments: const [],
                ),
              ]
            : const [],
      ),
      if (inheritedBold)
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: baseStyle,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: boldOwner,
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
                  overrides: const [],
                  hasConstructorDefault: true,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: "bold",
              owner: boldOwner,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
              rules: const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
      if (includeItems)
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: list,
            parameters: const [],
            representation: skir.RepresentationTemplate.createSequence(
              item: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              kind: skir.CollectionKind.list,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
    ],
    relations: const [],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: [
      skir.InitializationDescriptor(
        definition: root,
        mode: dynamicContaining
            ? skir.InitializationMode.creation
            : skir.InitializationMode.startup,
        captured: capturedStyle
            ? [skir.CapturedDefault(field: styleOwner, value: styleValue)]
            : const [],
        diagnostics: const [],
      ),
      skir.InitializationDescriptor(
        definition: style,
        mode: dynamicStyle
            ? skir.InitializationMode.creation
            : skir.InitializationMode.startup,
        captured: inheritedBold
            ? [
                skir.CapturedDefault(
                  field: boldOwner,
                  value: skir.DataValue.wrapBoolean(true),
                ),
              ]
            : const [],
        diagnostics: const [],
      ),
    ],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final resource = skir.ResourceId(value: "resource:parent");
  final snapshot = skir.AuthoringState(
    generation: catalogSnapshot.generation,
    resources: [
      skir.AuthoringResource(
        id: resource,
        definition: skir.ResourceDefinitionId(value: "test.action"),
        content: skir.AuthoringRecord(
          configuration: skir.TypeSelection.wrapComplete(rootUse),
          fields: [
            skir.FieldValue(name: "style", value: skir.DataValue.unfilled),
          ],
        ),
      ),
    ],
    links: const [],
    findings: const [],
  );
  skir.ValueLocation location(String field) => skir.ValueLocation(
    resource: resource,
    path: skir.ValuePath(
      segments: [
        skir.PathSegment.createField(name: "style"),
        skir.PathSegment.createField(name: field),
      ],
    ),
  );
  return (
    draft: AuthoringEdit.fromState(
      snapshot,
      catalog: CheckedEditorCatalog(catalogSnapshot),
    ),
    bold: location("bold"),
    repetitions: location("repetitions"),
    snapshot: snapshot,
  );
}

skir.PreparedValue _preparedContainingStyle(
  skir.ValuePreparationRequest request, {
  required bool bold,
  bool includeItems = false,
}) {
  final fields = <skir.FieldValue>[
    skir.FieldValue(name: "bold", value: skir.DataValue.wrapBoolean(bold)),
    skir.FieldValue(name: "repetitions", value: skir.DataValue.unfilled),
    if (includeItems)
      skir.FieldValue(
        name: "items",
        value: skir.DataValue.createNamed(
          actualType: skir.NamedTypeUse(
            definition: _definition("List"),
            arguments: const [],
          ),
          payload: skir.DataValue.createListValue(items: const []),
        ),
      ),
  ];
  return skir.PreparedValue(
    content: skir.PreparedContent.wrapRecord(
      skir.AuthoringRecord(
        configuration: request.recordSelection,
        fields: [
          skir.FieldValue(
            name: "style",
            value: skir.DataValue.createNamed(
              actualType: skir.NamedTypeUse(
                definition: _definition("Style"),
                arguments: const [],
              ),
              payload: skir.DataValue.createRecord(fields: fields),
            ),
          ),
        ],
      ),
    ),
    findings: const [],
  );
}

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

({
  AuthoringEdit draft,
  skir.ResourceId book,
  skir.ResourceId page,
  skir.ResourceDefinitionId pageResource,
  skir.EndpointId bookEndpoint,
  skir.NamedTypeUse sequenceUse,
  skir.AuthoringRecord pageRecord,
})
_pageCreationFixture() {
  final book = _definition("Book");
  final page = _definition("Page");
  final sequence = _definition("SequencePage");
  final pages = _definition("PageList");
  final bookLink = _definition("BookPagesBook");
  final pageLink = _definition("BookPagesPage");
  final bookEndpoint = skir.EndpointId(value: "book.pages");
  final pageEndpoint = skir.EndpointId(value: "page.book");
  final bookUse = skir.NamedTypeUse(definition: book, arguments: const []);
  final sequenceUse = skir.NamedTypeUse(
    definition: sequence,
    arguments: const [],
  );
  final pagesUse = skir.NamedTypeUse(definition: pages, arguments: const []);
  skir.NamedTypeTemplate template(skir.TypeDefinitionId definition) =>
      skir.NamedTypeTemplate(definition: definition, arguments: const []);
  skir.TypeTemplate named(skir.TypeDefinitionId definition) =>
      skir.TypeTemplate.wrapNamed(template(definition));
  skir.FieldDeclaration field(
    skir.TypeDefinitionId owner,
    String name,
    skir.TypeTemplate type,
  ) => skir.FieldDeclaration(
    owner: skir.FieldOwner(definition: owner, name: name),
    type: type,
    overrides: const [],
    hasConstructorDefault: false,
  );
  skir.EffectiveFieldTemplate effective(
    skir.TypeDefinitionId owner,
    String name,
    skir.TypeTemplate type,
  ) => skir.EffectiveFieldTemplate(
    key: name,
    owner: skir.FieldOwner(definition: owner, name: name),
    type: type,
    rules: const [],
  );
  skir.PublishedType published(
    skir.TypeDefinitionId id,
    skir.RepresentationTemplate representation, {
    List<skir.NamedTypeTemplate> parents = const [],
    List<skir.EffectiveFieldTemplate> fields = const [],
  }) => skir.PublishedType(
    display: null,
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: representation,
      parents: parents,
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: fields,
    ancestorTemplates: parents,
  );
  final bookPagesField = field(book, "pages", named(pages));
  final pageBookField = field(page, "book", named(pageLink));
  final pageNameField = field(
    page,
    "name",
    skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  );
  final pageParent = template(page);
  final generation = skir.CatalogGeneration(value: "catalog:page creation");
  final pageResource = skir.ResourceDefinitionId(value: "typewriter.page");
  final snapshot = skir.EditorCatalogWireSnapshot(
    generation: generation,
    types: [
      published(
        book,
        skir.RepresentationTemplate.createRecord(
          fields: [bookPagesField],
          abstract_: false,
        ),
        fields: [effective(book, "pages", named(pages))],
      ),
      published(
        page,
        skir.RepresentationTemplate.createRecord(
          fields: [pageBookField, pageNameField],
          abstract_: true,
        ),
        fields: [
          effective(page, "book", named(pageLink)),
          effective(
            page,
            "name",
            skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          ),
        ],
      ),
      published(
        sequence,
        skir.RepresentationTemplate.createRecord(
          fields: const [],
          abstract_: false,
        ),
        parents: [pageParent],
        fields: [
          effective(page, "book", named(pageLink)),
          effective(
            page,
            "name",
            skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          ),
        ],
      ),
      published(
        pages,
        skir.RepresentationTemplate.createSequence(
          item: named(bookLink),
          kind: skir.CollectionKind.list,
        ),
      ),
      published(
        bookLink,
        skir.RepresentationTemplate.createLink(
          endpoint: bookEndpoint,
          target: named(page),
        ),
      ),
      published(
        pageLink,
        skir.RepresentationTemplate.createLink(
          endpoint: pageEndpoint,
          target: named(book),
        ),
      ),
    ],
    relations: [
      skir.RelationContract(
        id: skir.RelationId(value: "book.pages"),
        first: skir.EndpointDefinition(
          id: bookEndpoint,
          slot: skir.EndpointSlot.first,
          resource: template(book),
          cardinality: skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.cascade,
        ),
        second: skir.EndpointDefinition(
          id: pageEndpoint,
          slot: skir.EndpointSlot.second,
          resource: template(page),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: const [],
      ),
    ],
    resourceDefinitions: [
      skir.AuthoringResourceDefinition(
        id: skir.ResourceDefinitionId(value: "typewriter.book"),
        root: book,
        navigationHandler: "",
      ),
      skir.AuthoringResourceDefinition(
        id: pageResource,
        root: page,
        navigationHandler: "",
      ),
    ],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: [
      skir.EndpointBindingTemplate(
        endpoint: bookEndpoint,
        containingResource: template(book),
        valueOwner: book,
        relativePath: skir.RelativeFieldPattern(
          segments: [
            skir.FieldPatternSegment.createField(name: "pages"),
            skir.FieldPatternSegment.items,
          ],
        ),
        target: named(page),
        containsCollection: true,
      ),
      skir.EndpointBindingTemplate(
        endpoint: pageEndpoint,
        containingResource: template(page),
        valueOwner: page,
        relativePath: skir.RelativeFieldPattern(
          segments: [skir.FieldPatternSegment.createField(name: "book")],
        ),
        target: named(book),
        containsCollection: false,
      ),
      skir.EndpointBindingTemplate(
        endpoint: pageEndpoint,
        containingResource: template(sequence),
        valueOwner: sequence,
        relativePath: skir.RelativeFieldPattern(
          segments: [skir.FieldPatternSegment.createField(name: "book")],
        ),
        target: named(book),
        containsCollection: false,
      ),
    ],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final bookId = skir.ResourceId(value: "book:original");
  final pageId = skir.ResourceId(value: "page:created");
  final bookRecord = skir.AuthoringRecord(
    configuration: skir.TypeSelection.wrapComplete(bookUse),
    fields: [
      skir.FieldValue(
        name: "pages",
        value: skir.DataValue.createNamed(
          actualType: pagesUse,
          payload: skir.DataValue.createListValue(items: const []),
        ),
      ),
    ],
  );
  final pageRecord = skir.AuthoringRecord(
    configuration: skir.TypeSelection.wrapComplete(sequenceUse),
    fields: [
      skir.FieldValue(name: "book", value: skir.DataValue.unfilled),
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue("Verification page"),
      ),
    ],
  );
  final authored = skir.AuthoringState(
    generation: generation,
    resources: [
      skir.AuthoringResource(
        id: bookId,
        definition: skir.ResourceDefinitionId(value: "typewriter.book"),
        content: bookRecord,
      ),
    ],
    links: const [],
    findings: const [],
  );
  return (
    draft: AuthoringEdit.fromState(
      authored,
      catalog: CheckedEditorCatalog(snapshot),
    ),
    book: bookId,
    page: pageId,
    pageResource: pageResource,
    bookEndpoint: bookEndpoint,
    sequenceUse: sequenceUse,
    pageRecord: pageRecord,
  );
}

skir.ValuePath _fieldPath(String name) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]);

({
  AuthoringEdit draft,
  skir.LinkOccurrence occurrence,
  skir.LinkOccurrence counterpart,
  skir.LinkOccurrence alternateCounterpart,
  skir.ResourceId newTarget,
  skir.ValueLocation originalOpposite,
  skir.ValueLocation newOpposite,
  skir.ValueLocation alternateOpposite,
})
_relationFixture({
  skir.RelationDeletePolicy firstDelete = skir.RelationDeletePolicy.clear,
  skir.RelationDeletePolicy secondDelete = skir.RelationDeletePolicy.clear,
  bool includeOppositeLocation = true,
}) {
  final fixture = _fixture();
  final endpoint = skir.EndpointId(value: "test.source");
  final opposite = skir.EndpointId(value: "test.target");
  final relation = skir.RelationId(value: "test.relation");
  final originalTarget = skir.ResourceId(value: "resource:original");
  final newTarget = skir.ResourceId(value: "resource:new");
  final oppositePath = skir.ValuePath(
    segments: [skir.PathSegment.createField(name: "back")],
  );
  final originalOpposite = skir.ValueLocation(
    resource: originalTarget,
    path: oppositePath,
  );
  final newOpposite = skir.ValueLocation(
    resource: newTarget,
    path: oppositePath,
  );
  final alternateOpposite = skir.ValueLocation(
    resource: newTarget,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "back2")],
    ),
  );
  final linkType = skir.NamedTypeUse(
    definition: _definition("Reference"),
    arguments: const [],
  );
  final originalResource = fixture.snapshot.resources.single;
  final linkedRecord = skir.AuthoringRecord(
    configuration: originalResource.content.configuration,
    fields: [
      for (final field in originalResource.content.fields)
        skir.FieldValue(
          name: field.name,
          value: field.name == "title"
              ? skir.DataValue.createNamed(
                  actualType: linkType,
                  payload: skir.DataValue.createLink(
                    endpoint: endpoint,
                    target: skir.LinkTarget(
                      resource: originalTarget,
                      opposite: includeOppositeLocation ? oppositePath : null,
                    ),
                  ),
                )
              : field.value,
        ),
    ],
  );
  final snapshot = skir.AuthoringState(
    generation: fixture.snapshot.generation,
    resources: [
      skir.AuthoringResource(
        id: originalResource.id,
        definition: originalResource.definition,
        content: linkedRecord,
      ),
      for (final target in [originalTarget, newTarget])
        skir.AuthoringResource(
          id: target,
          definition: originalResource.definition,
          content: skir.AuthoringRecord(
            configuration: originalResource.content.configuration,
            fields: [
              for (final name in ["back", "back2"])
                skir.FieldValue(
                  name: name,
                  value: includeOppositeLocation
                      ? skir.DataValue.createNamed(
                          actualType: linkType,
                          payload: skir.DataValue.createLink(
                            endpoint: opposite,
                            target: skir.LinkTarget(
                              resource: fixture.resource,
                              opposite: fixture.title.path,
                            ),
                          ),
                        )
                      : skir.DataValue.unfilled,
                ),
            ],
          ),
        ),
    ],
    links: [
      skir.LinkProjection(
        contract: relation,
        first: fixture.resource,
        second: originalTarget,
        firstLocation: fixture.title.path,
        secondLocation: includeOppositeLocation ? oppositePath : null,
      ),
    ],
    findings: fixture.snapshot.findings,
  );
  final selection = skir.NamedTypeTemplate(
    definition: fixture.listType.definition,
    arguments: const [],
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: fixture.snapshot.generation,
      types: const [],
      relations: [
        skir.RelationContract(
          id: relation,
          first: skir.EndpointDefinition(
            id: endpoint,
            slot: skir.EndpointSlot.first,
            resource: selection,
            cardinality: skir.EndpointCardinality.one,
            onDelete: firstDelete,
          ),
          second: skir.EndpointDefinition(
            id: opposite,
            slot: skir.EndpointSlot.second,
            resource: selection,
            cardinality: skir.EndpointCardinality.many,
            onDelete: secondDelete,
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
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  return (
    draft: AuthoringEdit.fromState(snapshot, catalog: checked),
    occurrence: skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(endpoint: endpoint, location: fixture.title),
      source: fixture.resource,
      target: skir.LinkTarget(
        resource: originalTarget,
        opposite: includeOppositeLocation ? oppositePath : null,
      ),
    ),
    counterpart: skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(endpoint: opposite, location: newOpposite),
      source: newTarget,
      target: skir.LinkTarget(
        resource: fixture.resource,
        opposite: fixture.title.path,
      ),
    ),
    alternateCounterpart: skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(
        endpoint: opposite,
        location: alternateOpposite,
      ),
      source: newTarget,
      target: skir.LinkTarget(
        resource: fixture.resource,
        opposite: fixture.title.path,
      ),
    ),
    newTarget: newTarget,
    originalOpposite: originalOpposite,
    newOpposite: newOpposite,
    alternateOpposite: alternateOpposite,
  );
}

({
  AuthoringEdit draft,
  skir.ValueLocation texts,
  skir.ValueLocation records,
  skir.NamedTypeUse textSet,
  skir.NamedTypeUse itemType,
})
_collectionRepairFixture() {
  final root = _definition("CollectionRoot");
  final textSetDefinition = _definition("TextSet");
  final recordSetDefinition = _definition("RecordSet");
  final itemDefinition = _definition("CollectionItem");
  final rootUse = skir.NamedTypeUse(definition: root, arguments: const []);
  final textSet = skir.NamedTypeUse(
    definition: textSetDefinition,
    arguments: const [],
  );
  final itemType = skir.NamedTypeUse(
    definition: itemDefinition,
    arguments: const [],
  );
  final textsOwner = skir.FieldOwner(definition: root, name: "texts");
  final recordsOwner = skir.FieldOwner(definition: root, name: "records");
  final nameOwner = skir.FieldOwner(definition: itemDefinition, name: "name");
  final textSetTemplate = skir.TypeTemplate.createNamed(
    definition: textSetDefinition,
    arguments: const [],
  );
  final recordSetTemplate = skir.TypeTemplate.createNamed(
    definition: recordSetDefinition,
    arguments: const [],
  );
  final itemTemplate = skir.TypeTemplate.createNamed(
    definition: itemDefinition,
    arguments: const [],
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
  final catalogSnapshot = skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "catalog:collection-repair"),
    types: [
      published(
        skir.TypeDefinition(
          id: root,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              skir.FieldDeclaration(
                owner: textsOwner,
                type: textSetTemplate,
                overrides: const [],
                hasConstructorDefault: false,
              ),
              skir.FieldDeclaration(
                owner: recordsOwner,
                type: recordSetTemplate,
                overrides: const [],
                hasConstructorDefault: false,
              ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        [
          skir.EffectiveFieldTemplate(
            key: "texts",
            owner: textsOwner,
            type: textSetTemplate,
            rules: const [],
          ),
          skir.EffectiveFieldTemplate(
            key: "records",
            owner: recordsOwner,
            type: recordSetTemplate,
            rules: const [],
          ),
        ],
      ),
      published(
        skir.TypeDefinition(
          id: textSetDefinition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createSequence(
            item: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            kind: skir.CollectionKind.set_,
          ),
          parents: const [],
        ),
        const [],
      ),
      published(
        skir.TypeDefinition(
          id: recordSetDefinition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createSequence(
            item: itemTemplate,
            kind: skir.CollectionKind.set_,
          ),
          parents: const [],
        ),
        const [],
      ),
      published(
        skir.TypeDefinition(
          id: itemDefinition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              skir.FieldDeclaration(
                owner: nameOwner,
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                overrides: const [],
                hasConstructorDefault: true,
              ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        [
          skir.EffectiveFieldTemplate(
            key: "name",
            owner: nameOwner,
            type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            rules: const [],
          ),
        ],
      ),
    ],
    relations: const [],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final resource = skir.ResourceId(value: "resource:collection-repair");
  final snapshot = skir.AuthoringState(
    generation: catalogSnapshot.generation,
    resources: [
      skir.AuthoringResource(
        id: resource,
        definition: skir.ResourceDefinitionId(value: "test.collection"),
        content: skir.AuthoringRecord(
          configuration: skir.TypeSelection.wrapComplete(rootUse),
          fields: [
            skir.FieldValue(name: "texts", value: skir.DataValue.unfilled),
            skir.FieldValue(name: "records", value: skir.DataValue.unfilled),
          ],
        ),
      ),
    ],
    links: const [],
    findings: const [],
  );
  skir.ValueLocation location(String field) => skir.ValueLocation(
    resource: resource,
    path: skir.ValuePath(segments: [skir.PathSegment.createField(name: field)]),
  );
  return (
    draft: AuthoringEdit.fromState(
      snapshot,
      catalog: CheckedEditorCatalog(catalogSnapshot),
    ),
    texts: location("texts"),
    records: location("records"),
    textSet: textSet,
    itemType: itemType,
  );
}

({
  AuthoringEdit draft,
  skir.ResourceId resource,
  skir.ValueLocation title,
  skir.ValueLocation items,
  skir.ItemId firstItem,
  skir.NamedTypeUse listType,
  skir.EditExpectation titleObservation,
  skir.InputToken absent,
  skir.AuthoringState snapshot,
})
_fixture() {
  final resource = skir.ResourceId(value: "resource:1");
  final title = skir.ValueLocation(
    resource: resource,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "title")],
    ),
  );
  final items = skir.ValueLocation(
    resource: resource,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "items")],
    ),
  );
  final firstItem = skir.ItemId(value: "first");
  final listType = skir.NamedTypeUse(
    definition: skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "typewriter",
        name: "List",
      ),
      revision: 1,
    ),
    arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
  );
  final record = skir.AuthoringRecord(
    configuration: skir.TypeSelection.unknown,
    fields: [
      skir.FieldValue(
        name: "title",
        value: skir.DataValue.wrapStringValue("original"),
      ),
      skir.FieldValue(
        name: "items",
        value: skir.DataValue.createNamed(
          actualType: listType,
          payload: skir.DataValue.createListValue(
            items: [
              skir.ListItem(
                id: firstItem,
                value: skir.DataValue.wrapStringValue("first"),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  final titleObservation = skir.EditExpectation.createValue(
    at: title,
    expected: skir.DataValue.wrapStringValue("original"),
  );
  final absent = skir.InputToken(value: "absent");
  final snapshot = skir.AuthoringState(
    generation: skir.CatalogGeneration(value: "catalog:1"),
    resources: [
      skir.AuthoringResource(
        id: resource,
        definition: skir.ResourceDefinitionId(value: "test.resource"),
        content: record,
      ),
    ],
    links: const [],
    findings: const [],
  );
  return (
    draft: AuthoringEdit.fromState(snapshot),
    resource: resource,
    title: title,
    items: items,
    firstItem: firstItem,
    listType: listType,
    titleObservation: titleObservation,
    absent: absent,
    snapshot: snapshot,
  );
}

Object _factKey(skir.EditExpectation fact) => switch (fact) {
  skir.EditExpectation_valueWrapper(value: final value) => ("value", value.at),
  skir.EditExpectation_configurationWrapper(value: final value) => (
    "configuration",
    value.at,
  ),
  skir.EditExpectation_resourceExistsWrapper(value: final value) => (
    "exists",
    value.id,
  ),
  skir.EditExpectation_resourceWrapper(value: final value) => (
    "resource",
    value.id,
  ),
  skir.EditExpectation_resourceIdsWrapper() => "resourceIds",
  skir.EditExpectation_linksWrapper(value: final value) => (
    "links",
    value.resource,
    value.contract,
  ),
  _ => throw StateError("Unknown expectation"),
};
