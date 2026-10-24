import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "package:typewriter_testkit/typewriter_testkit.dart";

/// Controls replies and confirmed observations independently. It never simulates Realm mutations.
final class ScriptedAuthoringTransport extends ChangeNotifier {
  ScriptedAuthoringTransport(this.observation, {this.onRequest});
  AsyncValue<AuthoringDocument> observation;
  final void Function(skir.PreparedEdit edit)? onRequest;
  final requests = <ScriptedAuthoringRequest>[];
  Object? refreshFailure;
  int fetches = 0;
  RealmEditPersistence get persistence =>
      fixtureRealmPersistence(commit: commit, confirmed: fetchConfirmed);
  void publish(AsyncValue<AuthoringDocument> next) {
    observation = next;
    notifyListeners();
  }

  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) {
    final request = ScriptedAuthoringRequest(edit);
    requests.add(request);
    onRequest?.call(edit);
    notifyListeners();
    return request.response.future;
  }

  Future<AuthoringDocument> fetchConfirmed() async {
    fetches++;
    if (refreshFailure case final error?) throw error;
    return observation.requireValue;
  }

  void confirm(int request, AuthoringDocument confirmed) {
    publish(AsyncData(confirmed));
    requests[request].response.complete(
      skir.CommitPreparedEditResponse.committed,
    );
  }

  void reject(int request, skir.CommitPreparedEditResponse response) {
    if (response == skir.CommitPreparedEditResponse.committed) {
      throw ArgumentError(
        "A committed reply requires an explicit confirmed document",
      );
    }
    requests[request].response.complete(response);
  }

  void loseReply(int request, Object error) =>
      requests[request].response.completeError(error);
}

final class ScriptedAuthoringRequest {
  ScriptedAuthoringRequest(this.edit);
  final skir.PreparedEdit edit;
  final response = Completer<skir.CommitPreparedEditResponse>();
}

/// Fixtures replace external observations and capabilities. Production workspace and queries run unchanged.
/// Default publication repositories belong to each provider key. A supplied
/// [publication] must match that scope and remains owned by its caller.
List<Override> authoringFixtureOverrides({
  AuthoringScope? scope,
  DisplayState? state,
  AuthoringDocument? document,
  AuthoringSessionState? initial,
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  Iterable<Page> pages = const [],
  CheckedEditorCatalog? catalog,
  ScriptedAuthoringTransport? transport,
  AsyncValue<AuthoringDocument>? observation,
  TestPublicationRepository? publication,
  AuthoredResourceCommands? commands,
  AuthoredResourceCommands Function(Ref, ScriptedAuthoringTransport)?
  commandsFactory,
  void Function(skir.PreparedEdit edit)? onRequest,
}) {
  final source =
      document ??
      initial?.confirmedDocument ??
      fixtureAuthoringDocument(
        books: books,
        tags: tags,
        pages: pages,
        catalog: catalog,
      );
  final scripted =
      transport ??
      ScriptedAuthoringTransport(
        observation ??
            (state == DisplayState.loading
                ? const AsyncLoading<AuthoringDocument>()
                : state == DisplayState.error
                ? AsyncError<AuthoringDocument>(
                    StateError("Realm fixture unavailable"),
                    StackTrace.current,
                  )
                : initial?.failure != null
                ? AsyncError<AuthoringDocument>(
                    initial!.failure!,
                    StackTrace.current,
                  )
                : AsyncData(source)),
        onRequest: onRequest,
      );
  return [
    realmPublicationRepositoryProvider.overrideWith((ref, scopeIds) {
      final (organizationId, realmId) = scopeIds;
      final requested = AuthoringScope(
        organizationId: organizationId,
        realmId: realmId,
      );
      final supplied = publication;
      if (supplied != null) {
        if (supplied.scope != requested) {
          throw StateError(
            "Publication fixture scope does not match the requested realm",
          );
        }
        return supplied;
      }
      final repository = TestPublicationRepository(
        requested,
        initial: PublicationObservation.available(
          skir.PublicationView(
            id: skir.PublicationViewId(value: "fixture:empty"),
            status: skir.PublicationStatus.createEmpty(notices: const []),
          ),
        ),
      );
      ref.onDispose(() => unawaited(repository.close()));
      return repository;
    }),
    selectedAuthoringScopeProvider.overrideWith(
      (ref) =>
          scope ??
          AuthoringScope(
            organizationId:
                ref.watch(organizationIdProvider) ??
                skir.recordId("organization:fixture"),
            realmId:
                ref.watch(realmIdProvider) ?? skir.recordId("realm:fixture"),
          ),
    ),
    confirmedAuthoringDocumentProvider.overrideWith((ref, scope) {
      scripted.addListener(ref.invalidateSelf);
      ref.onDispose(() => scripted.removeListener(ref.invalidateSelf));
      return scripted.observation;
    }),
    localWorkScopeProvider.overrideWith((ref) {
      final selected = ref.watch(selectedAuthoringScopeProvider);
      return LocalWorkScope(
        userId: "fixture",
        organizationId: selected?.organizationId,
      );
    }),
    realmEditPersistenceProvider.overrideWith(
      (ref, scope) => scripted.persistence,
    ),
    authoredResourceCommandsProvider.overrideWith(
      (ref, scope) =>
          commandsFactory?.call(ref, scripted) ??
          commands ??
          fixtureAuthoringCommands(scripted),
    ),
  ];
}

