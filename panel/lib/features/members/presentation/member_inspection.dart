import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// What the inspector shows for the selected [members]: one member's
/// details, then the roles every one of them holds.
///
/// Each role is a choice checked when every member holds it and striped
/// with "1 of 2" when some do. A press gives every member their next roles
/// in one change, all or none; protected roles show but cannot change.
class MemberInspection extends ConsumerWidget {
  const MemberInspection({required this.members, super.key});

  final List<skir.OrganizationMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final single = members.length == 1 ? members.single : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space3,
      children: [
        if (single != null)
          Row(
            spacing: context.spacing.space3,
            children: [
              MemberAvatar(
                avatarUrl:
                    single.avatarUrl?.nullIfEmpty ??
                    "$userIconUrl&seed=${single.userId}",
                radius: 24,
              ),
              Expanded(
                child: PersonSummary(name: single.name, email: single.email),
              ),
            ],
          ),
        const SectionTitle(title: "Roles"),
        RoleChecks(
          held: [
            for (final member in members)
              {for (final role in member.roles) role.roleId},
          ],
          onChanged: (next, roles) =>
              ref.assignRoles(context, members, next, roles),
        ),
      ],
    );
  }
}

/// Giving several members their roles in one change.
extension MemberRolesAssignment on WidgetRef {
  /// Gives each of [members] the roles of [roles] whose ids are at its
  /// place in [next], in one change for every member whose roles change.
  /// A failure shows where the user acted.
  void assignRoles(
    BuildContext context,
    List<skir.OrganizationMember> members,
    List<Set<skir.RecordId>> next,
    List<skir.OrganizationRole> roles,
  ) {
    final assignments = <skir.RecordId, List<skir.OrganizationRole>>{
      for (final (index, member) in members.indexed)
        if (!setEquals(next[index], {
          for (final role in member.roles) role.roleId,
        }))
          member.userId: [
            for (final role in roles)
              if (next[index].contains(role.roleId)) role,
          ],
    };
    if (assignments.isEmpty) return;
    executeMembership(
      membershipCommands.updateRoles(assignments),
      (response) => response.requireAccepted(),
    ).catchApiExceptionsAndDisplay(context);
  }
}

/// One labelled detail of an inspection: a quiet label over its value.
class InspectionDetail extends StatelessWidget {
  const InspectionDetail({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space1,
      children: [
        SectionTitle(title: label),
        child,
      ],
    );
  }
}
