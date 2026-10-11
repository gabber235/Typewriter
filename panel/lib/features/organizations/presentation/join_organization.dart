part of "route.dart";

/// Form and pending request list for the authenticated user's memberships.
///
/// Expired rows disappear locally, while submit and cancel operations delegate to
/// [UserJoinRequests]. A successful submission clears input; failures remain
/// visible through the shared panel error surface.
class _JoinOrganization extends HookConsumerWidget {
  const _JoinOrganization({required this.joinRequests});

  final List<UserJoinRequest> joinRequests;

  static const _inviteLinkPrefix = "https://panel.typewritermc.com/join/";
  static const _maxPendingRequests = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final theme = Theme.of(context);
    final activeRequests = joinRequests.where((request) {
      return !request.isExpired;
    }).toList();
    final hasActiveRequests = activeRequests.isNotEmpty;
    final hasReachedLimit = activeRequests.length >= _maxPendingRequests;

    Future<void> submitJoinRequest() => _submitJoinRequest(
      context: context,
      ref: ref,
      formKey: formKey,
      controller: controller,
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverStaggerEntrance(
          sliver: SliverToBoxAdapter(
            child: Text(
              "Join organization",
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        spacer(8),
        SliverStaggerEntrance(
          sliver: SliverToBoxAdapter(
            child: Text(
              "Enter an invite URL or code to request to join an organization.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        spacer(16),
        SliverStaggerEntrance(
          sliver: SliverToBoxAdapter(
            child: Form(
              key: formKey,
              child: Row(
                children: [
                  Expanded(
                    child: EditorTextField(
                      controller: controller,
                      enabled: !hasReachedLimit,
                      decoration: const InputDecoration(
                        hintText: "Invite URL or code",
                      ),
                      validator: _validateInput,
                      onSubmitted: hasReachedLimit
                          ? null
                          : (_) => submitJoinRequest(),
                    ),
                  ),
                  SizedBox(width: context.spacing.space3),
                  LoadingButton.filled(
                    onPressed: hasReachedLimit ? null : submitJoinRequest,
                    child: const Text("Join"),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverAnimatedContent(
          child: hasReachedLimit
              ? StaggerEntrance(
                  child: Padding(
                    padding: EdgeInsets.only(top: context.spacing.space2),
                    child: Text(
                      "You have reached the maximum of $_maxPendingRequests pending requests. Please wait for approval or cancel an existing request.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        spacer(hasActiveRequests ? 24 : 0),
        SliverStaggerEntrance(
          sliver: SliverAnimatedContent(
            child: hasActiveRequests
                ? Align(
                    alignment: .centerLeft,
                    child: SectionTitle(title: "Pending requests"),
                  )
                : null,
          ),
        ),
        spacer(hasActiveRequests ? 8 : 0),
        AnimatedSliverList<UserJoinRequest>(
          items: activeRequests,
          identity: (item) => item.requestId,
          itemBuilder: (context, item) => _PendingJoinRequestTile(
            request: item,
            onCancel: () =>
                _cancelJoinRequest(context: context, ref: ref, request: item),
            onExpire: () => ref
                .read(userJoinRequestsProvider.notifier)
                .cleanupExpiredRequests(),
          ),
        ),
      ],
    );
  }

  Widget spacer(double height) => SliverAnimatedGap(extent: height);

  String _extractCode(String input) {
    final trimmedInput = input.trim();
    if (!trimmedInput.startsWith(_inviteLinkPrefix)) {
      return trimmedInput;
    }
    return trimmedInput.substring(_inviteLinkPrefix.length);
  }

  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter an invite URL or code.";
    }
    if (_extractCode(value).isEmpty) {
      return "Invalid invite URL or code.";
    }
    return null;
  }

  Future<void> _submitJoinRequest({
    required BuildContext context,
    required WidgetRef ref,
    required GlobalKey<FormState> formKey,
    required TextEditingController controller,
  }) async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    try {
      await ref
          .read(userJoinRequestsProvider.notifier)
          .requestToJoin(_extractCode(controller.text));
      controller.clear();
      if (!context.mounted) {
        return;
      }
      showSuccessSnackBar(context, "Join request submitted successfully.");
    } on Exception catch (error) {
      if (!context.mounted) {
        return;
      }
      showErrorSnackBar(context, "Failed to submit join request: $error");
    }
  }

  Future<void> _cancelJoinRequest({
    required BuildContext context,
    required WidgetRef ref,
    required UserJoinRequest request,
  }) async {
    final confirmed = await showConfirmationDialogue(
      context: context,
      title: "Cancel join request?",
      content:
          "Are you sure you want to cancel your request to join ${request.organizationName.formatted}?",
      confirmText: "Cancel Request",
      confirmIcon: Fa6Solid.xmark,
      onConfirm: () async {
        await ref
            .read(userJoinRequestsProvider.notifier)
            .cancelRequest(request.requestId);
      },
    );

    if (!confirmed || !context.mounted) {
      return;
    }
    showSuccessSnackBar(context, "Join request canceled.");
  }
}

/// Displays one pending request and exposes its cancellation operation.
///
/// The countdown only triggers local cleanup when expiry is reached. It does not
/// imply that the server request was cancelled.
class _PendingJoinRequestTile extends StatelessWidget {
  const _PendingJoinRequestTile({
    required this.request,
    required this.onCancel,
    required this.onExpire,
  });

  final UserJoinRequest request;
  final VoidCallback onCancel;
  final VoidCallback onExpire;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: context.shapes.mediumBorderRadius,
      ),
      child: ManagedActionSet(
        shortcuts: [
          ActionShortcut.intent(
            id: "revoke_join_request",
            label: "Revoke request",
            description: "Cancel the join request",
            intent: DeleteIntent,
            priority: 2,
            onInvoke: (_) => onCancel(),
          ),
        ],
        child: ManagedFocusHighlight(
          borderRadius: context.shapes.mediumBorderRadius,
          child: ListTile(
            leading: OrganizationLogo(
              logoUrl: request.organizationLogoUrl,
              size: 40,
            ),
            title: Text(request.organizationName.formatted),
            subtitle: Text(
              "Awaiting approval",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountdownBadge(endDate: request.expiresAt, onExpired: onExpire),
                SizedBox(width: context.spacing.space2),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onCancel,
                  tooltip: "Cancel request",
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
