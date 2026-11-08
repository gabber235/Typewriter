import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Hold Delete or D on a member row, or Remove on a selection.
@widgetbook.UseCase(name: "Member rows", type: HoldRow)
Widget holdRowStory(BuildContext context) {
  return membershipStory(
    context,
    page: const MemberListRoute(),
    varied: MembershipList.members,
    traits: context.knobs.traits("Line layout", {
      for (final layout in HoldLineLayout.values)
        layout.name: [holdLine(layout)],
    }),
  );
}
