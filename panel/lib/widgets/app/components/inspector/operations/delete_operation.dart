import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";

/// A selectable-level operation holding the asynchronous delete callback.
class DeleteSelectableOperation extends SelectableOperation {
  DeleteSelectableOperation({required this.onDelete});
  final FutureOr<void> Function() onDelete;
}

/// The delete operation exposed when every selected item provides a
/// [DeleteSelectableOperation].
class DeleteOperation extends Operation {
  DeleteOperation();

  @override
  String get name => "Delete";

  @override
  List<ShortcutActivator> get shortcutActivators => [
        SingleActivator(LogicalKeyboardKey.keyD),
        SingleActivator(LogicalKeyboardKey.delete),
        SingleActivator(LogicalKeyboardKey.backspace),
      ];

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.allHaveOperation<DeleteSelectableOperation>();

  @override
  FutureOr<void> executeOn(
    BuildContext context,
    List<Selectable> selection,
  ) async {
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

    if (errors.isEmpty) return;
    if (!context.mounted) return;
    await _showErrorsPopup(context, errors);
  }

  @override
  Widget inspectorButton(List<Selectable> selection) =>
      DeleteOperationButton(selection: selection, operation: this);
}

class DeleteOperationButton extends HookWidget {
  const DeleteOperationButton({
    required this.selection,
    required this.operation,
    super.key,
  });

  final List<Selectable> selection;
  final DeleteOperation operation;

  @override
  Widget build(BuildContext context) {
    final isDeleting = useState(false);

    Future<void> runDeletes() async {
      if (isDeleting.value) return;
      isDeleting.value = true;

      await operation.executeOn(context, selection);

      if (!context.mounted) return;
      isDeleting.value = false;
    }

    void confirmAndDelete() => showConfirmationDialogue(
          context: context,
          title: "Delete ${selection.length} item(s)?",
          content: "This action cannot be undone.",
          confirmText: "Delete",
          confirmColor: Theme.of(context).colorScheme.error,
          onConfirm: runDeletes,
        );

    final buttonStyle = FilledButtonTheme.of(context).style;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: isDeleting.value ? null : confirmAndDelete,
        style: FilledButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onError,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: isDeleting.value
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    buttonStyle?.foregroundColor
                        ?.resolve({WidgetState.disabled}),
                  ),
                ),
              )
            : Icon(
                Icons.delete_outline,
                size: 16,
              ),
        label: Text(
          isDeleting.value
              ? "Deleting..."
              : selection.length > 1
                  ? "Delete (${selection.length})"
                  : "Delete",
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
