import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/application/members.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_constants.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_row_actions.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/role_multiselect_dropdown.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/selectable_avatar.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/blur_reveal.dart";
import "package:typewriter_panel/shared/ui/components/empty_state.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/async.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class MembersTable extends HookConsumerWidget {
  const MembersTable({
    required this.members,
    required this.selectedIds,
    super.key,
  });

  final List<OrganizationMember> members;
  final ValueNotifier<Set<skir.RecordId>> selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final focusedRowIndex = useState(-1);

    if (members.isEmpty) {
      return EmptyState(
        title: "No members yet",
        description: "Invite someone to get started!",
        icon: MaterialSymbols.groups_2_rounded,
      );
    }

    final allSelected =
        members.isNotEmpty && selectedIds.value.length == members.length;
    final someSelected =
        selectedIds.value.isNotEmpty &&
        selectedIds.value.length < members.length;

    return Surface(
      color: Surface.colorOf(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(48),
            1: IntrinsicColumnWidth(),
            2: FlexColumnWidth(1),
            3: FixedColumnWidth(80),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: Surface.colorOf(context)),
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
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
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Text(
                      "Member",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Text(
                      "Roles",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const TableCell(child: SizedBox.shrink()),
              ],
            ),
            for (final (index, member) in members.indexed)
              _buildMemberRow(
                context,
                ref,
                member,
                index,
                selectedIds.value.contains(member.userId),
                focusedRowIndex,
                theme,
              ),
          ],
        ),
      ),
    );
  }

  TableRow _buildMemberRow(
    BuildContext context,
    WidgetRef ref,
    OrganizationMember member,
    int index,
    bool isSelected,
    ValueNotifier<int> focusedRowIndex,
    ThemeData theme,
  ) {
    final isFocused = focusedRowIndex.value == index;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Material(
              color: Colors.transparent,
              shape: CircleBorder(),
              child: InkWell(
                customBorder: CircleBorder(),
                onFocusChange: (focused) {
                  focusedRowIndex.value = focused ? index : -1;
                },
                onTap: () {
                  if (isSelected) {
                    selectedIds.value = selectedIds.value
                        .where((id) => id != member.userId)
                        .toSet();
                  } else {
                    selectedIds.value = {...selectedIds.value, member.userId};
                  }
                },
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
        TableCell(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onFocusChange: (focused) {
                focusedRowIndex.value = focused ? index : -1;
              },
              onTap: () {
                if (isSelected) {
                  selectedIds.value = selectedIds.value
                      .where((id) => id != member.userId)
                      .toSet();
                } else {
                  selectedIds.value = {...selectedIds.value, member.userId};
                }
              },
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
        TableCell(
          child: Padding(
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
        TableCell(child: MemberRowActions(member: member)),
      ],
    );
  }
}
