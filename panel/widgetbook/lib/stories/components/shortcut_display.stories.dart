import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/widgets/generic/components/shortcut_display.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Single", type: ShortcutDisplay)
Widget singleShortcutDisplayUseCase(BuildContext context) {
  return FakeApp(
    child: Center(
      child: ShortcutDisplay(
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

  return FakeApp(
    child: Center(
      child: RotatingShortcuts(
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
