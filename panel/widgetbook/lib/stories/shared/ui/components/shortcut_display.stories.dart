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

/// Single keys as [LogicalKeyBoardDisplay] shows them: modifiers and named
/// keys as their familiar symbol, letters upper case.
@widgetbook.UseCase(name: "Keys", type: LogicalKeyBoardDisplay)
Widget logicalKeyBoardDisplayUseCase(BuildContext context) {
  final outline = context.knobs.boolean(label: "Outline");
  final size = context.knobs.double.slider(
    label: "Size",
    initialValue: 12,
    min: 10,
    max: 24,
  );
  final style = outline ? const KeyStyle.outline() : const KeyStyle.solid();
  return Story(
    const [],
    at: PanelLocation.component(
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final key in [
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.enter,
            LogicalKeyboardKey.escape,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.backspace,
            LogicalKeyboardKey.keyK,
            LogicalKeyboardKey.slash,
          ])
            LogicalKeyBoardDisplay(keyBoardKey: key, style: style, size: size),
        ],
      ),
    ),
  );
}

/// A hint teaching every binding of one move: [RotatingShortcuts] shows the
/// arrow, the letter and the Tab binding in turn.
@widgetbook.UseCase(name: "Rotating", type: RotatingShortcuts)
Widget rotatingShortcutsUseCase(BuildContext context) {
  final count = context.knobs.object.segmented(
    label: "Shortcuts",
    options: const [0, 1, 3],
    initialOption: 3,
  );
  const shortcuts = [
    SingleActivator(LogicalKeyboardKey.arrowDown),
    SingleActivator(LogicalKeyboardKey.keyJ),
    SingleActivator(LogicalKeyboardKey.tab),
  ];
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          const Text("Next row"),
          RotatingShortcuts(shortcuts: shortcuts.take(count).toList()),
        ],
      ),
    ),
  );
}
