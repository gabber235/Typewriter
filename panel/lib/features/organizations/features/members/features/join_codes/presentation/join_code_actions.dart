import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class BulkJoinCodeActions extends StatelessWidget {
  const BulkJoinCodeActions({
    required this.selectedCount,
    required this.onRevoke,
    required this.onClearSelection,
    super.key,
  });

  final int selectedCount;
  final Future<void> Function() onRevoke;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "revoke_bulk_join_codes_key",
          label: "Revoke join codes",
          description: "Revoke selected join codes",
          intent: DeleteIntent,
          priority: 2,
          onInvoke: (_) => onRevoke(),
        ),
        ActionShortcut.intent(
          id: "clear_bulk_join_codes",
          label: "Clear selection",
          description: "Clear selected join codes",
          intent: DismissIntent,
          priority: 2,
          onInvoke: (_) => onClearSelection(),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space2,
        children: [
          SelectedChip(
            selectedCount: selectedCount,
            onClearSelection: onClearSelection,
          ),
          LoadingButton.outlinedIcon(
            onPressed: onRevoke,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            icon: const Icon(Icons.link_off, size: 18),
            label: const Text("Revoke All"),
          ),
        ],
      ),
    );
  }
}