AuthoredResourceCommands fixtureAuthoringCommands(
  ScriptedAuthoringTransport transport, {
  Future<skir.PrepareValueResult> Function(skir.PreparationOperation)?
  prepareStep,
  Future<skir.ResolveResourceOperationsResult> Function(
    skir.ResolveResourceOperationsRequest,
  )?
  resolveResourceOperations,
  Future<skir.ResolveDropCandidatesResult> Function(
    skir.ResolveDropCandidatesRequest,
  )?
  resolveDropCandidates,
  Future<skir.AuthoringActionResult> Function(
    skir.PrepareAuthoringActionRequest,
  )?
  prepareAuthoringAction,
}) => AuthoredResourceCommands(
  previewTypeArguments: ({required resource, required requested}) async =>
      throw StateError("No type preview reply was scripted"),
  prepareTypeArguments: (_) async =>
      throw StateError("No type preparation reply was scripted"),
  prepareValue: (request) async => _fixturePrepareValue(transport, request),
  prepareStep:
      prepareStep ??
      (operation) async =>
          fixturePreparationStep(transport.observation.requireValue, operation),
  invokeCommand: ({required capabilityId, required payload}) async =>
      throw StateError("No command reply was scripted"),
  search: (_) async =>
      throw StateError("No resource search reply was scripted"),
  watchSearch: (_) => Stream.error(StateError("No search reply was scripted")),
  reload: () async {},
  resolveResourceOperations:
      resolveResourceOperations ??
      (_) async => skir.ResolveResourceOperationsResult.wrapResolved(
        skir.ResolvedResourceOperations(operations: const []),
      ),
  resolveDropCandidates:
      resolveDropCandidates ??
      (_) async => skir.ResolveDropCandidatesResult.wrapResolved(const []),
  prepareAuthoringAction:
      prepareAuthoringAction ??
      (_) async =>
          throw StateError("No authoring preparation reply was scripted"),
);

skir.PreparedValue _fixturePrepareValue(
  ScriptedAuthoringTransport transport,
  skir.ValuePreparationRequest request,
) {
  final catalog = transport.observation.requireValue.catalog;
  if (catalog.snapshot.generation != request.catalog) {
    throw StateError("The fixture catalog changed");
  }
  final defaults = transport.observation.requireValue;
  if (request.target case skir.PreparationTarget_valueWrapper(:final value)) {
    final named = catalog.namedUse(value);
    final prepared = named == null
        ? defaults.defaultValue(value)
        : skir.DataValue.createNamed(
            actualType: named,
            payload: skir.DataValue.createRecord(
              fields: [
                for (final field in catalog.fields(
                  skir.TypeSelection.wrapComplete(named),
                ))
                  skir.FieldValue(
                    name: field.template.key,
                    value: defaults.defaultValue(field.type),
                  ),
              ],
            ),
          );
    return skir.PreparedValue(
      content: skir.PreparedContent.wrapValue(
        request.suppliedValue ?? prepared,
      ),
      findings: const [],
    );
  }

  return skir.PreparedValue(
    content: skir.PreparedContent.wrapRecord(
      skir.AuthoringRecord(
        configuration: request.recordSelection,
        fields: [
          for (final field in catalog.fields(request.recordSelection))
            skir.FieldValue(
              name: field.template.key,
              value:
                  request.recordSuppliedFields
                      .firstWhereOrNull(
                        (value) => value.name == field.template.key,
                      )
                      ?.value ??
                  defaults.defaultValue(field.type),
            ),
        ],
      ),
    ),
    findings: const [],
  );
}

