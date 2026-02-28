part of "route.dart";

class _JoinRequestsTab extends HookConsumerWidget {
  const _JoinRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(organizationJoinRequestsProvider);

    return requestsAsync(
      name: "Join Requests",
      shrink: true,
      builder: (requests) => _JoinRequestsList(requests: requests),
      loading: (name) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LoadingIndicator(message: "Loading $name..."),
        ),
      ),
      error: (title, message) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ErrorScreen.small(title: title, message: message),
          ),
        ),
      ),
    );
  }
}

class _JoinRequestsList extends HookConsumerWidget {
  const _JoinRequestsList({required this.requests});

  final List<JoinRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = useState<Set<String>>({});
    final theme = Theme.of(context);

    if (requests.isEmpty) {
      return EmptyState(
        icon: Fa6Solid.user_plus,
        title: "No join requests",
        description: "When members request to join, they will appear here.",
      );
    }

    final allSelected =
        requests.isNotEmpty && selectedIds.value.length == requests.length;
    final someSelected =
        selectedIds.value.isNotEmpty &&
        selectedIds.value.length < requests.length;

    void handleSelectAll() {
      if (allSelected || someSelected) {
        selectedIds.value = {};
      } else {
        selectedIds.value = requests.map((r) => r.id).toSet();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          direction: .horizontal,
          alignment: .spaceBetween,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: handleSelectAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (value) => handleSelectAll(),
                  ),
                  Text(
                    "Select all",
                    style: TextStyle(
                      fontVariations: [.weight(500)],
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedIds.value.isNotEmpty)
              _BulkJoinRequestActions(
                selectedCount: selectedIds.value.length,
                selectedIds: selectedIds.value,
                onClearSelection: () => selectedIds.value = {},
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...requests.asMap().entries.map((entry) {
          final index = entry.key;
          final request = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _JoinRequestCard(
              key: ValueKey(request.id),
              request: request,
              index: index,
              isSelected: selectedIds.value.contains(request.id),
              onSelectionChanged: (selected) {
                if (selected) {
                  selectedIds.value = {...selectedIds.value, request.id};
                } else {
                  selectedIds.value = selectedIds.value
                      .where((id) => id != request.id)
                      .toSet();
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class _BulkJoinRequestActions extends HookConsumerWidget {
  const _BulkJoinRequestActions({
    required this.selectedCount,
    required this.selectedIds,
    required this.onClearSelection,
  });

  final int selectedCount;
  final Set<String> selectedIds;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bulkRoles = useState<List<MemberRole>>([]);

    final roleDropdown = _RoleMultiselectDropdown(
      selectedRoles: bulkRoles.value,
      onRolesChanged: (roles) => bulkRoles.value = roles,
      placeholder: "Select roles",
    );

    return Flex(
      direction: context.responsive(
        mobile: Axis.vertical,
        tablet: Axis.horizontal,
      ),
      spacing: 4,
      crossAxisAlignment: context.responsive(
        mobile: CrossAxisAlignment.start,
        tablet: CrossAxisAlignment.center,
      ),
      children: [
        _SelectedChip(
          selectedCount: selectedCount,
          onClearSelection: onClearSelection,
        ),
        if (context.isMobile) roleDropdown else Flexible(child: roleDropdown),
        // Bulk accept button
        LoadingButton.filledIcon(
          onPressed: bulkRoles.value.isEmpty
              ? null
              : () async {
                  for (final id in selectedIds) {
                    await ref
                        .read(organizationJoinRequestsProvider.notifier)
                        .approveRequest(id, bulkRoles.value);
                  }
                  bulkRoles.value = [];
                  onClearSelection();
                },
          icon: const Icon(Icons.check, size: 18),
          label: const Text("Accept All"),
        ),
        LoadingButton.outlinedIcon(
          onPressed: () => _confirmBulkDecline(context, ref),
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
    );
  }

  Future<void> _confirmBulkDecline(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Decline $selectedCount request(s)?",
      content: "Are you sure you want to decline these join requests?",
      confirmText: "Decline All",
      confirmIcon: Fa6Solid.xmark,
      onConfirm: () async {
        for (final id in selectedIds) {
          await ref
              .read(organizationJoinRequestsProvider.notifier)
              .declineRequest(id);
        }
        onClearSelection();
      },
    );
  }
}

class _JoinRequestCard extends HookConsumerWidget {
  const _JoinRequestCard({
    required this.request,
    required this.index,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final JoinRequest request;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedRoles = useState<List<MemberRole>>([]);
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
                    _buildExpandedSection(
                      context,
                      ref,
                      theme,
                      isExpanded,
                      backgroundColor,
                      isRemoving,
                      selectedRoles,
                      rolesAsync,
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
        ActionShortcut(
          id: "decline_${request.id}",
          label: "Decline",
          description: "Decline this join request",
          activators: shortcutsFor(DeleteIntent),
          priority: 1,
          onInvoke: (ref) async {
            await _confirmDeclineRequest(context, ref, isRemoving);
          },
        ),
        ActionShortcut(
          id: "accept_${request.id}",
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
                : _buildTabletLayout(
                    context,
                    ref,
                    theme,
                    isExpanded,
                    isRemoving,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ValueNotifier<bool> isExpanded,
    Color backgroundColor,
    ValueNotifier<bool> isRemoving,
    ValueNotifier<List<MemberRole>> selectedRoles,
    AsyncValue<List<MemberRole>> rolesAsync,
  ) {
    Future<void> confirmAddMember() async {
      isRemoving.value = true;
      onSelectionChanged(false);
      await ref
          .read(organizationJoinRequestsProvider.notifier)
          .approveRequest(request.id, selectedRoles.value);
    }

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      alignment: Alignment.topLeft,
      child: isExpanded.value
          ? Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              child: ManagedActionSet(
                shortcuts: [
                  if (selectedRoles.value.isNotEmpty)
                    ActionShortcut(
                      id: "confirm_${request.id}",
                      label: "Confirm",
                      description: "Confirm adding member",
                      activators: const [
                        SingleActivator(
                          LogicalKeyboardKey.enter,
                          control: true,
                        ),
                        SingleActivator(LogicalKeyboardKey.enter, meta: true),
                      ],
                      priority: 1,
                      onInvoke: (ref) => confirmAddMember(),
                    ),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select roles for this member:",
                            style: TextStyle(
                              fontVariations: [.weight(500)],
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          rolesAsync(
                            name: "Roles",
                            shrink: true,
                            builder: (roles) => RoleMultiselectChips(
                              availableRoles: roles,
                              selectedRoles: selectedRoles.value,
                              onRolesChanged: (newRoles) {
                                selectedRoles.value = newRoles;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              LoadingButton.filledIcon(
                                onPressed: selectedRoles.value.isEmpty
                                    ? null
                                    : confirmAddMember,
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text("Confirm & Add Member"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 200.ms),
              ),
            )
          : const SizedBox.shrink(),
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
        _SelectableAvatar(
          avatarUrl:
              request.userAvatarUrl.nullIfEmpty ??
              "$userIconUrl&seed=${request.userId}",
          isSelected: isSelected,
          radius: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.userName,
                style: const TextStyle(
                  fontVariations: [.weight(600)],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                request.userEmail,
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

  Widget _buildTabletLayout(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ValueNotifier<bool> isExpanded,
    ValueNotifier<bool> isRemoving,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SelectableAvatar(
              avatarUrl:
                  request.userAvatarUrl.nullIfEmpty ??
                  "$userIconUrl&seed=${request.userId}",
              isSelected: isSelected,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.userName,
                    style: const TextStyle(
                      fontVariations: [.weight(600)],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.userEmail,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CountdownBadge(
              endDate: request.expiresAt,
              onExpired: () => isRemoving.value = true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    _confirmDeclineRequest(context, ref, isRemoving),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text("Decline"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  isExpanded.value = !isExpanded.value;
                },
                child: Text(isExpanded.value ? "Cancel" : "Accept"),
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
            .declineRequest(request.id);
      },
    );
  }
}
