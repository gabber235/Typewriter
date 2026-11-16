import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The members as a table: avatar, name and email, and their roles.
///
/// The table renders the rows [MembersTab] owns. Each row selects through
/// the shared selection, so the inspector shows the selected members and
/// changes their roles or removes them.
class MembersTable extends StatelessWidget {
  const MembersTable({required this.rows, super.key});

  final AnimatedRows<skir.OrganizationMember> rows;

  @override
  Widget build(BuildContext context) {
    return SelectionTable<skir.OrganizationMember>(
      rows: rows,
      selectableOf: (member) => MemberIdentifier(member.userId),
      labelOf: (member) => member.displayName,
      labels: const ["Member", "Roles"],
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(1),
      },
      emptyBuilder: (context) => const EmptyState(
        title: "No members yet",
        description: "Invite someone to get started!",
        icon: MaterialSymbols.groups_2_rounded,
      ),
      leadingBuilder: (context, member) => MemberAvatar(
        avatarUrl:
            member.avatarUrl?.nullIfEmpty ??
            "$userIconUrl&seed=${member.userId}",
        radius: 16,
      ),
      cellsBuilder: (context, member) => [
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
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space2,
            vertical: context.spacing.space3,
          ),
          child: Wrap(
            spacing: context.spacing.space1,
            runSpacing: context.spacing.space1,
            children: [
              for (final role in member.roles)
                SmallChip(
                  label: role.name,
                  color: role.displayColor,
                  onDelete: null,
                ),
            ],
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

/// What a member is called on screen.
extension MemberDisplayName on skir.OrganizationMember {
  String get displayName => name ?? email ?? "Member";
}
