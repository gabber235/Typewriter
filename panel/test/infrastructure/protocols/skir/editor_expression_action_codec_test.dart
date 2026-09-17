import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
    final expressions = <(TypedExpression, skir.Expression_kind)>[
      (text, skir.Expression_kind.literalWrapper),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: BindingExpression(binding),
        ),
        skir.Expression_kind.bindingWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: FieldAccessExpression(target: text, fieldName: "name"),
        ),
        skir.Expression_kind.fieldAccessWrapper,
      ),
      (
        TypedExpression(
          resultType: const StringType(),
          expression: InterpolationExpression(const [
            InterpolationText("Name: "),
            InterpolationValue(text),
          ]),
        ),
        skir.Expression_kind.interpolationWrapper,
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
        skir.Expression_kind.comparisonWrapper,
      ),
      (
        TypedExpression(
          resultType: const BooleanType(),
          expression: BooleanExpression(
            operator: BooleanOperator.and,
            operands: const [truth, truth],
          ),
        ),
        skir.Expression_kind.booleanOperationWrapper,
      ),
      (
        TypedExpression(
          resultType: const IntegerType(width: IntegerWidth.signed64),
          expression: ArithmeticExpression(
            operator: ArithmeticOperator.add,
            operands: [one, one],
          ),
        ),
        skir.Expression_kind.arithmeticWrapper,
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
        skir.Expression_kind.conditionalWrapper,
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
        skir.Expression_kind.collectionMapWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: ConversionExpression(
            conversionId: ConversionId(namespace: "example", name: "to_string"),
            input: text,
          ),
        ),
        skir.Expression_kind.conversionWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: StringOperationExpression(
            operation: StringOperation.titleCase,
            operands: [text],
          ),
        ),
        skir.Expression_kind.stringOperationWrapper,
      ),
      (
        TypedExpression(
          resultType: const IntegerType(width: IntegerWidth.signed64),
          expression: CollectionOperationExpression(
            operation: CollectionOperation.length,
            operands: const [text],
          ),
        ),
        skir.Expression_kind.collectionOperationWrapper,
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
        skir.Expression_kind.regexWrapper,
      ),
      (
        const TypedExpression(
          resultType: StringType(),
          expression: CoalesceExpression([text, text]),
        ),
        skir.Expression_kind.coalesceWrapper,
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
        skir.Expression_kind.colorOperationWrapper,
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
      skir.TypedExpression(
        resultType: skir.TypeExpression.unit,
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
        skir.LocalEditorAction_kind.setValueWrapper,
      ),
      (
        EditorAction.local(
          InsertListItemAction(target: binding, index: one, value: text),
        ),
        skir.LocalEditorAction_kind.insertListItemWrapper,
      ),
      (
        EditorAction.local(RemoveListItemAction(target: binding, index: one)),
        skir.LocalEditorAction_kind.removeListItemWrapper,
      ),
      (
        const EditorAction.local(
          AppendListItemAction(target: binding, value: text),
        ),
        skir.LocalEditorAction_kind.appendListItemWrapper,
      ),
      (
        const EditorAction.local(DuplicateListItemAction(source: binding)),
        skir.LocalEditorAction_kind.duplicateListItemWrapper,
      ),
      (
        EditorAction.local(
          ReorderListItemAction(source: binding, newIndex: one),
        ),
        skir.LocalEditorAction_kind.reorderListItemWrapper,
      ),
      (
        const EditorAction.local(
          PutMapEntryAction(target: binding, key: text, value: text),
        ),
        skir.LocalEditorAction_kind.putMapEntryWrapper,
      ),
      (
        const EditorAction.local(
          RemoveMapEntryAction(target: binding, key: text),
        ),
        skir.LocalEditorAction_kind.removeMapEntryWrapper,
      ),
      (
        EditorAction.local(
          ReplaceConcreteTypeAction(
            target: binding,
            concreteType: named,
            initialValue: text,
          ),
        ),
        skir.LocalEditorAction_kind.replaceConcreteNominalTypeWrapper,
      ),
      (
        const EditorAction.realm(ReloadRealmAction()),
        skir.RealmEditorAction_kind.reloadWrapper,
      ),
      (
        const EditorAction.realm(
          InvokeRealmCommandAction(
            capabilityId: CapabilityId("capability"),
            payload: text,
          ),
        ),
        skir.RealmEditorAction_kind.commandWrapper,
      ),
    ];

    for (final (action, expectedKind) in actions) {
      final encoded = actionEncoder.encode(action).valueOrNull!;
      final actualKind = switch (encoded) {
        skir.EditorAction_localWrapper(:final value) => value.kind,
        skir.EditorAction_realmWrapper(:final value) => value.kind,
        skir.EditorAction_unknown() => null,
      };

      expect(actualKind, expectedKind);
      expect(actionDecoder.decode(encoded).valueOrNull, action);
    }
  });

  test("decodes every independently authored mutation result", () {
    final diagnostic = skir.TypeDiagnostic(
      code: skir.DiagnosticCode.invalidValue,
      severity: skir.DiagnosticSeverity.error,
      message: "Invalid",
      path: null,
      relatedType: null,
      details: const [],
    );
    final results = <skir.TypedMutationResult>[
      skir.TypedMutationResult.createSuccess(
        revision: 2,
        value: skir.TypedValue.wrapString("saved"),
      ),
      skir.TypedMutationResult.createConflict(
        expectedRevision: 1,
        actualRevision: 2,
        actualValue: skir.TypedValue.wrapString("actual"),
      ),
      skir.TypedMutationResult.wrapInvalid([diagnostic]),
      skir.TypedMutationResult.wrapUnavailable([diagnostic]),
      skir.TypedMutationResult.createPermissionDenied(
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
