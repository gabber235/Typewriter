import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// A mode whose R key counts how often it ran.
class CountingMode extends InteractionMode with ModeShortcut {
  int runs = 0;

  @override
  String get name => "Counting";

  @override
  List<ActionShortcut> getShortcuts() => [
    ActionShortcut(
      id: "count",
      label: "Count",
      description: "Counts each press",
      activators: [SingleActivator(LogicalKeyboardKey.keyR)],
      priority: 0,
      onInvoke: (_) => runs++,
    ),
  ];
}

/// A mode that shows its own display in the mode widget.
class DisplayTestMode extends InteractionMode with ModeDisplay {
  @override
  String get name => "TestWithDisplay";

  @override
  Widget buildDisplay(BuildContext context) {
    return const Text("Test Display");
  }
}

/// A mode that offers no display, so the mode widget shows nothing.
class PlainTestMode extends InteractionMode {
  @override
  String get name => "TestWithoutDisplay";
}

/// A mode that shows "Editing" and ends on Escape.
class EditingTestMode extends InteractionMode with ModeDisplay, ModeShortcut {
  @override
  String get name => "Edit";

  @override
  Widget buildDisplay(BuildContext context) => const Text("Editing");

  @override
  List<ActionShortcut> getShortcuts() => [escapeToNormalAction()];
}

/// A focusable item on the page, reachable as "Target".
class FocusableTarget extends StatelessWidget {
  const FocusableTarget({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: "Target",
    child: Focus(
      child: Builder(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Focus.of(context).requestFocus(),
          child: const SizedBox(width: 120, height: 40),
        ),
      ),
    ),
  );
}

/// Interaction modes as the panel switches them.
extension EnterMode on PanelDriver {
  /// Switches the panel to [mode], the way its shortcut does, and lets the
  /// panel react.
  Future<void> enterMode(InteractionMode mode) async {
    container.read(currentInteractionModeProvider.notifier).setMode(mode);
    await settle();
  }
}
