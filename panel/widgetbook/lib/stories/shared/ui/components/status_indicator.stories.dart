import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The online and offline [StatusIndicator] of the realm selector and the
/// suspension veil: online, offline since a time, offline never seen.
@widgetbook.UseCase(name: "Default", type: StatusIndicator)
Widget statusIndicatorUseCase(BuildContext context) {
  final large = context.knobs.boolean(label: "Large");
  final now = DateTime.now();
  return Story(
    const [],
    at: PanelLocation.component(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          for (final (online, lastSeen) in [
            (true, null),
            (false, now.subtract(const Duration(minutes: 42))),
            (false, null),
          ])
            StatusIndicator(
              isOnline: online,
              lastSeen: lastSeen,
              dotSize: large ? 12 : 8,
              fontSize: large ? 14 : 11,
            ),
        ],
      ),
    ),
  );
}
