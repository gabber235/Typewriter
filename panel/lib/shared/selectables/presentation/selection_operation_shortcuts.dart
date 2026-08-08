import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SelectionOperationShortcuts extends ConsumerWidget {
  const SelectionOperationShortcuts({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProvider).value;
    final operations = availableSelectionOperations(
      SelectionOperationsRoot.of(context),
      selected,
    ).whereType<ShortcutableOperation>();

    return ManagedActionSet(
      shortcuts: [
        if (enabled)
          for (final operation in operations) operation.shortcut,
      ],
      child: child,
    );
  }
}
