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

typedef EditorInteractionStarter =
    EditorInteractionSession? Function(BindingReference reference);

final class VirtualBindingHost {
  VirtualBindingHost({
    required this.id,
    required BindingSnapshot snapshot,
    required this.onChanged,
    this.interactionTarget,
  }) : _snapshot = snapshot;

  final BindingId id;
  final ValueChanged<DataValue> onChanged;
  final BindingReference? interactionTarget;
  BindingSnapshot _snapshot;

  BindingSnapshot get snapshot => _snapshot;

  ExpressionContext bind(ExpressionContext context) {
    return context.withBinding(id, _snapshot);
  }

  BindingReference interactionReference(BindingReference reference) {
    if (reference.bindingId != id || interactionTarget == null) {
      return reference;
    }
    return interactionTarget!.at(reference.path);
  }

  bool update(DataPath path, DataValue value) {
    final updated = path.replace(_snapshot.value, value).valueOrNull;
    if (updated == null) return false;

    _replace(updated);
    return true;
  }

  TypedMutationResult execute(
    LocalEditorAction action,
    ExpressionContext context, {
    required TypeRegistry registry,
    required ExpressionBudget budget,
  }) {
    final result = action.execute(
      bind(context),
      registry: registry,
      budget: budget,
    );
    if (result case MutationSuccess(:final value)) {
      _replace(value);
    }
    return result;
  }

  void _replace(DataValue value) {
    _snapshot = _snapshot.withValue(value);
    onChanged(value);
  }
}

@freezed
abstract class ResolvedPresentationDefinition
    with _$ResolvedPresentationDefinition {
  const factory ResolvedPresentationDefinition({
    required PresentationId id,
    required PresentationNode root,
  }) = _ResolvedPresentationDefinition;
}

@freezed
sealed class HeaderExpansionKey with _$HeaderExpansionKey {
  const factory HeaderExpansionKey.node({
    required String nodeId,
    required BindingReference? binding,
  }) = NodeHeaderExpansionKey;

  const factory HeaderExpansionKey.instance(Object identity) =
      InstanceHeaderExpansionKey;
}

final class HeaderExpansionStore {
  final Map<HeaderExpansionKey, bool> _values = {};

  bool value({required HeaderExpansionKey key, required bool initial}) {
    return _values[key] ?? initial;
  }

  void set({required HeaderExpansionKey key, required bool expanded}) {
    _values[key] = expanded;
  }

  void remove(HeaderExpansionKey key) {
    _values.remove(key);
  }

  void clear() {
    _values.clear();
  }
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
    EditorInteractionStarter? startInteraction,
    RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,
    @Default({})
    Map<PresentationCollectionSourceId, PresentationCollectionSource>
    collections,
    @Default({}) Map<BindingId, BindingReference> aliases,
    @Default({})
    Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,
    @Default({}) Set<(String, BindingReference?)> suppressedHeaders,
    @Default(true) bool enabled,
    @Default(false) bool readOnly,
    @Default("local") String historyNamespace,
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

  EditorInteractionSession? beginInteraction(BindingReference reference) =>
      startInteraction?.call(canonical(reference));

  PresentationRenderScope withAlias(
    BindingId id,
    BindingReference canonical,
    BindingSnapshot snapshot,
  ) => copyWith(
    expressions: expressions.withBinding(id, snapshot),
    aliases: {...aliases, id: canonical},
  );

  PresentationRenderScope withVirtualBinding(VirtualBindingHost host) {
    return copyWith(
      expressions: host.bind(expressions),
      startInteraction: (reference) {
        return startInteraction?.call(host.interactionReference(reference));
      },
      setBinding: (reference, value, context, aliases) {
        if (reference.bindingId != host.id) {
          setBinding(reference, value, context, aliases);
          return;
        }
        host.update(reference.path, value);
      },
      executeAction: (action, context, aliases) {
        if (action case LocalEditorAction(
          action: final local,
        ) when local._bindingReference.bindingId == host.id) {
          host.execute(action, context, registry: registry, budget: budget);
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
