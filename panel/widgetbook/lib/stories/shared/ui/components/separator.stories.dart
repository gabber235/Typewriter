import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [Separator] splitting everyday actions from the one that loses work.
@widgetbook.UseCase(name: "Between groups", type: Separator)
Widget separatorUseCase(BuildContext context) {
  return const Story(
    [],
    at: PanelLocation.component(
      SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Open"),
            Text("Duplicate"),
            Separator(),
            Text("Delete"),
          ],
        ),
      ),
    ),
  );
}
