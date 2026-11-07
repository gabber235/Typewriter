import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Single", type: ShortcutDisplay)
Widget singleShortcutDisplayUseCase(BuildContext context) {
  final variant = context.knobs.object.segmented(
    label: "Style",
    options: const [KeyStyle.solid(), KeyStyle.outline()],
    initialOption: const KeyStyle.solid(),
    labelBuilder: (style) => switch (style) {
      SolidKeyStyle() => "Solid",
      OutlineKeyStyle() => "Outline",
    },
  );
  final useCustomColors = context.knobs.boolean(
    label: "Custom Colors",
    initialValue: false,
  );
  final foregroundColor = useCustomColors
      ? context.knobs.color(
          label: "Foreground Color",
          initialValue: Colors.white,
        )
      : null;
  final style = switch (variant) {
    SolidKeyStyle() => KeyStyle.solid(
      backgroundColor: useCustomColors
          ? context.knobs.color(
              label: "Background Color",
              initialValue: Colors.blue,
            )
          : null,
      foregroundColor: foregroundColor,
      shadowColor: useCustomColors
          ? context.knobs.color(
              label: "Shadow Color",
              initialValue: Colors.blueGrey,
            )
          : null,
    ),
    OutlineKeyStyle() => KeyStyle.outline(
      foregroundColor: foregroundColor,
      borderColor: useCustomColors
          ? context.knobs.color(
              label: "Border Color",
              initialValue: Colors.blue,
            )
          : null,
    ),
  };
  return Story(
    const [],
    at: PanelLocation.component(
      ShortcutDisplay(
        style: style,
        shortcut: SingleActivator(
          LogicalKeyboardKey.keyD,
          meta: true,
          control: true,
          shift: true,
          alt: true,
        ),
      ),
    ),
  );
}
