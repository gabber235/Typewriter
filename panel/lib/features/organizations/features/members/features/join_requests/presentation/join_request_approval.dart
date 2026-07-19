import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/role_multiselect_chips.dart";
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class JoinRequestApproval extends StatelessWidget {
  const JoinRequestApproval({
    required this.request,
    required this.selectedRoles,
    required this.rolesAsync,
    required this.onRolesChanged,
    required this.onConfirm,
    super.key,
  });

  final OrganizationJoinRequest request;
  final List<OrganizationRole> selectedRoles;
  final AsyncValue<List<OrganizationRole>> rolesAsync;
  final ValueChanged<List<OrganizationRole>> onRolesChanged;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ManagedActionSet(
      shortcuts: [
        if (selectedRoles.isNotEmpty)
          ActionShortcut(
            id: "confirm_${request.requestId}",
            label: "Confirm",
            description: "Confirm adding member",
            activators: [
              AdaptiveSingleActivator(LogicalKeyboardKey.enter, control: true),
            ],
            priority: 1,
            onInvoke: (ref) => onConfirm(),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select roles for this member:",
                  style: TextStyle(
                    fontVariations: const [.weight(500)],
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                rolesAsync(
                  name: "Roles",
                  shrink: true,
                  builder: (availableRoles) => RoleMultiselectChips(
                    availableRoles: availableRoles,
                    selectedRoles: selectedRoles,
                    onRolesChanged: onRolesChanged,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LoadingButton.filledIcon(
                      onPressed: selectedRoles.isEmpty ? null : onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Confirm & Add Member"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
