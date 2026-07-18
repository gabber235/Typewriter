import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shortcuts/shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/selectable.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";
import "package:typewriter_panel/shared/ui/components/context_menu.dart";
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/ui/components/shortcut_display.dart";

/// A selectable-level operation holding the asynchronous delete callback.
class DeleteSelectableOperation extends SelectableOperation {
  DeleteSelectableOperation({required this.onDelete});
  final FutureOr<void> Function() onDelete;
}

/// The delete operation exposed when every selected item provides a
/// [DeleteSelectableOperation].
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
      selection.allHaveOperation<DeleteSelectableOperation>();

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selection = ref.read(selectedProvider).requireValue;
    final callbacks = <(Selectable, Future<void> Function())>[];
    for (final (s, op)
        in selection
            .collectOperationsWithSelectables<DeleteSelectableOperation>()) {
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LoadingButton.filledIcon(
        onPressed: () {
          showConfirmationDialogue(
            context: context,
            title: "Delete ${selection.length} item(s)?",
            content: "This action cannot be undone.",
            confirmText: "Delete",
            confirmColor: Theme.of(context).colorScheme.error,
            onConfirmColor: Theme.of(context).colorScheme.onError,
            onConfirm: () async {
              await operation.executeOn(ref);
            },
          );
        },
        style: FilledButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onError,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: const Icon(Icons.delete_outline, size: 16),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selection.length > 1 ? "Delete (${selection.length})" : "Delete",
            ),
            if (operation.shortcut.canInvoke) ...[
              const SizedBox(width: 8),
              RotatingShortcuts(shortcuts: operation.shortcut.shortcuts, style: KeyStyle.outline),
            ],
          ],
        ),
      ),
    );
  }
}
