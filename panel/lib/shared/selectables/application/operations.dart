import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const coreSelectionOperations = <SelectionOperation>[
  OpenOperation(),
  UnbindOperation(),
  DeleteOperation(),
];

/// Defines a user-invokable action that can operate on the current selection
/// in the inspector. Concrete implementations should be immutable and light-
/// weight; any expensive preparation should occur when executing, not on
/// construction.
abstract class SelectionOperation {
  const SelectionOperation();

  /// Human readable label displayed in menus / buttons.
  String get name;

  /// Human readable description displayed in tooltips.
  String get description;

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

abstract class ShortcutableOperation extends SelectionOperation {
  const ShortcutableOperation();

  /// Returns the [ActionShortcut] that should be registered for this operation.
  ActionShortcut get shortcut;
}

abstract class ActivatorShortcutOperation extends ShortcutableOperation {
  const ActivatorShortcutOperation();

  /// Keyboard shortcuts that trigger this operation.
  List<ShortcutActivator> get activators;

  @override
  ActionShortcut get shortcut => ActionShortcut(
    id: "operation_${name.snakeCase()}",
    label: name,
    description: description,
    activators: activators,
    onInvoke: executeOn,
    priority: 10,
  );
}

abstract class IntentShortcutOperation extends ShortcutableOperation {
  const IntentShortcutOperation();

  /// [Intent] that triggers this operation.
  Type get intent;

  @override
  ActionShortcut get shortcut => ActionShortcut.intent(
    id: "operation_${name.snakeCase()}",
    label: name,
    description: description,
    intent: intent,
    onInvoke: executeOn,
    priority: 10,
  );
}

/// Base type for per-selectable capability objects exposed via
/// [Selectable.capabilities]. Concrete [SelectionOperation] implementations inspect
/// the current selection for specific subclasses (e.g. [DeleteSelectionCapability])
/// to decide whether a higher-level operation is available and to aggregate
/// the per-item callbacks / data they carry. Extend this to advertise a
/// capability; it intentionally has no API itself.
extension SelectionCapabilitySelectionX on Iterable<Selectable> {
  /// True when every selectable exposes an operation of type [T].
  /// Returns false for an empty iterable.
  bool allHaveCapability<T extends SelectionCapability>() =>
      isNotEmpty && every((s) => s.capabilities.any((o) => o is T));

  /// True when at least one selectable exposes an operation of type [T].
  bool anyHaveCapability<T extends SelectionCapability>() =>
      any((s) => s.capabilities.any((o) => o is T));

  /// Collects all operations of type [T] from the selection in iteration order.
  Iterable<T> collectCapabilities<T extends SelectionCapability>() =>
      expand((s) => s.capabilities.whereType<T>());

  /// Collects all operations of type [T] and matching them with their respective selectable.
  Iterable<(Selectable, T)>
  collectCapabilitiesWithSelectables<T extends SelectionCapability>() =>
      expand((s) => s.capabilities.whereType<T>().map((o) => (s, o)));

  /// True when no selectable exposes an operation of type [T].
  bool noneHaveCapabilities<T extends SelectionCapability>() =>
      !anyHaveCapability<T>();
}

/// Computes the subset of registered [Operation]s that are currently
/// executable for the active selection. Emits an empty list when there is
/// no selection or nothing applicable, allowing the UI to hide controls.
List<SelectionOperation> availableSelectionOperations(
  List<SelectionOperation> operations,
  List<Selectable>? selected,
) {
  if (selected == null) return [];
  if (selected.isEmpty) return [];
  return operations
      .where((operation) => operation.canExecuteOn(selected))
      .toList();
}

/// Shows a dialog displaying errors that occurred during a batch operation.
/// Reusable across Delete, Unbind, and similar operations.
Future<void> showOperationErrorsPopup(
  BuildContext context,
  List<(Selectable, Object)> errors,
  String operationName,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        titlePadding: const EdgeInsets.only(
          left: 24,
          top: 16,
          right: 8,
          bottom: 0,
        ),
        title: Row(
          children: [
            Expanded(child: Text("$operationName errors")),
            IconButton(
              autofocus: true,
              splashRadius: 18,
              icon: const Icon(Icons.close),
              tooltip: "Close",
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  "Failed to ${operationName.toLowerCase()} ${errors.length} item(s). Others were ${operationName.toLowerCase()}d successfully.",
                ),
                for (final (selectable, err) in errors)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          selectable.name,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
                        ),
                        Text(
                          err.toString(),
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                        ),
                        const Divider(height: 8),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
