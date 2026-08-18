import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const context = ExpressionContext(bindings: BindingEnvironment({}));

  test("composes the Iconify query operations", () {
    final query = "mdi:account".asStringLiteral;
    final remoteQuery = query
        .regexCapture(r"^(?:[^:]+:)?(.+)$", group: 1)
        .coalesce(query);
    final prefix = query.regexCapture(r"^([^:]+):(.+)$", group: 1);
    final gate = query.length().greaterThanOrEqual(2);
    final humanized = "account-box".asStringLiteral
        .regexReplace("-", " ")
        .titleCase();

    expect(
      remoteQuery.evaluate(context, registry: null).valueOrNull,
      const StringValue("account"),
    );
    expect(
      prefix.evaluate(context, registry: null).valueOrNull,
      const StringValue("mdi"),
    );
    expect(
      gate.evaluate(context, registry: null).valueOrNull,
      const BooleanValue(true),
    );
    expect(
      humanized.evaluate(context, registry: null).valueOrNull,
      const StringValue("Account Box"),
    );
  });

  const itemBindingId = BindingId(1);
  const accumulatorBindingId = BindingId(2);
  const leftBindingId = BindingId(3);
  const rightBindingId = BindingId(4);
  final values = _values();
  final item = _binding(itemBindingId);
  final predicate = item.compare(
    ComparisonOperator.greaterThan,
    1.asIntegerLiteral,
  );

  group("collection expression authoring", () {
    test(
      "creates mapping and filtering expressions with inferred list types",
      () {
        final mapped = values.collectionMap(
          itemBindingId: itemBindingId,
          transform: item,
        );
        final filtered = values.filter(
          itemBindingId: itemBindingId,
          predicate: predicate,
        );
        final flatMapped = values.flatMap(
          itemBindingId: itemBindingId,
          transform: _integerList(),
        );

        expect(
          mapped.resultType,
          const ListType(element: IntegerType(width: IntegerWidth.signed64)),
        );
        expect(mapped.expression, isA<CollectionMapExpression>());
        expect(
          filtered.resultType,
          const ListType(element: IntegerType(width: IntegerWidth.signed64)),
        );
        expect(filtered.expression, isA<CollectionFilterExpression>());
        expect(
          flatMapped.resultType,
          const ListType(element: IntegerType(width: IntegerWidth.signed64)),
        );
        expect(flatMapped.expression, isA<CollectionTransformExpression>());
      },
    );

    test("creates quantifier, find, and count expressions", () {
      final expressions = [
        values.any(itemBindingId: itemBindingId, predicate: predicate),
        values.all(itemBindingId: itemBindingId, predicate: predicate),
        values.none(itemBindingId: itemBindingId, predicate: predicate),
        values.findFirst(itemBindingId: itemBindingId, predicate: predicate),
        values.findLast(itemBindingId: itemBindingId, predicate: predicate),
        values.countWhere(itemBindingId: itemBindingId, predicate: predicate),
      ];

      expect(expressions[0].expression, isA<CollectionQuantifierExpression>());
      expect(expressions[1].expression, isA<CollectionQuantifierExpression>());
      expect(expressions[2].expression, isA<CollectionQuantifierExpression>());
      expect(
        expressions[3].resultType,
        NamedType(standardTypeRefs.optionOf(_integerType)),
      );
      expect(
        expressions[4].resultType,
        NamedType(standardTypeRefs.optionOf(_integerType)),
      );
      expect(expressions[5].resultType, _integerType);
    });

    test("creates distinct, sorting, and grouping expressions", () {
      final comparator = CollectionComparator(
        leftBindingId: leftBindingId,
        rightBindingId: rightBindingId,
        comparison: 0.asIntegerLiteral,
      );
      final distinct = values.distinct();
      final distinctBy = values.distinctBy(
        itemBindingId: itemBindingId,
        key: item,
      );
      final sorted = values.sortBy(
        itemBindingId: itemBindingId,
        key: item,
        direction: CollectionSortDirection.descending,
        comparator: comparator,
      );
      final grouped = values.groupBy(itemBindingId: itemBindingId, key: item);
      final transformedGroup = values.groupBy(
        itemBindingId: itemBindingId,
        key: item,
        value: "value".asStringLiteral,
      );

      expect(distinct.expression, isA<CollectionDistinctExpression>());
      expect(distinctBy.expression, isA<CollectionDistinctExpression>());
      expect(
        (sorted.expression as CollectionSortExpression).comparator,
        comparator,
      );
      expect(
        grouped.resultType,
        const MapType(
          key: IntegerType(width: IntegerWidth.signed64),
          value: ListType(element: IntegerType(width: IntegerWidth.signed64)),
        ),
      );
      expect(
        transformedGroup.resultType,
        const MapType(
          key: IntegerType(width: IntegerWidth.signed64),
          value: ListType(element: StringType()),
        ),
      );
    });

    test("creates reduction and sequence transform expressions", () {
      final reduction = _binding(accumulatorBindingId);
      final reduced = values.reduce(
        accumulatorBindingId: accumulatorBindingId,
        itemBindingId: itemBindingId,
        reduction: reduction,
      );
      final folded = values.fold(
        initial: 0.asIntegerLiteral,
        accumulatorBindingId: accumulatorBindingId,
        itemBindingId: itemBindingId,
        reduction: reduction,
      );
      final taken = values.take(1.asIntegerLiteral);
      final skipped = values.skip(1.asIntegerLiteral);
      final reversed = values.reverse();

      expect(
        reduced.resultType,
        NamedType(standardTypeRefs.optionOf(_integerType)),
      );
      expect(folded.resultType, _integerType);
      expect(
        (taken.expression as CollectionTransformExpression).operation,
        CollectionTransformOperation.take,
      );
      expect(
        (skipped.expression as CollectionTransformExpression).operation,
        CollectionTransformOperation.skip,
      );
      expect(
        (reversed.expression as CollectionTransformExpression).operation,
        CollectionTransformOperation.reverse,
      );
    });

    test("rejects collection helpers for incompatible static result types", () {
      expect(
        () => 1.asIntegerLiteral.filter(
          itemBindingId: itemBindingId,
          predicate: predicate,
        ),
        throwsArgumentError,
      );
      expect(
        () => values.flatMap(itemBindingId: itemBindingId, transform: item),
        throwsArgumentError,
      );
    });
  });
}

const _integerType = IntegerType(width: IntegerWidth.signed64);

TypedExpression _values() => TypedExpression(
  resultType: const ListType(element: _integerType),
  expression: LiteralExpression(ListValue([IntegerValue(BigInt.one)])),
);

TypedExpression _integerList() => TypedExpression(
  resultType: const ListType(element: _integerType),
  expression: const LiteralExpression(ListValue([])),
);

TypedExpression _binding(BindingId bindingId) => TypedExpression(
  resultType: _integerType,
  expression: BindingExpression(BindingReference(bindingId: bindingId)),
);
