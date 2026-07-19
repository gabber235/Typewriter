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
    super.key,
  });

  final OrganizationJoinRequest request;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedRoles = useState<List<OrganizationRole>>([]);
    final isDesktop = context.isDesktop;

    final backgroundColor = isSelected
        ? Surface.colorOf(context)
        : Surface.colorOf(context);

    final expansibleController = useExpansibleController();

    return Expansible(
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
          backgroundColor,
          expansibleController,
        );
      },
      bodyBuilder: (context, animation) {
        return ElasticMessageTransition(
          animation: animation,
          child: JoinRequestApproval(
            request: request,
            backgroundColor: backgroundColor,
            selectedRoles: selectedRoles.value,
            rolesAsync: rolesAsync,
            onRolesChanged: (roles) => selectedRoles.value = roles,
            onConfirm: () async {
              onSelectionChanged(false);
              await ref
                  .read(organizationJoinRequestsProvider.notifier)
                  .approveRequest(request.requestId, selectedRoles.value);
            },
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDesktop,
    Color backgroundColor,
    ExpansibleController expansibleController,
  ) {
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "decline_${request.requestId}",
          label: "Decline",
          description: "Decline this join request",
          intent: DeleteIntent,
          priority: 1,
          onInvoke: (ref) async {
            await _confirmDeclineRequest(context, ref);
          },
        ),
        ActionShortcut(
          id: "accept_${request.requestId}",
          label: "Accept",
          description: "Accept this join request",
          activators: const [
            SingleActivator(LogicalKeyboardKey.keyA),
            SingleActivator(LogicalKeyboardKey.enter),
          ],
          priority: 1,
          onInvoke: (ref) {
            expansibleController.toggle();
          },
        ),
      ],
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
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
                    onExpired: () => ref
                        .read(organizationJoinRequestsProvider.notifier)
                        .cleanupExpiredRequests(),
                    onDecline: () => _confirmDeclineRequest(context, ref),
                    onToggle: () => expansibleController.toggle(),
                  ),
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
          onExpired: () => ref
              .read(organizationJoinRequestsProvider.notifier)
              .cleanupExpiredRequests(),
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
