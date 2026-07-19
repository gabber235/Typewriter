import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_list.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_panel/shared/ui/components/section.dart";

@RoutePage()
class MemberListPage extends StatelessWidget {
  const MemberListPage({super.key});

  @override
  Widget build(BuildContext context) => Pane(
    id: "members",
    child: Section(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              title: "Members",
              subtext: "Manage organization access and roles.",
            ),
            const Padding(padding: EdgeInsets.all(24), child: MembersTab()),
          ],
        ),
      ),
    ),
  );
}
