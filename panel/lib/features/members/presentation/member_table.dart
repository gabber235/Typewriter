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

    final name = member.name ?? member.email ?? "Member";
    Widget withShortcuts(Widget child, {RowRole role = RowRole.part}) =>
        MemberTableRowShortcuts(
          member: member,
          onToggleSelection: toggleSelection,
          onSelectAll: () => selection.selectedIds.value = members
              .map((m) => m.userId)
              .toSet(),
          onClearSelection: () => selection.selectedIds.value = {},
          isSelected: isSelected,
          hasSelection: selection.selectedIds.value.isNotEmpty,
          rows: selection.rows,
          selectedIds: selection.selectedIds.value,
          nameOf: (id) => selection.rows[id]?.item.name,
          // Inside the shortcuts, so they answer while the row is focused.
          child: RowStop(
            role: role,
            bounds: RingBounds.tableRow,
            borderRadius: context.shapes.mediumBorderRadius,
            label: role == RowRole.stop ? name : null,
            child: child,
          ),
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
            role: RowRole.stop,
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space3,
              ),
              // The row stop takes Space; the avatar is no second stop.
              child: ExcludeFocus(
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
            ExcludeFocus(
              child: Button(
                face: ButtonFace.bare,
                label: "",
                onPressed: toggleSelection,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.space2,
                    vertical: context.spacing.space3,
                  ),
                  // Read the theme here, inside the row, so a sending row's
                  // struck text theme reaches the name and email.
                  child: Builder(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (member.name != null)
                          Text(
                            member.name!,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (member.email != null)
                          BlurReveal(
                            blurSigma: 3,
                            child: Text(
                              member.email!,
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
        TableCell(
          child: withShortcuts(
            MemberRowActions(member: member, rows: selection.rows),
          ),
        ),
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
