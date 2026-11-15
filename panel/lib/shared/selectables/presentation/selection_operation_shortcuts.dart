import "package:typewriter_panel/typewriter_panel.dart";

/// Registers shortcuts for operations available to the items a key acts on:
/// the focused item or the selection ([operationTargetsProvider]).
///
/// Operations come from the source of the nearest [SelectionOperationsRoot].
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
    final targets = ref.watch(operationTargetsProvider).value;
    final operations = targets == null || targets.isEmpty
        ? const <ShortcutableOperation>[]
        : SelectionOperationsRoot.of(context)
              .operationsFor(ref, targets)
              .whereType<ShortcutableOperation>();

    return ManagedActionSet(
      shortcuts: [
        if (enabled)
          for (final operation in operations) operation.shortcut,
      ],
      child: child,
    );
  }
}
