import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The middle row squashing shut with [Leave], frozen at Progress: height,
/// scale and opacity go to zero together and the rows around it close the
/// gap.
@widgetbook.UseCase(name: "Default", type: Leave)
Widget leaveUseCase(BuildContext context) {
  final progress = context.knobs.fraction("Progress");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PanelRow(title: Text("Ada")),
            Leave(
              progress: progress,
              child: const PanelRow(title: Text("Grace is leaving")),
            ),
            const PanelRow(title: Text("Linus")),
          ],
        ),
      ),
    ),
  );
}
