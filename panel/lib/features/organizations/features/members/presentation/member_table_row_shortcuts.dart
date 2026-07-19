import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class MemberTableRowShortcuts extends ConsumerWidget {
  const MemberTableRowShortcuts({
    required this.member,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.isSelected,
    required this.hasSelection,
    required this.onRemoveSelection,
    required this.onRemoveFromSelection,
    required this.onFocusChange,
    required this.child,
    super.key,
  });

  final OrganizationMember member;
  final VoidCallback onToggleSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool isSelected;
  final bool hasSelection;
  final Future<void> Function() onRemoveSelection;
  final VoidCallback onRemoveFromSelection;
  final ValueChanged<bool> onFocusChange;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "select_table_member_${member.userId}",
          label: "Select member",
          description: "Toggle selection for this member",
          intent: ActivateIntent,
          priority: 1,
          onInvoke: (_) => onToggleSelection(),
        ),
        ActionShortcut.intent(
          id: "select_all_table_members_${member.userId}",
          label: "Select all members",
          description: "Select all visible members",
          intent: ActivateAllIntent,
          priority: 1,
          onInvoke: (_) => onSelectAll(),
        ),
        if (hasSelection)
          ActionShortcut.intent(
            id: "clear_table_member_selection_${member.userId}",
            label: "Clear selection",
            description: "Clear selected members",
            intent: DismissIntent,
            priority: 1,
            onInvoke: (_) {
              onClearSelection();
            },
          ),
        ActionShortcut.intent(
          id: "remove_table_member_${member.userId}",
          label: "Remove member",
          description: "Remove this member",
          intent: DeleteIntent,
          priority: 1,
          onInvoke: (_) => hasSelection && isSelected
              ? onRemoveSelection()
              : _confirmRemoveMember(context, ref),
        ),
      ],
      child: Focus(onFocusChange: onFocusChange, child: child),
    );
  }

  Future<void> _confirmRemoveMember(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Remove ${member.name}?",
      content:
          "Are you sure you want to remove this member from the organization?",
      confirmText: "Remove",
      confirmIcon: Fa6Solid.user_minus,
      onConfirm: () {
        onRemoveFromSelection();
        return ref
            .read(organizationMembersProvider.notifier)
            .removeMember(member.userId);
      },
    );
  }
}
