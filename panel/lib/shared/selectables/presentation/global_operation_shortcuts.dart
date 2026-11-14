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

/// The shortcut that clears the selection while selection shortcuts apply
/// and something is selected.
///
/// [GlobalOperationShortcuts] offers it, and the app offers it in dialogs
/// through [dialogShortcutsProvider]. With nothing selected it is not
/// offered, so Escape reaches what is around it, such as a dialog that
/// closes.
///
/// A [SelectionSurface] offers it too, closer to its items than the page
/// route, whose own disabled dismiss action would otherwise swallow Escape.
@riverpod
List<ActionShortcut> selectionClearingShortcuts(Ref ref) => [
  if (ref.watch(selectionShortcutsEnabledProvider) &&
      ref.watch(selectionProvider.select((selection) => selection.isNotEmpty)))
    _unselectSelection,
];

/// Clears the whole selection, which also ends select mode.
final _unselectSelection = ActionShortcut.intent(
  id: "normal_unselect_selection",
  label: "Clear Selection",
  description: "Clear the selection",
  intent: DismissIntent,
  priority: -11,
  show: false,
  run: ActionRun.press((ref) => ref.read(selectionProvider.notifier).clear()),
);