/// Portable fixture initialization. Native constructor captures belong to Realm tests.
skir.PrepareValueResult fixturePreparationStep(
  AuthoringDocument document,
  skir.PreparationOperation operation,
) {
  late skir.PreparationTarget target;
  late skir.AuthoringRecord record;
  switch (operation) {
    case skir.PreparationOperation_startWrapper(:final value):
      if (value.catalog != document.generation) {
        throw StateError("The fixture catalog changed");
      }
      target = value.target;
      record = skir.AuthoringRecord(
        configuration: value.recordSelection,
        fields: [
          for (final field in document.catalog.fields(value.recordSelection))
            skir.FieldValue(
              name: field.template.key,
              value:
                  value.recordSuppliedFields
                      .firstWhereOrNull(
                        (input) => input.name == field.template.key,
                      )
                      ?.value ??
                  document.defaultValue(field.type),
            ),
        ],
      );
    case skir.PreparationOperation_resumeWrapper(:final value):
      if (value.draft.catalog != document.generation) {
        throw StateError("The fixture catalog changed");
      }
      target = value.draft.target;
      record = switch (value.draft.content) {
        skir.PreparedContent_recordWrapper(:final value) => value,
        _ => throw StateError("Fixture preparation requires record content"),
      };
      for (final answer in value.answers) {
        record = switch (record.replaceAt(answer.path, answer.value)) {
          PortablePathValue(:final value) => value,
          PortablePathUnavailable(:final message) => throw StateError(message),
        };
      }
    case skir.PreparationOperation_unknown():
      throw StateError("Unknown fixture preparation operation");
  }
  final required = <skir.RequiredInput>[];
  void visit(skir.DataValue value, skir.ValuePath path) {
    if (value.authoredPayload == skir.DataValue.unfilled) {
      final expected = document.catalog.valueTypeAt(record.configuration, path);
      if (expected != null) {
        required.add(skir.RequiredInput(path: path, expected: expected));
      }
      return;
    }
    for (final field
        in value.authoredRecord?.fields ?? const <skir.FieldValue>[]) {
      visit(
        field.value,
        skir.ValuePath(
          segments: [
            ...path.segments,
            skir.PathSegment.createField(name: field.name),
          ],
        ),
      );
    }
    for (final item in value.authoredItems ?? const <skir.ListItem>[]) {
      visit(
        item.value,
        skir.ValuePath(
          segments: [
            ...path.segments,
            skir.PathSegment.createItem(id: item.id),
          ],
        ),
      );
    }
  }

  visit(
    skir.DataValue.createRecord(fields: record.fields),
    skir.ValuePath(segments: const []),
  );
  final content = skir.PreparedContent.wrapRecord(record);
  if (required.isEmpty) {
    return skir.PrepareValueResult.wrapReady(
      skir.PreparedValue(content: content, findings: const []),
    );
  }
  return skir.PrepareValueResult.wrapNeedsInput(
    skir.PreparationDraft(
      catalog: document.generation,
      target: target,
      content: content,
      pendingDefaults: const [],
      requiredInputs: required,
      findings: const [],
    ),
  );
}

/// The realm root of a fixture document built with `realm: true`.
final fixtureRealmRootId = skir.ResourceId(value: "fixture:realm");

/// The Library section of a fixture document built with `realm: true`.
final fixtureLibraryId = skir.ResourceId(value: "fixture:library");

/// The tags section of a fixture document built with `realm: true`.
final fixtureTaxonomyId = skir.ResourceId(value: "fixture:taxonomy");

