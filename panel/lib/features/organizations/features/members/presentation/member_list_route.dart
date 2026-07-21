import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
                subtext:
                    "Manage everyone who can access this organization. Review each member's assigned role and update permissions as your team and responsibilities change.",
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.all(24),
              sliver: MembersTab(),
            ),
          ],
        ),
      ),
    );
  }
}
