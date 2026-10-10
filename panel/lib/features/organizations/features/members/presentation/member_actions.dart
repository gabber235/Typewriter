import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Actions for the current member selection.
///
/// Role changes capture the selected ids and role values before submission, so
/// later selection changes cannot alter an in flight mutation. Successful role
/// updates clear the applied selection. Uncertain delivery remains visible in
/// the shared submission activity and is not falsely presented as completed.
class BulkMemberActions extends HookConsumerWidget {
  const BulkMemberActions({
    required this.selectedCount,
    required this.selectedIds,
    required this.onRemove,
    required this.onUnselect,
    super.key,
  });

  final int selectedCount;
  final Set<skir.RecordId> selectedIds;
  final VoidCallback onRemove;
  final ValueChanged<Set<skir.RecordId>> onUnselect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onClearSelection() => onUnselect(selectedIds);
    final theme = Theme.of(context);
    final bulkRoles = useState<List<OrganizationRole>>([]);
    final isApplying = useState(false);

    final roleDropdown = RoleMultiselectDropdown(
      selectedRoles: bulkRoles.value,
      onRolesChanged: (roles) => bulkRoles.value = roles,
      placeholder: "Assign roles",
    );

    Future<void> applyRoles() async {
      if (isApplying.value) return;
      isApplying.value = true;
      final roles = List<OrganizationRole>.unmodifiable(bulkRoles.value);
      final ids = Set<skir.RecordId>.unmodifiable(selectedIds);
      try {
        await ref.executeMembership(
          ref.membershipCommands.updateRoles(ids, roles),
          (response) => response.requireAccepted(),
        );
        if (context.mounted) {
          if (listEquals(bulkRoles.value, roles)) bulkRoles.value = [];
          onUnselect(ids);
        }
      } on ApiException catch (error) {
        if (context.mounted) showErrorSnackBar(context, error.message);
      } on SubmissionException {
        // The shared activity retains unresolved delivery.
      } finally {
        if (context.mounted) isApplying.value = false;
      }
    }

    return ManagedActionSet(
      shortcuts: [
        if (bulkRoles.value.isNotEmpty && !isApplying.value)
          ActionShortcut(
            id: "apply_bulk_member_roles",
            label: "Apply roles",
            description: "Apply roles to selected members",
            activators: const [SingleActivator(LogicalKeyboardKey.keyA)],
            priority: 2,
            onInvoke: (_) => applyRoles(),
          ),
        ActionShortcut.intent(
          id: "remove_bulk_members_key",
          label: "Remove members",
          description: "Remove selected members",
          intent: DeleteIntent,
          priority: 2,
          onInvoke: (_) => onRemove(),
        ),
        ActionShortcut.intent(
          id: "clear_bulk_members",
          label: "Clear selection",
          description: "Clear selected members",
          intent: DismissIntent,
          priority: 2,
          onInvoke: (_) => onClearSelection(),
        ),
      ],
      child: Flex(
        direction: context.responsive(
          mobile: Axis.vertical,
          tablet: Axis.horizontal,
        ),
        spacing: context.spacing.space1,
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

          if (bulkRoles.value.isNotEmpty)
            FilledButton.icon(
              onPressed: isApplying.value ? null : applyRoles,
              icon: const Icon(Icons.check, size: 18),
              label: const Text("Apply"),
            ),
          OutlinedButton.icon(
            onPressed: onRemove,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            icon: const Icon(Icons.person_remove_outlined, size: 18),
            label: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}