/// A working document holding [books], [tags] and [pages]. With [realm], the
/// document also holds the realm root owning a Library and a tags section,
/// which own every Book and Tag, as Realm provisions them.
AuthoringDocument fixtureAuthoringDocument({
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  Iterable<Page> pages = const [],
  CheckedEditorCatalog? catalog,
  bool realm = false,
}) {
  final entries = <skir.ResourceId, skir.AuthoringResource>{};
  final projections = <skir.LinkProjection>[];
  void record(
    skir.ResourceId id,
    String kind,
    Map<String, skir.DataValue> fields,
  ) => entries[id] = skir.AuthoringResource(
    id: id,
    content: skir.AuthoringRecord(
      configuration: _selection(kind),
      fields: [
        for (final entry in fields.entries) _field(entry.key, entry.value),
      ],
    ),
  );
  skir.ValuePath fieldPath(String field) =>
      skir.ValuePath(segments: [skir.PathSegment.createField(name: field)]);

  /// The owner's list of links to [targets] for [spec], projecting each link
  /// with the member's back reference when the relation declares one.
  skir.DataValue links(
    skir.ResourceId source,
    Iterable<skir.ResourceId> targets,
    _FixtureRelation spec,
  ) {
    final items = <skir.ListItem>[];
    for (final (index, target) in targets.indexed) {
      final item = skir.ItemId(
        value: "fixture:${source.value}:${spec.field}:$index",
      );
      final path = skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: spec.field),
          skir.PathSegment.createItem(id: item),
        ],
      );
      final opposite = spec.backReference == null
          ? null
          : fieldPath(spec.backReference!);
      items.add(
        skir.ListItem(
          id: item,
          value: _named(
            "${spec.kind}Link",
            skir.DataValue.createLink(
              endpoint: spec.first,
              target: skir.LinkTarget(resource: target, opposite: opposite),
            ),
          ),
        ),
      );
      projections.add(
        skir.LinkProjection(
          contract: spec.id,
          first: source,
          second: target,
          firstLocation: path,
          secondLocation: opposite,
        ),
      );
    }
    return _named(
      "${spec.kind}Collection",
      spec.list
          ? skir.DataValue.createListValue(items: items)
          : skir.DataValue.createSetValue(items: items),
    );
  }

  skir.DataValue backReference(skir.ResourceId? owner, _FixtureRelation spec) =>
      owner == null
      ? skir.DataValue.unfilled
      : _named(
          "${spec.kind}BackLink",
          skir.DataValue.createLink(
            endpoint: spec.second,
            target: skir.LinkTarget(resource: owner, opposite: null),
          ),
        );

  final pageList = pages.toList();
  final bookList = books.toList();
  final tagList = tags.toList();
  if (realm) {
    record(fixtureRealmRootId, "realm", {
      "sections": links(fixtureRealmRootId, [
        fixtureLibraryId,
        fixtureTaxonomyId,
      ], _realmSections),
    });
    record(fixtureLibraryId, "library", {
      "books": links(
        fixtureLibraryId,
        bookList.map((book) => book.bookId),
        _libraryBooks,
      ),
    });
    record(fixtureTaxonomyId, "taxonomy", {
      "tags": links(
        fixtureTaxonomyId,
        tagList.map((tag) => tag.tagId),
        _taxonomyTags,
      ),
    });
  }
  for (final tag in tagList) {
    record(tag.tagId, "tag", {
      "name": skir.DataValue.wrapStringValue(tag.name),
      "color": _integer(tag.color.toARGB32()),
      "parents": links(tag.tagId, tag.parentIds, _tagParents),
      "placement": _named(
        "placement",
        skir.DataValue.createRecord(
          fields: [
            _field("x", _integer(tag.placement.x)),
            _field("y", _integer(tag.placement.y)),
            _field("width", _integer(tag.placement.width)),
            _field("height", _integer(tag.placement.height)),
          ],
        ),
      ),
      "taxonomy": backReference(
        realm ? fixtureTaxonomyId : null,
        _taxonomyTags,
      ),
    });
  }
  for (final book in bookList) {
    record(book.bookId, "book", {
      "title": skir.DataValue.wrapStringValue(book.title),
      "color": _integer(book.color.toARGB32()),
      "icon": _named(
        "icon",
        skir.DataValue.createRecord(
          fields: [_field("value", skir.DataValue.wrapStringValue(book.icon))],
        ),
      ),
      "tags": links(book.bookId, book.tagIds, _bookTags),
      "pages": links(
        book.bookId,
        pageList
            .where((page) => page.bookId == book.bookId)
            .map((page) => page.pageId),
        _bookPages,
      ),
      "library": backReference(realm ? fixtureLibraryId : null, _libraryBooks),
    });
  }
  for (final page in pageList) {
    record(page.pageId, "page", {
      "name": skir.DataValue.wrapStringValue(page.name),
      "chapter": skir.DataValue.wrapStringValue(page.chapter),
      "priority": _integer(page.priority),
      "book": backReference(page.bookId, _bookPages),
    });
  }
  return AuthoringDocument(
    confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
    catalog: catalog ?? authoringFixtureCatalog(),
    entries: entries,
    links: projections,
  );
}

/// One relation of the fixture catalog: the [field] of the first endpoint's
/// resource lists links to the second's, which optionally link back through
/// [backReference].
final class _FixtureRelation {
  const _FixtureRelation({
    required this.kind,
    required this.relation,
    required this.owner,
    required this.field,
    required this.member,
    this.backReference,
    this.ownership = false,
    this.list = true,
  });

  final String kind;
  final String relation;
  final String owner;
  final String field;
  final String member;
  final String? backReference;
  final bool ownership;
  final bool list;

