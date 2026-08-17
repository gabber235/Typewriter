import "package:typewriter_panel/typewriter_panel.dart";

extension TypedExpressionPresentationSubstitution on TypedExpression {
  TypedExpression substituteTypes(Map<String, TypeExpression> substitutions) =>
      TypedExpression(
        resultType: resultType.substitute(substitutions),
        expression: expression._substituteTypes(substitutions),
      );
}

extension on Expression {
  Expression _substituteTypes(Map<String, TypeExpression> substitutions) {
    final value = this;
    return switch (value) {
      LiteralExpression() => value,
      BindingExpression() => value,
      FieldAccessExpression() => FieldAccessExpression(
        target: value.target.substituteTypes(substitutions),
        fieldName: value.fieldName,
      ),
      InterpolationExpression() => InterpolationExpression(
        value.parts
            .map(
              (part) => switch (part) {
                InterpolationText() => part,
                InterpolationValue() => InterpolationValue(
                  part.value.substituteTypes(substitutions),
                ),
              },
            )
            .toList(),
      ),
      ComparisonExpression() => ComparisonExpression(
        operator: value.operator,
        left: value.left.substituteTypes(substitutions),
        right: value.right.substituteTypes(substitutions),
      ),
      BooleanExpression() => BooleanExpression(
        operator: value.operator,
        operands: value.operands
            .map((operand) => operand.substituteTypes(substitutions))
            .toList(),
      ),
      ArithmeticExpression() => ArithmeticExpression(
        operator: value.operator,
        operands: value.operands
            .map((operand) => operand.substituteTypes(substitutions))
            .toList(),
      ),
      ConditionalExpression() => ConditionalExpression(
        condition: value.condition.substituteTypes(substitutions),
        whenTrue: value.whenTrue.substituteTypes(substitutions),
        whenFalse: value.whenFalse.substituteTypes(substitutions),
      ),
      CollectionMapExpression() => CollectionMapExpression(
        source: value.source.substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
        transform: value.transform.substituteTypes(substitutions),
      ),
      CollectionFilterExpression() => CollectionFilterExpression(
        source: value.source.substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
        predicate: value.predicate.substituteTypes(substitutions),
      ),
      CollectionQuantifierExpression() => CollectionQuantifierExpression(
        source: value.source.substituteTypes(substitutions),
        quantifier: value.quantifier,
        itemBindingId: value.itemBindingId,
        predicate: value.predicate.substituteTypes(substitutions),
      ),
      CollectionFindExpression() => CollectionFindExpression(
        source: value.source.substituteTypes(substitutions),
        selection: value.selection,
        itemBindingId: value.itemBindingId,
        predicate: value.predicate.substituteTypes(substitutions),
      ),
      CollectionCountExpression() => CollectionCountExpression(
        source: value.source.substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
        predicate: value.predicate.substituteTypes(substitutions),
      ),
      CollectionDistinctExpression() => CollectionDistinctExpression(
        source: value.source.substituteTypes(substitutions),
        key: value.key?.substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
      ),
      CollectionSortExpression() => CollectionSortExpression(
        source: value.source.substituteTypes(substitutions),
        key: value.key.substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
        direction: value.direction,
        comparator: value.comparator?.copyWith(
          comparison: value.comparator!.comparison.substituteTypes(
            substitutions,
          ),
        ),
      ),
      CollectionGroupExpression() => CollectionGroupExpression(
        source: value.source.substituteTypes(substitutions),
        key: value.key.substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
        value: value.value?.substituteTypes(substitutions),
      ),
      CollectionReduceExpression() => CollectionReduceExpression(
        source: value.source.substituteTypes(substitutions),
        accumulatorBindingId: value.accumulatorBindingId,
        itemBindingId: value.itemBindingId,
        reduction: value.reduction.substituteTypes(substitutions),
      ),
      CollectionFoldExpression() => CollectionFoldExpression(
        source: value.source.substituteTypes(substitutions),
        initial: value.initial.substituteTypes(substitutions),
        accumulatorBindingId: value.accumulatorBindingId,
        itemBindingId: value.itemBindingId,
        reduction: value.reduction.substituteTypes(substitutions),
      ),
      CollectionTransformExpression() => CollectionTransformExpression(
        source: value.source.substituteTypes(substitutions),
        operation: value.operation,
        transform: value.transform?.substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
        count: value.count?.substituteTypes(substitutions),
      ),
      IsTypeExpression() => IsTypeExpression(
        source: value.source.substituteTypes(substitutions),
        type: value.type.substitute(substitutions),
      ),
      ConversionExpression() => ConversionExpression(
        conversionId: value.conversionId,
        input: value.input.substituteTypes(substitutions),
      ),
      StringOperationExpression() => StringOperationExpression(
        operation: value.operation,
        operands: value.operands
            .map((operand) => operand.substituteTypes(substitutions))
            .toList(),
      ),
      CollectionOperationExpression() => CollectionOperationExpression(
        operation: value.operation,
        operands: value.operands
            .map((operand) => operand.substituteTypes(substitutions))
            .toList(),
      ),
      RegexExpression() => RegexExpression(
        operation: value.operation,
        source: value.source.substituteTypes(substitutions),
        pattern: value.pattern,
        group: value.group,
        replacement: value.replacement,
      ),
      CoalesceExpression() => CoalesceExpression(
        value.operands
            .map((operand) => operand.substituteTypes(substitutions))
            .toList(),
      ),
      ColorOperationExpression() => ColorOperationExpression(
        operation: value.operation,
        color: value.color.substituteTypes(substitutions),
        alpha: value.alpha.substituteTypes(substitutions),
      ),
    };
  }
}

