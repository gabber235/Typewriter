import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Adds the member row's keyboard contract without changing its rendering.
///
/// Selection commands operate on the same transient set as pointer controls.
/// Holding Delete removes the whole current selection when this row is
/// selected; otherwise it removes this member alone.
class MemberTableRowShortcuts extends StatelessWidget {
  const MemberTableRowShortcuts({
    required this.member,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.isSelected,
    required this.hasSelection,
    required this.rows,
    required this.selectedIds,
    required this.nameOf,
    required this.child,
    super.key,
  });

  final skir.OrganizationMember member;
  final VoidCallback onToggleSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool isSelected;
  final bool hasSelection;

  /// The members rows the tab owns; the remove hold sends and refuses on
  /// them.
  final AnimatedRows<Object?> rows;
  final Set<skir.RecordId> selectedIds;
  final String? Function(skir.RecordId member) nameOf;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "select_table_member_${member.userId}",
          label: "Select member",
          description: "Toggle selection for this member",
          intent: ActivateIntent,
          priority: 1,
          run: ActionRun.press((_) => onToggleSelection()),
        ),
        ActionShortcut.intent(
          id: "select_all_table_members_${member.userId}",
          label: "Select all members",
          description: "Select all visible members",
          intent: ActivateAllIntent,
          priority: 1,
          run: ActionRun.press((_) => onSelectAll()),
        ),
        if (hasSelection)
          ActionShortcut.intent(
            id: "clear_table_member_selection_${member.userId}",
            label: "Clear selection",
            description: "Clear selected members",
            intent: DismissIntent,
            priority: 1,
            run: ActionRun.press((_) {
              onClearSelection();
            }),
          ),
        memberRemoval(
          id: "remove_table_member_${member.userId}",
          label: hasSelection && isSelected
              ? "Remove members"
              : "Remove member",
          // Act on the selection if it contains the focused row, otherwise
          // on the row.
          targets: () =>
              hasSelection && isSelected ? selectedIds : {member.userId},
          nameOf: nameOf,
          rows: rows,
        ),
      ],
      child: child,
    );
  }
}
