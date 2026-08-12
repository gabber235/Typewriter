import "package:typewriter_panel/typewriter_panel.dart";

part "action_list_reorder_executor.dart";

extension LocalEditorActionExecution on LocalEditorAction {
  TypedMutationResult execute(
    ExpressionContext context, {
    required TypeRegistry? registry,
    ExpressionBudget budget = const ExpressionBudget(),
  }) => action._execute(context, registry, budget);
}

extension on LocalAction {
  TypedMutationResult _execute(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) => switch (this) {
    final SetValueAction action => action._set(context, registry, budget),
    final InsertListItemAction action => action._insert(
      context,
      registry,
      budget,
    ),
    final RemoveListItemAction action => action._remove(
      context,
      registry,
      budget,
    ),
    final AppendListItemAction action => action._append(
      context,
      registry,
      budget,
    ),
    final DuplicateListItemAction action => action._duplicate(
      context,
      registry,
    ),
    final ReorderListItemAction action => action._reorder(
      context,
      registry,
      budget,
    ),
    final PutMapEntryAction action => action.executeMapMutation(
      context,
      registry,
      budget,
    ),
    final RemoveMapEntryAction action => action.executeMapMutation(
      context,
      registry,
      budget,
    ),
    final ReplaceConcreteTypeAction action => action.executeConcreteReplacement(
      context,
      registry,
      budget,
    ),
  };
}

extension on SetValueAction {
  TypedMutationResult _set(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context);
    if (binding case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    final evaluated = value.evaluate(
      context,
      registry: registry,
      budget: budget,
    );
    if (evaluated case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    return target.replaceValue(
      binding.valueOrNull!.type,
      evaluated.valueOrNull!,
      context,
      registry,
    );
  }
}

extension on InsertListItemAction {
  TypedMutationResult _insert(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context);
    if (binding case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    final position = index._integer(context, registry, budget);
    if (position case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    return _insertValue(
      binding.valueOrNull!,
      position.valueOrNull!,
      value,
      context,
      registry,
      budget,
    );
  }
}

extension on AppendListItemAction {
  TypedMutationResult _append(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context);
    if (binding case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    final resolved = binding.valueOrNull!;
    if (resolved.value is! ListValue) {
      return invalidMutation("Append target must be a list");
    }
    return _insertValue(
      resolved,
      (resolved.value as ListValue).values.length,
      value,
      context,
      registry,
      budget,
    );
  }
}

extension on RemoveListItemAction {
  TypedMutationResult _remove(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context);
    if (binding case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    final position = index._integer(context, registry, budget);
    if (position case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    final resolved = binding.valueOrNull!;
    if (resolved.type is! ListType || resolved.value is! ListValue) {
      return invalidMutation("Remove target must be a list");
    }
    final values = List<DataValue>.of((resolved.value as ListValue).values);
    final offset = position.valueOrNull!;
    if (offset < 0 || offset >= values.length) {
      return invalidMutation("Remove index is outside the list");
    }
    values.removeAt(offset);
    return target.replaceValue(
      resolved.type,
      ListValue(values),
      context,
      registry,
    );
  }
}

TypeResult<ResolvedBinding> _resolved(
  BindingReference reference,
  ExpressionContext context,
) {
  final resolved = context.bindings.resolve(reference);
  if (resolved case TypeSuccess(:final value) when !value.writable) {
    return TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Binding is read only",
      ),
    ]);
  }
  return resolved;
}

TypedMutationResult _insertValue(
  ResolvedBinding binding,
  int index,
  TypedExpression value,
  ExpressionContext context,
  TypeRegistry? registry,
  ExpressionBudget budget,
) {
  if (binding.type is! ListType || binding.value is! ListValue) {
    return invalidMutation("Insert target must be a list");
  }
  final type = binding.type as ListType;
  final values = List<DataValue>.of((binding.value as ListValue).values);
  if (index < 0 || index > values.length) {
    return invalidMutation("Insert index is outside the list");
  }
  final evaluated = value.evaluate(context, registry: registry, budget: budget);
  if (evaluated case TypeFailure(:final diagnostics)) {
    return MutationInvalid(diagnostics);
  }
  final diagnostics = evaluated.valueOrNull!.validateAgainst(
    type.element,
    registry: registry,
  );
  if (diagnostics.isNotEmpty) return MutationInvalid(diagnostics);
  values.insert(index, evaluated.valueOrNull!);
  return binding.reference.replaceValue(
    type,
    ListValue(values),
    context,
    registry,
  );
}
