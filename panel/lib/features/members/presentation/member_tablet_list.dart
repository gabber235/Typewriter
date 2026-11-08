import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Touch oriented member projection with one expandable card per member.
///
/// It shares selection semantics with [MembersTable], but delegates row detail
/// and role editing to [MemberTabletCard]. It renders the rows [MembersTab]
/// owns, whose mechanic plays every arrival and removal.
class MembersTabletList extends HookConsumerWidget {
  const MembersTabletList({required this.selection, super.key});

  final SelectableRows<skir.OrganizationMember> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = selection.rows.items;

    // The empty state shows once the last leaving row is gone.
    if (selection.rows.entries.isEmpty) {
      return SliverFillRemaining(
        child: const EmptyState(
          icon: MaterialSymbols.groups_2_rounded,
          title: "No members yet",
          description: "Invite someone to get started!",
        ),
      );
    }

    final allSelected =
        members.isNotEmpty &&
        selection.selectedIds.value.length == members.length;
    final someSelected =
        selection.selectedIds.value.isNotEmpty &&
        selection.selectedIds.value.length < members.length;

    void handleSelectAll() {
      if (allSelected || someSelected) {
        selection.selectedIds.value = {};
      } else {
        selection.selectedIds.value = members.map((m) => m.userId).toSet();
      }
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Enter(
            token: MotionToken.loadIn,
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
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverAnimatedRows<skir.OrganizationMember>(
          rows: selection.rows,
          itemBuilder: (context, entry) => _child(context, entry.item, members),
        ),
      ],
    );
  }

  Widget _child(
    BuildContext context,
    skir.OrganizationMember member,
    List<skir.OrganizationMember> members,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.space3),
      child: MemberTabletCard(
        key: ValueKey(member.userId),
        member: member,
        isSelected: selection.selectedIds.value.contains(member.userId),
        onSelectionChanged: (selected) {
          if (selected) {
            selection.selectedIds.value = {
              ...selection.selectedIds.value,
              member.userId,
            };
          } else {
            selection.selectedIds.value = selection.selectedIds.value
                .where((id) => id != member.userId)
                .toSet();
          }
        },
        onSelectAll: () => selection.selectedIds.value = members
            .map((member) => member.userId)
            .toSet(),
        onClearSelection: () => selection.selectedIds.value = {},
        hasSelection: selection.selectedIds.value.isNotEmpty,
        rows: selection.rows,
        selectedIds: selection.selectedIds.value,
        nameOf: (id) => selection.rows[id]?.item.name,
      ),
    );
  }
}
