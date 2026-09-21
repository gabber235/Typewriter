import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test("multi collection intersects declared selectability", () async {
    final merged = mergeAuthoringCollectionSources([
      _collection(selectable: true),
      _collection(selectable: false),
    ]);

    expect(merged.diagnostics, isEmpty);
    final snapshot = await merged.valueOrNull!
        .watch(const PresentationCollectionQuery.all())
        .first;
    final value = snapshot.rows.single.value as RecordValue;
    expect(value.fields["selectable"], const BooleanValue(false));
  });

  test("multi collection rejects mismatched stable row values", () {
    final merged = mergeAuthoringCollectionSources([
      _collection(selectable: true, label: "First"),
      _collection(selectable: true, label: "Second"),
    ]);

    expect(merged.valueOrNull, isNull);
    expect(merged.diagnostics.single.message, contains("inconsistent"));
  });

  test(
    "Tag selection uses Realm presentations and authoritative collections",
    () {
      final presentation = _presentation();
      final collection = _collection(selectable: true);
      final catalog = _catalog();
      final codec = TypedAuthoringCodec(catalog);
      final snapshot = TypedAuthoringEditorSnapshot(
        resource: skir.AuthoringResource(
          id: skir.ResourceId(value: "test"),
          kind: skir.ResourceKind.tag,
          content: codec
              .encodeEnvelope(
                const TypedValueEnvelope(
                  rootType: _tagType,
                  rootValue: StringValue("tag"),
                ),
              )
              .valueOrNull!,
        ),
        content: const TypedValueEnvelope(
          rootType: _tagType,
          rootValue: StringValue("tag"),
        ),
        revision: 1,
        codec: codec,
      );
      final tag = Tag(
        tagId: skir.ResourceId(value: "test"),
        name: "Test",
        color: Colors.blue,
        parentIds: const [],
        placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
      );
      final selection = TagSelectable(
        resource: FakeEditableResource(
          key: EditorResourceKey(scope: null, identity: tag.tagId),
          current: snapshot,
          commit: (_) async => throw StateError("No save in this test"),
        ),
        onDelete: () async => throw StateError("No delete in this test"),
        id: TagIdentifier(tag.tagId),
        tag: tag,
        snapshot: snapshot,
        catalogPresentations: [presentation],
        tagCollection: collection,
      );

      expect(selection.presentations, [presentation]);
      expect(selection.collections, [collection]);
      expect(selection.multiInspection.id, presentation.id);
    },
  );
}

LocalPresentationCollectionSource _collection({
  required bool selectable,
  String label = "Tag",
}) {
  const rowBinding = BindingId(40);
  const rowType = RecordType(
    fields: {
      "key": TypeField(name: "key", type: StringType()),
      "label": TypeField(name: "label", type: StringType()),
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
        "label": StringValue(label),
        "selectable": BooleanValue(selectable),
      }),
    ],
    registry: TypeRegistry(const TypeCatalog([])),
  );
}

PresentationDefinition _presentation() => const PresentationDefinition(
  id: PresentationId(namespace: "typewriter.core", name: "tag.default"),
  inputs: [],
  root: PresentationNode(
    id: "root",
    element: TextElement(
      TypedExpression(
        resultType: StringType(),
        expression: LiteralExpression(StringValue("Tag")),
      ),
    ),
  ),
);

RealmEditorCatalogSnapshot _catalog() => RealmEditorCatalogSnapshot(
  catalog: TypeCatalog([
    TypeDefinition(
      id: _tagType,
      kind: NominalTypeKind.concrete,
      representation: const StringType(),
    ),
  ]),
  generation: const CatalogGeneration("1"),
);

const _tagType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "com.typewritermc.library", name: "Tag"),
  revision: 1,
);
