import "package:typewriter_panel/typewriter_panel.dart";

/// Hosts the members capability's nested routes.
///
/// The shell owns navigation only. [MemberListPage] owns the current member
/// administration screen, while sibling member capabilities remain free to add
/// their own routes without coupling this shell to their content.
@RoutePage()
class MembersPage extends StatelessWidget {
  const MembersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}
