import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/presentation/global_mode_shortcut.dart";
import "package:typewriter_panel/shared/hooks/disable_context_menu.dart";
import "package:typewriter_panel/shared/ui/components/cursor_controller.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";

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
