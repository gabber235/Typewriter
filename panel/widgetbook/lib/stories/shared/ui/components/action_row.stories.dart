import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

ActionShortcut _action(
  String label,
  IconData icon,
  int priority, {
  List<ShortcutActivator> activators = const [],
  bool slow = false,
}) => ActionShortcut(
  id: label.snakeCase(),
  label: label,
  description: label,
  activators: activators,
  priority: priority,
  icon: Icon(icon),
  run: ActionRun.press(
    slow
        ? (ref) => Future<void>.delayed(const Duration(milliseconds: 800))
        : (ref) {},
  ),
);

/// The [ActionRow] of a selected resource: its actions with their shortcuts,
/// highest priority on the right; in a narrow window the lowest priority
/// actions are dropped first.
@widgetbook.UseCase(name: "Default", type: ActionRow)
Widget actionRowUseCase(BuildContext context) {
  final shortcuts = [
    _action(
      "Save",
      Icons.save_outlined,
      3,
      activators: const [SingleActivator(LogicalKeyboardKey.keyS, meta: true)],
      slow: true,
    ),
    _action(
      "Duplicate",
      Icons.copy,
      2,
      activators: const [SingleActivator(LogicalKeyboardKey.keyD, meta: true)],
    ),
    _action("Export selection", Icons.ios_share, 1, slow: true),
    _action(
      "Delete",
      Icons.delete_outline,
      0,
      activators: const [SingleActivator(LogicalKeyboardKey.delete)],
    ),
  ];
  return Story(
    context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
      "Phone": [window(const Size(360, 720))],
    }),
    at: PanelLocation.component(
      ActionSet(
        shortcuts: shortcuts,
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: ActionRow(),
        ),
      ),
    ),
  );
}
