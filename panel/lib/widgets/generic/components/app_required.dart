import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/disable_context_menu.dart";
import "package:typewriter_panel/utils/shortuct.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/cursor_controller.dart";
import "package:typewriter_panel/widgets/generic/components/panes.dart";

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
          child: GlobalOperationShortcuts(
            child: ActionSet(
              shortcuts: [
                ActionShortcut(
                  id: "global_nav_focus",
                  label: "Switch Focus",
                  description: "Move between focusable elements in the UI",
                  activators: [
                    SortedLogicalKeyActivator.fromList([
                      LogicalKeyboardKey.arrowLeft,
                      LogicalKeyboardKey.arrowDown,
                      LogicalKeyboardKey.arrowUp,
                      LogicalKeyboardKey.arrowRight,
                    ]),
                    SortedLogicalKeyActivator.fromList([
                      LogicalKeyboardKey.keyH,
                      LogicalKeyboardKey.keyJ,
                      LogicalKeyboardKey.keyK,
                      LogicalKeyboardKey.keyL,
                    ]),
                    SingleActivator(LogicalKeyboardKey.tab),
                    SingleActivator(LogicalKeyboardKey.tab, shift: true),
                  ],
                  priority: -1,
                ),
              ],
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
