import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: ActionRow)
Widget actionRowUseCase(BuildContext context) {
  final actionCount = context.knobs.int.input(
    label: "Action count",
    initialValue: 6,
  );
  final asyncDelay = context.knobs.duration(
    label: "Async delay",
    initialValue: const Duration(milliseconds: 800),
  );
  final baseLabels = List<String>.generate(
    actionCount,
    (i) => switch (i % 6) {
      0 => "Save",
      1 => "Open",
      2 => "Duplicate",
      3 => "Export Selection",
      4 => "Toggle",
      _ => "Action $i",
    },
  );

  final shortcuts = <ActionShortcut>[];
  for (var i = 0; i < baseLabels.length; i++) {
    final label = baseLabels[i];
    final id = "action_$i";
    final priority =
        i; // Higher index = higher priority (appears further right)
    final isAsync = i.isOdd;
    final activators = switch (i % 4) {
      0 => [
          SingleActivator(LogicalKeyboardKey.keyS, meta: true),
          SingleActivator(LogicalKeyboardKey.keyS, control: true),
        ],
      1 => [SingleActivator(LogicalKeyboardKey.keyO, meta: true)],
      2 => [
          SingleActivator(LogicalKeyboardKey.keyD, meta: true),
          SingleActivator(LogicalKeyboardKey.keyD, control: true),
        ],
      _ => <ShortcutActivator>[],
    };

    shortcuts.add(
      ActionShortcut(
        id: id,
        label: label,
        description: "Runs $label",
        activators: activators,
        priority: priority,
        icon: Icon(
          switch (i % 5) {
            0 => Icons.save_outlined,
            1 => Icons.folder_open,
            2 => Icons.copy,
            3 => Icons.ios_share,
            _ => Icons.flash_on,
          },
        ),
        onInvoke: isAsync
            ? (ref) async {
                await Future.delayed(asyncDelay);
              }
            : (ref) {},
      ),
    );
  }

  return FakeApp(
    child: Builder(
      builder: (context) {
        return ActionSet(
          shortcuts: shortcuts,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${shortcuts.length} registered action(s)\nResize the preview to test overflow truncation.\nHighest priority items stay on the right.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const ActionRow()],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
