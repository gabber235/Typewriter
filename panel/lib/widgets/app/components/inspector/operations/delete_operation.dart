import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/context_menu.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";
import "package:typewriter_panel/widgets/generic/components/shortcut_display.dart";

/// A selectable-level operation holding the asynchronous delete callback.
class DeleteSelectableOperation extends SelectableOperation {
  DeleteSelectableOperation({required this.onDelete});
  final FutureOr<void> Function() onDelete;
}

/// The delete operation exposed when every selected item provides a
/// [DeleteSelectableOperation].
class DeleteOperation extends Operation {
  const DeleteOperation();

  @override
  String get name => "Delete";

  @override
  String get description => "Delete selected items";

  @override
  List<ShortcutActivator> get shortcutActivators => shortcutsFor(DeleteIntent);

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.allHaveOperation<DeleteSelectableOperation>();

  @override
  FutureOr<void> executeOn(
    WidgetRef ref,
  ) async {
    final selection = ref.read(selectedProvider).requireValue;
    final callbacks = <(Selectable, Future<void> Function())>[];
    for (final (s, op) in selection
        .collectOperationsWithSelectables<DeleteSelectableOperation>()) {
      callbacks.add((s, () async => await op.onDelete()));
    }

    final errors = <(Selectable, Object)>[];
    for (final (selectable, callback) in callbacks) {
      try {
        await callback();
      } on Error catch (e) {
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
    await _showErrorsPopup(ref.context, errors);
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: Icon(Icons.delete),
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
        icon: const Icon(
          Icons.delete_outline,
          size: 16,
        ),
        label: Row(
          children: [
            Text(
              selection.length > 1 ? "Delete (${selection.length})" : "Delete",
            ),
            if (operation.shortcutActivators.isEmpty) ...[
              const SizedBox(width: 8),
              RotatingShortcuts(
                shortcuts: operation.shortcutActivators,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showErrorsPopup(
  BuildContext context,
  List<(Selectable, Object)> errors,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        titlePadding:
            const EdgeInsets.only(left: 24, top: 16, right: 8, bottom: 0),
        title: Row(
          children: [
            const Expanded(
              child: Text("Delete errors"),
            ),
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
                  "Failed to delete ${errors.length} item(s). Others were deleted successfully.",
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          err.toString(),
                          style: TextStyle(
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
