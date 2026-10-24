import "package:typewriter_panel/typewriter_panel.dart";

/// Gates selection operations and selection clearing by the current
/// interaction context.
///
/// Both are enabled only in [NormalMode] and while interaction is not
/// suspended. This wrapper is separate from [GlobalModeShortcut] because
/// selection operations are a fixed capability rather than mode supplied
/// actions.
class GlobalOperationShortcuts extends ConsumerWidget {
  const GlobalOperationShortcuts({required this.child, super.key});

  /// Subtree whose selection operation shortcuts are gated.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        !ref.watch(interactionSuspendedProvider) &&
        ref.watch(currentInteractionModeProvider) is NormalMode;
    return ManagedActionSet(
      shortcuts: [if (enabled) _unselectSelection],
      child: SelectionOperationShortcuts(enabled: enabled, child: child),
    );
  }
}

/// Clears the selection, or narrows a multi selection to the focused item.
final _unselectSelection = ActionShortcut.intent(
  id: "normal_unselect_selection",
  label: "Unselect Selection",
  description: "Unselect the currently selected item",
  intent: DismissIntent,
  priority: -11,
  show: false,
  onInvoke: (ref) {
    final focused = SelectableScope.primaryFocusedId();
    if (focused == null) {
      ref.read(selectionProvider.notifier).clear();
      return;
    }

    final selection = ref.read(selectionProvider);
    if (selection.isEmpty) return;
    if (selection.length == 1) {
      ref.read(selectionProvider.notifier).clear();
      return;
    }
    ref.read(selectionProvider.notifier).select(focused, isMultiSelect: false);
  },
);
