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

  testWidgets(
    "collection graph binds children and renders the recursive slot",
    (tester) async {
      final fixture = _fixture();
      const childrenBindingId = BindingId(7);
      final children = TypedExpression(
        resultType: ListType(element: fixture.source.schema.rowType),
        expression: const BindingExpression(
          BindingReference(bindingId: childrenBindingId),
        ),
      );
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
              childrenBindingId: childrenBindingId,
              node: PresentationNode(
                id: "occurrence",
                element: ColumnElement(
                  children: [
                    fixture.rowName("name"),
                    PresentationNode(
                      id: "childCount",
                      element: TextElement(children.length()),
                    ),
                    const PresentationNode(
                      id: "children",
                      element: PresentationSlotElement(slotId: "children"),
                    ),
                  ],
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
      expect(find.text("1"), findsNWidgets(2));
      expect(find.text("0"), findsOneWidget);
    },
  );

  testWidgets("collection graph rejects a children and row binding collision", (
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
            childrenBindingId: fixture.source.schema.rowBindingId,
            node: const PresentationNode(
              id: "occurrence",
              element: PresentationSlotElement(slotId: "children"),
            ),
          ),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(
      find.text("Collection children binding collides with the row binding"),
      findsOneWidget,
    );
  });

  testWidgets("collection graph preserves immediate child traversal order", (
    tester,
  ) async {
    final fixture = _fixture(
      rows: [
        _row("a", "Alpha", ["b", "c"]),
        _row("b", "Beta", []),
        _row("c", "Gamma", []),
      ],
    );
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
            childrenBindingId: const BindingId(7),
            node: PresentationNode(
              id: "occurrence",
              element: ColumnElement(
                children: [
                  fixture.rowName("name"),
                  const PresentationNode(
                    id: "children",
                    element: PresentationSlotElement(slotId: "children"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(
      tester.getTopLeft(find.text("Beta")).dy,
      lessThan(tester.getTopLeft(find.text("Gamma")).dy),
    );
  });

  testWidgets("an unfilled presentation slot renders a diagnostic", (
    tester,
  ) async {
    final fixture = _fixture();
    await tester.pumpTestApp(
      child: _renderer(
        fixture,
        value: const UnitValue(),
        type: const UnitType(),
        presentation: const PresentationNode(
          id: "slot",
          element: PresentationSlotElement(slotId: "children"),
        ),
      ),
    );

    expect(
      find.text("Presentation slot children has no content"),
      findsOneWidget,
    );
  });

  testWidgets("collection graph rejects distinct child slot identifiers", (
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
            childrenBindingId: const BindingId(7),
            node: const PresentationNode(
              id: "occurrence",
              element: ColumnElement(
                children: [
                  PresentationNode(
                    id: "first",
                    element: PresentationSlotElement(slotId: "first"),
                  ),
                  PresentationNode(
                    id: "second",
                    element: PresentationSlotElement(slotId: "second"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(
      find.text("Collection graph node contains distinct slot identifiers"),
      findsOneWidget,
    );
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

_CollectionFixture _fixture({List<RecordValue>? rows}) {
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
    rows:
        rows ??
        [
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
