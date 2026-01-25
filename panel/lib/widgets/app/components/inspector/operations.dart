import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/normal_mode.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations/delete_operation.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations/entry_operations.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations/open_operation.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations/unbind_operation.dart";
import "package:typewriter_panel/widgets/generic/components/context_menu.dart";

export "package:typewriter_panel/widgets/app/components/inspector/operations/open_operation.dart";
export "package:typewriter_panel/widgets/app/components/inspector/operations/unbind_operation.dart";

part "operations.g.dart";

/// Provides the complete registry of available [Operation] implementations.
/// Add new operations here to expose them to the UI
/// Keep ordering meaningful; it will be used for presentation where applicable.
@riverpod
List<Operation> operations(Ref ref) => [
  const OpenOperation(),
  const UnbindOperation(),
  const DeleteOperation(),

  /// Entry operations
  const EntryLinkWithOperation(),
  const EntryLinkWithDuplicateOperation(),
  const EntryDuplicateOperation(),
  const EntryMoveToPageOperation(),
  const EntryReplaceWithOperation(),
];

/// Defines a user-invokable action that can operate on the current selection
/// in the inspector. Concrete implementations should be immutable and light-
/// weight; any expensive preparation should occur when executing, not on
/// construction.
abstract class Operation {
  const Operation();

  /// Human readable label displayed in menus / buttons.
  String get name;

  /// Human readable description displayed in tooltips.
  String get description;

  /// Keyboard shortcuts that trigger this operation (platform aware).
  List<ShortcutActivator> get shortcutActivators;

  /// Returns true if this operation can currently execute on the provided
  /// selection set. Called reactively; keep fast and side-effect free.
  /// Assures that the selection is not empty.
  bool canExecuteOn(List<Selectable> selection);

  /// Executes this operation for the given (non-empty) selection.
  ///
  /// This is invoked only after [canExecuteOn] has returned true for the same
  /// selection. Implementations may:
  /// - Mutate underlying model / document state.
  /// - Emit provider state changes.
  /// - Trigger UI side-effects (navigation, dialogs, etc.).
  ///
  /// Asynchrony:
  /// Return a Future to perform asynchronous work; return synchronously (void)
  /// for immediate completion. Callers may await the returned FutureOr.
  ///
  /// Contract / expectations:
  /// - [selection] is guaranteed by the caller to be non-empty and still valid;
  ///   defensive re-checks are optional.
  /// - Do not retain the passed list instance; the function should be emphemeral.
  /// - Validation / enablement logic should reside in [canExecuteOn]; this
  ///   method should only throw for unrecoverable programmer errors.
  FutureOr<void> executeOn(WidgetRef ref);

  /// Builds the context menu representation for this operation.
  ///
  /// Implementations should return a lightweight [MenuItem] that, when
  /// activated, triggers [executeOn]. This is used by components such as
  /// [ContextMenuRegion] to surface the operation in right‑click / long‑press
  /// menus.
  ///
  /// Parameter:
  /// - [ref]: A [WidgetRef] giving access to providers needed to evaluate
  ///   current selection state or perform the operation when invoked.
  ///
  /// Expectations / guidelines:
  /// - Must be fast and side‑effect free (other than creating the menu item).
  /// - Enable / disable logic should already be handled via [canExecuteOn] and
  ///   filtering (i.e. this method is only called for applicable operations).
  /// - Implementations may still defensively guard against unexpected states,
  ///   but should avoid heavy recomputation.
  MenuItem menuItem(WidgetRef ref);

  /// Builds the UI control (e.g. a button) representing this operation for
  /// the given selection. The control is responsible for invoking the action.
  Widget inspectorButton(List<Selectable> selection);
}

/// Base type for per-selectable capability objects exposed via
/// [Selectable.operations]. Concrete [Operation] implementations inspect
/// the current selection for specific subclasses (e.g. [DeleteSelectableOperation])
/// to decide whether a higher-level operation is available and to aggregate
/// the per-item callbacks / data they carry. Extend this to advertise a
/// capability; it intentionally has no API itself.
abstract class SelectableOperation {}

/// Selection helpers for inspecting [Selectable.operations].
extension SelectableOperationSelectionX on Iterable<Selectable> {
  /// True when every selectable exposes an operation of type [T].
  /// Returns false for an empty iterable.
  bool allHaveOperation<T extends SelectableOperation>() =>
      isNotEmpty && every((s) => s.operations.any((o) => o is T));

  /// True when at least one selectable exposes an operation of type [T].
  bool anyHaveOperation<T extends SelectableOperation>() =>
      any((s) => s.operations.any((o) => o is T));

  /// Collects all operations of type [T] from the selection in iteration order.
  Iterable<T> collectOperations<T extends SelectableOperation>() =>
      expand((s) => s.operations.whereType<T>());

  /// Collects all operations of type [T] and matching them with their respective selectable.
  Iterable<(Selectable, T)>
  collectOperationsWithSelectables<T extends SelectableOperation>() =>
      expand((s) => s.operations.whereType<T>().map((o) => (s, o)));

  /// True when no selectable exposes an operation of type [T].
  bool noneHaveOperations<T extends SelectableOperation>() =>
      !anyHaveOperation<T>();
}

/// Computes the subset of registered [Operation]s that are currently
/// executable for the active selection. Emits an empty list when there is
/// no selection or nothing applicable, allowing the UI to hide controls.
@riverpod
List<Operation> availableOperations(Ref ref) {
  final operations = ref.watch(operationsProvider);
  final selected = ref.watch(selectedProvider).value;
  if (selected == null) return [];
  if (selected.isEmpty) return [];
  return operations
      .where((operation) => operation.canExecuteOn(selected))
      .toList();
}

/// Global widget that registers keyboard shortcuts for currently available
/// operations (based on current selection) and invokes them when triggered.
class GlobalOperationShortcuts extends ConsumerWidget {
  const GlobalOperationShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentInteractionModeProvider);

    final operations = ref.watch(
      availableOperationsProvider.select(
        (s) => s.where((o) => o.shortcutActivators.isNotEmpty).toList(),
      ),
    );

    final activeOperations = currentMode is NormalMode
        ? operations
        : <Operation>[];

    return ActionSet(
      shortcuts: [
        for (final op in activeOperations)
          ActionShortcut(
            id: "operation_${op.name.snakeCase()}",
            label: op.name,
            description: op.description,
            activators: op.shortcutActivators,
            onInvoke: op.executeOn,
            priority: 10,
          ),
      ],
      child: Shortcuts(
        shortcuts: {
          for (final op in activeOperations)
            for (final activator in op.shortcutActivators)
              activator: _OperationIntent(operation: op),
        },
        child: Actions(
          actions: {
            _OperationIntent: CallbackAction<_OperationIntent>(
              onInvoke: (intent) {
                intent.operation.executeOn(ref);
                return null;
              },
            ),
          },
          child: child,
        ),
      ),
    );
  }
}

class _OperationIntent extends Intent {
  const _OperationIntent({required this.operation});
  final Operation operation;
}
