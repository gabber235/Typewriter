import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test(
    "deleting an owner removes the complete cascade from working queries",
    () {
      final document = _document();
      final container = ProviderContainer.test(
        overrides: authoringFixtureOverrides(document: document),
      );
      addTearDown(container.dispose);
      final workspace = container.read(
        authoringWorkspaceProvider(
          container.read(selectedAuthoringScopeProvider)!,
        ),
      );
      final result = workspace.edit(
        label: "Delete book",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.delete(_book),
      );
      expect(result, isA<AuthoringEditStaged>());
      expect(workspace.document.entry(_book), isNull);
      expect(workspace.document.entry(_page), isNull);
      expect(container.read(workingBooksProvider).requireValue, isEmpty);
      expect(container.read(workingPagesProvider).requireValue, isEmpty);
      expect(container.read(workingTagsProvider).requireValue, hasLength(2));
      expect(workspace.state.groups.values.single.resources, {_book, _page});
      workspace.discard((result as AuthoringEditStaged).group);
      expect(container.read(workingPagesProvider).requireValue, hasLength(1));
    },
  );

  test("deleting a linked page clears the owner's exact collection item", () {
    final document = _document();
    final edit = AuthoringEdit.fromDocument(document)..delete(_page);
    expect(
      edit.resource(_book)!.authoredField("pages")!.authoredItems,
      isEmpty,
    );
    expect(
      edit.links.any((link) => link.first == _page || link.second == _page),
      isFalse,
    );
    expect(edit.intents.single, isA<skir.EditIntent_deleteResourceWrapper>());
    expect(
      edit.expectations.whereType<skir.EditExpectation_valueWrapper>().any(
        (fact) => fact.value.at.resource == _book,
      ),
      isTrue,
    );
  });

  test("tag deletion clears surviving parents and book links together", () {
    final edit = AuthoringEdit.fromDocument(_document())..delete(_parent);
    expect(
      edit.resource(_child)!.authoredField("parents")!.authoredItems,
      isEmpty,
    );
    expect(edit.resource(_book)!.authoredField("tags")!.authoredItems, isEmpty);
    expect(edit.resource(_page), isNotNull);
    expect(
      edit.links.any((link) => link.first == _parent || link.second == _parent),
      isFalse,
    );
  });

  test(
    "restrict policy rejects deletion without publishing a partial batch",
    () {
      final original = _document();
      final wire = original.catalog.snapshot;
      final relations = [
        for (final relation in wire.relations)
          if (relation.id.value == "fixture.book.tags")
            skir.RelationContract(
              id: relation.id,
              first: relation.first,
              second: skir.EndpointDefinition(
                id: relation.second.id,
                slot: relation.second.slot,
                resource: relation.second.resource,
                cardinality: relation.second.cardinality,
                onDelete: skir.RelationDeletePolicy.restrict,
              ),
              families: relation.families,
            )
          else
            relation,
      ];
      final changed = wire.toMutable()..relations = relations;
      final document = original.copyWith(
        catalog: CheckedEditorCatalog(changed.toFrozen()),
      );
      final transport = ScriptedAuthoringTransport(AsyncData(document));
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: document,
      );
      addTearDown(workspace.dispose);
      addTearDown(transport.dispose);
      final before = workspace.document;
      final result = workspace.edit(
        label: "Invalid batch",
        apply: (edit) {
          edit
            ..set(
              authoredFieldLocation(_book, ["title"]),
              skir.DataValue.wrapStringValue("Changed"),
            )
            ..delete(_parent);
        },
      );
      expect(result, isA<AuthoringEditRejected>());
      expect(workspace.document, before);
      expect(workspace.state.groups, isEmpty);
    },
  );

  test("invalid relation locations reject their whole operation", () {
    final document = _document();
    final transport = ScriptedAuthoringTransport(AsyncData(document));
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: document,
    );
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
    final before = workspace.document;
    final result = workspace.edit(
      label: "Invalid connection",
      apply: (edit) {
        edit
          ..set(
            authoredFieldLocation(_child, ["name"]),
            skir.DataValue.wrapStringValue("Changed"),
          )
          ..connect(
            skir.LinkOccurrence(
              id: skir.LinkOccurrenceId(
                endpoint: skir.EndpointId(value: "fixture.tag.parents.first"),
                location: authoredFieldLocation(_child, ["absent"]),
              ),
              source: _child,
              target: skir.LinkTarget(resource: _parent, opposite: null),
            ),
            _parent,
          );
      },
    );
    expect(result, isA<AuthoringEditRejected>());
    expect(workspace.document, before);
  });
  test("missing relation targets reject a prepared batch", () {
    final document = _document();
    final transport = ScriptedAuthoringTransport(AsyncData(document));
    final workspace = AuthoringWorkspace(
      transport: transport,
      initial: document,
    );
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
    final before = workspace.document;
    final missing = skir.ResourceId(value: "missing");
    final result = workspace.edit(
      label: "Invalid target",
      apply: (edit) {
        edit
          ..set(
            authoredFieldLocation(_child, ["name"]),
            skir.DataValue.wrapStringValue("Changed"),
          )
          ..connect(
            skir.LinkOccurrence(
              id: skir.LinkOccurrenceId(
                endpoint: skir.EndpointId(value: "fixture.tag.parents.first"),
                location: skir.ValueLocation(
                  resource: _child,
                  path: skir.ValuePath(
                    segments: [
                      skir.PathSegment.createField(name: "parents"),
                      skir.PathSegment.createItem(
                        id: skir.ItemId(value: "new"),
                      ),
                    ],
                  ),
                ),
              ),
              source: _child,
              target: skir.LinkTarget(resource: missing, opposite: null),
            ),
            missing,
          );
      },
    );
    expect(result, isA<AuthoringEditRejected>());
    expect(workspace.document, before);
    expect(workspace.state.groups, isEmpty);
  });
}

final _book = skir.ResourceId(value: "book");
final _page = skir.ResourceId(value: "page");
final _parent = skir.ResourceId(value: "parent");
final _child = skir.ResourceId(value: "child");
AuthoringDocument _document() => fixtureAuthoringDocument(
  books: [
    Book(
      bookId: _book,
      title: "Book",
      icon: "mdi:book",
      color: Colors.blue,
      tagIds: [_parent],
    ),
  ],
  tags: [
    Tag(
      tagId: _parent,
      name: "Parent",
      color: Colors.blue,
      parentIds: const [],
      placement: const GraphPlacement(x: 0, y: 0, width: 2, height: 1),
    ),
    Tag(
      tagId: _child,
      name: "Child",
      color: Colors.blue,
      parentIds: [_parent],
      placement: const GraphPlacement(x: 2, y: 0, width: 2, height: 1),
    ),
  ],
  pages: [
    Page(
      pageId: _page,
      bookId: _book,
      name: "Page",
      configuration: skir.TypeSelection.unknown,
      chapter: "",
      priority: 0,
    ),
  ],
);
