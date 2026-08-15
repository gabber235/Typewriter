import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const context = ExpressionContext(bindings: BindingEnvironment({}));

  group("string operations", () {
    test("evaluate every operation", () {
      final cases = <TypedExpression, DataValue>{
        _stringOperation(StringOperation.trim, [_string(" value ")]):
            const StringValue("value"),
        _stringOperation(StringOperation.lowerCase, [_string("VALUE")]):
            const StringValue("value"),
        _stringOperation(StringOperation.upperCase, [_string("value")]):
            const StringValue("VALUE"),
        _stringOperation(StringOperation.titleCase, [_string("hello world")]):
            const StringValue("Hello World"),
        _stringOperation(StringOperation.replace, [
          _string("a b a"),
          _string("a"),
          _string("x"),
        ]): const StringValue(
          "x b x",
        ),
        _typed(
          const ListType(element: StringType()),
          StringOperationExpression(
            operation: StringOperation.split,
            operands: [_string("a,b"), _string(",")],
          ),
        ): const ListValue([
          StringValue("a"),
          StringValue("b"),
        ]),
        _stringOperation(StringOperation.join, [
          _strings(["a", "b"]),
          _string("|"),
        ]): const StringValue(
          "a|b",
        ),
        _stringOperation(StringOperation.substring, [
          _string("search"),
          _integer(1),
          _integer(4),
        ]): const StringValue(
          "ear",
        ),
        _booleanStringOperation(StringOperation.contains, [
          _string("search"),
          _string("arc"),
        ]): const BooleanValue(
          true,
        ),
        _booleanStringOperation(StringOperation.startsWith, [
          _string("search"),
          _string("sea"),
        ]): const BooleanValue(
          true,
        ),
        _booleanStringOperation(StringOperation.endsWith, [
          _string("search"),
          _string("rch"),
        ]): const BooleanValue(
          true,
        ),
      };

      for (final MapEntry(key: expression, value: expected) in cases.entries) {
        expect(
          expression.evaluate(context, registry: null).valueOrNull,
          expected,
        );
      }
    });

    test("rejects invalid arity and operand types", () {
      final invalidArity = _stringOperation(StringOperation.trim, [
        _string("a"),
        _string("b"),
      ]);
      final invalidType = _stringOperation(StringOperation.lowerCase, [
        _integer(1),
      ]);

      expect(
        invalidArity.evaluate(context, registry: null),
        isA<TypeFailure>(),
      );
      expect(invalidType.evaluate(context, registry: null), isA<TypeFailure>());
    });
  });

  group("collection operations", () {
    test("accesses and inspects typed collections", () {
      final values = _strings(["first", "second"]);
      final map = _typed(
        const MapType(key: StringType(), value: StringType()),
        const LiteralExpression(
          MapValue([
            DataMapEntry(key: StringValue("key"), value: StringValue("value")),
          ]),
        ),
      );
      final record = _typed(
        RecordType(
          fields: const {"name": TypeField(name: "name", type: StringType())},
        ),
        LiteralExpression(RecordValue(const {"name": StringValue("Ada")})),
      );
      final cases = <TypedExpression, DataValue>{
        _collection(const StringType(), CollectionOperation.access, [
          values,
          _integer(1),
        ]): const StringValue(
          "second",
        ),
        _collection(const StringType(), CollectionOperation.access, [
          map,
          _string("key"),
        ]): const StringValue(
          "value",
        ),
        _collection(const StringType(), CollectionOperation.access, [
          record,
          _string("name"),
        ]): const StringValue(
          "Ada",
        ),
        _collection(
          const IntegerType(width: IntegerWidth.signed64),
          CollectionOperation.length,
          [_string("query")],
        ): IntegerValue(
          BigInt.from(5),
        ),
        _collection(const BooleanType(), CollectionOperation.contains, [
          values,
          _string("second"),
        ]): const BooleanValue(
          true,
        ),
      };

      for (final MapEntry(key: expression, value: expected) in cases.entries) {
        expect(
          expression.evaluate(context, registry: null).valueOrNull,
          expected,
        );
      }
    });

    test("fails for absent keys and invalid indexes", () {
      final values = _strings(["first"]);
      final missing = _collection(
        const StringType(),
        CollectionOperation.access,
        [values, _integer(2)],
      );

      expect(missing.evaluate(context, registry: null), isA<TypeFailure>());
    });
  });
}

TypedExpression _typed(TypeExpression type, Expression expression) =>
    TypedExpression(resultType: type, expression: expression);

TypedExpression _string(String value) => value.asStringLiteral;

TypedExpression _integer(int value) => value.asSigned64Literal;

TypedExpression _strings(List<String> values) => _typed(
  const ListType(element: StringType()),
  LiteralExpression(ListValue(values.map(StringValue.new).toList())),
);

TypedExpression _stringOperation(
  StringOperation operation,
  List<TypedExpression> operands,
) => _typed(
  const StringType(),
  StringOperationExpression(operation: operation, operands: operands),
);

TypedExpression _booleanStringOperation(
  StringOperation operation,
  List<TypedExpression> operands,
) => _typed(
  const BooleanType(),
  StringOperationExpression(operation: operation, operands: operands),
);

TypedExpression _collection(
  TypeExpression type,
  CollectionOperation operation,
  List<TypedExpression> operands,
) => _typed(
  type,
  CollectionOperationExpression(operation: operation, operands: operands),
);
