import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const relation = PresentationCollectionRelationId("references");
  final source = _source(relation);

  test("supports lookup and local search across heterogeneous rows", () async {
    final lookup = await source
        .watch(const PresentationCollectionQuery.keys([StringValue("segment")]))
        .first;
    final search = await source
        .watch(
          const PresentationCollectionQuery.search(
            SearchQueryContext(normalizedQuery: "entry", selectors: []),
          ),
        )
        .first;

    expect(lookup.rows.single.key, const StringValue("segment"));
    expect(search.rows.single.key, const StringValue("entry"));
    expect(
      DataPath.root.field("kind").read(lookup.rows.single.value).valueOrNull,
      const StringValue("segmentCue"),
    );
  });

  test(
    "forward traversal deduplicates rows and preserves every path",
    () async {
      final snapshot = await source
          .watch(
            const PresentationCollectionQuery.graph(
              roots: [StringValue("entry")],
              relation: relation,
              direction: CollectionGraphDirection.forward,
            ),
          )
          .first;

      expect(snapshot.rootRows.map((row) => row.key), const [
        StringValue("entry"),
      ]);
      expect(
        snapshot.rows.map((row) => row.key),
        isNot(contains(const StringValue("entry"))),
      );
      expect(snapshot.row(const StringValue("entry")), isNotNull);
      expect(snapshot.rows.map((row) => row.key), const [
        StringValue("segment"),
        StringValue("keyframe"),
        StringValue("dialogue"),
      ]);
      expect(
        snapshot.paths.map((path) => path.keys),
        containsAll([
          const [StringValue("entry"), StringValue("segment")],
          const [
            StringValue("entry"),
            StringValue("segment"),
            StringValue("keyframe"),
          ],
          const [
            StringValue("entry"),
            StringValue("dialogue"),
            StringValue("keyframe"),
          ],
        ]),
      );
    },
  );

  test("reverse traversal provides used by chains", () async {
    final snapshot = await source
        .watch(
          const PresentationCollectionQuery.graph(
            roots: [StringValue("keyframe")],
            relation: relation,
            direction: CollectionGraphDirection.reverse,
          ),
        )
        .first;

    expect(snapshot.rows.map((row) => row.key).toSet(), {
      const StringValue("segment"),
      const StringValue("entry"),
      const StringValue("dialogue"),
    });
    expect(
      snapshot.paths.map(
        (path) => path.keys.map((key) => key.expressionDisplayText).join("/"),
      ),
      contains("keyframe/dialogue/entry"),
    );
  });

  test(
    "multiple roots preserve order and never repeat as reached rows",
    () async {
      final snapshot = await source
          .watch(
            const PresentationCollectionQuery.graph(
              roots: [StringValue("dialogue"), StringValue("segment")],
              relation: relation,
              direction: CollectionGraphDirection.forward,
            ),
          )
          .first;

      expect(snapshot.rootRows.map((row) => row.key), const [
        StringValue("dialogue"),
        StringValue("segment"),
      ]);
      expect(
        snapshot.rows.map((row) => row.key),
        isNot(
          anyOf(
            contains(const StringValue("dialogue")),
            contains(const StringValue("segment")),
          ),
        ),
      );
    },
  );

  test("cycles and graph budget exhaustion are diagnostic", () async {
    final cycle = _source(
      relation,
      rows: [
        _row("one", "entry", ["two"]),
        _row("two", "segmentCue", ["one"]),
      ],
    );
    final cycleResult = await cycle
        .watch(
          const PresentationCollectionQuery.graph(
            roots: [StringValue("one")],
            relation: relation,
            direction: CollectionGraphDirection.forward,
          ),
        )
        .first;
    final budget = _source(relation, graphNodeBudget: 1);
    final budgetResult = await budget
        .watch(
          const PresentationCollectionQuery.graph(
            roots: [StringValue("entry")],
            relation: relation,
            direction: CollectionGraphDirection.forward,
          ),
        )
        .first;

    expect(cycleResult.diagnostics.single.message, contains("cycle"));
    expect(budgetResult.diagnostics.single.message, contains("budget"));
  });

  test("duplicate relation targets retain only unique paths", () async {
    final duplicate = _source(
      relation,
      rows: [
        _row("one", "entry", ["two", "two"]),
        _row("two", "segmentCue", []),
      ],
    );
    final snapshot = await duplicate
        .watch(
          const PresentationCollectionQuery.graph(
            roots: [StringValue("one")],
            relation: relation,
            direction: CollectionGraphDirection.forward,
          ),
        )
        .first;

    expect(snapshot.paths, hasLength(1));
  });
}

LocalPresentationCollectionSource _source(
  PresentationCollectionRelationId relation, {
  List<DataValue>? rows,
  int graphNodeBudget = 4096,
}) {
  const rowBinding = BindingId(7);
  final rowType = RecordType(
    fields: const {
      "key": TypeField(name: "key", type: StringType()),
      "kind": TypeField(name: "kind", type: StringType()),
      "references": TypeField(
        name: "references",
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
  return LocalPresentationCollectionSource(
    id: const PresentationCollectionSourceId("elements"),
    schema: PresentationCollectionSchema(
      rowType: rowType,
      keyType: const StringType(),
      rowBindingId: rowBinding,
      key: field("key", const StringType()),
      relations: [
        PresentationCollectionRelation(
          id: relation,
          targets: field("references", const ListType(element: StringType())),
        ),
      ],
    ),
    rows:
        rows ??
        [
          _row("entry", "entry", ["segment", "dialogue"]),
          _row("segment", "segmentCue", ["keyframe"]),
          _row("dialogue", "segmentCue", ["keyframe"]),
          _row("keyframe", "keyframeCue", []),
        ],
    registry: TypeRegistry(const TypeCatalog([])),
    searchPredicate: (row, query) =>
        (row as RecordValue).fields["key"] ==
        StringValue(query.normalizedQuery),
    graphNodeBudget: graphNodeBudget,
  );
}

RecordValue _row(String key, String kind, List<String> references) =>
    RecordValue({
      "key": StringValue(key),
      "kind": StringValue(kind),
      "references": ListValue(references.map(StringValue.new).toList()),
    });
