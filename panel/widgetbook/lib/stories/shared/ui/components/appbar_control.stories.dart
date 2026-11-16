import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// [AppBarControl]s in an app bar strip: a quiet search with its shortcut
/// and a filled publish, each in the slot an app bar gives it. Compact makes
/// each slot square, so only the icons remain; focus stays on the control
/// across the change.
@widgetbook.UseCase(name: "Default", type: AppBarControl)
Widget appBarControlUseCase(BuildContext context) {
  final compact = context.knobs.boolean(label: "Compact");
  final busy = context.knobs.boolean(label: "Busy");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SizedBox(
              width: compact ? 40 : 220,
              child: AppBarControl(
                tooltip: "Search",
                semanticLabel: "Search",
                onPressed: () {},
                contentBuilder: (context, compact) => AppBarControlContent(
                  icon: const Icon(Icons.search),
                  label: "Search",
                  shortcut: const ShortcutDisplay(
                    shortcut: SingleActivator(
                      LogicalKeyboardKey.keyK,
                      control: true,
                    ),
                  ),
                  compact: compact,
                ),
              ),
            ),
            SizedBox(
              width: compact ? 40 : 160,
              child: AppBarControl(
                tooltip: "Publish",
                semanticLabel: "Publish",
                face: ButtonFace.filled,
                onPressed: () {},
                contentBuilder: (context, compact) => AppBarControlContent(
                  icon: const Icon(Icons.publish),
                  label: busy ? "Publishing" : "Publish",
                  rippling: busy,
                  compact: compact,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// [AppBarControlContent] alone: its icon, label and shortcut, or only the
/// icon when Compact. Busy ripples the label as a running status.
@widgetbook.UseCase(name: "Default", type: AppBarControlContent)
Widget appBarControlContentUseCase(BuildContext context) {
  final compact = context.knobs.boolean(label: "Compact");
  final busy = context.knobs.boolean(label: "Busy");
  return Story(
    const [],
    at: PanelLocation.component(
      AppBarControlContent(
        icon: const Icon(Icons.sync),
        label: busy ? "Syncing" : "Synced",
        rippling: busy,
        shortcut: const ShortcutDisplay(
          shortcut: SingleActivator(LogicalKeyboardKey.keyS, control: true),
        ),
        compact: compact,
      ),
    ),
  );
}
