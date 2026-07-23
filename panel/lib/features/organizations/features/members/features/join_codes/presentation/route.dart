import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class JoinCodesPage extends StatelessWidget {
  const JoinCodesPage({super.key});

  @override
  Widget build(BuildContext context) => Pane(
    id: "join-codes",
    primary: true,
    child: Section(
      margin: EdgeInsets.zero,
      child: CustomScrollView(
        primary: true,
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeading(
              title: "Join Codes",
              subtext:
                  "Create invitation codes that grant access to this organization. Share codes with trusted collaborators, review their assigned roles, and revoke codes when no longer needed.",
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(context.spacing.space6),
            sliver: JoinCodesTab(),
          ),
        ],
      ),
    ),
  );
}
