import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_card.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/empty_state.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";

class MembersTabletList extends HookConsumerWidget {
  const MembersTabletList({
    required this.members,
    required this.selectedIds,
    super.key,
  });

  final List<OrganizationMember> members;
  final ValueNotifier<Set<skir.RecordId>> selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (members.isEmpty) {
      return const EmptyState(
        icon: MaterialSymbols.groups_2_rounded,
        title: "No members yet",
        description: "Invite someone to get started!",
      );
    }

    final allSelected =
        members.isNotEmpty && selectedIds.value.length == members.length;
    final someSelected =
        selectedIds.value.isNotEmpty &&
        selectedIds.value.length < members.length;

    void handleSelectAll() {
      if (allSelected || someSelected) {
        selectedIds.value = {};
      } else {
        selectedIds.value = members.map((m) => m.userId).toSet();
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: handleSelectAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Surface.colorOf(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected ? true : (someSelected ? null : false),
                  tristate: true,
                  onChanged: (_) => handleSelectAll(),
                ),
                Text(
                  "Select all",
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        ...members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return MemberTabletCard(
            key: ValueKey(member.userId),
            member: member,
            index: index,
            isSelected: selectedIds.value.contains(member.userId),
            onSelectionChanged: (selected) {
              if (selected) {
                selectedIds.value = {...selectedIds.value, member.userId};
              } else {
                selectedIds.value = selectedIds.value
                    .where((id) => id != member.userId)
                    .toSet();
              }
            },
          );
        }),
      ],
    );
  }
}
