import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "render_scope.freezed.dart";

typedef BindingSetter =
    void Function(
      BindingReference reference,
      DataValue value,
      ExpressionContext context,
      Map<BindingId, BindingReference> aliases,
    );

typedef ActionExecutor =
    void Function(
      EditorAction action,
      ExpressionContext context,
      Map<BindingId, BindingReference> aliases,
    );

@freezed
abstract class ResolvedPresentationDefinition
    with _$ResolvedPresentationDefinition {
  const factory ResolvedPresentationDefinition({
    required PresentationId id,
    required PresentationNode root,
  }) = _ResolvedPresentationDefinition;
}

final class HeaderExpansionStore {
  final Map<Object, bool> _values = {};

  bool value({
    required String nodeId,
    required BindingReference? binding,
    required bool initial,
    Object? identity,
  }) => _values[identity ?? (nodeId, binding)] ?? initial;

  void set({
    required String nodeId,
    required BindingReference? binding,
    required bool expanded,
    Object? identity,
  }) => _values[identity ?? (nodeId, binding)] = expanded;

  void remove(Object identity) => _values.remove(identity);

  void clear() => _values.clear();
}

typedef PresentationResolver =
    ResolvedPresentationDefinition? Function(
      TypeExpression type,
      PresentationId? requested,
    );

@freezed
abstract class PresentationRenderScope with _$PresentationRenderScope {
  const factory PresentationRenderScope({
    required ExpressionContext expressions,
    required TypeRegistry registry,
    required ExpressionBudget budget,
    required BindingSetter setBinding,
    required ActionExecutor executeAction,
    required PresentationResolver resolvePresentation,
    required HeaderExpansionStore expansionStore,
    @Default({}) Map<BindingId, BindingReference> aliases,
    @Default({})
    Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,
    @Default({}) Set<(String, BindingReference?)> suppressedHeaders,
    @Default(true) bool enabled,
    @Default(false) bool readOnly,
    @Default({}) Set<PresentationId> activePresentations,
  }) = _PresentationRenderScope;

  const PresentationRenderScope._();

  BindingReference canonical(BindingReference reference) {
    final alias = aliases[reference.bindingId];
    if (alias == null) return reference;
    return alias.at(reference.path);
  }

  TypeResult<ResolvedBinding> resolve(BindingReference reference) =>
      expressions.bindings.resolve(reference);

  TypeResult<DataValue> evaluate(TypedExpression expression) =>
      expression.evaluate(expressions, registry: registry, budget: budget);

  String expressionText(TypedExpression expression) {
    final value = evaluate(expression).valueOrNull;
    return value == null ? "" : value.expressionDisplayText;
  }

  List<ShortcutActivator> shortcuts(
    HeaderItemId itemId,
    HeaderItemCommand command,
  ) =>
      headerShortcuts[HeaderItemCommandId(itemId: itemId, command: command)] ??
      const [];

  void update(BindingReference reference, DataValue value) {
    if (!enabled || readOnly) return;
    setBinding(reference, value, expressions, aliases);
  }

  void invoke(EditorAction action) {
    if (!enabled) return;
    if (readOnly && action is LocalEditorAction) return;
    executeAction(action, expressions, aliases);
  }

  PresentationRenderScope withAlias(
    BindingId id,
    BindingReference canonical,
    BindingSnapshot snapshot,
  ) => copyWith(
    expressions: expressions.withBinding(id, snapshot),
    aliases: {...aliases, id: canonical},
  );

  PresentationRenderScope withVirtualBinding(
    BindingId id,
    BindingSnapshot snapshot,
    ValueChanged<DataValue> onChanged,
  ) {
    var currentValue = snapshot.value;
    return copyWith(
      expressions: expressions.withBinding(id, snapshot),
      setBinding: (reference, value, context, aliases) {
        if (reference.bindingId != id) {
          setBinding(reference, value, context, aliases);
          return;
        }
        final updated = reference.path.replace(currentValue, value).valueOrNull;
        if (updated == null) return;
        currentValue = updated;
        onChanged(updated);
      },
      executeAction: (action, context, aliases) {
        if (action case LocalEditorAction(
          action: final local,
        ) when local._bindingReference.bindingId == id) {
          final result = action.execute(
            context,
            registry: registry,
            budget: budget,
          );
          if (result case MutationSuccess(:final value)) {
            currentValue = value;
            onChanged(value);
          }
          return;
        }
        executeAction(action, context, aliases);
      },
    );
  }
}

extension on LocalAction {
  BindingReference get _bindingReference => switch (this) {
    SetValueAction(:final target) ||
    InsertListItemAction(:final target) ||
    RemoveListItemAction(:final target) ||
    AppendListItemAction(:final target) ||
    PutMapEntryAction(:final target) ||
    RemoveMapEntryAction(:final target) ||
    ReplaceConcreteTypeAction(:final target) => target,
    DuplicateListItemAction(:final source) ||
    ReorderListItemAction(:final source) => source,
  };
}

Widget presentationDiagnostic(
  BuildContext context,
  Iterable<TypeDiagnostic> diagnostics,
) {
  final values = diagnostics.toList();
  final colors = Theme.of(context).colorScheme;
  return Material(
    color: colors.errorContainer,
    borderRadius: context.shapes.mediumBorderRadius,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 24),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                values.map((item) => item.message).join("\n"),
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Icon(Icons.error_outline, color: colors.onErrorContainer),
            ),
          ],
        ),
      ),
    ),
  );
}