  skir.RelationId get id => skir.RelationId(value: relation);
  skir.EndpointId get first => skir.EndpointId(value: "$relation:first");
  skir.EndpointId get second => skir.EndpointId(value: "$relation:second");
}

const _realmSections = _FixtureRelation(
  kind: "realmSections",
  relation: "fixture.realm.sections",
  owner: "realm",
  field: "sections",
  member: "section",
  ownership: true,
);
const _libraryBooks = _FixtureRelation(
  kind: "libraryBooks",
  relation: "fixture.library.books",
  owner: "library",
  field: "books",
  member: "book",
  backReference: "library",
  ownership: true,
);
const _taxonomyTags = _FixtureRelation(
  kind: "taxonomyTags",
  relation: "fixture.taxonomy.tags",
  owner: "taxonomy",
  field: "tags",
  member: "tag",
  backReference: "taxonomy",
  ownership: true,
);
const _tagParents = _FixtureRelation(
  kind: "tagParents",
  relation: "fixture.tag.parents",
  owner: "tag",
  field: "parents",
  member: "tag",
  list: false,
);
const _bookTags = _FixtureRelation(
  kind: "bookTags",
  relation: "fixture.book.tags",
  owner: "book",
  field: "tags",
  member: "tag",
  list: false,
);

/// The relation by which fixture Books own pages.
const fixtureBookPagesRelation = "fixture.book.pages";

const _bookPages = _FixtureRelation(
  kind: "bookPages",
  relation: fixtureBookPagesRelation,
  owner: "book",
  field: "pages",
  member: "page",
  backReference: "book",
  ownership: true,
);
const _fixtureRelations = [
  _realmSections,
  _libraryBooks,
  _taxonomyTags,
  _tagParents,
  _bookTags,
  _bookPages,
];

/// The type of resource [kind] in the fixture catalog.
skir.TypeDefinitionId fixtureResourceType(String kind) => _definition(kind);

