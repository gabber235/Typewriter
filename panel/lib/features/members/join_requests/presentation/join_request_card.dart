import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Presents one moderation request and its transient interaction state.
///
/// The card owns expansion and per request role selection. List selection is
/// owned by [JoinRequestsList]. Approval executes a prepared repository
/// command through shared local work; declining holds, over the selection
/// when it contains this request. The countdown clears selection only;
/// the visibility projection separately filters expired rows using local time.
class JoinRequestCard extends HookConsumerWidget {
  const JoinRequestCard({
    required this.request,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.hasSelection,
    required this.rows,
    required this.selectedIds,
    required this.nameOf,
    super.key,
  });

  final skir.OrganizationJoinRequest request;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool hasSelection;

  /// The request rows the list owns; the decline hold sends and refuses on
  /// them.
  final AnimatedRows<Object?> rows;
  final Set<skir.RecordId> selectedIds;
  final String? Function(skir.RecordId request) nameOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedRoles = useState<List<skir.OrganizationRole>>([]);
    final isDesktop = context.isDesktop;

    final expansibleController = useExpansibleController();
    useListenable(expansibleController);
    // In a list the card is the stop, so Tab passes over its header.
    final headerFocus = useFocusNode(skipTraversal: true);

    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : expansibleController.isExpanded
        ? theme.cardColor
        : Surface.colorOf(context);

    return Material(
      color: backgroundColor,
      borderRadius: context.shapes.mediumBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: Surface(
        color: backgroundColor,
        child: GrowingCard(
          controller: expansibleController,
          header: (context, animation) {
            return _buildMainContent(
              context,
              ref,
              theme,
              isDesktop,
              expansibleController,
              headerFocus,
            );
          },
          // Part of the row, so focus in it still counts as the card.
          body: (context) {
            return RowStop(
              role: RowRole.part,
              child: JoinRequestApproval(
                request: request,
                selectedRoles: selectedRoles.value,
                rolesAsync: rolesAsync,
                onRolesChanged: (roles) => selectedRoles.value = roles,
                onConfirm: () {
                  onSelectionChanged(false);
                  return ref
                      .executeMembership(
                        ref.membershipCommands.approve([
                          request.requestId,
                        ], selectedRoles.value),
                        (response) => response.requireAccepted(),
                      )
                      .catchApiExceptionsAndDisplay(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDesktop,
    ExpansibleController expansibleController,
    FocusNode headerFocus,
  ) {
    final inList = RowEntryScope.maybeOf(context) != null;
    // One command for the card's key and its Decline buttons.
    final decline = joinRequestDecline(
      id: "decline_${request.requestId}",
      label: hasSelection && isSelected ? "Decline requests" : "Decline",
      targets: () =>
          hasSelection && isSelected ? selectedIds : {request.requestId},
      nameOf: nameOf,
      rows: rows,
    );
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "select_join_request_${request.requestId}",
          label: "Select request",
          description: "Toggle selection for this request",
          intent: ActivateIntent,
          priority: 1,
          run: ActionRun.press((_) => onSelectionChanged(!isSelected)),
        ),
        ActionShortcut.intent(
          id: "select_all_join_requests_${request.requestId}",
          label: "Select all requests",
          description: "Select all visible requests",
          intent: ActivateAllIntent,
          priority: 1,
          run: ActionRun.press((_) => onSelectAll()),
        ),
        // Esc steps out one level: first the card, then the selection.
        if (hasSelection && !expansibleController.isExpanded)
          ActionShortcut.intent(
            id: "clear_join_request_selection_${request.requestId}",
            label: "Clear selection",
            description: "Clear selected requests",
            intent: DismissIntent,
            priority: 1,
            run: ActionRun.press((_) => onClearSelection()),
          ),
        decline,
        ActionShortcut(
          id: "accept_${request.requestId}",
          label: "Accept",
          description: "Accept this join request",
          activators: const [
            SingleActivator(LogicalKeyboardKey.keyA),
            SingleActivator(LogicalKeyboardKey.space),
          ],
          priority: 1,
          run: ActionRun.press((ref) {
            expansibleController.toggle();
          }),
        ),
      ],
      // Inside the shortcuts, so Decline and Accept answer while the card is
      // focused.
      child: RowStop(
        borderRadius: context.shapes.mediumBorderRadius,
        label: request.userName ?? request.userEmail ?? "Join request",
        child: Button(
          face: ButtonFace.bare,
          label: isSelected ? "Deselect request" : "Select request",
          focusNode: inList ? headerFocus : null,
          onPressed: () => onSelectionChanged(!isSelected),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.space4),
            child: isDesktop
                ? _buildDesktopLayout(
                    context,
                    theme,
                    expansibleController,
                    decline,
                  )
                : JoinRequestResponsiveContent(
                    request: request,
                    isSelected: isSelected,
                    isExpanded: expansibleController.isExpanded,
                    onExpired: () {
                      onSelectionChanged(false);
                    },
                    decline: decline,
                    onToggle: () => expansibleController.toggle(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    ExpansibleController expansibleController,
    ActionShortcut decline,
  ) {
    return Row(
      children: [
        SelectableAvatar(
          avatarUrl:
              request.userAvatarUrl?.nullIfEmpty ??
              "$userIconUrl&seed=${request.userId}",
          isSelected: isSelected,
          radius: 24,
        ),
        SizedBox(width: context.spacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              if (request.userName != null)
                Text(
                  request.userName!,
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(fontVariations: [.weight(600)], fontSize: 16),
                ),
              if (request.userEmail != null)
                Text(
                  request.userEmail!,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        CountdownBadge(
          endDate: request.expiresAt,
          onExpired: () {
            onSelectionChanged(false);
          },
        ),
        SizedBox(width: context.spacing.space4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommandButton(
              command: decline,
              face: ButtonFace.outlined,
              color: context.colors.dangerText,
              label: "Decline",
            ),
            SizedBox(width: context.spacing.space2),
            Button(
              face: ButtonFace.filled,
              onPressed: expansibleController.toggle,
              label: expansibleController.isExpanded ? "Cancel" : "Accept",
              busyLabel: "Accepting",
            ),
          ],
        ),
      ],
    );
  }
}
