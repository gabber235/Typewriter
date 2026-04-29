import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/context_menu.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";

/// A selectable-level operation holding the asynchronous unbind callback.
class UnbindSelectableOperation extends SelectableOperation {
  UnbindSelectableOperation({required this.onUnbind});
  final FutureOr<void> Function() onUnbind;
}

/// The unbind operation exposed when every selected item provides an
/// [UnbindSelectableOperation].
class UnbindOperation extends ActivatorShortcutOperation {
  const UnbindOperation();

  @override
  String get name => "Unbind";

  @override
  String get description => "Unbind selected items";

  @override
  List<ShortcutActivator> get activators => [
    SingleActivator(
      LogicalKeyboardKey.backspace,
      meta: defaultTargetPlatform == TargetPlatform.macOS,
      control: defaultTargetPlatform != TargetPlatform.macOS,
    ),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.allHaveOperation<UnbindSelectableOperation>();

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selection = ref.read(selectedProvider).requireValue;
    final callbacks = <(Selectable, Future<void> Function())>[];
    for (final (s, op)
        in selection
            .collectOperationsWithSelectables<UnbindSelectableOperation>()) {
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
      color: Colors.deepOrange,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) =>
      UnbindOperationButton(selection: selection, operation: this);
}

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
    final color = Colors.orange;
    final onColor = color.on(context);
    return LoadingButton.filledIcon(
      onPressed: () {
        showConfirmationDialogue(
          context: context,
          title: "Unbind ${selection.length} item(s)?",
          content: "This will disconnect the selected items.",
          confirmText: "Unbind",
          confirmColor: color,
          onConfirmColor: onColor,
          onConfirm: () async {
            await operation.executeOn(ref);
          },
        );
      },
      style: FilledButton.styleFrom(
        foregroundColor: onColor,
        backgroundColor: color,
      ),
      icon: const Icon(Icons.link_off, size: 16),
      label: Text(
        selection.length > 1 ? "Unbind (${selection.length})" : "Unbind",
      ),
    );
  }
}
