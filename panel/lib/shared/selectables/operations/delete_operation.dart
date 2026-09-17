import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Advertises deletion for one selectable.
///
/// The callback owns deletion of its item. [DeleteOperation] invokes callbacks
/// serially, retains failures per item, and removes only successful items from
/// the canonical selection.
class DeleteSelectionCapability extends SelectionCapability {
  DeleteSelectionCapability({required this.onDelete});
  final FutureOr<void> Function() onDelete;
}

/// Deletes the selected items when every item supports deletion.
///
/// Successful callbacks are committed independently. Failed callbacks remain
/// selected and are reported together after the batch completes.
class DeleteOperation extends IntentShortcutOperation {
  const DeleteOperation();

  @override
  String get name => "Delete";

  @override
  String get description => "Delete selected items";

  @override
  Type get intent => DeleteIntent;

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.allHaveCapability<DeleteSelectionCapability>();

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selection = ref.read(selectedProvider).requireValue;

    final context = ref.context;
    final scheme = Theme.of(context).colorScheme;
    final foregroundColor = scheme.onError;
    final backgroundColor = scheme.error;

    final confirmed = await showConfirmationDialogue(
      context: context,
      title: "Delete ${selection.length} item(s)?",
      content: "This action cannot be undone.",
      confirmText: "Delete",
      confirmColor: backgroundColor,
      onConfirmColor: foregroundColor,
    );
    if (!confirmed) return;

    final callbacks = <(Selectable, Future<void> Function())>[];
    for (final (s, op)
        in selection
            .collectCapabilitiesWithSelectables<DeleteSelectionCapability>()) {
      callbacks.add((s, () async => await op.onDelete()));
    }

    final errors = <(Selectable, Object)>[];
    for (final (selectable, callback) in callbacks) {
      try {
        await callback();
      } on Object catch (e) {
        errors.add((selectable, e));
      }
    }

    if (!ref.context.mounted) return;
    final removed = selection
        .map((s) => s.id)
        .where((id) => errors.none((e) => e.$1.id == id))
        .toList();
    ref.read(selectionProvider.notifier).unselectAll(removed);
    if (errors.isEmpty) return;
    await showOperationErrorsPopup(ref.context, errors, "Delete");
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icon(Icons.delete),
      label: "Delete",
      color: Theme.of(ref.context).colorScheme.error,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) =>
      DeleteOperationButton(selection: selection, operation: this);
}

/// Inspector control for [DeleteOperation], including confirmation and count.
class DeleteOperationButton extends HookConsumerWidget {
  const DeleteOperationButton({
    required this.selection,
    required this.operation,
    super.key,
  });

  final List<Selectable> selection;
  final DeleteOperation operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final foregroundColor = scheme.onError;
    final backgroundColor = scheme.error;

    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.space2),
      child: OperationButton.filledIcon(
        operation: operation,
        onPressed: () async {
          await operation.executeOn(ref);
        },
        style: FilledButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
        icon: const Icon(Icons.delete_outline, size: 16),
        label: Text(
          selection.length > 1 ? "Delete (${selection.length})" : "Delete",
        ),
      ),
    );
  }
}
