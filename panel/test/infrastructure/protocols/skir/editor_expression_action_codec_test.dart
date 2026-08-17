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
  final color = TypedExpression(
    resultType: NamedType(standardTypeRefs.color),
    expression: LiteralExpression(IntegerValue(BigInt.from(0xFF336699))),
  );

  test("maps every expression variant and its fields", () {
    final expressions = <(TypedExpression, wire_expression.Expression_kind)>[
      (text, wire_expression.Expression_kind.literalWrapper),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: BindingExpression(binding),
        ),
        wire_expression.Expression_kind.bindingWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: FieldAccessExpression(target: text, fieldName: "name"),
        ),
        wire_expression.Expression_kind.fieldAccessWrapper,
      ),
      (
        TypedExpression(
          resultType: const StringType(),
          expression: InterpolationExpression(const [
            InterpolationText("Name: "),
            InterpolationValue(text),
          ]),
        ),
        wire_expression.Expression_kind.interpolationWrapper,
      ),
      (
        const TypedExpression(
          resultType: BooleanType(),
          expression: ComparisonExpression(
            operator: ComparisonOperator.equal,
            left: text,
            right: text,
          ),
        ),
        wire_expression.Expression_kind.comparisonWrapper,
      ),
      (
        TypedExpression(
          resultType: const BooleanType(),
          expression: BooleanExpression(
            operator: BooleanOperator.and,
            operands: const [truth, truth],
          ),
        ),
        wire_expression.Expression_kind.booleanOperationWrapper,
      ),
      (
        TypedExpression(
          resultType: const IntegerType(width: IntegerWidth.signed64),
          expression: ArithmeticExpression(
            operator: ArithmeticOperator.add,
            operands: [one, one],
          ),
        ),
        wire_expression.Expression_kind.arithmeticWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: ConditionalExpression(
            condition: truth,
            whenTrue: text,
            whenFalse: text,
          ),
        ),
        wire_expression.Expression_kind.conditionalWrapper,
      ),
      (
        TypedExpression(
          resultType: const ListType(element: StringType()),
          expression: CollectionMapExpression(
            source: TypedExpression(
              resultType: const ListType(element: StringType()),
              expression: LiteralExpression(
                ListValue(const [StringValue("a")]),
              ),
            ),
            itemBindingId: const BindingId(9),
            transform: const TypedExpression(
              resultType: StringType(),
              expression: BindingExpression(
                BindingReference(bindingId: BindingId(9)),
              ),
            ),
          ),
        ),
        wire_expression.Expression_kind.collectionMapWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: ConversionExpression(
            conversionId: ConversionId(namespace: "example", name: "to_string"),
            input: text,
          ),
        ),
        wire_expression.Expression_kind.conversionWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: StringOperationExpression(
            operation: StringOperation.titleCase,
            operands: [text],
          ),
        ),
        wire_expression.Expression_kind.stringOperationWrapper,
      ),
      (
        TypedExpression(
          resultType: const IntegerType(width: IntegerWidth.signed64),
          expression: CollectionOperationExpression(
            operation: CollectionOperation.length,
            operands: const [text],
          ),
        ),
        wire_expression.Expression_kind.collectionOperationWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: RegexExpression(
            operation: RegexOperation.capture,
            source: text,
            pattern: "(value)",
            group: 1,
          ),
        ),
        wire_expression.Expression_kind.regexWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: CoalesceExpression([text, text]),
        ),
        wire_expression.Expression_kind.coalesceWrapper,
      ),
      (
        TypedExpression(
          resultType: NamedType(standardTypeRefs.color),
          expression: ColorOperationExpression(
            operation: ColorOperation.withAlpha,
            color: color,
            alpha: one,
          ),
        ),
        wire_expression.Expression_kind.colorOperationWrapper,
      ),
    ];

    for (final (expression, expectedKind) in expressions) {
      final encoded = expressionEncoder.encode(expression).valueOrNull!;
      expect(encoded.expression?.kind, expectedKind);
      expect(expressionDecoder.decode(encoded).valueOrNull, expression);
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

  test("maps every editor action variant and its fields", () {
    final actions = <(EditorAction, Object)>[
      (
        const EditorAction.local(SetValueAction(target: binding, value: text)),
        wire_action.LocalEditorAction_kind.setValueWrapper,
      ),
      (
        EditorAction.local(
          InsertListItemAction(target: binding, index: one, value: text),
        ),
        wire_action.LocalEditorAction_kind.insertListItemWrapper,
      ),
      (
        EditorAction.local(RemoveListItemAction(target: binding, index: one)),
        wire_action.LocalEditorAction_kind.removeListItemWrapper,
      ),
      (
        const EditorAction.local(
          AppendListItemAction(target: binding, value: text),
        ),
        wire_action.LocalEditorAction_kind.appendListItemWrapper,
      ),
      (
        const EditorAction.local(DuplicateListItemAction(source: binding)),
        wire_action.LocalEditorAction_kind.duplicateListItemWrapper,
      ),
      (
        EditorAction.local(
          ReorderListItemAction(source: binding, newIndex: one),
        ),
        wire_action.LocalEditorAction_kind.reorderListItemWrapper,
      ),
      (
        const EditorAction.local(
          PutMapEntryAction(target: binding, key: text, value: text),
        ),
        wire_action.LocalEditorAction_kind.putMapEntryWrapper,
      ),
      (
        const EditorAction.local(
          RemoveMapEntryAction(target: binding, key: text),
        ),
        wire_action.LocalEditorAction_kind.removeMapEntryWrapper,
      ),
      (
        EditorAction.local(
          ReplaceConcreteTypeAction(
            target: binding,
            concreteType: named,
            initialValue: text,
          ),
        ),
        wire_action.LocalEditorAction_kind.replaceConcreteNominalTypeWrapper,
      ),
      (
        const EditorAction.realm(ReloadRealmAction()),
        wire_action.RealmEditorAction_kind.reloadWrapper,
      ),
      (
        const EditorAction.realm(
          InvokeRealmCallbackAction(
            actionId: RealmActionId(namespace: "example", name: "save"),
            payload: text,
          ),
        ),
        wire_action.RealmEditorAction_kind.callbackWrapper,
      ),
    ];

    for (final (action, expectedKind) in actions) {
      final encoded = actionEncoder.encode(action).valueOrNull!;
      final actualKind = switch (encoded) {
        wire_action.EditorAction_localWrapper(:final value) => value.kind,
        wire_action.EditorAction_realmWrapper(:final value) => value.kind,
        wire_action.EditorAction_unknown() => null,
      };
      expect(actualKind, expectedKind);
      expect(actionDecoder.decode(encoded).valueOrNull, action);
    }
  });

  test("decodes every independently authored mutation result", () {
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
    expect(
      actionDecoder.decodeMutation(results[0]).valueOrNull,
      const MutationSuccess(revision: 2, value: StringValue("saved")),
    );
    expect(
      actionDecoder.decodeMutation(results[1]).valueOrNull,
      const MutationConflict(
        expectedRevision: 1,
        actualRevision: 2,
        actualValue: StringValue("actual"),
      ),
    );
    final invalid = actionDecoder.decodeMutation(results[2]).valueOrNull!;
    expect(invalid, isA<MutationInvalid>());
    expect((invalid as MutationInvalid).diagnostics.single.message, "Invalid");
    final unavailable = actionDecoder.decodeMutation(results[3]).valueOrNull!;
    expect(unavailable, isA<MutationUnavailable>());
    expect(
      (unavailable as MutationUnavailable).diagnostics.single.code,
      TypeDiagnosticCode.invalidValue,
    );
    expect(
      actionDecoder.decodeMutation(results[4]).valueOrNull,
      const MutationPermissionDenied("Denied by policy"),
    );
  });
}
