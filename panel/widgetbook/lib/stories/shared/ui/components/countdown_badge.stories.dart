import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [CountdownBadge] with time to spare, below its urgent threshold, and
/// expired, side by side.
@widgetbook.UseCase(name: "Default", type: CountdownBadge)
Widget countdownBadgeUseCase(BuildContext context) {
  final now = DateTime.now();
  return Story(
    const [],
    at: PanelLocation.component(
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          for (final left in const [
            Duration(hours: 3),
            Duration(seconds: 45),
            Duration(seconds: -5),
          ])
            CountdownBadge(
              endDate: now.add(left),
              urgentThreshold: const Duration(minutes: 1),
            ),
        ],
      ),
    ),
  );
}
