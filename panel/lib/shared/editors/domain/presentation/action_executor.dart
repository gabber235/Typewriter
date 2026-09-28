import "package:typewriter_panel/typewriter_panel.dart";

part "action_list_reorder_executor.dart";

/// Executes local actions against one immutable expression context.
///
/// Resolution checks writability and expression evaluation checks the supplied
/// budget. Concrete type selection is handled by the draft owner because its
/// payload must be completed by Realm initialization before persistence.

extension LocalEditorActionExecution on LocalEditorAction {
  LocalMutationResult execute(
    ExpressionContext context, {
    required TypeRegistry? registry,
    ExpressionBudget budget = const ExpressionBudget(),
  }) => action._execute(context, registry, budget);
}

extension on LocalAction {
  LocalMutationResult _execute(
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
    ReplaceConcreteTypeAction() => invalidLocalMutation(
      "Concrete type selection must be applied by the draft owner",
    ),
  };
}

extension on SetValueAction {
  LocalMutationResult _set(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context, registry);
    if (binding case TypeFailure(:final diagnostics)) {
      return LocalMutationInvalid(diagnostics);
    }
    final evaluated = value.evaluate(
      context,
      registry: registry,
      budget: budget,
    );
    if (evaluated case TypeFailure(:final diagnostics)) {
      return LocalMutationInvalid(diagnostics);
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
  LocalMutationResult _insert(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context, registry);
    if (binding case TypeFailure(:final diagnostics)) {
      return LocalMutationInvalid(diagnostics);
    }
    final position = index._integer(context, registry, budget);
    if (position case TypeFailure(:final diagnostics)) {
      return LocalMutationInvalid(diagnostics);
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
  LocalMutationResult _append(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context, registry);
    if (binding case TypeFailure(:final diagnostics)) {
      return LocalMutationInvalid(diagnostics);
    }
    final resolved = binding.valueOrNull!;
    if (resolved.value is! ListValue) {
      return invalidLocalMutation("Append target must be a list");
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
  LocalMutationResult _remove(
    ExpressionContext context,
    TypeRegistry? registry,
    ExpressionBudget budget,
  ) {
    final binding = _resolved(target, context, registry);
    if (binding case TypeFailure(:final diagnostics)) {
      return LocalMutationInvalid(diagnostics);
    }
    final position = index._integer(context, registry, budget);
    if (position case TypeFailure(:final diagnostics)) {
      return LocalMutationInvalid(diagnostics);
    }

    final resolved = binding.valueOrNull!;
    if (resolved.type is! ListType || resolved.value is! ListValue) {
      return invalidLocalMutation("Remove target must be a list");
    }

    final values = List<DataValue>.of((resolved.value as ListValue).values);

    final offset = position.valueOrNull!;
    if (offset < 0 || offset >= values.length) {
      return invalidLocalMutation("Remove index is outside the list");
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
  TypeRegistry? registry,
) {
  final resolved = context.bindings.resolve(reference, registry: registry);
  if (resolved case TypeSuccess(:final value) when !value.writable) {
    return TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Binding is read only",
      ),
    ]);
  }
  if (resolved case TypeSuccess(:final value)) {
    return TypeResult.success(
      value.copyWith(type: value.type.bindingRepresentation(registry)),
    );
  }
  return resolved;
}

LocalMutationResult _insertValue(
  ResolvedBinding binding,
  int index,
  TypedExpression value,
  ExpressionContext context,
  TypeRegistry? registry,
  ExpressionBudget budget,
) {
  if (binding.type is! ListType || binding.value is! ListValue) {
    return invalidLocalMutation("Insert target must be a list");
  }
  final type = binding.type as ListType;
  final values = List<DataValue>.of((binding.value as ListValue).values);
  if (index < 0 || index > values.length) {
    return invalidLocalMutation("Insert index is outside the list");
  }

  final evaluated = value.evaluate(context, registry: registry, budget: budget);
  if (evaluated case TypeFailure(:final diagnostics)) {
    return LocalMutationInvalid(diagnostics);
  }
  final diagnostics = evaluated.valueOrNull!.validateAgainst(
    type.element,
    registry: registry,
  );

  if (diagnostics.isNotEmpty) return LocalMutationInvalid(diagnostics);

  values.insert(index, evaluated.valueOrNull!);
  return binding.reference.replaceValue(
    type,
    ListValue(values),
    context,
    registry,
  );
}
