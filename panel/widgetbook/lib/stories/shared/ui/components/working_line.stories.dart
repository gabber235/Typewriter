import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [WorkingLine] along the bottom of a field that loads its first results.
@widgetbook.UseCase(name: "Along a field", type: WorkingLine)
Widget workingLineUseCase(BuildContext context) {
  return const Story(
    [],
    at: PanelLocation.component(
      SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Search the realm"),
            SizedBox(height: 8),
            WorkingLine(label: "Searching"),
          ],
        ),
      ),
    ),
  );
}
