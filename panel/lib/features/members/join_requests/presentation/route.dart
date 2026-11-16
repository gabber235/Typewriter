import "package:typewriter_panel/typewriter_panel.dart";

/// Organization scoped route for moderating pending membership requests.
///
/// The route supplies the page shell and stable scrolling surface. [JoinRequestsTab]
/// owns provider state handling and chooses loading, error, empty, or populated
/// content.
@RoutePage()
class JoinRequestsPage extends StatelessWidget {
  const JoinRequestsPage({super.key});

  @override
  Widget build(BuildContext context) => const MembershipPage(
    id: "join-requests",
    title: "Join Requests",
    subtext: "Review people waiting to join this organization. Approve each request with the right role, or decline requests that should not receive access.",
    tab: JoinRequestsTab(),
  );
}
