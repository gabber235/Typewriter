part of "route.dart";

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
    final hasReachedLimit = activeRequests.length >= _maxPendingRequests;
    final animation = useAnimatedList(
      items: activeRequests,
      identity: (item) => item.requestId,
      removedItemBuilder: (context, item, animation) =>
          _child(context, item, ref, animation, ignorePointer: true),
    );

    Future<void> submitJoinRequest() => _submitJoinRequest(
      context: context,
      ref: ref,
      formKey: formKey,
      controller: controller,
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggerEntrance(
            child: Text(
              "Join organization",
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          StaggerEntrance(
            child: Text(
              "Enter an invite URL or code to request to join an organization.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          StaggerEntrance(
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    enabled: !hasReachedLimit,
                    decoration: const InputDecoration(
                      hintText: "Invite URL or code",
                    ),
                    validator: _validateInput,
                    onFieldSubmitted: hasReachedLimit
                        ? null
                        : (_) => submitJoinRequest(),
                  ),
                ),
                const SizedBox(width: 12),
                LoadingButton.filled(
                  onPressed: hasReachedLimit ? null : submitJoinRequest,
                  child: const Text("Join"),
                ),
              ],
            ),
          ),
          ElasticMessageSwitcher(
            child: hasReachedLimit
                ? StaggerEntrance(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
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
          if (activeRequests.isNotEmpty) ...[
            const SizedBox(height: 24),
            const StaggerEntrance(
              child: SectionTitle(title: "Pending requests"),
            ),
            const SizedBox(height: 8),
            AnimatedList(
              key: animation.key,
              shrinkWrap: true,
              initialItemCount: animation.items.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index, animation) =>
                  _child(context, activeRequests[index], ref, animation),
            ),
          ],
        ],
      ),
    );
  }

  Widget _child(
    BuildContext context,
    UserJoinRequest item,
    WidgetRef ref,
    Animation<double> animation, {
    bool ignorePointer = false,
  }) {
    return IgnorePointer(
      key: ValueKey(item.organizationId),
      ignoring: ignorePointer,
      child: ElasticTransition(
        animation: animation,
        child: StaggerEntrance(
          child: _PendingJoinRequestTile(
            request: item,
            onCancel: () =>
                _cancelJoinRequest(context: context, ref: ref, request: item),
          ),
        ),
      ),
    );
  }

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

class _PendingJoinRequestTile extends StatelessWidget {
  const _PendingJoinRequestTile({
    required this.request,
    required this.onCancel,
  });

  final UserJoinRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            CountdownBadge(endDate: request.expiresAt),
            const SizedBox(width: 8),
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
    );
  }
}
