import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class JoinRequestCard extends HookConsumerWidget {
  const JoinRequestCard({
    required this.request,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.hasSelection,
    required this.onDeclineSelection,
    super.key,
  });

  final OrganizationJoinRequest request;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool hasSelection;
  final Future<void> Function() onDeclineSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedRoles = useState<List<OrganizationRole>>([]);
    final isDesktop = context.isDesktop;

    final expansibleController = useExpansibleController();
    useListenable(expansibleController);

    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : expansibleController.isExpanded
        ? theme.cardColor
        : Surface.colorOf(context);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Surface(
        color: backgroundColor,
        child: Expansible(
          controller: expansibleController,
          animationStyle: AnimationStyle(
            duration: 500.ms,
            curve: ElasticOutCurve(0.9),
            reverseDuration: 20.ms,
            reverseCurve: Curves.easeInCubic,
          ),
          headerBuilder: (context, animation) {
            return _buildMainContent(
              context,
              ref,
              theme,
              isDesktop,
              expansibleController,
            );
          },
          bodyBuilder: (context, animation) {
            return ElasticMessageTransition(
              animation: animation,
              child: JoinRequestApproval(
                request: request,
                selectedRoles: selectedRoles.value,
                rolesAsync: rolesAsync,
                onRolesChanged: (roles) => selectedRoles.value = roles,
                onConfirm: () {
                  onSelectionChanged(false);
                  return ref
                      .read(organizationJoinRequestsProvider.notifier)
                      .approveRequest(request.requestId, selectedRoles.value)
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
  ) {
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "select_join_request_${request.requestId}",
          label: "Select request",
          description: "Toggle selection for this request",
          intent: ActivateIntent,
          priority: 1,
          onInvoke: (_) => onSelectionChanged(!isSelected),
        ),
        ActionShortcut.intent(
          id: "select_all_join_requests_${request.requestId}",
          label: "Select all requests",
          description: "Select all visible requests",
          intent: ActivateAllIntent,
          priority: 1,
          onInvoke: (_) => onSelectAll(),
        ),
        if (hasSelection)
          ActionShortcut.intent(
            id: "clear_join_request_selection_${request.requestId}",
            label: "Clear selection",
            description: "Clear selected requests",
            intent: DismissIntent,
            priority: 1,
            onInvoke: (_) => onClearSelection(),
          ),
        ActionShortcut.intent(
          id: "decline_${request.requestId}",
          label: "Decline",
          description: "Decline this join request",
          intent: DeleteIntent,
          priority: 1,
          onInvoke: (ref) => hasSelection && isSelected
              ? onDeclineSelection()
              : _confirmDeclineRequest(context, ref),
        ),
        ActionShortcut(
          id: "accept_${request.requestId}",
          label: "Accept",
          description: "Accept this join request",
          activators: const [
            SingleActivator(LogicalKeyboardKey.keyA),
            SingleActivator(LogicalKeyboardKey.space),
          ],
          priority: 1,
          onInvoke: (ref) {
            expansibleController.toggle();
          },
        ),
      ],
      child: InkWell(
        onTap: () => onSelectionChanged(!isSelected),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isDesktop
              ? _buildDesktopLayout(context, ref, theme, expansibleController)
              : JoinRequestResponsiveContent(
                  request: request,
                  isSelected: isSelected,
                  isExpanded: expansibleController.isExpanded,
                  onExpired: () {
                    onSelectionChanged(false);
                    ref
                        .read(organizationJoinRequestsProvider.notifier)
                        .cleanupExpiredRequests();
                  },
                  onDecline: () => _confirmDeclineRequest(context, ref),
                  onToggle: () => expansibleController.toggle(),
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ExpansibleController expansibleController,
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              if (request.userName != null)
                Text(
                  request.userName!,
                  style: const TextStyle(
                    fontVariations: [.weight(600)],
                    fontSize: 16,
                  ),
                ),
              if (request.userEmail != null)
                Text(
                  request.userEmail!,
                  style: TextStyle(
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
            ref
                .read(organizationJoinRequestsProvider.notifier)
                .cleanupExpiredRequests();
          },
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingButton.outlined(
              onPressed: () => _confirmDeclineRequest(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: const Text("Decline"),
            ),
            const SizedBox(width: 8),
            LoadingButton.filled(
              onPressed: () {
                expansibleController.toggle();
              },
              child: Text(
                expansibleController.isExpanded ? "Cancel" : "Accept",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeclineRequest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Decline ${request.userName}'s request?",
      content: "Are you sure you want to decline this join request?",
      confirmText: "Decline",
      confirmIcon: Fa6Solid.xmark,
      onConfirm: () async {
        onSelectionChanged(false);
        await ref
            .read(organizationJoinRequestsProvider.notifier)
            .declineRequest(request.requestId);
      },
    );
  }
}
