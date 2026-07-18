import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/selectable.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";
import "package:typewriter_panel/shared/ui/components/context_menu.dart";

/// A selectable-level operation holding the asynchronous open callback.
class OpenSelectableOperation extends SelectableOperation {
  OpenSelectableOperation({required this.onOpen, this.allowMultiSelect = true});

  final FutureOr<void> Function() onOpen;

  /// When false, the Open operation will not appear if this item
  /// is part of a multi-select with other items.
  final bool allowMultiSelect;
}

/// The open operation exposed when every selected item provides an
/// [OpenSelectableOperation].
class OpenOperation extends ActivatorShortcutOperation {
  const OpenOperation();

  @override
  String get name => "Open";

  @override
  String get description => "Open selected items";

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.enter),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allHaveOperation<OpenSelectableOperation>()) return false;

    // Single selection: always allowed
    if (selection.length == 1) return true;

    // Multi-select: ensure none have allowMultiSelect disabled
    return selection.collectOperations<OpenSelectableOperation>().none(
      (op) => !op.allowMultiSelect,
    );
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selection = ref.read(selectedProvider).requireValue;
    for (final (_, op)
        in selection
            .collectOperationsWithSelectables<OpenSelectableOperation>()) {
      await op.onOpen();
      if (!ref.context.mounted) return;
    }
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icon(Icons.open_in_new),
      label: "Open",
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) =>
      OpenOperationButton(selection: selection, operation: this);
}

class OpenOperationButton extends HookConsumerWidget {
  const OpenOperationButton({
    required this.selection,
    required this.operation,
    super.key,
  });

  final List<Selectable> selection;
  final OpenOperation operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => operation.executeOn(ref),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(selection.length > 1 ? "Open (${selection.length})" : "Open"),
    );
  }
}
