import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/disable_context_menu.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/global_mode_shortcut.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/cursor_controller.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";

/// A widget that makes sure that all the required global widgets are present.
/// It's a shortcut for wrapping the entire app with all the different widgets individually.
class AppRequiredWidgets extends HookWidget {
  const AppRequiredWidgets({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    useDisableContextMenu();
    return GlobalCursorController(
      child: GlobalPaneNavigator(
        child: GlobalActionsManager(
          child: GlobalModeShortcut(
            child: GlobalOperationShortcuts(
              child: Shimmer(
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
