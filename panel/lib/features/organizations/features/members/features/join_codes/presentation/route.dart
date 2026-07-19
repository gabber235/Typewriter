import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/route_content.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_panel/shared/ui/components/section.dart";

@RoutePage()
class JoinCodesPage extends StatelessWidget {
  const JoinCodesPage({super.key});

  @override
  Widget build(BuildContext context) => Pane(
    id: "join-codes",
    child: Section(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              title: "Join Codes",
              subtext: "Create, share, and revoke organization join codes.",
            ),
            const Padding(padding: EdgeInsets.all(24), child: JoinCodesTab()),
          ],
        ),
      ),
    ),
  );
}
