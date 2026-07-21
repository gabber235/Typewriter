import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// A widget that makes sure that all the required global widgets are present.
/// It's a shortcut for wrapping the entire app with all the different widgets individually.
class AppRequiredWidgets extends HookWidget {
  const AppRequiredWidgets({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    useDisableContextMenu();
    return GlobalCursorController(
      child: GlobalPaneNavigator(
        child: GlobalActionsManager(
          child: GlobalModeShortcut(
            child: GlobalOperationShortcuts(child: Shimmer(child: child)),
          ),
        ),
      ),
    );
  }
}
