import "package:typewriter_panel/typewriter_panel.dart";

/// Registers shortcuts for operations available to the current selection.
///
/// Generic operations come from the nearest [SelectionOperationsRoot]; authoring
/// resources use their Realm operation affordances. [selectedProvider] supplies
/// the resolved batch, including retained data during provider refresh.
class SelectionOperationShortcuts extends ConsumerWidget {
  const SelectionOperationShortcuts({
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// Content that receives the managed action set.
  final Widget child;

  /// Whether operation shortcuts should be registered for this subtree.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProvider).value;
    final operations = selectionOperationsFor(
      ref,
      context,
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
