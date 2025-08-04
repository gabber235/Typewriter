import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/disable_context_menu.dart";
import "package:typewriter_panel/widgets/generic/components/cursor_controller.dart";

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
      child: child,
    );
  }
}
