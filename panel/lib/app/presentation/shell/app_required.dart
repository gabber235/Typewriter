import "package:typewriter_panel/typewriter_panel.dart";

/// Installs the interaction infrastructure required by the panel shell.
///
/// This wrapper owns no application state. It composes the shared selection,
/// cursor, pane navigation, action, shortcut, and loading effect layers around
/// [child]. Keep it above route content so those capabilities span route
/// changes and can coordinate across otherwise separate widgets.
class AppRequiredWidgets extends HookWidget {
  const AppRequiredWidgets({required this.child, super.key});

  /// Route content that receives the shell capabilities.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    useDisableContextMenu();
    return SelectionOperationsRoot(
      operations: const [...coreSelectionOperations],
      child: GlobalCursorController(
        child: GlobalPaneNavigator(
          child: GlobalActionsManager(
            child: GlobalModeShortcut(
              child: GlobalOperationShortcuts(child: Shimmer(child: child)),
            ),
          ),
        ),
      ),
    );
  }
}
