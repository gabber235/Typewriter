import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The frame every membership page shares: a heading over the page's tab.
/// The tab here is a plain list, so the story shows the frame alone.
@widgetbook.UseCase(name: "Default", type: MembershipPage)
Widget membershipPageUseCase(BuildContext context) {
  final longText = context.knobs.boolean(label: "Long heading");
  final rows = context.knobs.rowCount();
  return Story(
    context.knobs.windows(),
    at: PanelLocation.component(
      MembershipPage(
        id: "story",
        title: longText
            ? "Members of the Very Long Named Interactive Storytelling Guild"
            : "Members",
        subtext: longText
            ? "Manage everyone who can access this organization. Review each "
                  "member's assigned role and update permissions as your team "
                  "and responsibilities change, from the founders who started "
                  "it to the guests who just arrived."
            : "Manage everyone who can access this organization.",
        tab: rows == 0
            ? const SliverFillRemaining(
                child: EmptyState(
                  icon: MaterialSymbols.groups_2_rounded,
                  title: "No members yet",
                  description: "Invite someone to get started!",
                ),
              )
            : SliverList.builder(
                itemCount: rows,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.spacing.space2,
                  ),
                  child: Text("Row ${index + 1}"),
                ),
              ),
      ),
    ),
  );
}
