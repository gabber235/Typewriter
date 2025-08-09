import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations/delete_operation.dart";

part "operations.g.dart";

/// Provides the complete registry of available [Operation] implementations.
/// Add new operations here to expose them to the UI
/// Keep ordering meaningful; it will be used for presentation where applicable.
@riverpod
List<Operation> operations(Ref ref) => [
      DeleteOperation(),
    ];

/// Defines a user-invokable action that can operate on the current selection
/// in the inspector. Concrete implementations should be immutable and light-
/// weight; any expensive preparation should occur when executing, not on
/// construction.
abstract class Operation {
  /// Human readable label displayed in menus / buttons.
  String get name;

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
  FutureOr<void> executeOn(BuildContext context, List<Selectable> selection);

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
  final selected = ref.watch(selectedProvider).value;
  if (selected == null) return [];
  if (selected.isEmpty) return [];
  final operations = ref.watch(operationsProvider);
  return operations
      .where((operation) => operation.canExecuteOn(selected))
      .toList();
}
