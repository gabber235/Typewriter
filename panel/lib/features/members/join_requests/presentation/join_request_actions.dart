import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders actions for the currently selected moderation rows.
///
/// Selection belongs to [JoinRequestsList]. This widget owns only the role
/// choices and in flight approval state, then executes one prepared repository
/// command for the captured ids and roles. Uncertain submission stays in the
/// shared mutation activity instead of being presented as a local rejection.
class BulkJoinRequestActions extends HookConsumerWidget {
  const BulkJoinRequestActions({
    required this.selectedCount,
    required this.selectedIds,
    required this.onClearSelection,
    required this.decline,
    super.key,
  });

  final int selectedCount;
  final Set<skir.RecordId> selectedIds;
  final VoidCallback onClearSelection;

  /// The decline hold over the selected requests.
  final ActionShortcut decline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bulkRoles = useState<List<skir.OrganizationRole>>([]);
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
      final roles = List<skir.OrganizationRole>.unmodifiable(bulkRoles.value);
      try {
        await ref.executeMembership(
          ref.membershipCommands.approve(ids, roles),
          (response) => response.requireAccepted(),
        );
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
            run: ActionRun.press((_) => acceptSelected()),
          ),
        decline,
        ActionShortcut.intent(
          id: "clear_bulk_join_requests",
          label: "Clear selection",
          description: "Clear selected join requests",
          intent: DismissIntent,
          priority: 2,
          run: ActionRun.press((_) => onClearSelection()),
        ),
      ],
      child: AnimatedPresence(
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
                  Button(
                    face: ButtonFace.filled,
                    onPressed: bulkRoles.value.isEmpty || isAccepting.value
                        ? null
                        : acceptSelected,
                    icon: const Icon(Icons.check, size: 18),
                    label: "Accept All",
                    busyLabel: "Accepting",
                  ),
                  CommandButton(
                    command: decline,
                    face: ButtonFace.outlined,
                    color: context.colors.dangerText,
                    icon: const Icon(Icons.close, size: 18),
                    label: "Decline all",
                  ),
                ],
              ),
      ),
    );
  }
}
