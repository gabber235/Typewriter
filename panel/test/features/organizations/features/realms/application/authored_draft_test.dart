import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:skir_client/skir_client.dart" show ByteString;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring_facts.dart"
    as facts;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/duration.dart"
    as kernel;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("expression edits enroll reads only after the mutation succeeds", () {
    final fixture = _fixture();
    final read = PortableExpressionRead(
      types.ExpressionBindingId(value: "configured_value"),
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
          branch.set(fixture.title, types.DataValue.wrapStringValue("changed"))
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
      types.DataValue.wrapStringValue("changed"),
    );
    expect(updated, isA<PortablePathValue<types.AuthoringRecord>>());
    final read = draft.read(fixture.title);

    expect(
      (read as PortablePathValue<types.DataValue>).value,
      types.DataValue.wrapStringValue("changed"),
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
    fixture.draft.set(
      fixture.title,
      types.DataValue.wrapStringValue("changed"),
    );

    final prepared = fixture.draft.prepare();
    fixture.draft.set(fixture.title, types.DataValue.wrapStringValue("later"));

    expect(prepared.catalog, fixture.draft.generation);
    expect(prepared.expectations, contains(fixture.titleObservation));
    expect(prepared.intents, hasLength(1));
  });

  test("isolated edit forks never mutate the session baseline", () {
    final fixture = _fixture();
    final first = fixture.draft.fork();
    final second = fixture.draft.fork();

    first.set(fixture.title, types.DataValue.wrapStringValue("first"));
    second.set(fixture.title, types.DataValue.wrapStringValue("second"));

    expect(fixture.draft.intents, isEmpty);
    expect(
      (fixture.draft.read(
        fixture.title,
      ) as PortablePathValue<types.DataValue>).value,
      types.DataValue.wrapStringValue("original"),
    );
    expect(first.intents, hasLength(1));
    expect(second.intents, hasLength(1));
    expect(
      (first.read(fixture.title) as PortablePathValue<types.DataValue>).value,
      types.DataValue.wrapStringValue("first"),
    );
    expect(
      (second.read(fixture.title) as PortablePathValue<types.DataValue>).value,
      types.DataValue.wrapStringValue("second"),
    );
  });

  test("forks preserve staged history and isolate later changes", () {
    final fixture = _fixture();
    fixture.draft.set(fixture.title, types.DataValue.wrapStringValue("first"));
    final evidence = fixture.draft.expectations.toList(growable: false);
    final branch = fixture.draft.fork()
      ..set(fixture.title, types.DataValue.wrapStringValue("second"));

    expect(branch.intents, hasLength(2));
    expect(branch.expectations, containsAll(evidence));
    expect(
      (branch.read(fixture.title) as PortablePathValue<types.DataValue>).value,
      types.DataValue.wrapStringValue("second"),
    );
    expect(fixture.draft.intents, hasLength(1));
    expect(
      (fixture.draft.read(
        fixture.title,
      ) as PortablePathValue<types.DataValue>).value,
      types.DataValue.wrapStringValue("first"),
    );
  });

  test("cancelled creation discards its isolated resource and intents", () {
    final fixture = _fixture();
    final created = types.ResourceId(value: "resource:created");
    final record = fixture.snapshot.resources.single.content;
    final staged = stageResourceCreation(
      baseline: fixture.draft,
      request: ResourceCreationRequest(
        id: created,
        initializationId: types.InitializationRequestId(value: "create:1"),
        definition: catalog.ResourceDefinitionId(value: "test.resource"),
        configuration: record.configuration,
      ),
      prepared: catalog.PreparedCreation(record: record, findings: const []),
    );

    expect(staged.resource(created), record);
    expect(staged.intents, hasLength(1));
    expect(fixture.draft.resource(created), isNull);
    expect(fixture.draft.intents, isEmpty);
  });

  test("page creation inserts its book slot before connecting", () {
    final fixture = _pageCreationFixture();
    final item = types.ItemId(value: "page:item");
    final staged = stageResourceCreation(
      baseline: fixture.draft,
      request: ResourceCreationRequest(
        id: fixture.page,
        initializationId: types.InitializationRequestId(value: "create:page"),
        definition: fixture.pageResource,
        configuration: types.TypeSelection.wrapComplete(fixture.sequenceUse),
        connections: [
          ResourceCreationConnection.collection(
            source: fixture.book,
            endpoint: fixture.bookEndpoint,
            containing: _fieldPath("pages"),
            item: item,
          ),
        ],
      ),
      prepared: catalog.PreparedCreation(
        record: fixture.pageRecord,
        findings: const [],
      ),
    );

    expect(staged.intents, [
      isA<authoring.EditIntent_createResourceWrapper>(),
      isA<authoring.EditIntent_insertWrapper>(),
      isA<authoring.EditIntent_connectRelationWrapper>(),
    ]);
    final insert =
        (staged.intents[1] as authoring.EditIntent_insertWrapper).value;
    expect(insert.at.resource, fixture.book);
    expect(insert.at.path, _fieldPath("pages"));
    expect(insert.item.id, item);
    final bookLink = switch (staged.read(
      types.ValueLocation(
        resource: fixture.book,
        path: types.ValuePath(
          segments: [
            types.PathSegment.createField(name: "pages"),
            types.PathSegment.createItem(id: item),
          ],
        ),
      ),
    )) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    expect(bookLink?.target.resource, fixture.page);
    final pageBook = switch (staged.read(
      types.ValueLocation(resource: fixture.page, path: _fieldPath("book")),
    )) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    expect(pageBook?.target.resource, fixture.book);
    final encoded = authoring.PreparedEdit.serializer.toBytes(staged.prepare());
    final decoded = authoring.PreparedEdit.serializer.fromBytes(encoded);
    expect(decoded.intents, hasLength(3));
    final pageBookLocation = types.ValueLocation(
      resource: fixture.page,
      path: _fieldPath("book"),
    );
    expect(
      decoded.expectations.map(_factKey),
      containsAll(
        {
          ("exists", fixture.page),
          (
            "configuration",
            types.ValueLocation(
              resource: fixture.page,
              path: types.ValuePath(segments: const []),
            ),
          ),
          ("configuration", pageBookLocation),
          ("value", pageBookLocation),
        },
      ),
    );
  });

  test("page creation materializes an omitted direct reciprocal field", () {
    final fixture = _pageCreationFixture();
    final withoutBook = types.AuthoringRecord(
      configuration: fixture.pageRecord.configuration,
      fields: fixture.pageRecord.fields.where((field) => field.name != "book"),
    );
    final staged = stageResourceCreation(
      baseline: fixture.draft,
      request: ResourceCreationRequest(
        id: fixture.page,
        initializationId: types.InitializationRequestId(value: "create:page"),
        definition: fixture.pageResource,
        configuration: types.TypeSelection.wrapComplete(fixture.sequenceUse),
        connections: [
          ResourceCreationConnection.collection(
            source: fixture.book,
            endpoint: fixture.bookEndpoint,
            containing: _fieldPath("pages"),
            item: types.ItemId(value: "page:item"),
          ),
        ],
      ),
      prepared: catalog.PreparedCreation(
        record: withoutBook,
        findings: const [],
      ),
    );

    final pageBook = switch (staged.read(
      types.ValueLocation(resource: fixture.page, path: _fieldPath("book")),
    )) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    expect(pageBook?.target.resource, fixture.book);
  });

  test("commit rejection reports each located value problem", () {
    final response = authoring.CommitPreparedEditResponse.wrapResult(
      authoring.CommitResult.wrapRejected([
        diagnostic.ValueProblem(
          location: types.ValueLocation(
            resource: types.ResourceId(value: "page:created"),
            path: types.ValuePath(
              segments: [
                types.PathSegment.createField(name: "book"),
                types.PathSegment.createItem(
                  id: types.ItemId(value: "page:item"),
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

  test("a catalog change requires preparing against the new catalog", () {
    final fixture = _fixture();
    fixture.draft.set(fixture.title, types.DataValue.wrapStringValue("edit"));
    final next = authoring.AuthoringState(
      generation: types.CatalogGeneration(value: "replacement"),
      resources: fixture.snapshot.resources,
      links: fixture.snapshot.links,
      findings: fixture.snapshot.findings,
    );
    expect(
      fixture.draft.rebaseOnto(AuthoredDraft.fromState(next)),
      isA<AuthoredDraftRebaseFailed>(),
    );
  });

  test(
    "independent field changes and restored expected values remain compatible",
    () {
      final fixture = _fixture();
      fixture.draft.set(fixture.title, types.DataValue.wrapStringValue("edit"));
      final next = _stateWithFields(fixture.snapshot, {
        "description": types.DataValue.wrapStringValue("other edit"),
      });
      expect(
        fixture.draft.rebaseOnto(AuthoredDraft.fromState(next)),
        isA<AuthoredDraftRebased>(),
      );
      final changed = _stateWithFields(next, {
        "title": types.DataValue.wrapStringValue("Story"),
      });
      expect(
        fixture.draft.rebaseOnto(AuthoredDraft.fromState(changed)),
        isA<AuthoredDraftRebaseConflict>(),
      );
      final restored = _stateWithFields(changed, {
        "title": types.DataValue.wrapStringValue("original"),
      });
      expect(
        fixture.draft.rebaseOnto(AuthoredDraft.fromState(restored)),
        isA<AuthoredDraftRebased>(),
      );
    },
  );

  test("record field order is irrelevant while collection identities and order remain guarded", () {
    final fixture = _fixture();
    final root = types.ValueLocation(
      resource: fixture.resource,
      path: types.ValuePath(segments: const []),
    );
    fixture.draft.read(root);
    fixture.draft.set(fixture.title, types.DataValue.wrapStringValue("edit"));
    final resource = fixture.snapshot.resources.single;
    final reordered = authoring.AuthoringState(
      generation: fixture.snapshot.generation,
      links: fixture.snapshot.links,
      findings: const [],
      resources: [
        authoring.AuthoringResource(
          id: resource.id,
          definition: resource.definition,
          content: types.AuthoringRecord(
            configuration: resource.content.configuration,
            fields: resource.content.fields.toList().reversed,
          ),
        ),
      ],
    );
    expect(
      fixture.draft.rebaseOnto(AuthoredDraft.fromState(reordered)),
      isA<AuthoredDraftRebased>(),
    );
    final changed = _stateWithFields(reordered, {
      "items": types.DataValue.createNamed(
        actualType: fixture.listType,
        payload: types.DataValue.createListValue(
          items: [
            types.ListItem(
              id: types.ItemId(value: "replacement"),
              value: types.DataValue.wrapStringValue("first"),
            ),
          ],
        ),
      ),
    });
    expect(
      fixture.draft.rebaseOnto(AuthoredDraft.fromState(changed)),
      isA<AuthoredDraftRebaseConflict>(),
    );
  });

  test("changed tracked reads reject a dependent edit", () {
    final fixture = _fixture();
    final input = types.ValueLocation(
      resource: fixture.resource,
      path: _fieldPath("computedInput"),
    );
    fixture.draft
      ..read(input)
      ..set(fixture.title, types.DataValue.wrapStringValue("computed"));
    final changed = _stateWithFields(fixture.snapshot, {
      "computedInput": types.DataValue.wrapStringValue("new"),
    });
    final conflict = fixture.draft.rebaseOnto(
      AuthoredDraft.fromState(changed),
    ) as AuthoredDraftRebaseConflict;
    expect(_factKey(conflict.expected), ("value", input));
  });

  test("accepted prefix recovery preserves a conflicting tail read", () {
    final fixture = _fixture();
    final input = types.ValueLocation(
      resource: fixture.resource,
      path: _fieldPath("computedInput"),
    );
    fixture.draft.set(fixture.title, types.DataValue.wrapStringValue("prefix"));
    final count = fixture.draft.intents.length;
    fixture.draft.stageExpressionEdit(
      [
        PortableExpressionRead(
          types.ExpressionBindingId(value: "read"),
          input.path,
          location: input,
        ),
      ],
      (branch) =>
          branch.set(fixture.title, types.DataValue.wrapStringValue("tail"))
              is PortablePathValue,
    );
    final changed = _stateWithFields(fixture.snapshot, {
      "title": types.DataValue.wrapStringValue("prefix"),
      "computedInput": types.DataValue.wrapStringValue("other edit"),
    });
    final conflict = fixture.draft.rebaseTailOnto(
      AuthoredDraft.fromState(changed),
      acceptedIntentCount: count,
    ) as AuthoredDraftRebaseConflict;
    expect(_factKey(conflict.expected), ("value", input));
  });

  test("tail reads remain tracked after recovering a committed prefix", () {
    final fixture = _fixture();
    final input = types.ValueLocation(
      resource: fixture.resource,
      path: _fieldPath("computedInput"),
    );
    fixture.draft.set(fixture.title, types.DataValue.wrapStringValue("prefix"));
    final count = fixture.draft.intents.length;
    fixture.draft.stageExpressionEdit(
      [
        PortableExpressionRead(
          types.ExpressionBindingId(value: "read"),
          input.path,
          location: input,
        ),
      ],
      (branch) =>
          branch.set(fixture.title, types.DataValue.wrapStringValue("tail"))
              is PortablePathValue,
    );
    final saved = _stateWithFields(fixture.snapshot, {
      "title": types.DataValue.wrapStringValue("prefix"),
    });
    final rebased = fixture.draft.rebaseTailOnto(
      AuthoredDraft.fromState(saved),
      acceptedIntentCount: count,
    ) as AuthoredDraftRebased;
    final changed = _stateWithFields(saved, {
      "computedInput": types.DataValue.wrapStringValue("new"),
    });
    final conflict = rebased.draft.rebaseOnto(
      AuthoredDraft.fromState(changed),
    ) as AuthoredDraftRebaseConflict;
    expect(_factKey(conflict.expected), ("value", input));
  });

  test("a missing value is an explicit null expectation", () {
    final fixture = _fixture();
    final at = types.ValueLocation(
      resource: fixture.resource,
      path: _fieldPath("count"),
    );
    fixture.draft.set(at, types.DataValue.wrapInteger("3"));
    expect(
      fixture.draft.expectations,
      contains(facts.EditExpectation.createValue(at: at, expected: null)),
    );
  });

  test("ordered collection edits preserve tags and intent order", () {
    final fixture = _fixture();
    final draft = fixture.draft;
    final inserted = types.ListItem(
      id: types.ItemId(value: "inserted"),
      value: types.DataValue.wrapStringValue("second"),
    );

    draft
      ..insert(fixture.items, fixture.firstItem, inserted)
      ..move(fixture.items, inserted.id, null)
      ..remove(fixture.items, fixture.firstItem);

    expect(draft.intents, [
      isA<authoring.EditIntent_insertWrapper>(),
      isA<authoring.EditIntent_moveWrapper>(),
      isA<authoring.EditIntent_removeWrapper>(),
    ]);
    final value =
        (draft.read(fixture.items) as PortablePathValue<types.DataValue>).value
            as types.DataValue_namedWrapper;
    expect(value.value.actualType, fixture.listType);
    final list = value.value.payload as types.DataValue_listValueWrapper;
    expect(list.value.items.map((item) => item.id), [inserted.id]);
  });

  test("insert materializes an Unfilled collection from checked shape", () {
    final fixture = _collectionRepairFixture();
    final item = types.ListItem(
      id: types.ItemId(value: "item:text"),
      value: fixture.draft.defaultValue(
        types.TypeUse.wrapScalar(types.ScalarKind.text),
      ),
    );

    final result = fixture.draft.insert(fixture.texts, null, item);

    expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
    final value = switch (fixture.draft.read(fixture.texts)) {
      PortablePathValue(value: final value) => value,
      _ => null,
    };
    expect(value?.authoredActualType, fixture.textSet);
    expect(value?.authoredItems?.single.id, item.id);
    expect(value?.authoredItems?.single.value.authoredString, "");
    expect(fixture.draft.intents, [isA<authoring.EditIntent_insertWrapper>()]);
  });

  test(
    "prepared collection insertion keeps one intent and located findings",
    () {
      final fixture = _collectionRepairFixture();
      final item = types.ItemId(value: "item:record");
      final selection = types.TypeSelection.wrapComplete(fixture.itemType);
      final request = catalog.InitializationRequest(
        id: types.InitializationRequestId(value: "prepare:item"),
        catalog: fixture.draft.generation,
        type: selection,
        supplied: const [],
        intentHash: "item:record",
      );
      final prepared = catalog.PreparedCreation(
        record: types.AuthoringRecord(
          configuration: selection,
          fields: [
            types.FieldValue(
              name: "name",
              value: types.DataValue.wrapStringValue("prepared"),
            ),
          ],
        ),
        findings: [
          diagnostic.InitializationDiagnostic(
            field: types.FieldOwner(
              definition: fixture.itemType.definition,
              name: "name",
            ),
            code: "default_capture_failed",
            message: "The item default could not be captured",
            relativePath: types.ValuePath(
              segments: [types.PathSegment.createField(name: "name")],
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

      expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
      expect(fixture.draft.intents, [
        isA<authoring.EditIntent_insertWrapper>(),
      ]);
      expect(
        fixture.draft.initializationFindings.single.relativePath,
        types.ValuePath(
          segments: [
            types.PathSegment.createField(name: "records"),
            types.PathSegment.createItem(id: item),
            types.PathSegment.createField(name: "name"),
          ],
        ),
      );
    },
  );

  test("a missing nested parent records no write intent", () {
    final fixture = _fixture();
    final nested = types.ValueLocation(
      resource: fixture.resource,
      path: types.ValuePath(
        segments: [
          types.PathSegment.createField(name: "style"),
          types.PathSegment.createField(name: "bold"),
        ],
      ),
    );

    final result = fixture.draft.set(nested, types.DataValue.wrapBoolean(true));

    expect(result, isA<PortablePathUnavailable<types.AuthoringRecord>>());
    expect(fixture.draft.intents, isEmpty);
  });

  test("writes capture existence and configuration at every ancestor", () {
    final fixture = _fixture();

    fixture.draft.set(
      fixture.title,
      types.DataValue.wrapStringValue("changed"),
    );

    final identities = fixture.draft.expectations
        .map(_factKey)
        .toSet();
    expect(
      identities,
      containsAll(
        {
          ("exists", fixture.resource),
          (
            "configuration",
            types.ValueLocation(
              resource: fixture.resource,
              path: types.ValuePath(segments: const []),
            ),
          ),
          ("value", fixture.title),
        },
      ),
    );
  });

  test("nullable clear writes null while required clear writes unfilled", () {
    final fixture = _fixture();

    fixture.draft.clear(
      fixture.title,
      expected: types.TypeUse.createNullable(
        value: types.TypeUse.wrapScalar(types.ScalarKind.text),
      ),
    );
    final nullable = fixture.draft.intents.last;
    expect(
      (nullable as authoring.EditIntent_setValueWrapper).value.value,
      types.DataValue.null_,
    );

    fixture.draft.clear(
      fixture.title,
      expected: types.TypeUse.wrapScalar(types.ScalarKind.text),
    );
    final required = fixture.draft.intents.last;
    expect(
      (required as authoring.EditIntent_setValueWrapper).value.value,
      types.DataValue.unfilled,
    );
  });

  test("relation edits capture endpoint and incoming graph evidence", () {
    final fixture = _fixture();
    final endpoint = types.EndpointId(value: "test.source");
    final opposite = types.EndpointId(value: "test.target");
    final relation = types.RelationId(value: "test.relation");
    final target = types.ResourceId(value: "resource:2");
    final selection = types.NamedTypeTemplate(
      definition: fixture.listType.definition,
      arguments: const [],
    );
    final checked = CheckedEditorCatalog(
      catalog.EditorCatalogWireSnapshot(
        generation: types.CatalogGeneration(value: "catalog:1"),
        types: const [],
        relations: [
          catalog.RelationContract(
            id: relation,
            first: catalog.EndpointDefinition(
              id: endpoint,
              slot: catalog.EndpointSlot.first,
              resource: selection,
              cardinality: catalog.EndpointCardinality.one,
              onDelete: catalog.RelationDeletePolicy.clear,
            ),
            second: catalog.EndpointDefinition(
              id: opposite,
              slot: catalog.EndpointSlot.second,
              resource: selection,
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
        endpointBindings: const [],
        capabilities: const [],
        recommendations: const [],
        roleFallbacks: const [],
      ),
    );
    final draft = AuthoredDraft.fromState(fixture.snapshot, catalog: checked);
    final source = authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(
        endpoint: endpoint,
        location: fixture.title,
      ),
      source: fixture.resource,
      target: types.LinkTarget(resource: target, opposite: null),
    );

    draft.connect(source, target);

    final identities = draft.expectations
        .map(_factKey)
        .toSet();
    expect(
      identities,
      containsAll(
        {
          ("value", fixture.title),
          ("exists", target),
          ("links", fixture.resource, relation),
          ("links", target, relation),
        },
      ),
    );
    expect(
      draft.intents.single,
      isA<authoring.EditIntent_connectRelationWrapper>(),
    );
    expect(draft.links, hasLength(1));
    expect(draft.links.single.first, fixture.resource);
    expect(draft.links.single.second, target);

    draft.disconnect(source);

    expect(draft.links, isEmpty);
  });

  test("collection relation sources capture parent order evidence", () {
    final fixture = _fixture();
    final target = types.ResourceId(value: "resource:2");
    final containing = fixture.items;
    final item = types.ValueLocation(
      resource: fixture.resource,
      path: types.ValuePath(
        segments: [
          ...containing.path.segments,
          types.PathSegment.createItem(id: fixture.firstItem),
        ],
      ),
    );
    final source = authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(
        endpoint: types.EndpointId(value: "test.source"),
        location: item,
      ),
      source: fixture.resource,
      target: types.LinkTarget(resource: target, opposite: null),
    );

    fixture.draft.connect(source, target);

    final identities = fixture.draft.expectations
        .map(_factKey)
        .toSet();
    expect(
      identities,
      containsAll(
        {
          ("value", item),
          ("configuration", containing),
          ("value", containing),
          ("value", containing),
        },
      ),
    );
  });

  test("collection relation counterparts capture parent order evidence", () {
    final fixture = _fixture();
    final counterpartLocation = types.ValueLocation(
      resource: fixture.resource,
      path: types.ValuePath(
        segments: [
          ...fixture.items.path.segments,
          types.PathSegment.createItem(id: fixture.firstItem),
        ],
      ),
    );
    final source = authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(
        endpoint: types.EndpointId(value: "test.source"),
        location: fixture.title,
      ),
      source: fixture.resource,
      target: types.LinkTarget(resource: fixture.resource, opposite: null),
    );
    final counterpart = authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(
        endpoint: types.EndpointId(value: "test.target"),
        location: counterpartLocation,
      ),
      source: fixture.resource,
      target: types.LinkTarget(
        resource: fixture.resource,
        opposite: fixture.title.path,
      ),
    );

    fixture.draft.connect(
      source,
      fixture.resource,
      counterpart: authoring.CounterpartChoice.wrapExisting(counterpart),
    );

    final identities = fixture.draft.expectations
        .map(_factKey)
        .toSet();
    expect(
      identities,
      containsAll(
        {
          ("value", counterpartLocation),
          ("configuration", fixture.items),
          ("value", fixture.items),
          ("value", fixture.items),
        },
      ),
    );
  });

  test("collection relation disconnects capture parent order evidence", () {
    final fixture = _fixture();
    final item = types.ValueLocation(
      resource: fixture.resource,
      path: types.ValuePath(
        segments: [
          ...fixture.items.path.segments,
          types.PathSegment.createItem(id: fixture.firstItem),
        ],
      ),
    );
    final occurrence = authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(
        endpoint: types.EndpointId(value: "test.source"),
        location: item,
      ),
      source: fixture.resource,
      target: types.LinkTarget(
        resource: types.ResourceId(value: "resource:2"),
        opposite: null,
      ),
    );

    fixture.draft.disconnect(occurrence);

    final identities = fixture.draft.expectations
        .map(_factKey)
        .toSet();
    expect(
      identities,
      containsAll(
        {
          ("value", item),
          ("configuration", fixture.items),
          ("value", fixture.items),
          ("value", fixture.items),
        },
      ),
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
          counterpart: authoring.CounterpartChoice.wrapExisting(
            fixture.counterpart,
          ),
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
                as PortablePathValue<types.DataValue>)
            .value
            .authoredLink
            ?.target
            .resource,
        fixture.newTarget,
      );
      expect(
        (branch.read(
          fixture.originalOpposite,
        ) as PortablePathValue<types.DataValue>).value,
        types.DataValue.unfilled,
      );
      expect(
        (branch.read(fixture.newOpposite) as PortablePathValue<types.DataValue>)
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
        ) as PortablePathValue<types.DataValue>).value,
        types.DataValue.unfilled,
      );
      expect(
        (fixture.draft.read(fixture.occurrence.id.location)
                as PortablePathValue<types.DataValue>)
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
    final identities = branch.expectations
        .map(_factKey)
        .toSet();

    expect(branch.resource(deleted), isNull);
    expect(branch.links, isEmpty);
    expect(
      branch.intents.single,
      isA<authoring.EditIntent_deleteResourceWrapper>(),
    );
    expect(
      identities,
      containsAll(
        {
          ("links", fixture.occurrence.source, relation),

          ("links", deleted, relation),
          ("exists", fixture.occurrence.source),
          (
            "configuration",
            types.ValueLocation(
              resource: fixture.occurrence.source,
              path: types.ValuePath(segments: const []),
            ),
          ),
          ("configuration", fixture.occurrence.id.location),
          ("value", fixture.occurrence.id.location),
        },
      ),
    );
    expect(identities, isNot(contains(("links", fixture.newTarget, relation))));
  });

  test("cascade deletion observes an undeclared counterpart resource", () {
    final fixture = _relationFixture(
      firstDelete: catalog.RelationDeletePolicy.cascade,
      includeOppositeLocation: false,
    );
    final cascaded = fixture.occurrence.target.resource;
    final branch = fixture.draft.fork()..delete(fixture.occurrence.source);
    final identities = branch.expectations
        .map(_factKey)
        .toSet();

    expect(
      identities,
      containsAll(
        {
          ("exists", cascaded),
          (
            "configuration",
            types.ValueLocation(
              resource: cascaded,
              path: types.ValuePath(segments: const []),
            ),
          ),
        },
      ),
    );
  });

  test("retarget clears an earlier opposite in the same target", () {
    final fixture = _relationFixture();
    final branch = fixture.draft.fork()
      ..connect(
        fixture.occurrence,
        fixture.newTarget,
        counterpart: authoring.CounterpartChoice.wrapExisting(
          fixture.counterpart,
        ),
      )
      ..connect(
        fixture.occurrence,
        fixture.newTarget,
        counterpart: authoring.CounterpartChoice.wrapExisting(
          fixture.alternateCounterpart,
        ),
      );

    expect(
      (branch.read(
        fixture.newOpposite,
      ) as PortablePathValue<types.DataValue>).value,
      types.DataValue.unfilled,
    );
    expect(
      (branch.read(fixture.alternateOpposite)
              as PortablePathValue<types.DataValue>)
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
      types.DataValue.wrapInteger("3"),
    );

    expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
    expect(fixture.draft.intents, hasLength(2));
    final parent =
        (fixture.draft.intents.first as authoring.EditIntent_setValueWrapper)
                .value
                .value
            as types.DataValue_namedWrapper;
    final payload = parent.value.payload as types.DataValue_recordWrapper;
    expect(
      payload.value.fields.singleWhere((field) => field.name == "bold").value,
      types.DataValue.wrapBoolean(true),
    );
    final identities = fixture.draft.expectations
        .map(_factKey)
        .toSet();
    expect(
      identities,
      contains((
        "configuration",
        types.ValueLocation(
          resource: fixture.repetitions.resource,
          path: types.ValuePath(
            segments: [types.PathSegment.createField(name: "style")],
          ),
        ),
      )),
    );
  });

  test("nullable nested parent materializes before the child write", () {
    final fixture = _parentFixture(capturedStyle: true, nullableStyle: true);

    final result = fixture.draft.set(
      fixture.repetitions,
      types.DataValue.wrapInteger("3"),
    );

    expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
    expect(fixture.draft.intents, hasLength(2));
  });

  test("dynamic parent uses the containing field prepared default", () async {
    final fixture = _parentFixture(
      capturedStyle: false,
      dynamicStyle: true,
      nullableStyle: true,
    );
    final styleUse = types.NamedTypeUse(
      definition: _definition("Style"),
      arguments: const [],
    );
    catalog.InitializationRequest? observed;

    final result = await fixture.draft.setWithInitialization(
      fixture.repetitions,
      types.DataValue.wrapInteger("3"),
      (request) async {
        observed = request;
        return catalog.PreparedCreation(
          record: types.AuthoringRecord(
            configuration: request.type,
            fields: [
              types.FieldValue(
                name: "style",
                value: types.DataValue.createNamed(
                  actualType: styleUse,
                  payload: types.DataValue.createRecord(
                    fields: [
                      types.FieldValue(
                        name: "bold",
                        value: types.DataValue.wrapBoolean(true),
                      ),
                      types.FieldValue(
                        name: "repetitions",
                        value: types.DataValue.unfilled,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          findings: const [],
        );
      },
    );

    expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
    expect(observed, isNotNull);
    expect(observed!.supplied, isEmpty);
    expect(
      (observed!.type as types.TypeSelection_completeWrapper).value.definition,
      _definition("Action"),
    );
    final style =
        fixture.draft
                .resource(fixture.repetitions.resource)!
                .authoredField("style")!
            as types.DataValue_namedWrapper;
    final fields =
        (style.value.payload as types.DataValue_recordWrapper).value.fields;
    expect(
      fields.singleWhere((field) => field.name == "bold").value,
      types.DataValue.wrapBoolean(true),
    );
    expect(
      fixture.draft.expectations,
      contains(
        facts.EditExpectation.createValue(
          at: types.ValueLocation(
            resource: fixture.repetitions.resource,
            path: types.ValuePath(segments: const []),
          ),
          expected: types.DataValue.createRecord(
            fields: fixture.snapshot.resources.single.content.fields,
          ),
        ),
      ),
    );
    expect(
      fields.singleWhere((field) => field.name == "repetitions").value,
      types.DataValue.wrapInteger("3"),
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
      final requests = <catalog.InitializationRequest>[];

      final result = await fixture.draft.setWithInitialization(
        fixture.repetitions,
        types.DataValue.wrapInteger("3"),
        (request) async {
          requests.add(request);
          return _preparedContainingStyle(request, bold: true);
        },
      );

      expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
      expect(requests, hasLength(1));
      expect(
        (requests.single.type as types.TypeSelection_completeWrapper)
            .value
            .definition,
        _definition("Action"),
      );
      final style =
          fixture.draft
                  .resource(fixture.repetitions.resource)!
                  .authoredField("style")!
              as types.DataValue_namedWrapper;
      final fields =
          (style.value.payload as types.DataValue_recordWrapper).value.fields;
      expect(
        fields.singleWhere((field) => field.name == "bold").value,
        types.DataValue.wrapBoolean(true),
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
      final root = types.ValueLocation(
        resource: fixture.repetitions.resource,
        path: types.ValuePath(segments: const []),
      );

      final result = await fixture.draft.setWithInitialization(
        fixture.repetitions,
        types.DataValue.wrapInteger("3"),
        (request) async => _preparedContainingStyle(request, bold: true),
      );

      expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
      expect(
        fixture.draft.expectations,
        contains(
          facts.EditExpectation.createValue(
            at: root,
            expected: types.DataValue.createRecord(
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
      final requests = <catalog.InitializationRequest>[];

      Future<catalog.PreparedCreation> fail(
        catalog.InitializationRequest request,
      ) async {
        requests.add(request);
        throw StateError("temporary failure");
      }

      await expectLater(
        fixture.draft.setWithInitialization(
          fixture.repetitions,
          types.DataValue.wrapInteger("3"),
          fail,
        ),
        throwsStateError,
      );
      final result = await fixture.draft.setWithInitialization(
        fixture.repetitions,
        types.DataValue.wrapInteger("3"),
        (request) async {
          requests.add(request);
          return _preparedContainingStyle(request, bold: true);
        },
      );

      expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
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
      final requests = <catalog.InitializationRequest>[];
      Future<catalog.PreparedCreation> prepare(
        catalog.InitializationRequest request,
      ) async {
        requests.add(request);
        return _preparedContainingStyle(request, bold: true);
      }

      await fixture.draft.setWithInitialization(
        fixture.repetitions,
        types.DataValue.wrapInteger("3"),
        prepare,
      );
      final style = types.ValueLocation(
        resource: fixture.repetitions.resource,
        path: types.ValuePath(
          segments: [types.PathSegment.createField(name: "style")],
        ),
      );
      expect(
        fixture.draft.set(style, types.DataValue.null_),
        isA<PortablePathValue<types.AuthoringRecord>>(),
      );
      await fixture.draft.setWithInitialization(
        fixture.repetitions,
        types.DataValue.wrapInteger("4"),
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
      final style = types.ValueLocation(
        resource: fixture.repetitions.resource,
        path: types.ValuePath(
          segments: [types.PathSegment.createField(name: "style")],
        ),
      );
      final missingChild = types.ValueLocation(
        resource: fixture.repetitions.resource,
        path: types.ValuePath(
          segments: [
            types.PathSegment.createField(name: "style"),
            types.PathSegment.createField(name: "items"),
            types.PathSegment.createItem(id: types.ItemId(value: "missing")),
            types.PathSegment.createField(name: "value"),
          ],
        ),
      );

      final result = await fixture.draft.setWithInitialization(
        missingChild,
        types.DataValue.wrapStringValue("changed"),
        (request) async =>
            _preparedContainingStyle(request, bold: true, includeItems: true),
      );

      expect(result, isA<PortablePathUnavailable<types.AuthoringRecord>>());
      expect(fixture.draft.intents, isEmpty);
      expect(
        (fixture.draft.read(style) as PortablePathValue<types.DataValue>).value,
        types.DataValue.unfilled,
      );
    },
  );

  test("concurrent draft change prevents prepared parent adoption", () async {
    final fixture = _parentFixture(
      capturedStyle: false,
      dynamicContaining: true,
      nullableStyle: true,
    );
    final response = Completer<catalog.PreparedCreation>();
    final pending = fixture.draft.setWithInitialization(
      fixture.repetitions,
      types.DataValue.wrapInteger("3"),
      (request) => response.future,
    );
    final concurrent = types.ResourceId(value: "resource:concurrent");
    fixture.draft.create(
      concurrent,
      types.AuthoringRecord(
        configuration: types.TypeSelection.wrapComplete(
          types.NamedTypeUse(
            definition: _definition("Action"),
            arguments: const [],
          ),
        ),
        fields: const [],
      ),
    );
    response.complete(
      _preparedContainingStyle(
        catalog.InitializationRequest.defaultInstance,
        bold: true,
      ),
    );

    final result = await pending;
    expect(result, isA<PortablePathUnavailable<types.AuthoringRecord>>());
    expect(fixture.draft.resource(concurrent), isNotNull);
    expect(fixture.draft.intents, hasLength(1));
  });

  test("disposed presentation host ignores a delayed initialization", () async {
    final fixture = _parentFixture(
      capturedStyle: false,
      dynamicContaining: true,
      nullableStyle: true,
    );
    final prepared = Completer<catalog.PreparedCreation>();
    late catalog.InitializationRequest request;
    var changes = 0;
    var notifications = 0;
    var statuses = 0;
    final host = AuthoredDraftPresentationHost(
      resource: fixture.repetitions.resource,
      draft: fixture.draft,
      material: catalog.PresentationMaterial.defaultInstance,
      role: catalog.PresentationRole.inspector,
      budget: expression.EvaluationBudget.defaultInstance,
      capabilities: const PortablePresentationCapabilities(),
      prepareCreation: (value) {
        request = value;
        return prepared.future;
      },
      onDraftChanged: () => changes++,
      reportStatus: (_) => statuses++,
    )..addListener(() => notifications++);
    final reference = binding.BindingRef(
      bindingId: configuredValueBindingId,
      path: fixture.repetitions.path,
    );

    final pending = host.write(reference, types.DataValue.wrapInteger("3"));
    expect(host.enabled, isFalse);
    expect(notifications, 1);

    host.dispose();
    prepared.complete(_preparedContainingStyle(request, bold: true));

    expect(await pending, isA<PortablePresentationWriteApplied>());
    expect(host.enabled, isFalse);
    expect(changes, 0);
    expect(statuses, 0);
    expect(notifications, 1);
    final intentCount = fixture.draft.intents.length;
    expect(
      await host.write(reference, types.DataValue.wrapInteger("4")),
      isA<PortablePresentationWriteRejected>(),
    );
    expect(fixture.draft.intents, hasLength(intentCount));
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
      types.DataValue.wrapInteger("3"),
      (request) async {
        invocation++;
        if (invocation == 1) {
          return catalog.PreparedCreation(
            record: types.AuthoringRecord(
              configuration: request.type,
              fields: [
                types.FieldValue(
                  name: "style",
                  value: types.DataValue.unfilled,
                ),
              ],
            ),
            findings: [
              diagnostic.InitializationDiagnostic(
                field: types.FieldOwner(
                  definition: _definition("Action"),
                  name: "style",
                ),
                code: "default_capture_failed",
                message: "The default could not be captured",
                relativePath: types.ValuePath(
                  segments: [types.PathSegment.createField(name: "style")],
                ),
              ),
            ],
          );
        }
        return catalog.PreparedCreation(
          record: types.AuthoringRecord(
            configuration: request.type,
            fields: [
              types.FieldValue(
                name: "bold",
                value: types.DataValue.wrapBoolean(false),
              ),
              types.FieldValue(
                name: "repetitions",
                value: types.DataValue.unfilled,
              ),
              types.FieldValue(
                name: "bytes",
                value: types.DataValue.wrapBytes(ByteString.empty),
              ),
              types.FieldValue(
                name: "duration",
                value: types.DataValue.createDuration(
                  value: kernel.Duration(milliseconds: 0),
                ),
              ),
              types.FieldValue(
                name: "timestamp",
                value: types.DataValue.unfilled,
              ),
            ],
          ),
          findings: [
            diagnostic.InitializationDiagnostic(
              field: types.FieldOwner(
                definition: _definition("Style"),
                name: "repetitions",
              ),
              code: "default_capture_failed",
              message: "The default could not be captured",
              relativePath: types.ValuePath(
                segments: [types.PathSegment.createField(name: "repetitions")],
              ),
            ),
          ],
        );
      },
    );

    expect(result, isA<PortablePathValue<types.AuthoringRecord>>());
    expect(invocation, 2);
    expect(fixture.draft.intents, hasLength(2));
    expect(
      fixture.draft.initializationFindings.last.relativePath,
      types.ValuePath(
        segments: [
          types.PathSegment.createField(name: "style"),
          types.PathSegment.createField(name: "repetitions"),
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
    final style = types.ValueLocation(
      resource: fixture.repetitions.resource,
      path: types.ValuePath(
        segments: [types.PathSegment.createField(name: "style")],
      ),
    );
    final missingChild = types.ValueLocation(
      resource: fixture.repetitions.resource,
      path: types.ValuePath(
        segments: [
          types.PathSegment.createField(name: "style"),
          types.PathSegment.createField(name: "items"),
          types.PathSegment.createItem(id: types.ItemId(value: "missing")),
          types.PathSegment.createField(name: "value"),
        ],
      ),
    );

    final result = fixture.draft.set(
      missingChild,
      types.DataValue.wrapStringValue("changed"),
    );

    expect(result, isA<PortablePathUnavailable<types.AuthoringRecord>>());
    expect(fixture.draft.intents, isEmpty);
    expect(fixture.draft.expectations, isEmpty);
    expect(
      (fixture.draft.read(style) as PortablePathValue<types.DataValue>).value,
      types.DataValue.unfilled,
    );
  });

  test("uncaptured constructor defaults remain unfilled", () {
    final fixture = _parentFixture(capturedStyle: false);

    fixture.draft.set(fixture.bold, types.DataValue.wrapBoolean(true));

    final parent =
        (fixture.draft.intents.first as authoring.EditIntent_setValueWrapper)
                .value
                .value
            as types.DataValue_namedWrapper;
    final payload = parent.value.payload as types.DataValue_recordWrapper;
    expect(
      payload.value.fields
          .singleWhere((field) => field.name == "repetitions")
          .value,
      types.DataValue.unfilled,
    );
  });

  test("inherited captured defaults use their declaration owner", () {
    final fixture = _parentFixture(capturedStyle: false, inheritedBold: true);

    fixture.draft.set(fixture.repetitions, types.DataValue.wrapInteger("3"));

    final parent =
        (fixture.draft.intents.first as authoring.EditIntent_setValueWrapper)
                .value
                .value
            as types.DataValue_namedWrapper;
    final payload = parent.value.payload as types.DataValue_recordWrapper;
    expect(
      payload.value.fields.singleWhere((field) => field.name == "bold").value,
      types.DataValue.wrapBoolean(true),
    );
  });

  test("ordinary scalar defaults match Realm initialization", () {
    final fixture = _parentFixture(capturedStyle: false);

    fixture.draft.set(fixture.bold, types.DataValue.wrapBoolean(true));

    final parent =
        (fixture.draft.intents.first as authoring.EditIntent_setValueWrapper)
                .value
                .value
            as types.DataValue_namedWrapper;
    final payload = parent.value.payload as types.DataValue_recordWrapper;
    types.DataValue field(String name) =>
        payload.value.fields.singleWhere((field) => field.name == name).value;

    expect(field("bytes"), isA<types.DataValue_bytesWrapper>());
    expect(
      (field("bytes") as types.DataValue_bytesWrapper).value,
      ByteString.empty,
    );
    expect(field("duration"), isA<types.DataValue_durationWrapper>());
    expect(
      (field(
        "duration",
      ) as types.DataValue_durationWrapper).value.value.milliseconds,
      0,
    );
    expect(field("timestamp"), types.DataValue.unfilled);
  });
}

({
  AuthoredDraft draft,
  types.ValueLocation bold,
  types.ValueLocation repetitions,
  authoring.AuthoringState snapshot,
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
  final rootUse = types.NamedTypeUse(definition: root, arguments: const []);
  final styleUse = types.NamedTypeUse(definition: style, arguments: const []);
  final styleOwner = types.FieldOwner(definition: root, name: "style");
  final boldOwner = types.FieldOwner(
    definition: inheritedBold ? baseStyle : style,
    name: "bold",
  );
  final repetitionsOwner = types.FieldOwner(
    definition: style,
    name: "repetitions",
  );
  final bytesOwner = types.FieldOwner(definition: style, name: "bytes");
  final durationOwner = types.FieldOwner(definition: style, name: "duration");
  final timestampOwner = types.FieldOwner(definition: style, name: "timestamp");
  final itemsOwner = types.FieldOwner(definition: style, name: "items");
  final list = _definition("List");
  final styleTemplate = types.TypeTemplate.wrapNamed(
    types.NamedTypeTemplate(definition: style, arguments: const []),
  );
  final declaredStyleTemplate = nullableStyle
      ? types.TypeTemplate.createNullable(value: styleTemplate)
      : styleTemplate;
  final styleValue = types.DataValue.createNamed(
    actualType: styleUse,
    payload: types.DataValue.createRecord(
      fields: [
        types.FieldValue(
          name: "bold",
          value: types.DataValue.wrapBoolean(true),
        ),
        types.FieldValue(name: "repetitions", value: types.DataValue.unfilled),
      ],
    ),
  );
  final catalogSnapshot = catalog.EditorCatalogWireSnapshot(
    generation: types.CatalogGeneration(value: generation),
    types: [
      catalog.PublishedType(
        display: null,
        definition: types.TypeDefinition(
          id: root,
          parameters: const [],
          representation: types.RepresentationTemplate.createRecord(
            fields: [
              types.FieldDeclaration(
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
        status: catalog.DeclarationStatus.ready,
        effectiveFields: [
          catalog.EffectiveFieldTemplate(
            key: "style",
            owner: styleOwner,
            type: declaredStyleTemplate,
            rules: const [],
          ),
        ],
        ancestorTemplates: const [],
      ),
      catalog.PublishedType(
        display: null,
        definition: types.TypeDefinition(
          id: style,
          parameters: const [],
          representation: types.RepresentationTemplate.createRecord(
            fields: [
              if (!inheritedBold)
                types.FieldDeclaration(
                  owner: boldOwner,
                  type: types.TypeTemplate.wrapScalar(types.ScalarKind.boolean),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              types.FieldDeclaration(
                owner: repetitionsOwner,
                type: types.TypeTemplate.wrapScalar(
                  types.ScalarKind.createInteger(
                    width: types.IntegerWidth.signedThirtyTwo,
                  ),
                ),
                overrides: const [],
                hasConstructorDefault: true,
              ),
              types.FieldDeclaration(
                owner: bytesOwner,
                type: types.TypeTemplate.wrapScalar(types.ScalarKind.bytes),
                overrides: const [],
                hasConstructorDefault: false,
              ),
              types.FieldDeclaration(
                owner: durationOwner,
                type: types.TypeTemplate.wrapScalar(types.ScalarKind.duration),
                overrides: const [],
                hasConstructorDefault: false,
              ),
              types.FieldDeclaration(
                owner: timestampOwner,
                type: types.TypeTemplate.wrapScalar(types.ScalarKind.timestamp),
                overrides: const [],
                hasConstructorDefault: false,
              ),
              if (includeItems)
                types.FieldDeclaration(
                  owner: itemsOwner,
                  type: types.TypeTemplate.wrapNamed(
                    types.NamedTypeTemplate(
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
                  types.NamedTypeTemplate(
                    definition: baseStyle,
                    arguments: const [],
                  ),
                ]
              : const [],
        ),
        status: catalog.DeclarationStatus.ready,
        effectiveFields: [
          catalog.EffectiveFieldTemplate(
            key: "bold",
            owner: boldOwner,
            type: types.TypeTemplate.wrapScalar(types.ScalarKind.boolean),
            rules: const [],
          ),
          catalog.EffectiveFieldTemplate(
            key: "repetitions",
            owner: repetitionsOwner,
            type: types.TypeTemplate.wrapScalar(
              types.ScalarKind.createInteger(
                width: types.IntegerWidth.signedThirtyTwo,
              ),
            ),
            rules: const [],
          ),
          catalog.EffectiveFieldTemplate(
            key: "bytes",
            owner: bytesOwner,
            type: types.TypeTemplate.wrapScalar(types.ScalarKind.bytes),
            rules: const [],
          ),
          catalog.EffectiveFieldTemplate(
            key: "duration",
            owner: durationOwner,
            type: types.TypeTemplate.wrapScalar(types.ScalarKind.duration),
            rules: const [],
          ),
          catalog.EffectiveFieldTemplate(
            key: "timestamp",
            owner: timestampOwner,
            type: types.TypeTemplate.wrapScalar(types.ScalarKind.timestamp),
            rules: const [],
          ),
          if (includeItems)
            catalog.EffectiveFieldTemplate(
              key: "items",
              owner: itemsOwner,
              type: types.TypeTemplate.wrapNamed(
                types.NamedTypeTemplate(definition: list, arguments: const []),
              ),
              rules: const [],
            ),
        ],
        ancestorTemplates: inheritedBold
            ? [
                types.NamedTypeTemplate(
                  definition: baseStyle,
                  arguments: const [],
                ),
              ]
            : const [],
      ),
      if (inheritedBold)
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: baseStyle,
            parameters: const [],
            representation: types.RepresentationTemplate.createRecord(
              fields: [
                types.FieldDeclaration(
                  owner: boldOwner,
                  type: types.TypeTemplate.wrapScalar(types.ScalarKind.boolean),
                  overrides: const [],
                  hasConstructorDefault: true,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: [
            catalog.EffectiveFieldTemplate(
              key: "bold",
              owner: boldOwner,
              type: types.TypeTemplate.wrapScalar(types.ScalarKind.boolean),
              rules: const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
      if (includeItems)
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: list,
            parameters: const [],
            representation: types.RepresentationTemplate.createSequence(
              item: types.TypeTemplate.wrapScalar(types.ScalarKind.text),
              kind: types.CollectionKind.list,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
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
      catalog.InitializationDescriptor(
        definition: root,
        mode: dynamicContaining
            ? catalog.InitializationMode.creation
            : catalog.InitializationMode.startup,
        captured: capturedStyle
            ? [catalog.CapturedDefault(field: styleOwner, value: styleValue)]
            : const [],
        diagnostics: const [],
      ),
      catalog.InitializationDescriptor(
        definition: style,
        mode: dynamicStyle
            ? catalog.InitializationMode.creation
            : catalog.InitializationMode.startup,
        captured: inheritedBold
            ? [
                catalog.CapturedDefault(
                  field: boldOwner,
                  value: types.DataValue.wrapBoolean(true),
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
  final resource = types.ResourceId(value: "resource:parent");
  final snapshot = authoring.AuthoringState(
    generation: catalogSnapshot.generation,
    resources: [
      authoring.AuthoringResource(
        id: resource,
        definition: catalog.ResourceDefinitionId(value: "test.action"),
        content: types.AuthoringRecord(
          configuration: types.TypeSelection.wrapComplete(rootUse),
          fields: [
            types.FieldValue(name: "style", value: types.DataValue.unfilled),
          ],
        ),
      ),
    ],
    links: const [],
    findings: const [],
  );
  types.ValueLocation location(String field) => types.ValueLocation(
    resource: resource,
    path: types.ValuePath(
      segments: [
        types.PathSegment.createField(name: "style"),
        types.PathSegment.createField(name: field),
      ],
    ),
  );
  return (
    draft: AuthoredDraft.fromState(
      snapshot,
      catalog: CheckedEditorCatalog(catalogSnapshot),
    ),
    bold: location("bold"),
    repetitions: location("repetitions"),
    snapshot: snapshot,
  );
}

catalog.PreparedCreation _preparedContainingStyle(
  catalog.InitializationRequest request, {
  required bool bold,
  bool includeItems = false,
}) {
  final fields = <types.FieldValue>[
    types.FieldValue(name: "bold", value: types.DataValue.wrapBoolean(bold)),
    types.FieldValue(name: "repetitions", value: types.DataValue.unfilled),
    if (includeItems)
      types.FieldValue(
        name: "items",
        value: types.DataValue.createNamed(
          actualType: types.NamedTypeUse(
            definition: _definition("List"),
            arguments: const [],
          ),
          payload: types.DataValue.createListValue(items: const []),
        ),
      ),
  ];
  return catalog.PreparedCreation(
    record: types.AuthoringRecord(
      configuration: request.type,
      fields: [
        types.FieldValue(
          name: "style",
          value: types.DataValue.createNamed(
            actualType: types.NamedTypeUse(
              definition: _definition("Style"),
              arguments: const [],
            ),
            payload: types.DataValue.createRecord(fields: fields),
          ),
        ),
      ],
    ),
    findings: const [],
  );
}

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

({
  AuthoredDraft draft,
  types.ResourceId book,
  types.ResourceId page,
  catalog.ResourceDefinitionId pageResource,
  types.EndpointId bookEndpoint,
  types.NamedTypeUse sequenceUse,
  types.AuthoringRecord pageRecord,
})
_pageCreationFixture() {
  final book = _definition("Book");
  final page = _definition("Page");
  final sequence = _definition("SequencePage");
  final pages = _definition("PageList");
  final bookLink = _definition("BookPagesBook");
  final pageLink = _definition("BookPagesPage");
  final bookEndpoint = types.EndpointId(value: "book.pages");
  final pageEndpoint = types.EndpointId(value: "page.book");
  final bookUse = types.NamedTypeUse(definition: book, arguments: const []);
  final sequenceUse = types.NamedTypeUse(
    definition: sequence,
    arguments: const [],
  );
  final pagesUse = types.NamedTypeUse(definition: pages, arguments: const []);
  types.NamedTypeTemplate template(types.TypeDefinitionId definition) =>
      types.NamedTypeTemplate(definition: definition, arguments: const []);
  types.TypeTemplate named(types.TypeDefinitionId definition) =>
      types.TypeTemplate.wrapNamed(template(definition));
  types.FieldDeclaration field(
    types.TypeDefinitionId owner,
    String name,
    types.TypeTemplate type,
  ) => types.FieldDeclaration(
    owner: types.FieldOwner(definition: owner, name: name),
    type: type,
    overrides: const [],
    hasConstructorDefault: false,
  );
  catalog.EffectiveFieldTemplate effective(
    types.TypeDefinitionId owner,
    String name,
    types.TypeTemplate type,
  ) => catalog.EffectiveFieldTemplate(
    key: name,
    owner: types.FieldOwner(definition: owner, name: name),
    type: type,
    rules: const [],
  );
  catalog.PublishedType published(
    types.TypeDefinitionId id,
    types.RepresentationTemplate representation, {
    List<types.NamedTypeTemplate> parents = const [],
    List<catalog.EffectiveFieldTemplate> fields = const [],
  }) => catalog.PublishedType(
    display: null,
    definition: types.TypeDefinition(
      id: id,
      parameters: const [],
      representation: representation,
      parents: parents,
    ),
    status: catalog.DeclarationStatus.ready,
    effectiveFields: fields,
    ancestorTemplates: parents,
  );
  final bookPagesField = field(book, "pages", named(pages));
  final pageBookField = field(page, "book", named(pageLink));
  final pageNameField = field(
    page,
    "name",
    types.TypeTemplate.wrapScalar(types.ScalarKind.text),
  );
  final pageParent = template(page);
  final generation = types.CatalogGeneration(value: "catalog:page creation");
  final pageResource = catalog.ResourceDefinitionId(value: "typewriter.page");
  final snapshot = catalog.EditorCatalogWireSnapshot(
    generation: generation,
    types: [
      published(
        book,
        types.RepresentationTemplate.createRecord(
          fields: [bookPagesField],
          abstract_: false,
        ),
        fields: [effective(book, "pages", named(pages))],
      ),
      published(
        page,
        types.RepresentationTemplate.createRecord(
          fields: [pageBookField, pageNameField],
          abstract_: true,
        ),
        fields: [
          effective(page, "book", named(pageLink)),
          effective(
            page,
            "name",
            types.TypeTemplate.wrapScalar(types.ScalarKind.text),
          ),
        ],
      ),
      published(
        sequence,
        types.RepresentationTemplate.createRecord(
          fields: const [],
          abstract_: false,
        ),
        parents: [pageParent],
        fields: [
          effective(page, "book", named(pageLink)),
          effective(
            page,
            "name",
            types.TypeTemplate.wrapScalar(types.ScalarKind.text),
          ),
        ],
      ),
      published(
        pages,
        types.RepresentationTemplate.createSequence(
          item: named(bookLink),
          kind: types.CollectionKind.list,
        ),
      ),
      published(
        bookLink,
        types.RepresentationTemplate.createLink(
          endpoint: bookEndpoint,
          target: named(page),
        ),
      ),
      published(
        pageLink,
        types.RepresentationTemplate.createLink(
          endpoint: pageEndpoint,
          target: named(book),
        ),
      ),
    ],
    relations: [
      catalog.RelationContract(
        id: types.RelationId(value: "book.pages"),
        first: catalog.EndpointDefinition(
          id: bookEndpoint,
          slot: catalog.EndpointSlot.first,
          resource: template(book),
          cardinality: catalog.EndpointCardinality.one,
          onDelete: catalog.RelationDeletePolicy.cascade,
        ),
        second: catalog.EndpointDefinition(
          id: pageEndpoint,
          slot: catalog.EndpointSlot.second,
          resource: template(page),
          cardinality: catalog.EndpointCardinality.many,
          onDelete: catalog.RelationDeletePolicy.clear,
        ),
        families: const [],
      ),
    ],
    resourceDefinitions: [
      catalog.AuthoringResourceDefinition(
        id: catalog.ResourceDefinitionId(value: "typewriter.book"),
        root: book,
        navigationHandler: "",
      ),
      catalog.AuthoringResourceDefinition(
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
      catalog.EndpointBindingTemplate(
        endpoint: bookEndpoint,
        containingResource: template(book),
        valueOwner: book,
        relativePath: types.RelativeFieldPattern(
          segments: [
            types.FieldPatternSegment.createField(name: "pages"),
            types.FieldPatternSegment.items,
          ],
        ),
        target: named(page),
        containsCollection: true,
      ),
      catalog.EndpointBindingTemplate(
        endpoint: pageEndpoint,
        containingResource: template(page),
        valueOwner: page,
        relativePath: types.RelativeFieldPattern(
          segments: [types.FieldPatternSegment.createField(name: "book")],
        ),
        target: named(book),
        containsCollection: false,
      ),
      catalog.EndpointBindingTemplate(
        endpoint: pageEndpoint,
        containingResource: template(sequence),
        valueOwner: sequence,
        relativePath: types.RelativeFieldPattern(
          segments: [types.FieldPatternSegment.createField(name: "book")],
        ),
        target: named(book),
        containsCollection: false,
      ),
    ],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final bookId = types.ResourceId(value: "book:original");
  final pageId = types.ResourceId(value: "page:created");
  final bookRecord = types.AuthoringRecord(
    configuration: types.TypeSelection.wrapComplete(bookUse),
    fields: [
      types.FieldValue(
        name: "pages",
        value: types.DataValue.createNamed(
          actualType: pagesUse,
          payload: types.DataValue.createListValue(items: const []),
        ),
      ),
    ],
  );
  final pageRecord = types.AuthoringRecord(
    configuration: types.TypeSelection.wrapComplete(sequenceUse),
    fields: [
      types.FieldValue(name: "book", value: types.DataValue.unfilled),
      types.FieldValue(
        name: "name",
        value: types.DataValue.wrapStringValue("Verification page"),
      ),
    ],
  );
  final authored = authoring.AuthoringState(
    generation: generation,
    resources: [
      authoring.AuthoringResource(
        id: bookId,
        definition: catalog.ResourceDefinitionId(value: "typewriter.book"),
        content: bookRecord,
      ),
    ],
    links: const [],
    findings: const [],
  );
  return (
    draft: AuthoredDraft.fromState(
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

types.ValuePath _fieldPath(String name) =>
    types.ValuePath(segments: [types.PathSegment.createField(name: name)]);

({
  AuthoredDraft draft,
  authoring.LinkOccurrence occurrence,
  authoring.LinkOccurrence counterpart,
  authoring.LinkOccurrence alternateCounterpart,
  types.ResourceId newTarget,
  types.ValueLocation originalOpposite,
  types.ValueLocation newOpposite,
  types.ValueLocation alternateOpposite,
})
_relationFixture({
  catalog.RelationDeletePolicy firstDelete = catalog.RelationDeletePolicy.clear,
  catalog.RelationDeletePolicy secondDelete =
      catalog.RelationDeletePolicy.clear,
  bool includeOppositeLocation = true,
}) {
  final fixture = _fixture();
  final endpoint = types.EndpointId(value: "test.source");
  final opposite = types.EndpointId(value: "test.target");
  final relation = types.RelationId(value: "test.relation");
  final originalTarget = types.ResourceId(value: "resource:original");
  final newTarget = types.ResourceId(value: "resource:new");
  final oppositePath = types.ValuePath(
    segments: [types.PathSegment.createField(name: "back")],
  );
  final originalOpposite = types.ValueLocation(
    resource: originalTarget,
    path: oppositePath,
  );
  final newOpposite = types.ValueLocation(
    resource: newTarget,
    path: oppositePath,
  );
  final alternateOpposite = types.ValueLocation(
    resource: newTarget,
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: "back2")],
    ),
  );
  final linkType = types.NamedTypeUse(
    definition: _definition("Reference"),
    arguments: const [],
  );
  final originalResource = fixture.snapshot.resources.single;
  final linkedRecord = types.AuthoringRecord(
    configuration: originalResource.content.configuration,
    fields: [
      for (final field in originalResource.content.fields)
        types.FieldValue(
          name: field.name,
          value: field.name == "title"
              ? types.DataValue.createNamed(
                  actualType: linkType,
                  payload: types.DataValue.createLink(
                    endpoint: endpoint,
                    target: types.LinkTarget(
                      resource: originalTarget,
                      opposite: includeOppositeLocation ? oppositePath : null,
                    ),
                  ),
                )
              : field.value,
        ),
    ],
  );
  final snapshot = authoring.AuthoringState(
    generation: fixture.snapshot.generation,
    resources: [
      authoring.AuthoringResource(
        id: originalResource.id,
        definition: originalResource.definition,
        content: linkedRecord,
      ),
      for (final target in [originalTarget, newTarget])
        authoring.AuthoringResource(
          id: target,
          definition: originalResource.definition,
          content: types.AuthoringRecord(
            configuration: originalResource.content.configuration,
            fields: [
              for (final name in ["back", "back2"])
                types.FieldValue(
                  name: name,
                  value: includeOppositeLocation
                      ? types.DataValue.createNamed(
                          actualType: linkType,
                          payload: types.DataValue.createLink(
                            endpoint: opposite,
                            target: types.LinkTarget(
                              resource: fixture.resource,
                              opposite: fixture.title.path,
                            ),
                          ),
                        )
                      : types.DataValue.unfilled,
                ),
            ],
          ),
        ),
    ],
    links: [
      facts.LinkProjection(
        contract: relation,
        first: fixture.resource,
        second: originalTarget,
        firstLocation: fixture.title.path,
        secondLocation: includeOppositeLocation ? oppositePath : null,
      ),
    ],
    findings: fixture.snapshot.findings,
  );
  final selection = types.NamedTypeTemplate(
    definition: fixture.listType.definition,
    arguments: const [],
  );
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
      generation: fixture.snapshot.generation,
      types: const [],
      relations: [
        catalog.RelationContract(
          id: relation,
          first: catalog.EndpointDefinition(
            id: endpoint,
            slot: catalog.EndpointSlot.first,
            resource: selection,
            cardinality: catalog.EndpointCardinality.one,
            onDelete: firstDelete,
          ),
          second: catalog.EndpointDefinition(
            id: opposite,
            slot: catalog.EndpointSlot.second,
            resource: selection,
            cardinality: catalog.EndpointCardinality.many,
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
    draft: AuthoredDraft.fromState(snapshot, catalog: checked),
    occurrence: authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(
        endpoint: endpoint,
        location: fixture.title,
      ),
      source: fixture.resource,
      target: types.LinkTarget(
        resource: originalTarget,
        opposite: includeOppositeLocation ? oppositePath : null,
      ),
    ),
    counterpart: authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(endpoint: opposite, location: newOpposite),
      source: newTarget,
      target: types.LinkTarget(
        resource: fixture.resource,
        opposite: fixture.title.path,
      ),
    ),
    alternateCounterpart: authoring.LinkOccurrence(
      id: authoring.LinkOccurrenceId(
        endpoint: opposite,
        location: alternateOpposite,
      ),
      source: newTarget,
      target: types.LinkTarget(
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
  AuthoredDraft draft,
  types.ValueLocation texts,
  types.ValueLocation records,
  types.NamedTypeUse textSet,
  types.NamedTypeUse itemType,
})
_collectionRepairFixture() {
  final root = _definition("CollectionRoot");
  final textSetDefinition = _definition("TextSet");
  final recordSetDefinition = _definition("RecordSet");
  final itemDefinition = _definition("CollectionItem");
  final rootUse = types.NamedTypeUse(definition: root, arguments: const []);
  final textSet = types.NamedTypeUse(
    definition: textSetDefinition,
    arguments: const [],
  );
  final itemType = types.NamedTypeUse(
    definition: itemDefinition,
    arguments: const [],
  );
  final textsOwner = types.FieldOwner(definition: root, name: "texts");
  final recordsOwner = types.FieldOwner(definition: root, name: "records");
  final nameOwner = types.FieldOwner(definition: itemDefinition, name: "name");
  final textSetTemplate = types.TypeTemplate.createNamed(
    definition: textSetDefinition,
    arguments: const [],
  );
  final recordSetTemplate = types.TypeTemplate.createNamed(
    definition: recordSetDefinition,
    arguments: const [],
  );
  final itemTemplate = types.TypeTemplate.createNamed(
    definition: itemDefinition,
    arguments: const [],
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
  final catalogSnapshot = catalog.EditorCatalogWireSnapshot(
    generation: types.CatalogGeneration(value: "catalog:collection-repair"),
    types: [
      published(
        types.TypeDefinition(
          id: root,
          parameters: const [],
          representation: types.RepresentationTemplate.createRecord(
            fields: [
              types.FieldDeclaration(
                owner: textsOwner,
                type: textSetTemplate,
                overrides: const [],
                hasConstructorDefault: false,
              ),
              types.FieldDeclaration(
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
          catalog.EffectiveFieldTemplate(
            key: "texts",
            owner: textsOwner,
            type: textSetTemplate,
            rules: const [],
          ),
          catalog.EffectiveFieldTemplate(
            key: "records",
            owner: recordsOwner,
            type: recordSetTemplate,
            rules: const [],
          ),
        ],
      ),
      published(
        types.TypeDefinition(
          id: textSetDefinition,
          parameters: const [],
          representation: types.RepresentationTemplate.createSequence(
            item: types.TypeTemplate.wrapScalar(types.ScalarKind.text),
            kind: types.CollectionKind.set_,
          ),
          parents: const [],
        ),
        const [],
      ),
      published(
        types.TypeDefinition(
          id: recordSetDefinition,
          parameters: const [],
          representation: types.RepresentationTemplate.createSequence(
            item: itemTemplate,
            kind: types.CollectionKind.set_,
          ),
          parents: const [],
        ),
        const [],
      ),
      published(
        types.TypeDefinition(
          id: itemDefinition,
          parameters: const [],
          representation: types.RepresentationTemplate.createRecord(
            fields: [
              types.FieldDeclaration(
                owner: nameOwner,
                type: types.TypeTemplate.wrapScalar(types.ScalarKind.text),
                overrides: const [],
                hasConstructorDefault: true,
              ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        [
          catalog.EffectiveFieldTemplate(
            key: "name",
            owner: nameOwner,
            type: types.TypeTemplate.wrapScalar(types.ScalarKind.text),
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
  final resource = types.ResourceId(value: "resource:collection-repair");
  final snapshot = authoring.AuthoringState(
    generation: catalogSnapshot.generation,
    resources: [
      authoring.AuthoringResource(
        id: resource,
        definition: catalog.ResourceDefinitionId(value: "test.collection"),
        content: types.AuthoringRecord(
          configuration: types.TypeSelection.wrapComplete(rootUse),
          fields: [
            types.FieldValue(name: "texts", value: types.DataValue.unfilled),
            types.FieldValue(name: "records", value: types.DataValue.unfilled),
          ],
        ),
      ),
    ],
    links: const [],
    findings: const [],
  );
  types.ValueLocation location(String field) => types.ValueLocation(
    resource: resource,
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: field)],
    ),
  );
  return (
    draft: AuthoredDraft.fromState(
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
  AuthoredDraft draft,
  types.ResourceId resource,
  types.ValueLocation title,
  types.ValueLocation items,
  types.ItemId firstItem,
  types.NamedTypeUse listType,
  facts.EditExpectation titleObservation,
  types.InputToken absent,
  authoring.AuthoringState snapshot,
})
_fixture() {
  final resource = types.ResourceId(value: "resource:1");
  final title = types.ValueLocation(
    resource: resource,
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: "title")],
    ),
  );
  final items = types.ValueLocation(
    resource: resource,
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: "items")],
    ),
  );
  final firstItem = types.ItemId(value: "first");
  final listType = types.NamedTypeUse(
    definition: types.TypeDefinitionId(
      typeId: types.TypeId.createQualified(
        namespace: "typewriter",
        name: "List",
      ),
      revision: 1,
    ),
    arguments: [types.TypeUse.wrapScalar(types.ScalarKind.text)],
  );
  final record = types.AuthoringRecord(
    configuration: types.TypeSelection.unknown,
    fields: [
      types.FieldValue(
        name: "title",
        value: types.DataValue.wrapStringValue("original"),
      ),
      types.FieldValue(
        name: "items",
        value: types.DataValue.createNamed(
          actualType: listType,
          payload: types.DataValue.createListValue(
            items: [
              types.ListItem(
                id: firstItem,
                value: types.DataValue.wrapStringValue("first"),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  final titleObservation = facts.EditExpectation.createValue(
    at: title,
    expected: types.DataValue.wrapStringValue("original"),
  );
  final absent = types.InputToken(value: "absent");
  final snapshot = authoring.AuthoringState(
    generation: types.CatalogGeneration(value: "catalog:1"),
    resources: [
      authoring.AuthoringResource(
        id: resource,
        definition: catalog.ResourceDefinitionId(value: "test.resource"),
        content: record,
      ),
    ],
    links: const [],
    findings: const [],
  );
  return (
    draft: AuthoredDraft.fromState(snapshot),
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

Object _factKey(facts.EditExpectation fact) => switch (fact) {
  facts.EditExpectation_valueWrapper(value: final value) => ("value", value.at),
  facts.EditExpectation_configurationWrapper(value: final value) => (
    "configuration",
    value.at,
  ),
  facts.EditExpectation_resourceExistsWrapper(value: final value) => (
    "exists",
    value.id,
  ),
  facts.EditExpectation_resourceWrapper(value: final value) => (
    "resource",
    value.id,
  ),
  facts.EditExpectation_resourceIdsWrapper() => "resourceIds",
  facts.EditExpectation_linksWrapper(value: final value) => (
    "links",
    value.resource,
    value.contract,
  ),
  _ => throw StateError("Unknown expectation"),
};
authoring.AuthoringState _stateWithFields(
  authoring.AuthoringState state,
  Map<String, types.DataValue> changes,
) {
  final resource = state.resources.single;
  final fields = {
    for (final field in resource.content.fields) field.name: field.value,
  }..addAll(changes);
  return authoring.AuthoringState(
    generation: state.generation,
    links: state.links,
    findings: state.findings,
    resources: [
      authoring.AuthoringResource(
        id: resource.id,
        definition: resource.definition,
        content: types.AuthoringRecord(
          configuration: resource.content.configuration,
          fields: [
            for (final entry in fields.entries)
              types.FieldValue(name: entry.key, value: entry.value),
          ],
        ),
      ),
    ],
  );
}
