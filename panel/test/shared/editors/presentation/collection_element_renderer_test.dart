import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("collection lookup renders found rows without raw key labels", (
    tester,
  ) async {
    final fixture = _fixture();
    await tester.pumpTestApp(
      child: _renderer(
        fixture,
        value: const StringValue("b"),
        type: const StringType(),
        presentation: PresentationNode(
          id: "lookup",
          element: CollectionLookupElement(
            sourceId: fixture.source.id,
            key: const BindingReference(bindingId: BindingId(0)),
            found: fixture.rowName("found"),
            missing: const PresentationNode(
              id: "missing",
              element: TextElement(
                TypedExpression(
                  resultType: StringType(),
                  expression: LiteralExpression(StringValue("Missing")),
                ),
              ),
            ),
          ),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(find.text("Beta"), findsOneWidget);
    expect(find.text("b"), findsNothing);
  });

  testWidgets("collection graph renders roots, reached rows, and every path", (
    tester,
  ) async {
    final fixture = _fixture();
    await tester.pumpTestApp(
      child: _renderer(
        fixture,
        value: const ListValue([StringValue("a")]),
        type: const ListType(element: StringType()),
        presentation: PresentationNode(
          id: "graph",
          element: CollectionGraphElement(
            sourceId: fixture.source.id,
            roots: const BindingReference(bindingId: BindingId(0)),
            relation: fixture.relation,
            direction: CollectionGraphDirection.forward,
            pathBindingId: const BindingId(7),
            rootRows: SequencePresentation(item: fixture.rowName("root")),
            reachedRows: SequencePresentation(item: fixture.rowName("reached")),
            paths: const SequencePresentation(
              item: PresentationNode(
                id: "path",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: LiteralExpression(StringValue("Path")),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Beta"), findsOneWidget);
    expect(find.text("Gamma"), findsOneWidget);
    expect(find.text("Path"), findsNWidgets(2));
  });
}

EditorProtocolRenderer _renderer(
  _CollectionFixture fixture, {
  required DataValue value,
  required TypeExpression type,
  required PresentationNode presentation,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "collectionRoot"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    collections: [fixture.source],
    presentation: presentation,
  );
}

_CollectionFixture _fixture() {
  const rowBinding = BindingId(8);
  const relation = PresentationCollectionRelationId("links");
  final rowType = RecordType(
    fields: const {
      "key": TypeField(name: "key", type: StringType()),
      "name": TypeField(name: "name", type: StringType()),
      "links": TypeField(
        name: "links",
        type: ListType(element: StringType()),
      ),
    },
  );
  TypedExpression field(String name, TypeExpression type) => TypedExpression(
    resultType: type,
    expression: FieldAccessExpression(
      target: TypedExpression(
        resultType: rowType,
        expression: const BindingExpression(
          BindingReference(bindingId: rowBinding),
        ),
      ),
      fieldName: name,
    ),
  );
  final source = LocalPresentationCollectionSource(
    id: const PresentationCollectionSourceId("nodes"),
    schema: PresentationCollectionSchema(
      rowType: rowType,
      keyType: const StringType(),
      rowBindingId: rowBinding,
      key: field("key", const StringType()),
      relations: [
        PresentationCollectionRelation(
          id: relation,
          targets: field("links", const ListType(element: StringType())),
        ),
      ],
    ),
    rows: [
      _row("a", "Alpha", ["b"]),
      _row("b", "Beta", ["c"]),
      _row("c", "Gamma", []),
    ],
    registry: TypeRegistry(const TypeCatalog([])),
  );
  return _CollectionFixture(
    source: source,
    relation: relation,
    rowName: (id) => PresentationNode(
      id: id,
      element: TextElement(field("name", const StringType())),
    ),
  );
}

RecordValue _row(String key, String name, List<String> links) => RecordValue({
  "key": StringValue(key),
  "name": StringValue(name),
  "links": ListValue(links.map(StringValue.new).toList()),
});

final class _CollectionFixture {
  const _CollectionFixture({
    required this.source,
    required this.relation,
    required this.rowName,
  });

  final LocalPresentationCollectionSource source;
  final PresentationCollectionRelationId relation;
  final PresentationNode Function(String id) rowName;
}
