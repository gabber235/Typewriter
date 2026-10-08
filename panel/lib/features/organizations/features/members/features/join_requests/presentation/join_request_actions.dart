import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders actions for the currently selected moderation rows.
///
/// Selection belongs to [JoinRequestsList]. This widget owns only the role
/// choices and in flight approval state, then delegates the atomic mutation to
/// [OrganizationJoinRequests]. Uncertain submission stays in the shared
/// mutation activity instead of being presented as a local rejection.
class BulkJoinRequestActions extends HookConsumerWidget {
  const BulkJoinRequestActions({
    required this.selectedCount,
    required this.selectedIds,
    required this.onClearSelection,
    required this.onDecline,
    super.key,
  });

  final int selectedCount;
  final Set<skir.RecordId> selectedIds;
  final VoidCallback onClearSelection;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bulkRoles = useState<List<OrganizationRole>>([]);
    final isAccepting = useState(false);

    final roleDropdown = RoleMultiselectDropdown(
      selectedRoles: bulkRoles.value,
      onRolesChanged: (roles) => bulkRoles.value = roles,
      placeholder: "Select roles",
    );

    Future<void> acceptSelected() async {
      if (isAccepting.value) return;
      isAccepting.value = true;
      final ids = Set<skir.RecordId>.unmodifiable(selectedIds);
      final roles = List<OrganizationRole>.unmodifiable(bulkRoles.value);
      try {
        await ref
            .read(organizationJoinRequestsProvider.notifier)
            .approveRequests(ids, roles);
        if (context.mounted) {
          if (listEquals(bulkRoles.value, roles)) bulkRoles.value = [];
          if (setEquals(selectedIds, ids)) onClearSelection();
        }
      } on ApiException catch (error) {
        if (context.mounted) showErrorSnackBar(context, error.message);
      } on SubmissionException {
        // The shared activity retains unresolved delivery.
      } finally {
        if (context.mounted) isAccepting.value = false;
      }
    }

    return ManagedActionSet(
      shortcuts: [
        if (bulkRoles.value.isNotEmpty && !isAccepting.value)
          ActionShortcut(
            id: "accept_bulk_join_requests",
            label: "Accept requests",
            description: "Accept selected join requests",
            activators: const [SingleActivator(LogicalKeyboardKey.keyA)],
            priority: 2,
            onInvoke: (_) => acceptSelected(),
          ),
        ActionShortcut.intent(
          id: "decline_bulk_join_requests_key",
          label: "Decline requests",
          description: "Decline selected join requests",
          intent: DeleteIntent,
          priority: 2,
          onInvoke: (_) => onDecline(),
        ),
        ActionShortcut.intent(
          id: "clear_bulk_join_requests",
          label: "Clear selection",
          description: "Clear selected join requests",
          intent: DismissIntent,
          priority: 2,
          onInvoke: (_) => onClearSelection(),
        ),
      ],
      child: AnimatedSize(
        duration: 500.ms,
        alignment: .topLeft,
        curve: context.responsive(
          mobile: ElasticOutCurve(0.9),
          tablet: Curves.easeOutCubic,
        ),
        child: AnimatedSwitcher(
          duration: 100.ms,
          child: selectedIds.isEmpty
              ? null
              : Flex(
                  direction: context.responsive(
                    mobile: Axis.vertical,
                    tablet: Axis.horizontal,
                  ),
                  spacing: context.responsive(mobile: 8.0, tablet: 4.0),
                  crossAxisAlignment: context.responsive(
                    mobile: CrossAxisAlignment.end,
                    tablet: CrossAxisAlignment.center,
                  ),
                  children: [
                    if (context.isMobile)
                      roleDropdown
                    else
                      Flexible(child: roleDropdown),
                    LoadingButton.filledIcon(
                      onPressed: bulkRoles.value.isEmpty || isAccepting.value
                          ? null
                          : acceptSelected,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Accept All"),
                    ),
                    LoadingButton.outlinedIcon(
                      onPressed: onDecline,
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
                ),
        ),
      ),
    );
  }
}
