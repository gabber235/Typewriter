import "package:typewriter_panel/typewriter_panel.dart";

/// Gates selection operations by the current interaction context.
///
/// Operations are enabled only in [NormalMode] and while realm interaction is
/// not suspended. This wrapper is separate from [GlobalModeShortcut] because
/// selection operations are a fixed capability rather than mode supplied
/// actions.
class GlobalOperationShortcuts extends ConsumerWidget {
  const GlobalOperationShortcuts({required this.child, super.key});

  /// Subtree whose selection operation shortcuts are gated.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(realmInteractionProvider).suspended) {
      return SelectionOperationShortcuts(enabled: false, child: child);
    }

    final currentMode = ref.watch(currentInteractionModeProvider);
    return SelectionOperationShortcuts(
      enabled: currentMode is NormalMode,
      child: child,
    );
  }
}
