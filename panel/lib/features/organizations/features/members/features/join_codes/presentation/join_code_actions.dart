import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/selected_chip.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";

class BulkJoinCodeActions extends HookConsumerWidget {
  const BulkJoinCodeActions({
    required this.selectedCount,
    required this.selectedCodes,
    required this.onClearSelection,
    super.key,
  });

  final int selectedCount;
  final Set<skir.RecordId> selectedCodes;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        SelectedChip(
          selectedCount: selectedCount,
          onClearSelection: onClearSelection,
        ),
        LoadingButton.outlinedIcon(
          onPressed: () => _confirmBulkRevoke(context, ref),
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
    );
  }

  Future<void> _confirmBulkRevoke(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke $selectedCount join code(s)?",
      content:
          "Are you sure you want to revoke these join codes? They will no longer work.",
      confirmText: "Revoke All",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        for (final code in selectedCodes) {
          await ref
              .read(organizationJoinCodesProvider.notifier)
              .revokeCode(code);
        }
        onClearSelection();
      },
    );
  }
}
