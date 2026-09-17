import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Advertises unbinding for one selectable.
///
/// The callback owns the resource side effect. [UnbindOperation] invokes
/// callbacks serially and keeps failed items selected for retry.
class UnbindSelectionCapability extends SelectionCapability {
  UnbindSelectionCapability({required this.onUnbind});
  final FutureOr<void> Function() onUnbind;
}

/// Unbinds the selected items when every item supports unbinding.
///
/// Successful items are removed from canonical selection. Failed items remain
/// selected and are reported together after the batch completes.
class UnbindOperation extends ActivatorShortcutOperation {
  const UnbindOperation();

  @override
  String get name => "Unbind";

  @override
  String get description => "Unbind selected items";

  @override
  List<ShortcutActivator> get activators => [
    AdaptiveSingleActivator(LogicalKeyboardKey.backspace, control: true),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.allHaveCapability<UnbindSelectionCapability>();

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selection = ref.read(selectedProvider).requireValue;

    final context = ref.context;
    final backgroundColor = Colors.orange;
    final foregroundColor = backgroundColor.on(context);

    final confirmed = await showConfirmationDialogue(
      context: context,
      title: "Unbind ${selection.length} item(s)?",
      content: "This will disconnect the selected items.",
      confirmText: "Unbind",
      confirmColor: backgroundColor,
      onConfirmColor: foregroundColor,
    );
    if (!confirmed) return;

    final callbacks = <(Selectable, Future<void> Function())>[];
    for (final (s, op)
        in selection
            .collectCapabilitiesWithSelectables<UnbindSelectionCapability>()) {
      callbacks.add((s, () async => await op.onUnbind()));
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
    await showOperationErrorsPopup(ref.context, errors, "Unbind");
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icon(Icons.link_off),
      label: "Unbind",
      color: Colors.orange,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) =>
      UnbindOperationButton(selection: selection, operation: this);
}

/// Inspector control for [UnbindOperation], including confirmation and count.
class UnbindOperationButton extends HookConsumerWidget {
  const UnbindOperationButton({
    required this.selection,
    required this.operation,
    super.key,
  });

  final List<Selectable> selection;
  final UnbindOperation operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = Colors.orange;
    final foregroundColor = backgroundColor.on(context);
    return OperationButton.filledIcon(
      operation: operation,
      onPressed: () async {
        await operation.executeOn(ref);
      },
      style: FilledButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      ),
      icon: const Icon(Icons.link_off, size: 16),
      label: Text(
        selection.length > 1 ? "Unbind (${selection.length})" : "Unbind",
      ),
    );
  }
}
