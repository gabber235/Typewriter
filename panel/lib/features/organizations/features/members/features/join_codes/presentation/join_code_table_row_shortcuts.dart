import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class JoinCodeTableRowShortcuts extends ConsumerWidget {
  const JoinCodeTableRowShortcuts({
    required this.code,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onCopy,
    required this.isSelected,
    required this.hasSelection,
    required this.onRevokeSelection,
    required this.onFocusChange,
    required this.child,
    super.key,
  });

  final OrganizationJoinCode code;
  final VoidCallback onToggleSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onCopy;
  final bool isSelected;
  final bool hasSelection;
  final Future<void> Function() onRevokeSelection;
  final ValueChanged<bool> onFocusChange;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "select_table_join_code_${code.code}",
          label: "Select join code",
          description: "Toggle selection for this join code",
          intent: ActivateIntent,
          priority: 1,
          onInvoke: (_) => onToggleSelection(),
        ),
        ActionShortcut.intent(
          id: "select_all_table_join_codes_${code.code}",
          label: "Select all join codes",
          description: "Select all visible join codes",
          intent: ActivateAllIntent,
          priority: 1,
          onInvoke: (_) => onSelectAll(),
        ),
        ActionShortcut.intent(
          id: "clear_table_join_code_selection_${code.code}",
          label: "Clear selection",
          description: "Clear selected join codes",
          intent: DismissIntent,
          priority: 1,
          onInvoke: (_) => onClearSelection(),
        ),
        if (!hasSelection)
          ActionShortcut(
            id: "copy_table_join_code_${code.code}",
            label: "Copy join code",
            description: "Copy this join code",
            activators: const [SingleActivator(LogicalKeyboardKey.keyC)],
            priority: 1,
            onInvoke: (_) => onCopy(),
          ),
        ActionShortcut.intent(
          id: "revoke_table_join_code_${code.code}",
          label: "Revoke join code",
          description: "Revoke this join code",
          intent: DeleteIntent,
          priority: 1,
          onInvoke: (_) => hasSelection && isSelected
              ? onRevokeSelection()
              : _confirmRevokeCode(context, ref),
        ),
      ],
      child: Focus(onFocusChange: onFocusChange, child: child),
    );
  }

  Future<void> _confirmRevokeCode(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this join code?",
      content:
          "Are you sure you want to revoke this join code? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () => ref
          .read(organizationJoinCodesProvider.notifier)
          .revokeCode(code.code),
    );
  }
}
