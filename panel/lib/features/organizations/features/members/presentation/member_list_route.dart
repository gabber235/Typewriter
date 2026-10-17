import "package:typewriter_panel/typewriter_panel.dart";

/// Entry screen for the current organization's membership projection.
///
/// The page supplies the stable pane and heading. [MembersTab] owns the live
/// list, responsive presentation choice, transient selection, and recovery UI.
@RoutePage()
class MemberListPage extends StatelessWidget {
  const MemberListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "members",
      primary: true,
      child: Section(
        margin: EdgeInsets.zero,
        child: CustomScrollView(
          primary: true,
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeading(
                title: "Members",
                subtext: "Manage everyone who can access this organization. Review each member's assigned role and update permissions as your team and responsibilities change.",
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(context.spacing.space6),
              sliver: MembersTab(),
            ),
          ],
        ),
      ),
    );
  }
}
