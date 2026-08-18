import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("presentation collection values", () {
    test("identifiers support equality and copying", () {
      const sourceId = PresentationCollectionSourceId("elements");
      const relationId = PresentationCollectionRelationId("references");

      expect(sourceId, const PresentationCollectionSourceId("elements"));
      expect(sourceId.copyWith(value: "other").value, "other");
      expect(relationId, const PresentationCollectionRelationId("references"));
      expect(relationId.copyWith(value: "children").value, "children");
      expect(sourceId.toString(), "elements");
      expect(relationId.toString(), "references");
    });

    test("schemas and relations support deep equality and copying", () {
      const relation = PresentationCollectionRelation(
        id: PresentationCollectionRelationId("references"),
        targets: TypedExpression(
          resultType: StringType(),
          expression: Expression.literal(StringValue("target")),
        ),
      );
      const schema = PresentationCollectionSchema(
        rowType: StringType(),
        keyType: StringType(),
        rowBindingId: BindingId(1),
        key: TypedExpression(
          resultType: StringType(),
          expression: Expression.literal(StringValue("key")),
        ),
        relations: [relation],
      );

      expect(
        schema,
        const PresentationCollectionSchema(
          rowType: StringType(),
          keyType: StringType(),
          rowBindingId: BindingId(1),
          key: TypedExpression(
            resultType: StringType(),
            expression: Expression.literal(StringValue("key")),
          ),
          relations: [relation],
        ),
      );
      expect(schema.copyWith(relations: []).relations, isEmpty);
      expect(
        relation
            .copyWith(id: const PresentationCollectionRelationId("children"))
            .id
            .value,
        "children",
      );
    });

    test("queries support deep equality, copying, and matching", () {
      const relation = PresentationCollectionRelationId("references");
      const graph = PresentationCollectionGraph(
        roots: [StringValue("root")],
        relation: relation,
        direction: CollectionGraphDirection.forward,
        maximumDepth: 2,
      );

      expect(
        graph,
        const PresentationCollectionQuery.graph(
          roots: [StringValue("root")],
          relation: relation,
          direction: CollectionGraphDirection.forward,
          maximumDepth: 2,
        ),
      );
      expect(graph.copyWith(maximumDepth: 3).maximumDepth, 3);
      expect(_queryLabel(const PresentationCollectionQuery.all()), "all");
      expect(
        _queryLabel(
          const PresentationCollectionQuery.keys([StringValue("key")]),
        ),
        "keys",
      );
      expect(
        _queryLabel(
          const PresentationCollectionQuery.search(
            SearchQueryContext(normalizedQuery: "query", selectors: []),
          ),
        ),
        "search",
      );
      expect(_queryLabel(graph), "graph");
    });

    test("rows, paths, and snapshots have deep value semantics", () {
      const row = PresentationCollectionRow(
        key: StringValue("key"),
        value: StringValue("value"),
      );
      const path = PresentationCollectionPath([
        StringValue("root"),
        StringValue("key"),
      ]);
      const snapshot = PresentationCollectionSnapshot(
        rootRows: [row],
        paths: [path],
      );

      expect(
        row,
        const PresentationCollectionRow(
          key: StringValue("key"),
          value: StringValue("value"),
        ),
      );
      expect(
        path,
        const PresentationCollectionPath([
          StringValue("root"),
          StringValue("key"),
        ]),
      );
      expect(
        snapshot,
        const PresentationCollectionSnapshot(rootRows: [row], paths: [path]),
      );
      expect(snapshot.copyWith(loading: true).loading, isTrue);
      expect(snapshot.row(const StringValue("key")), row);
    });
  });
}

String _queryLabel(PresentationCollectionQuery query) => switch (query) {
  PresentationCollectionAll() => "all",
  PresentationCollectionKeys() => "keys",
  PresentationCollectionSearch() => "search",
  PresentationCollectionGraph() => "graph",
};
