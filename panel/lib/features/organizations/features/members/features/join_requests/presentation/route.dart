import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class JoinRequestsPage extends StatelessWidget {
  const JoinRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "join-requests",
      primary: true,
      child: Section(
        margin: EdgeInsets.zero,
        child: CustomScrollView(
          primary: true,
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeading(
                title: "Join Requests",
                subtext:
                    "Review people waiting to join this organization. Approve each request with the right role, or decline requests that should not receive access.",
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(context.spacing.space6),
              sliver: JoinRequestsTab(),
            ),
          ],
        ),
      ),
    );
  }
}
