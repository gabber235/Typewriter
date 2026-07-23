import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class MembersTabletList extends HookConsumerWidget {
  const MembersTabletList({
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
    final animation = useSliverAnimatedList(
      items: members,
      identity: (item) => item.userId,
      removedItemBuilder: (context, item, animation) =>
          _child(item, selectedIds, animation, ignorePointer: true),
    );

    if (members.isEmpty) {
      return SliverFillRemaining(
        child: const EmptyState(
          icon: MaterialSymbols.groups_2_rounded,
          title: "No members yet",
          description: "Invite someone to get started!",
        ),
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

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: StaggerEntrance(
            child: GestureDetector(
              onTap: handleSelectAll,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: context.spacing.space2),
                decoration: BoxDecoration(
                  color: Surface.colorOf(context),
                  borderRadius: BorderRadius.vertical(
                    top: context.shapes.mediumRadius,
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
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverAnimatedList(
          key: animation.key,
          initialItemCount: animation.items.length,
          itemBuilder: (context, index, animation) {
            final member = members[index];
            return _child(member, selectedIds, animation);
          },
        ),
      ],
    );
  }

  Widget _child(
    OrganizationMember member,
    ValueNotifier<Set<skir.RecordId>> selectedIds,
    Animation<double> animation, {
    bool ignorePointer = false,
  }) {
    return IgnorePointer(
      key: ValueKey(member.userId),
      ignoring: ignorePointer,
      child: ElasticTransition(
        animation: animation,
        child: StaggerEntrance(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MemberTabletCard(
              key: ValueKey(member.userId),
              member: member,
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
              onSelectAll: () => selectedIds.value = members
                  .map((member) => member.userId)
                  .toSet(),
              onClearSelection: () => selectedIds.value = {},
              hasSelection: selectedIds.value.isNotEmpty,
              onRemoveSelection: onRemoveSelection,
            ),
          ),
        ),
      ),
    );
  }
}
