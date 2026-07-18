import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/shared/ui/components/shortcut_display.dart";
import "package:typewriter_panel/shared/utilities/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Single", type: ShortcutDisplay)
Widget singleShortcutDisplayUseCase(BuildContext context) {
  final style = context.knobs.object.segmented(
    label: "Style",
    options: KeyStyle.values,
    initialOption: KeyStyle.solid,
    labelBuilder: (style) => style.name.formatted,
  );
  return FakeApp(
    child: Center(
      child: ShortcutDisplay(
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

@widgetbook.UseCase(name: "Rotating", type: ShortcutDisplay)
Widget rotatingShortcutsUseCase(BuildContext context) {
  final interval = context.knobs.duration(
    label: "Interval",
    initialValue: const Duration(seconds: 4),
  );
  final style = context.knobs.object.segmented(
    label: "Style",
    options: KeyStyle.values,
    initialOption: KeyStyle.solid,
    labelBuilder: (style) => style.name.formatted,
  );

  return FakeApp(
    child: Center(
      child: RotatingShortcuts(
        style: style,
        shortcuts: [
          SingleActivator(LogicalKeyboardKey.keyD),
          SingleActivator(LogicalKeyboardKey.delete, meta: true),
          SingleActivator(LogicalKeyboardKey.backspace, control: true),
          CharacterActivator(r"\", alt: true),
        ],
        interval: interval,
      ),
    ),
  );
}