/// A catalog standing in for Realm's library: a realm root owning a Library
/// and a tags section, Books owning pages, and Tags with parents. Pages have a
/// workspace and Books a chapter tree navigator, so surfaces resolve as they
/// do against Realm.
CheckedEditorCatalog authoringFixtureCatalog({
  skir.CatalogGeneration? generation,
}) {
  final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final integer = skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
  );
  final fields = <String, Map<String, skir.TypeTemplate>>{
    "realm": {"sections": _template("realmSectionsCollection")},
    "library": {"books": _template("libraryBooksCollection")},
    "taxonomy": {"tags": _template("taxonomyTagsCollection")},
    "tag": {
      "name": text,
      "color": integer,
      "parents": _template("tagParentsCollection"),
      "placement": _template("placement"),
      "taxonomy": _template("taxonomyTagsBackLink"),
    },
    "book": {
      "title": text,
      "color": integer,
      "icon": _template("icon"),
      "tags": _template("bookTagsCollection"),
      "pages": _template("bookPagesCollection"),
      "library": _template("libraryBooksBackLink"),
    },
    "page": {
      "name": text,
      "chapter": text,
      "priority": integer,
      "book": _template("bookPagesBackLink"),
    },
    "placement": {
      "x": integer,
      "y": integer,
      "width": integer,
      "height": integer,
    },
    "icon": {"value": text},
    "hierarchyGroup": {
      "path": text,
      "name": text,
      "members": skir.TypeTemplate.createNamed(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "typewriter",
            name: "List",
          ),
          revision: 1,
        ),
        arguments: [
          skir.TypeTemplate.createNamed(
            definition: frameworkResourceIdUse.definition,
            arguments: const [],
          ),
        ],
      ),
    },
  };
  const sectionKinds = {"library", "taxonomy"};
  // Resource types publish a search key, as the Kotlin catalog does.
  const resourceKinds = {"realm", ...sectionKinds, "tag", "book", "page"};
  final types = <skir.PublishedType>[
    _published(
      "section",
      skir.RepresentationTemplate.createRecord(abstract_: true, fields: []),
    ),
    for (final type in fields.entries)
      _published(
        type.key,
        skir.RepresentationTemplate.createRecord(
          abstract_: false,
          fields: [
            for (final field in type.value.entries)
              skir.FieldDeclaration(
                owner: skir.FieldOwner(
                  definition: _definition(type.key),
                  name: field.key,
                ),
                type: field.value,
                overrides: const [],
                hasConstructorDefault: false,
              ),
          ],
        ),
        fields: type.value,
        ancestors: sectionKinds.contains(type.key) ? ["section"] : const [],
        searchKey: resourceKinds.contains(type.key) ? type.key : null,
      ),
  ];
  final relations = <skir.RelationContract>[];
  final bindings = <skir.EndpointBindingTemplate>[];
  for (final spec in _fixtureRelations) {
    types.add(
      _published(
        "${spec.kind}Link",
        skir.RepresentationTemplate.createLink(
          endpoint: spec.first,
          target: _template(spec.member),
        ),
      ),
    );
    types.add(
      _published(
        "${spec.kind}Collection",
        skir.RepresentationTemplate.createSequence(
          item: _template("${spec.kind}Link"),
          kind: spec.list ? skir.CollectionKind.list : skir.CollectionKind.set_,
        ),
      ),
    );
    bindings.add(
      skir.EndpointBindingTemplate(
        endpoint: spec.first,
        containingResource: _namedTemplate(spec.owner),
        valueOwner: _definition(spec.owner),
        relativePath: skir.RelativeFieldPattern(
          segments: [
            skir.FieldPatternSegment.createField(name: spec.field),
            skir.FieldPatternSegment.items,
          ],
        ),
        target: _template(spec.member),
        containsCollection: true,
      ),
    );
    if (spec.backReference case final field?) {
      types.add(
        _published(
          "${spec.kind}BackLink",
          skir.RepresentationTemplate.createLink(
            endpoint: spec.second,
            target: _template(spec.owner),
          ),
        ),
      );
      bindings.add(
        skir.EndpointBindingTemplate(
          endpoint: spec.second,
          containingResource: _namedTemplate(spec.member),
          valueOwner: _definition(spec.member),
          relativePath: skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: field)],
          ),
          target: _template(spec.owner),
          containsCollection: false,
        ),
      );
    }
    relations.add(
      skir.RelationContract(
        id: spec.id,
        first: skir.EndpointDefinition(
          id: spec.first,
          slot: skir.EndpointSlot.first,
          resource: _namedTemplate(spec.owner),
          cardinality: spec.ownership
              ? skir.EndpointCardinality.one
              : skir.EndpointCardinality.many,
          onDelete: spec.ownership
              ? skir.RelationDeletePolicy.cascade
              : skir.RelationDeletePolicy.clear,
        ),
        second: skir.EndpointDefinition(
          id: spec.second,
          slot: skir.EndpointSlot.second,
          resource: _namedTemplate(spec.member),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: spec.ownership ? [skir.resourceOwnershipFamily] : const [],
      ),
    );
  }
  final descriptors = <skir.PresentationDescriptor>[];
  final materials = <skir.PresentationMaterial>[];
  void present(
    String kind,
    skir.PresentationRole role,
    skir.PresentationNode layout,
  ) {
    final target = skir.PresentationTarget.createNamed(
      definition: _definition(kind),
      arguments: const [],
    );
    final id = skir.PresentationId(
      namespace: "fixture",
      name: "$kind.${role.kind.name}",
    );
    descriptors.add(
      skir.PresentationDescriptor(
        id: id,
        owner: skir.DeclarationOwner.defaultInstance,
        target: target,
        roles: [role],
        priority: 0,
      ),
    );
    materials.add(
      skir.PresentationMaterial(
        inheritableNodes: const [],
        provider: id,
        target: target,
        role: role,
        subject: _template(kind),
        dependencies: skir.PresentationDependencies.defaultInstance,
        layout: layout,
      ),
    );
  }

  skir.BindingRef field(String name) => skir.BindingRef(
    bindingId: configuredValueBindingId,
    path: skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]),
  );
  for (final kind in ["tag", "book", "page"]) {
    final reference = field(kind == "book" ? "title" : "name");
    final input = skir.PresentationNode(
      nodeId: "fixture.$kind.${reference.path.segments.single}",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.createTextInput(
        control: skir.BoundControl(
          binding: reference,
          label: _literal(kind == "book" ? "title" : "name"),
          description: null,
          prefix: null,
          semanticLabel: null,
        ),
        appearance: null,
        content: null,
        entry: null,
        mappings: null,
        options: skir.TextEditingOptions.defaultInstance,
      ),
    );
    final label = skir.PresentationNode(
      nodeId: "fixture.$kind.label",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.wrapText(
        (skir.TextContent.mutable()
              ..value = skir.ExpressionNode.createInput(
                binding: reference.bindingId,
                path: reference.path,
              ))
            .toFrozen(),
      ),
    );
    present(kind, skir.PresentationRole.inspector, input);
    present(kind, skir.PresentationRole.referencePreview, label);
    if (kind == "page") present(kind, skir.PresentationRole.workspace, input);
    if (kind == "tag") present(kind, skir.PresentationRole.item, label);
  }
  skir.PresentationNode resources(
    String id,
    String linkField,
    skir.ResourcesLayout layout, {
    skir.ExpressionNode? order,
  }) => skir.PresentationNode(
    nodeId: id,
    properties: skir.PresentationProperties.defaultInstance,
    header: null,
    element: skir.PresentationElement.createResources(
      control: skir.BoundControl(
        binding: field(linkField),
        label: null,
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      layout: layout,
      order: order,
      itemBindingId: fixtureResourcesItemBinding,
    ),
  );
  present(
    "realm",
    skir.PresentationRole.navigator,
    resources("fixture.realm.sections", "sections", skir.ResourcesLayout.list),
  );
  present(
    "library",
    skir.PresentationRole.workspace,
    resources(
      "fixture.library.books",
      "books",
      skir.ResourcesLayout.createGrid(
        itemExtent: _number(240),
        aspectRatio: _number(0.72),
        spacing: _number(16),
      ),
    ),
  );
  present(
    "taxonomy",
    skir.PresentationRole.workspace,
    resources(
      "fixture.taxonomy.tags",
      "tags",
      skir.ResourcesLayout.createGraph(
        direction: skir.GraphDirection.topToBottom,
        appearance: null,
      ),
    ),
  );
  final group = skir.ExpressionBindingId(value: "fixture.book.chapter");
  present(
    "book",
    skir.PresentationRole.navigator,
    resources(
      "fixture.book.pages",
      "pages",
      order: skir.ExpressionNode.wrapLinkTarget(
        skir.ExpressionNode.createInput(
          binding: fixtureResourcesItemBinding,
          path: editorRootPath,
        ),
      ),
      skir.ResourcesLayout.createTree(
        path: editorRootPath.field("chapter"),
        groupBindingId: group,
        connectors: null,
        initiallyExpanded: true,
        group: skir.PresentationNode(
          nodeId: "fixture.book.chapter",
          properties: skir.PresentationProperties.defaultInstance,
          header: null,
          element: skir.PresentationElement.wrapChildren(
            skir.ChildrenElement.createWrap(
              children: [
                skir.PresentationNode(
                  nodeId: "fixture.book.chapter.name",
                  properties: skir.PresentationProperties.defaultInstance,
                  header: null,
                  element: skir.PresentationElement.wrapText(
                    (skir.TextContent.mutable()
                          ..value = skir.ExpressionNode.createInput(
                            binding: group,
                            path: editorRootPath.field("name"),
                          ))
                        .toFrozen(),
                  ),
                ),
                skir.PresentationNode(
                  nodeId: "fixture.book.chapter.create",
                  properties: skir.PresentationProperties.defaultInstance,
                  header: null,
                  element: skir.PresentationElement.createButton(
                    label: _literal("New page"),
                    action: skir.EditorAction.createCreate(
                      type: _definition("page"),
                      owner: field("pages"),
                      fields: [
                        skir.CreateFieldValue(
                          path: editorRootPath.field("chapter"),
                          value: skir.ExpressionNode.createInput(
                            binding: group,
                            path: editorRootPath.field("path"),
                          ),
                        ),
                      ],
                    ),
                    appearance: null,
                    icon: null,
                  ),
                ),
              ],
              layout: skir.WrapChildrenLayout.defaultInstance,
            ),
          ),
        ),
      ),
    ),
  );
  return CheckedEditorCatalog(
    skir.EditorCatalog(
      resourceDisplays: _fixtureDisplays,
      resourceOperations: const [],
      generation:
          generation ??
          skir.CatalogGeneration(value: realmFixtureGeneration.value),
      types: types,
      relations: relations,
      realmRoot: _definition("realm"),
      presentations: descriptors,
      presentationMaterials: materials,
      configuration: const [],
      diagnostics: const [],
      endpointBindings: bindings,
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
}

/// The item binding of every fixture resources layout.
final fixtureResourcesItemBinding = skir.ExpressionBindingId(
  value: "fixture.resources.item",
);

skir.ExpressionNode _literal(String value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));
skir.ExpressionNode _number(double value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(value));

/// The displays Realm publishes for the framework Book, Tag and Page and for
/// any resource, retargeted to the fixture types standing in for them, so
/// fixture resources are named exactly as Realm names them.
final _fixtureDisplays = [
  for (final display in compiledSdkControlCatalog.resourceDisplays)
    if (display.target == skir.ResourceTarget.anyResource)
      display
    else if (_displayStandIns[_displayTarget(display)] case final name?)
      skir.ResourceDisplayFormulas(
        target: skir.ResourceTarget.wrapType(_template(name)),
        label: display.label,
        accent: display.accent,
        icon: display.icon,
      ),
];

final _displayStandIns = {
  skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "bbb646b300cf4dd2b7aab051854e4dd1",
    ),
    revision: 1,
  ): "book",
  skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "ce1ae253a42d4509935c48b8ecba664a",
    ),
    revision: 1,
  ): "tag",
  skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "kotlin",
      name: "com.typewritermc.library.Page",
    ),
    revision: 1,
  ): "page",
};

