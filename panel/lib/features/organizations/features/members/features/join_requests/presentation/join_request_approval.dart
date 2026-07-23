import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
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
            padding: EdgeInsets.all(context.spacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select roles for this member:",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontVariations: const [.weight(500)],
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: context.spacing.space3),
                rolesAsync(
                  name: "Roles",
                  shrink: true,
                  builder: (availableRoles) => RoleMultiselectChips(
                    availableRoles: availableRoles,
                    selectedRoles: selectedRoles,
                    onRolesChanged: onRolesChanged,
                  ),
                ),
                SizedBox(height: context.spacing.space4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LoadingButton.filledIcon(
                      onPressed: selectedRoles.isEmpty ? null : onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text("Confirm & Add Member"),
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
