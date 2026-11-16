import "package:flutter_test/flutter_test.dart";
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
      run: ActionRun.press((_) => runs++),
    ),
  ];
}

/// A mode that shows its own display in the mode widget.
class DisplayTestMode extends InteractionMode with ModeDisplay {
  @override
  String get name => "TestWithDisplay";

  @override
  ModeLook look(BuildContext context) => const ModeLook(
    label: "Test Display",
    tone: Colors.deepOrange,
    icon: Icons.open_with_rounded,
  );
}

/// A resting mode with a soft chip and no icon, as Normal shows.
class SoftDisplayTestMode extends InteractionMode with ModeDisplay {
  @override
  String get name => "TestSoft";

  @override
  ModeLook look(BuildContext context) =>
      const ModeLook(label: "Resting", tone: Colors.indigo, soft: true);
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
  ModeLook look(BuildContext context) =>
      const ModeLook(label: "Editing", tone: Colors.teal, icon: Icons.edit);

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

/// Reading the app bar mode chip.
extension ModeChipFill on WidgetTester {
  /// The fill the mode chip paints this frame.
  Color get modeChipFill {
    final box = widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ModeChip),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return (box.decoration as BoxDecoration).color!;
  }
}