skir.TypeDefinitionId? _displayTarget(skir.ResourceDisplayFormulas display) =>
    switch (display.target) {
      skir.ResourceTarget_typeWrapper(
        value: skir.TypeTemplate_namedWrapper(:final value),
      ) =>
        value.definition,
      _ => null,
    };

/// Fixture types standing in for framework types keep the framework identity,
/// so production readers such as graph placement recognize their values.
final _frameworkDefinitions = {
  "placement": graphPlacementTypeRef,
  "hierarchyGroup": hierarchyGroupUse.definition,
};

skir.TypeDefinitionId _definition(String name) =>
    _frameworkDefinitions[name] ??
    skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(namespace: "fixture", name: name),
      revision: 1,
    );
skir.NamedTypeUse _use(String name) =>
    skir.NamedTypeUse(definition: _definition(name), arguments: const []);
skir.TypeSelection _selection(String name) =>
    skir.TypeSelection.wrapComplete(_use(name));
skir.NamedTypeTemplate _namedTemplate(String name) =>
    skir.NamedTypeTemplate(definition: _definition(name), arguments: const []);
skir.TypeTemplate _template(String name) =>
    skir.TypeTemplate.wrapNamed(_namedTemplate(name));
skir.DataValue _named(String name, skir.DataValue payload) =>
    skir.DataValue.createNamed(actualType: _use(name), payload: payload);
