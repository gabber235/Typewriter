import "package:typewriter_panel/typewriter_panel.dart";

/// Collects the roles required before one request can be approved.
///
/// Role data comes from the organization role catalog. This widget owns no
/// membership state and does not submit directly. It enables confirmation only
/// after a role selection and lets the card owner perform the mutation.
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
          ActionShortcut.intent(
            id: "confirm_${request.requestId}",
            label: "Confirm",
            description: "Confirm adding member",
            intent: PrimaryActionIntent,
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
