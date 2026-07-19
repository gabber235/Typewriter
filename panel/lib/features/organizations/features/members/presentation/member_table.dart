import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_table_row_shortcuts.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class MembersTable extends HookConsumerWidget {
  const MembersTable({
    required this.members,
    required this.selectedIds,
    required this.onRemoveSelection,
    super.key,
  });

  final List<OrganizationMember> members;
  final ValueNotifier<Set<skir.RecordId>> selectedIds;
  final Future<void> Function() onRemoveSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final focusedMemberId = useState<skir.RecordId?>(null);
    final animated = useAnimatedTable(
      items: members,
      identity: (member) => member.userId,
      removedItemBuilder: (context, member, animation) => _buildMemberRow(
        context,
        ref,
        member,
        selectedIds.value.contains(member.userId),
        focusedMemberId,
        theme,
      ),
    );

    final allSelected =
        members.isNotEmpty && selectedIds.value.length == members.length;
    final someSelected =
        selectedIds.value.isNotEmpty &&
        selectedIds.value.length < members.length;

    return SliverFillRemaining(
      child: AnimatedTable(
        key: animated.key,
        initialItemCount: animated.items.length,
        columnWidths: const {
          0: FixedColumnWidth(48),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(1),
          3: FixedColumnWidth(80),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        headerRows: [
          TableRow(
            decoration: BoxDecoration(color: Surface.colorOf(context)),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: StaggerEntrance(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Checkbox(
                      value: allSelected ? true : (someSelected ? null : false),
                      tristate: true,
                      onChanged: (value) {
                        if (allSelected || someSelected) {
                          selectedIds.value = {};
                        } else {
                          selectedIds.value = members
                              .map((m) => m.userId)
                              .toSet();
                        }
                      },
                    ),
                  ),
                ),
              ),
              _headerCell(theme, "Member"),
              _headerCell(theme, "Roles"),
              const TableCell(child: SizedBox.shrink()),
            ],
          ),
        ],
        emptyBuilder: (context) => EmptyState(
          title: "No members yet",
          description: "Invite someone to get started!",
          icon: MaterialSymbols.groups_2_rounded,
        ),
        transitionBuilder: (context, animation, child) {
          return ElasticTransition(animation: animation, child: child);
        },
        tableBuilder: (context, table) => Surface(
          color: Surface.colorOf(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: table,
          ),
        ),
        rowBuilder: (context, index, animation) {
          final member = animated.items[index];
          return _buildMemberRow(
            context,
            ref,
            member,
            selectedIds.value.contains(member.userId),
            focusedMemberId,
            theme,
          );
        },
      ),
    );
  }

  TableCell _headerCell(ThemeData theme, String label) {
    return TableCell(
      child: StaggerEntrance(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildMemberRow(
    BuildContext context,
    WidgetRef ref,
    OrganizationMember member,
    bool isSelected,
    ValueNotifier<skir.RecordId?> focusedMemberId,
    ThemeData theme,
  ) {
    final isFocused = focusedMemberId.value == member.userId;

    void toggleSelection() {
      if (isSelected) {
        selectedIds.value = selectedIds.value
            .where((id) => id != member.userId)
            .toSet();
        return;
      }
      selectedIds.value = {...selectedIds.value, member.userId};
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
          selectedIds.value = members.map((m) => m.userId).toSet(),
      onClearSelection: () => selectedIds.value = {},
      isSelected: isSelected,
      hasSelection: selectedIds.value.isNotEmpty,
      onRemoveSelection: onRemoveSelection,
      onRemoveFromSelection: () => selectedIds.value = selectedIds.value
          .where((id) => id != member.userId)
          .toSet(),
      onFocusChange: updateFocus,
      child: child,
    );

    return TableRow(
      key: ValueKey(member.userId),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(
                alpha: isFocused ? 0.24 : 0.12,
              )
            : isFocused
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: StaggerEntrance(
            child: withShortcuts(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: CircleBorder(),
                  child: InkWell(
                    customBorder: CircleBorder(),
                    onTap: toggleSelection,
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
        ),
        TableCell(
          child: StaggerEntrance(
            child: withShortcuts(
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: toggleSelection,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (member.name != null)
                          Text(
                            member.name!,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (member.email != null)
                          BlurReveal(
                            blurSigma: 3,
                            child: Text(
                              member.email!,
                              style: TextStyle(
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
        ),
        TableCell(
          child: StaggerEntrance(
            child: withShortcuts(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: RoleMultiselectDropdown(
                  selectedRoles: member.roles,
                  onRolesChanged: (newRoles) {
                    ref
                        .read(organizationMembersProvider.notifier)
                        .updateMemberRoles(member.userId, newRoles)
                        .catchApiExceptionsAndDisplay(context);
                  },
                  placeholder: "Select roles",
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: StaggerEntrance(
            child: withShortcuts(MemberRowActions(member: member)),
          ),
        ),
      ],
    );
  }
}