skir.DataValue _integer(int value) =>
    skir.DataValue.wrapInteger(value.toString());
skir.FieldValue _field(String name, skir.DataValue value) =>
    skir.FieldValue(name: name, value: value);
skir.PublishedType _published(
  String name,
  skir.RepresentationTemplate representation, {
  Map<String, skir.TypeTemplate> fields = const {},
  List<String> ancestors = const [],
  String? searchKey,
}) => skir.PublishedType(
  searchKey: searchKey,
  placementField: fields.containsKey("placement")
      ? editorRootPath.field("placement")
      : null,
  definition: skir.TypeDefinition(
    id: _definition(name),
    parameters: const [],
    representation: representation,
    parents: [for (final ancestor in ancestors) _namedTemplate(ancestor)],
  ),
  display: defaultTypeDisplay(""),
  status: skir.DeclarationStatus.ready,
  effectiveFields: [
    for (final field in fields.entries)
      skir.EffectiveFieldTemplate(
        key: field.key,
        owner: skir.FieldOwner(definition: _definition(name), name: field.key),
        type: field.value,
        rules: const [],
      ),
  ],
  ancestorTemplates: [
    for (final ancestor in ancestors) _namedTemplate(ancestor),
  ],
);

/// External reply control composed with the production editing owner.
RealmEditPersistence fixtureRealmPersistence({
  required Future<skir.CommitPreparedEditResponse> Function(skir.PreparedEdit)
  commit,
  required Future<AuthoringDocument> Function() confirmed,
}) => RealmEditPersistence(
  reservations: (edits) => {for (final edit in edits) ...edit.editedResources},
  observe: confirmed,
  request: (edit) => PreparedCommit(
    id: Object(),
    label: "Apply fixture changes",
    resources: edit.editedResources.toSet(),
    send: () async {
      final response = await commit(edit);
      return switch (response) {
        skir.CommitPreparedEditResponse_internalErrorWrapper() ||
        skir.CommitPreparedEditResponse_unknown() => SubmissionResult.uncertain(
          message: "Unknown fixture outcome",
          cause: response,
          stackTrace: StackTrace.current,
        ),
        skir.CommitPreparedEditResponse.committed => SubmissionResult.confirmed(
          response,
        ),
        _ => SubmissionResult.rejected(
          message: response.rejectionMessage,
          response: response,
        ),
      };
    },
  ),
);
