import "package:typewriter_panel/typewriter_panel.dart";

part "global_operation_shortcuts.g.dart";

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
    return ManagedActionSet(
      shortcuts: ref.watch(selectionClearingShortcutsProvider),
      child: SelectionOperationShortcuts(
        enabled: ref.watch(selectionShortcutsEnabledProvider),
        child: child,
      ),
    );
  }
}

/// Whether selection shortcuts apply: only in [NormalMode] while interaction
/// is not suspended.
@riverpod
bool selectionShortcutsEnabled(Ref ref) =>
    !ref.watch(interactionSuspendedProvider) &&
    ref.watch(currentInteractionModeProvider) is NormalMode;

/// The shortcut that clears the selection while selection shortcuts apply.
///
/// [GlobalOperationShortcuts] offers it, and the app offers it in dialogs
/// through [dialogShortcutsProvider].
@riverpod
List<ActionShortcut> selectionClearingShortcuts(Ref ref) => [
  if (ref.watch(selectionShortcutsEnabledProvider)) _unselectSelection,
];

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