extension EditorActionPresentationSubstitution on EditorAction {
  EditorAction substituteTypes(Map<String, TypeExpression> substitutions) =>
      switch (this) {
        LocalEditorAction(:final action) => EditorAction.local(
          action._substituteTypes(substitutions),
        ),
        RealmEditorAction(:final action) => EditorAction.realm(
          action._substituteTypes(substitutions),
        ),
      };
}

extension on LocalAction {
  LocalAction _substituteTypes(Map<String, TypeExpression> substitutions) {
    final value = this;
    return switch (value) {
      SetValueAction() => SetValueAction(
        target: value.target,
        value: value.value.substituteTypes(substitutions),
      ),
      InsertListItemAction() => InsertListItemAction(
        target: value.target,
        index: value.index.substituteTypes(substitutions),
        value: value.value.substituteTypes(substitutions),
      ),
      RemoveListItemAction() => RemoveListItemAction(
        target: value.target,
        index: value.index.substituteTypes(substitutions),
      ),
      AppendListItemAction() => AppendListItemAction(
        target: value.target,
        value: value.value.substituteTypes(substitutions),
      ),
      DuplicateListItemAction() => value,
      ReorderListItemAction() => ReorderListItemAction(
        source: value.source,
        newIndex: value.newIndex.substituteTypes(substitutions),
      ),
      PutMapEntryAction() => PutMapEntryAction(
        target: value.target,
        key: value.key.substituteTypes(substitutions),
        value: value.value.substituteTypes(substitutions),
      ),
      RemoveMapEntryAction() => RemoveMapEntryAction(
        target: value.target,
        key: value.key.substituteTypes(substitutions),
      ),
      ReplaceConcreteTypeAction() => ReplaceConcreteTypeAction(
        target: value.target,
        concreteType: value.concreteType.substitute(substitutions),
        initialValue: value.initialValue.substituteTypes(substitutions),
      ),
    };
  }
}

extension on RealmAction {
  RealmAction _substituteTypes(Map<String, TypeExpression> substitutions) {
    final value = this;
    return switch (value) {
      ReloadRealmAction() => value,
      InvokeRealmCallbackAction() => InvokeRealmCallbackAction(
        actionId: value.actionId,
        payload: value.payload.substituteTypes(substitutions),
      ),
    };
  }
}
