import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/role_multiselect_dropdown.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/selected_chip.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/utilities/context.dart";

class BulkJoinRequestActions extends HookConsumerWidget {
  const BulkJoinRequestActions({
    required this.selectedCount,
    required this.selectedIds,
    required this.onClearSelection,
    super.key,
  });

  final int selectedCount;
  final Set<skir.RecordId> selectedIds;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bulkRoles = useState<List<OrganizationRole>>([]);

    final roleDropdown = RoleMultiselectDropdown(
      selectedRoles: bulkRoles.value,
      onRolesChanged: (roles) => bulkRoles.value = roles,
      placeholder: "Select roles",
    );

    return Flex(
      direction: context.responsive(
        mobile: Axis.vertical,
        tablet: Axis.horizontal,
      ),
      spacing: 4,
      crossAxisAlignment: context.responsive(
        mobile: CrossAxisAlignment.start,
        tablet: CrossAxisAlignment.center,
      ),
      children: [
        SelectedChip(
          selectedCount: selectedCount,
          onClearSelection: onClearSelection,
        ),
        if (context.isMobile) roleDropdown else Flexible(child: roleDropdown),
        // Bulk accept button
        LoadingButton.filledIcon(
          onPressed: bulkRoles.value.isEmpty
              ? null
              : () async {
                  for (final id in selectedIds) {
                    await ref
                        .read(organizationJoinRequestsProvider.notifier)
                        .approveRequest(id, bulkRoles.value);
                  }
                  bulkRoles.value = [];
                  onClearSelection();
                },
          icon: const Icon(Icons.check, size: 18),
          label: const Text("Accept All"),
        ),
        LoadingButton.outlinedIcon(
          onPressed: () => _confirmBulkDecline(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          icon: const Icon(Icons.close, size: 18),
          label: const Text("Decline All"),
        ),
      ],
    );
  }

  Future<void> _confirmBulkDecline(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Decline $selectedCount request(s)?",
      content: "Are you sure you want to decline these join requests?",
      confirmText: "Decline All",
      confirmIcon: Fa6Solid.xmark,
      onConfirm: () async {
        for (final id in selectedIds) {
          await ref
              .read(organizationJoinRequestsProvider.notifier)
              .declineRequest(id);
        }
        onClearSelection();
      },
    );
  }
}
