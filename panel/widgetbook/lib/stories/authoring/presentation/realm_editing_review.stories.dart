import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/retained_rename.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Retained rename", type: RealmEditingReview)
Widget realmEditingReviewUseCase(BuildContext context) {
  return Story(
    [
      ...retainedRenameWorld(const []),
      ...context.knobs.traits("Saved values", {
        "Readable": const [],
        "Unreadable": const [savedDocumentUnreadable],
      }),
    ],
    at: PanelLocation.component(
      SizedBox(
        width: context.knobs.double.slider(
          label: "Width",
          initialValue: 720,
          min: 360,
          max: 960,
        ),
        child: RetainedRename(
          builder: (context, workspace, group) => SingleChildScrollView(
            padding: EdgeInsets.all(context.spacing.space3),
            child: RealmEditingReview(workspace: workspace, id: group),
          ),
        ),
      ),
    ),
  );
}
