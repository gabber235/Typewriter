import "dart:async";

// ignore: implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "realm_catalog_fixture.dart";

class AuthoringSessionMock extends AuthoringSession {
  AuthoringSessionMock({AuthoringSessionState? initial, this.onApply})
    : initial = initial ?? _fixtureState(books: const [], tags: const []);
  final AuthoringSessionState initial;
  final FutureOr<void> Function(List<skir.EditIntent> intents)? onApply;

  @override
  Future<void> refresh({bool catalog = false}) async {}

  @override
  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => initial;

  @override
  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) async {
    await onApply?.call(edit.intents.toList(growable: false));
    return skir.CommitPreparedEditResponse.wrapResult(
      skir.CommitResult.createCommitted(
        snapshot:
            state.snapshot?.snapshot ?? skir.SnapshotId(value: "fixture:1"),
        changed: const [],
      ),
    );
  }
}

List<Override> authoringSessionMockOverrides({
  AuthoringSessionState? initial,
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  bool includeCatalog = true,
  CheckedEditorCatalog? catalog,
  FutureOr<void> Function(List<skir.EditIntent> intents)? onApply,
}) {
  assert(
    initial == null || (books.isEmpty && tags.isEmpty),
    "Use either an initial state or domain fixtures",
  );
  final base = initial ?? _fixtureState(books: books, tags: tags);
  final state = base.copyWith(
    catalog: includeCatalog
        ? catalog ?? base.catalog ?? receivedCheckedEditorCatalog()
        : null,
  );
  return [
    authoringSessionProvider.overrideWith2(
      (_) => AuthoringSessionMock(initial: state, onApply: onApply),
    ),
  ];
}

AuthoringSessionState _fixtureState({
  required Iterable<Book> books,
  required Iterable<Tag> tags,
}) {
  final generation = skir.CatalogGeneration(
    value: realmFixtureGeneration.value,
  );
  return AuthoringSessionState(
    catalog: receivedCheckedEditorCatalog(generation: generation),
    snapshot: skir.AuthoringSnapshot(
      snapshot: skir.SnapshotId(value: "fixture:1"),
      generation: generation,
      resources: [
        for (final book in books) _bookResource(book),
        for (final tag in tags) _tagResource(tag),
      ],
      links: const [],
      findings: const [],
      observations: const [],
      absentInputToken: skir.InputToken(value: "absent"),
      findingsToken: skir.FindingsToken(value: "fixture:findings"),
    ),
  );
}

skir.AuthoringResource _bookResource(Book book) => skir.AuthoringResource(
  id: book.bookId,
  definition: skir.ResourceDefinitionId(value: "typewriter.book"),
  content: skir.AuthoringRecord(
    configuration: skir.TypeSelection.unknown,
    fields: [
      _field("title", skir.DataValue.wrapStringValue(book.title)),
      _field(
        "icon",
        _named(
          skir.DataValue.createRecord(
            fields: [
              _field("wireValue", skir.DataValue.wrapStringValue(book.icon)),
            ],
          ),
        ),
      ),
      _field(
        "color",
        _named(
          skir.DataValue.wrapInteger(
            book.color.toARGB32().toUnsigned(32).toString(),
          ),
        ),
      ),
      _field("tags", _links(book.tagIds, endpoint: "typewriter.book.tags")),
    ],
  ),
);

skir.AuthoringResource _tagResource(Tag tag) => skir.AuthoringResource(
  id: tag.tagId,
  definition: skir.ResourceDefinitionId(value: "typewriter.tag"),
  content: skir.AuthoringRecord(
    configuration: skir.TypeSelection.unknown,
    fields: [
      _field("name", skir.DataValue.wrapStringValue(tag.name)),
      _field(
        "color",
        _named(
          skir.DataValue.wrapInteger(
            tag.color.toARGB32().toUnsigned(32).toString(),
          ),
        ),
      ),
      _field(
        "parents",
        _links(tag.parentIds, endpoint: "typewriter.tag.parents"),
      ),
      _field(
        "placement",
        _named(
          skir.DataValue.createRecord(
            fields: [
              _field(
                "x",
                skir.DataValue.wrapInteger(tag.placement.x.toString()),
              ),
              _field(
                "y",
                skir.DataValue.wrapInteger(tag.placement.y.toString()),
              ),
              _field(
                "width",
                skir.DataValue.wrapInteger(tag.placement.width.toString()),
              ),
              _field(
                "height",
                skir.DataValue.wrapInteger(tag.placement.height.toString()),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

skir.FieldValue _field(String name, skir.DataValue value) =>
    skir.FieldValue(name: name, value: value);

skir.DataValue _named(skir.DataValue payload) => skir.DataValue.createNamed(
  actualType: skir.NamedTypeUse.defaultInstance,
  payload: payload,
);

skir.DataValue _links(
  Iterable<skir.ResourceId> resources, {
  required String endpoint,
}) => _named(
  skir.DataValue.createSetValue(
    items: [
      for (final (index, resource) in resources.indexed)
        skir.ListItem(
          id: skir.ItemId(value: "fixture:$index:${resource.value}"),
          value: _link(resource, endpoint),
        ),
    ],
  ),
);

skir.DataValue _link(skir.ResourceId target, String endpoint) => _named(
  skir.DataValue.createLink(
    endpoint: skir.EndpointId(value: endpoint),
    target: skir.LinkTarget(resource: target, opposite: null),
  ),
);

CheckedEditorCatalog authoringFixtureCatalog() =>
    receivedCheckedEditorCatalog();
