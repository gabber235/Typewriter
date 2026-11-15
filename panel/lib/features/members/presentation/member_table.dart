import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The members as a table: avatar, name and email, inline roles, and a
/// remove button on each row.
///
/// The table renders the rows [MembersTab] owns. Each row selects through
/// the shared selection, so the inspector shows the selected members.
class MembersTable extends HookConsumerWidget {
  const MembersTable({required this.rows, super.key});

  final AnimatedRows<skir.OrganizationMember> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SelectionTable<skir.OrganizationMember>(
      rows: rows,
      selectableOf: (member) => MemberIdentifier(member.userId),
      labelOf: (member) => member.displayName,
      labels: const ["Member", "Roles"],
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(1),
        3: FixedColumnWidth(80),
      },
      emptyBuilder: (context) => const EmptyState(
        title: "No members yet",
        description: "Invite someone to get started!",
        icon: MaterialSymbols.groups_2_rounded,
      ),
      shortcutsOf: (member) => [memberRowRemoval(member, rows)],
      leadingBuilder: (context, member) => MemberAvatar(
        avatarUrl:
            member.avatarUrl?.nullIfEmpty ??
            "$userIconUrl&seed=${member.userId}",
        radius: 16,
      ),
      cellsBuilder: (context, member) => [
        SelectionTableCell(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space3,
            ),
            // Read the theme here, inside the row, so a sending row's struck
            // text theme reaches the name and email.
            child: Builder(
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (member.name case final name?)
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (member.email case final email?)
                    BlurReveal(
                      blurSigma: 3,
                      child: Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SelectionTableCell.controls(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space2,
            ),
            child: RoleMultiselectDropdown(
              selectedRoles: member.roles.toList(),
              onRolesChanged: (roles) =>
                  ref.assignMemberRoles(context, member.userId, roles),
              placeholder: "Select roles",
            ),
          ),
        ),
        SelectionTableCell.controls(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
            child: CommandButton(
              face: ButtonFace.icon,
              color: context.colors.danger,
              icon: const Icon(Icons.person_remove_outlined, size: 20),
              label: "Remove member",
              command: memberRowRemoval(member, rows),
            ),
          ),
        ),
      ],
    );
  }
}

/// The members as cards for touch layouts: avatar, name and email. A tap
/// selects the member, and the inspector shows their roles and Remove.
class MembersCardList extends StatelessWidget {
  const MembersCardList({required this.rows, super.key});

  final AnimatedRows<skir.OrganizationMember> rows;

  @override
  Widget build(BuildContext context) {
    return SelectionCardList<skir.OrganizationMember>(
      rows: rows,
      selectableOf: (member) => MemberIdentifier(member.userId),
      labelOf: (member) => member.displayName,
      emptyBuilder: (context) => const EmptyState(
        icon: MaterialSymbols.groups_2_rounded,
        title: "No members yet",
        description: "Invite someone to get started!",
      ),
      shortcutsOf: (member) => [memberRowRemoval(member, rows)],
      contentBuilder: (context, member) => Row(
        spacing: context.spacing.space3,
        children: [
          MemberAvatar(
            avatarUrl:
                member.avatarUrl?.nullIfEmpty ??
                "$userIconUrl&seed=${member.userId}",
            radius: 20,
          ),
          Expanded(
            child: PersonSummary(name: member.name, email: member.email),
          ),
        ],
      ),
    );
  }
}

/// The Remove member command of [member]'s row: its key and its button. It
/// removes the selection when the selection holds the member, otherwise the
/// member alone.
ActionShortcut memberRowRemoval(
  skir.OrganizationMember member,
  AnimatedRows<skir.OrganizationMember> rows,
) {
  return memberRemoval(
    id: "remove_member_${member.userId}",
    label: "Remove member",
    targets: (ref) => {
      for (final id
          in ref
              .selectionOrRow(MemberIdentifier(member.userId))
              .whereType<MemberIdentifier>())
        id.userId,
    },
    nameOf: (_, id) => rows[id]?.item.displayName,
    rows: rows,
  );
}

/// What a member is called on screen.
extension MemberDisplayName on skir.OrganizationMember {
  String get displayName => name ?? email ?? "Member";
}

/// Gives one member a new set of roles, showing a failure where it happened.
extension MemberRoleAssignment on WidgetRef {
  void assignMemberRoles(
    BuildContext context,
    skir.RecordId memberId,
    List<skir.OrganizationRole> roles,
  ) {
    executeMembership(
      membershipCommands.updateRoles({memberId: roles}),
      (response) => response.requireAccepted(),
    ).catchApiExceptionsAndDisplay(context);
  }
}
