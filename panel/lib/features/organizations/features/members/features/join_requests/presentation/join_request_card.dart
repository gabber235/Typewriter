import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/app/presentation/shortcuts/shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_approval.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_responsive_content.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_constants.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/selectable_avatar.dart";
import "package:typewriter_panel/shared/ui/components/countdown_badge.dart";
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class JoinRequestCard extends HookConsumerWidget {
  const JoinRequestCard({
    required this.request,
    required this.index,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final OrganizationJoinRequest request;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedRoles = useState<List<OrganizationRole>>([]);
    final isExpanded = useState(false);
    final isRemoving = useState(request.isExpired);
    final isDesktop = context.isDesktop;

    final backgroundColor = isSelected
        ? Surface.colorOf(context)
        : Surface.colorOf(context);

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      child: isRemoving.value
          ? const SizedBox.shrink()
          : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMainContent(
                      context,
                      ref,
                      theme,
                      isDesktop,
                      backgroundColor,
                      isExpanded,
                      isRemoving,
                    ),
                    JoinRequestApproval(
                      request: request,
                      isExpanded: isExpanded.value,
                      backgroundColor: backgroundColor,
                      selectedRoles: selectedRoles.value,
                      rolesAsync: rolesAsync,
                      onRolesChanged: (roles) => selectedRoles.value = roles,
                      onConfirm: () async {
                        isRemoving.value = true;
                        onSelectionChanged(false);
                        await ref
                            .read(organizationJoinRequestsProvider.notifier)
                            .approveRequest(
                              request.requestId,
                              selectedRoles.value,
                            );
                      },
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                .slideY(
                  begin: 0.02,
                  end: 0,
                  duration: 300.ms,
                  delay: (50 * index).ms,
                ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDesktop,
    Color backgroundColor,
    ValueNotifier<bool> isExpanded,
    ValueNotifier<bool> isRemoving,
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
            await _confirmDeclineRequest(context, ref, isRemoving);
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
            isExpanded.value = !isExpanded.value;
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
                ? _buildDesktopLayout(
                    context,
                    ref,
                    theme,
                    isExpanded,
                    isRemoving,
                  )
                : JoinRequestResponsiveContent(
                    request: request,
                    isSelected: isSelected,
                    isExpanded: isExpanded.value,
                    onExpired: () => isRemoving.value = true,
                    onDecline: () =>
                        _confirmDeclineRequest(context, ref, isRemoving),
                    onToggle: () => isExpanded.value = !isExpanded.value,
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
    ValueNotifier<bool> isExpanded,
    ValueNotifier<bool> isRemoving,
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
          onExpired: () => isRemoving.value = true,
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingButton.outlined(
              onPressed: () => _confirmDeclineRequest(context, ref, isRemoving),
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
                isExpanded.value = !isExpanded.value;
              },
              child: Text(isExpanded.value ? "Cancel" : "Accept"),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeclineRequest(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRemoving,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Decline ${request.userName}'s request?",
      content: "Are you sure you want to decline this join request?",
      confirmText: "Decline",
      confirmIcon: Fa6Solid.xmark,
      onConfirm: () async {
        isRemoving.value = true;
        onSelectionChanged(false);
        await ref
            .read(organizationJoinRequestsProvider.notifier)
            .declineRequest(request.requestId);
      },
    );
  }
}
