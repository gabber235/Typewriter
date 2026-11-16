import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// One menu choice with its icon, shortcut, availability and the highlight a
/// filtering field draws while it keeps focus.
@widgetbook.UseCase(name: "Default", type: PanelMenuItem)
Widget panelMenuItemUseCase(BuildContext context) {
  final leading = context.knobs.boolean(label: "Icon", initialValue: true);
  final trailing = context.knobs.boolean(label: "Shortcut", initialValue: true);
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final highlighted = context.knobs.boolean(
    label: "Highlighted",
    initialValue: false,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 240,
        child: PanelMenuItem(
          label: "Duplicate",
          leading: leading ? const Icon(Icons.copy) : null,
          trailing: trailing
              ? const ShortcutDisplay(
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyD,
                    meta: true,
                  ),
                )
              : null,
          enabled: enabled,
          highlighted: highlighted,
          onPressed: () {},
        ),
      ),
    ),
  );
}
