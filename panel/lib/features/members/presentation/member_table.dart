import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Desktop member projection with bulk selection and inline role editing.
///
/// The table does not own membership data. It renders the provider snapshot,
/// keeps selection and focus transient, and submits repository commands through
/// shared local work. Row identity is the user's record id, allowing animated
/// updates to follow members across live add, update, and remove events.
class MembersTable extends HookConsumerWidget {
  const MembersTable({required this.selection, super.key});

  final SelectableRows<skir.OrganizationMember> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final focusedMemberId = useState<skir.RecordId?>(null);
    final members = selection.rows.items;

    return SelectionTable<skir.OrganizationMember>(
      selection: selection,
      idOf: (member) => member.userId,
      labels: const ["Member", "Roles"],
      columnWidths: const {
        0: FixedColumnWidth(48),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(1),
        3: FixedColumnWidth(80),
      },
      emptyBuilder: (context) => EmptyState(
        title: "No members yet",
        description: "Invite someone to get started!",
        icon: MaterialSymbols.groups_2_rounded,
      ),
      rowBuilder: (context, entry) => _buildMemberRow(
        context,
        ref,
        entry.item,
        members,
        selection.selectedIds.value.contains(entry.id),
        focusedMemberId,
        theme,
      ),
    );
  }

  TableRow _buildMemberRow(
    BuildContext context,
    WidgetRef ref,
    skir.OrganizationMember member,
    List<skir.OrganizationMember> members,
    bool isSelected,
    ValueNotifier<skir.RecordId?> focusedMemberId,
    ThemeData theme,
  ) {
    void toggleSelection() {
      if (isSelected) {
        selection.selectedIds.value = selection.selectedIds.value
            .where((id) => id != member.userId)
            .toSet();
        return;
      }
      selection.selectedIds.value = {
        ...selection.selectedIds.value,
        member.userId,
      };
    }

    void updateFocus(bool focused) {
      if (focused) {
        focusedMemberId.value = member.userId;
      } else if (focusedMemberId.value == member.userId) {
        focusedMemberId.value = null;
      }
    }

    Widget withShortcuts(Widget child) => MemberTableRowShortcuts(
      member: member,
      onToggleSelection: toggleSelection,
      onSelectAll: () =>
          selection.selectedIds.value = members.map((m) => m.userId).toSet(),
      onClearSelection: () => selection.selectedIds.value = {},
      isSelected: isSelected,
      hasSelection: selection.selectedIds.value.isNotEmpty,
      onRemoveSelection: selection.onRemoveSelection,
      onRemoveFromSelection: () => selection.selectedIds.value = selection
          .selectedIds
          .value
          .where((id) => id != member.userId)
          .toSet(),
      onFocusChange: updateFocus,
      child: child,
    );

    return TableRow(
      key: ValueKey(member.userId),
      decoration: BoxDecoration(
        // Fill means selected; the ring layer shows focus.
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: withShortcuts(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space3,
              ),
              child: Material(
                color: Colors.transparent,
                shape: CircleBorder(),
                child: Button(
                  face: ButtonFace.bare,
                  label: isSelected
                      ? "Deselect ${member.name ?? member.email ?? "member"}"
                      : "Select ${member.name ?? member.email ?? "member"}",
                  onPressed: toggleSelection,
                  child: SelectableAvatar(
                    avatarUrl:
                        member.avatarUrl?.nullIfEmpty ??
                        "$userIconUrl&seed=${member.userId}",
                    isSelected: isSelected,
                    radius: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: withShortcuts(
            Material(
              color: Colors.transparent,
              borderRadius: context.shapes.mediumBorderRadius,
              child: Button(
                face: ButtonFace.bare,
                label: "",
                onPressed: toggleSelection,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.space2,
                    vertical: context.spacing.space3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (member.name != null)
                        Text(
                          member.name!,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (member.email != null)
                        BlurReveal(
                          blurSigma: 3,
                          child: Text(
                            member.email!,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
          ),
        ),
        TableCell(
          child: withShortcuts(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space2,
              ),
              child: RoleMultiselectDropdown(
                selectedRoles: member.roles.toList(),
                onRolesChanged: (newRoles) =>
                    ref.assignMemberRoles(context, member.userId, newRoles),
                placeholder: "Select roles",
              ),
            ),
          ),
        ),
        TableCell(child: withShortcuts(MemberRowActions(member: member))),
      ],
    );
  }
}

/// Gives one member a new set of roles, showing a failure where it happened.
extension MemberRoleAssignment on WidgetRef {
  void assignMemberRoles(
    BuildContext context,
    skir.RecordId memberId,
    List<skir.OrganizationRole> roles,
  ) {
    executeMembership(
      membershipCommands.updateRoles([memberId], roles),
      (response) => response.requireAccepted(),
    ).catchApiExceptionsAndDisplay(context);
  }
}
