import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as wire_action;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire_diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as wire_expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final types = SkirTypeCodec(TypeRegistry(TypeCatalog(const [])));
  final values = SkirDataValueCodec(types);
  final expressionEncoder = SkirExpressionEncoder(types, values);
  final expressionDecoder = SkirExpressionDecoder(types, values);
  final actionEncoder = SkirActionEncoder(expressionEncoder, values);
  final actionDecoder = SkirActionDecoder(expressionDecoder, values);
  const binding = BindingReference(
    bindingId: BindingId(7),
    path: DataPath.root,
  );
  final named = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "entry"),
    revision: 1,
  );
  const text = TypedExpression(
    resultType: StringType(),
    expression: LiteralExpression(StringValue("value")),
  );
  const truth = TypedExpression(
    resultType: BooleanType(),
    expression: LiteralExpression(BooleanValue(true)),
  );
  final one = TypedExpression(
    resultType: const IntegerType(width: IntegerWidth.signed64),
    expression: LiteralExpression(IntegerValue(BigInt.one)),
  );

  test("round trips every expression variant as bytes", () {
    final expressions = <TypedExpression>[
      text,
      const TypedExpression(
        resultType: StringType(),
        expression: BindingExpression(binding),
      ),
      const TypedExpression(
        resultType: StringType(),
        expression: FieldAccessExpression(target: text, fieldName: "name"),
      ),
      TypedExpression(
        resultType: const StringType(),
        expression: InterpolationExpression(const [
          InterpolationText("Name: "),
          InterpolationValue(text),
        ]),
      ),
      const TypedExpression(
        resultType: BooleanType(),
        expression: ComparisonExpression(
          operator: ComparisonOperator.equal,
          left: text,
          right: text,
        ),
      ),
      TypedExpression(
        resultType: const BooleanType(),
        expression: BooleanExpression(
          operator: BooleanOperator.and,
          operands: const [truth, truth],
        ),
      ),
      TypedExpression(
        resultType: const IntegerType(width: IntegerWidth.signed64),
        expression: ArithmeticExpression(
          operator: ArithmeticOperator.add,
          operands: [one, one],
        ),
      ),
      const TypedExpression(
        resultType: StringType(),
        expression: ConditionalExpression(
          condition: truth,
          whenTrue: text,
          whenFalse: text,
        ),
      ),
      TypedExpression(
        resultType: const ListType(element: StringType()),
        expression: CollectionProjectionExpression(
          source: TypedExpression(
            resultType: const ListType(element: StringType()),
            expression: LiteralExpression(ListValue(const [StringValue("a")])),
          ),
          itemBindingId: const BindingId(9),
          projection: const TypedExpression(
            resultType: StringType(),
            expression: BindingExpression(
              BindingReference(bindingId: BindingId(9)),
            ),
          ),
        ),
      ),
      const TypedExpression(
        resultType: StringType(),
        expression: ConversionExpression(
          conversionId: ConversionId(namespace: "example", name: "to_string"),
          input: text,
        ),
      ),
      const TypedExpression(
        resultType: StringType(),
        expression: StringOperationExpression(
          operation: StringOperation.titleCase,
          operands: [text],
        ),
      ),
      TypedExpression(
        resultType: const IntegerType(width: IntegerWidth.signed64),
        expression: CollectionOperationExpression(
          operation: CollectionOperation.length,
          operands: const [text],
        ),
      ),
      const TypedExpression(
        resultType: StringType(),
        expression: RegexExpression(
          operation: RegexOperation.capture,
          source: text,
          pattern: "(value)",
          group: 1,
        ),
      ),
      const TypedExpression(
        resultType: StringType(),
        expression: CoalesceExpression([text, text]),
      ),
    ];

    for (final expression in expressions) {
      final encoded = expressionEncoder.encode(expression).valueOrNull!;
      final bytes = wire_expression.TypedExpression.serializer.toBytes(encoded);
      final wire = wire_expression.TypedExpression.serializer.fromBytes(bytes);
      final decoded = expressionDecoder.decode(wire).valueOrNull!;
      final reencoded = expressionEncoder.encode(decoded).valueOrNull!;
      expect(
        wire_expression.TypedExpression.serializer.toBytes(reencoded),
        bytes,
      );
    }
  });

  test("rejects a missing expression payload", () {
    final result = expressionDecoder.decode(
      wire_expression.TypedExpression(
        resultType: wire_type.TypeExpression.unit,
        expression: null,
      ),
    );

    expect(result.valueOrNull, isNull);
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.code, TypeDiagnosticCode.invalidValue);
  });

  test("round trips every editor action variant as bytes", () {
    final actions = <EditorAction>[
      const EditorAction.local(SetValueAction(target: binding, value: text)),
      EditorAction.local(
        InsertListItemAction(target: binding, index: one, value: text),
      ),
      EditorAction.local(RemoveListItemAction(target: binding, index: one)),
      const EditorAction.local(
        AppendListItemAction(target: binding, value: text),
      ),
      const EditorAction.local(DuplicateListItemAction(source: binding)),
      EditorAction.local(ReorderListItemAction(source: binding, newIndex: one)),
      const EditorAction.local(
        PutMapEntryAction(target: binding, key: text, value: text),
      ),
      const EditorAction.local(
        RemoveMapEntryAction(target: binding, key: text),
      ),
      EditorAction.local(
        ReplaceConcreteTypeAction(
          target: binding,
          concreteType: named,
          initialValue: text,
        ),
      ),
      const EditorAction.realm(ReloadRealmAction()),
      const EditorAction.realm(
        InvokeRealmCallbackAction(
          actionId: RealmActionId(namespace: "example", name: "save"),
          payload: text,
        ),
      ),
    ];

    for (final action in actions) {
      final encoded = actionEncoder.encode(action).valueOrNull!;
      final bytes = wire_action.EditorAction.serializer.toBytes(encoded);
      final wire = wire_action.EditorAction.serializer.fromBytes(bytes);
      final decoded = actionDecoder.decode(wire).valueOrNull!;
      final reencoded = actionEncoder.encode(decoded).valueOrNull!;
      expect(wire_action.EditorAction.serializer.toBytes(reencoded), bytes);
    }
  });

  test("round trips every typed mutation result variant as bytes", () {
    final diagnostic = wire_diagnostic.TypeDiagnostic(
      code: wire_diagnostic.DiagnosticCode.invalidValue,
      severity: wire_diagnostic.DiagnosticSeverity.error,
      message: "Invalid",
      path: null,
      relatedType: null,
      details: const [],
    );
    final results = <wire_action.TypedMutationResult>[
      wire_action.TypedMutationResult.createSuccess(
        revision: 2,
        value: wire_type.TypedValue.wrapString("saved"),
      ),
      wire_action.TypedMutationResult.createConflict(
        expectedRevision: 1,
        actualRevision: 2,
        actualValue: wire_type.TypedValue.wrapString("actual"),
      ),
      wire_action.TypedMutationResult.wrapInvalid([diagnostic]),
      wire_action.TypedMutationResult.wrapUnavailable([diagnostic]),
      wire_action.TypedMutationResult.createPermissionDenied(
        message: "Denied by policy",
      ),
    ];
    for (final result in results) {
      final bytes = wire_action.TypedMutationResult.serializer.toBytes(result);
      final decodedWire = wire_action.TypedMutationResult.serializer.fromBytes(
        bytes,
      );
      final domain = actionDecoder.decodeMutation(decodedWire).valueOrNull!;
      final reencoded = actionEncoder.encodeMutation(domain).valueOrNull!;
      expect(
        wire_action.TypedMutationResult.serializer.toBytes(reencoded),
        bytes,
      );
    }
  });
}
