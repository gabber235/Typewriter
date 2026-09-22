import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test(
    "Book selection uses Realm presentations and authoritative collections",
    () {
      final fixture = _bookSelection("first");

      expect(fixture.selection.presentations, [fixture.presentation]);
      expect(fixture.selection.collections, [fixture.collection]);
      expect(
        fixture.selection.multiInspection.id,
        const PresentationId(
          namespace: "typewriter.authoring",
          name: "typewriter.book",
        ),
      );
    },
  );

  test("Book multi inspector composes one Realm declared editor", () {
    final first = _bookSelection("first");
    final second = _bookSelection(
      "second",
      presentation: first.presentation,
      collection: first.collection,
      catalog: first.catalog,
    );
    final registry = EditorOwnerRegistry();
    final refresh = registry.beginRefresh();
    final context = InspectionBuildContext(refresh);
    addTearDown(() {
      context.dispose();
      refresh.rollback();
      registry.dispose();
    });

    final result = const RealmAuthoringMultiInspectionDefinition(
      CoreResourceDefinitionIds.book,
    ).build([first.selection, second.selection], context);

    expect(result.diagnostics, isEmpty);
    final model = result.valueOrNull!.model;
    expect(model.presentations, [first.presentation]);
    expect(model.collections.byId, hasLength(1));
    expect(model.collections.byId, contains(authoringTagCollectionSourceId));
  });

  test("Book multi inspector rejects inconsistent Realm presentations", () {
    final first = _bookSelection("first");
    final second = _bookSelection(
      "second",
      collection: first.collection,
      catalog: first.catalog,
      presentation: _presentation("other"),
    );
    final registry = EditorOwnerRegistry();
    final refresh = registry.beginRefresh();
    final context = InspectionBuildContext(refresh);
    addTearDown(() {
      context.dispose();
      refresh.rollback();
      registry.dispose();
    });

    final result = const RealmAuthoringMultiInspectionDefinition(
      CoreResourceDefinitionIds.book,
    ).build([first.selection, second.selection], context);

    expect(result.valueOrNull, isNull);
    expect(result.diagnostics.single.message, contains("Realm presentations"));
  });
}

({
  BookSelection selection,
  PresentationDefinition presentation,
  LocalPresentationCollectionSource collection,
  RealmEditorCatalogSnapshot catalog,
})
_bookSelection(
  String id, {
  PresentationDefinition? presentation,
  LocalPresentationCollectionSource? collection,
  RealmEditorCatalogSnapshot? catalog,
}) {
  final definition = presentation ?? _presentation("book.default");
  final snapshotCatalog = catalog ?? _catalog(_bookType);
  final codec = TypedAuthoringCodec(snapshotCatalog);
  final snapshot = TypedAuthoringEditorSnapshot(
    resource: skir.AuthoringResource(
      id: skir.ResourceId(value: id),
      definition: CoreResourceDefinitionIds.book.toWire(),
      content: TypedAuthoringCodec(snapshotCatalog)
          .encodeEnvelope(
            TypedValueEnvelope(rootType: _bookType, rootValue: StringValue(id)),
          )
          .valueOrNull!,
    ),
    content: TypedValueEnvelope(
      rootType: _bookType,
      rootValue: StringValue(id),
    ),
    revision: 1,
    codec: codec,
  );
  final source = collection ?? _collection();
  final book = Book(
    bookId: skir.ResourceId(value: id),
    title: id,
    icon: "mdi:book",
    color: Colors.blue,
    tagIds: const [],
  );
  return (
    selection: BookSelection(
      resource: FakeEditableResource(
        key: EditorResourceKey(scope: null, identity: book.bookId),
        current: snapshot,
        commit: (_) async => throw StateError("No save in this test"),
      ),
      onOpen: null,
      id: BookIdentifier(book.bookId),
      book: book,
      snapshot: snapshot,
      catalogPresentations: [definition],
      tagCollection: source,
    ),
    presentation: definition,
    collection: source,
    catalog: snapshotCatalog,
  );
}

PresentationDefinition _presentation(String name) => PresentationDefinition(
  id: PresentationId(namespace: "typewriter.core", name: name),
  inputs: const [],
  root: const PresentationNode(
    id: "root",
    element: TextElement(
      TypedExpression(
        resultType: StringType(),
        expression: LiteralExpression(StringValue("Book")),
      ),
    ),
  ),
);

LocalPresentationCollectionSource _collection() {
  const rowBinding = BindingId(40);
  const rowType = RecordType(
    fields: {
      "key": TypeField(name: "key", type: StringType()),
      "selectable": TypeField(name: "selectable", type: BooleanType()),
    },
  );
  TypedExpression field(String name, TypeExpression type) => TypedExpression(
    resultType: type,
    expression: BindingExpression(
      BindingReference(bindingId: rowBinding, path: DataPath.root.field(name)),
    ),
  );
  return LocalPresentationCollectionSource(
    id: authoringTagCollectionSourceId,
    schema: PresentationCollectionSchema(
      rowType: rowType,
      rowBindingId: rowBinding,
      key: field("key", const StringType()),
      selectability: field("selectable", const BooleanType()),
    ),
    rows: [
      RecordValue({
        "key": const StringValue("tag"),
        "selectable": const BooleanValue(true),
      }),
    ],
    registry: TypeRegistry(const TypeCatalog([])),
  );
}

RealmEditorCatalogSnapshot _catalog(ResolvedTypeRef root) =>
    RealmEditorCatalogSnapshot(
      catalog: TypeCatalog([
        TypeDefinition(
          id: root,
          kind: NominalTypeKind.concrete,
          representation: const StringType(),
        ),
      ]),
      generation: const CatalogGeneration("1"),
    );

const _bookType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "com.typewritermc.library", name: "Book"),
  revision: 1,
);
