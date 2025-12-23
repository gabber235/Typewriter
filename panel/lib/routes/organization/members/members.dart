part of "route.dart";

class _MembersTab extends HookConsumerWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(organizationMembersProvider);
    final selectedIds = useState<Set<String>>({});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Text("Current Members", style: theme.textTheme.titleMedium),
              if (selectedIds.value.isNotEmpty)
                _BulkMemberActions(
                  selectedCount: selectedIds.value.length,
                  selectedIds: selectedIds.value,
                  onRemove: () async {
                    final confirmed = await showConfirmationDialogue(
                      context: context,
                      title: "Remove ${selectedIds.value.length} member(s)?",
                      content:
                          "Are you sure you want to remove these members from the organization?",
                      confirmText: "Remove",
                      confirmIcon: Fa6Solid.user_minus,
                      onConfirm: () async {
                        for (final id in selectedIds.value) {
                          await ref
                              .read(organizationMembersProvider.notifier)
                              .removeMember(id);
                        }
                        selectedIds.value = {};
                      },
                    );
                    if (!confirmed) return;
                  },
                  onClearSelection: () => selectedIds.value = {},
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        membersAsync(
          name: "Members",
          builder: (members) => context.isDesktop
              ? _MembersTable(members: members, selectedIds: selectedIds)
              : _MembersTabletList(members: members, selectedIds: selectedIds),
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
        ),
      ],
    );
  }
}

class _BulkMemberActions extends HookConsumerWidget {
  const _BulkMemberActions({
    required this.selectedCount,
    required this.selectedIds,
    required this.onRemove,
    required this.onClearSelection,
  });

  final int selectedCount;
  final Set<String> selectedIds;
  final VoidCallback onRemove;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bulkRoles = useState<List<MemberRole>>([]);

    final roleDropdown = _RoleMultiselectDropdown(
      selectedRoles: bulkRoles.value,
      onRolesChanged: (roles) => bulkRoles.value = roles,
      placeholder: "Assign roles",
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

        // Apply bulk roles button
        if (bulkRoles.value.isNotEmpty)
          FilledButton.icon(
            onPressed: () async {
              for (final id in selectedIds) {
                await ref
                    .read(organizationMembersProvider.notifier)
                    .updateMemberRoles(id, bulkRoles.value)
                    .catchApiExceptionsAndDisplay(context);
              }
              bulkRoles.value = [];
              onClearSelection();
            },
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
    );
  }
}

/// Row actions for a member (remove button).
class _MemberRowActions extends HookConsumerWidget {
  const _MemberRowActions({required this.member});

  final OrganizationMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRemoving = useState(false);

    if (isRemoving.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(
          Icons.person_remove_outlined,
          size: 20,
          color: theme.colorScheme.error,
        ),
        onPressed: () => _confirmRemoveMember(context, ref, isRemoving),
        tooltip: "Remove member",
      ),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRemoving,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Remove ${member.name}?",
      content:
          "Are you sure you want to remove this member from the organization?",
      confirmText: "Remove",
      confirmIcon: Fa6Solid.user_minus,
      onConfirm: () async {
        isRemoving.value = true;
        await ref
            .read(organizationMembersProvider.notifier)
            .removeMember(member.id);
      },
    );
  }
}

class _MembersTabletList extends HookConsumerWidget {
  const _MembersTabletList({required this.members, required this.selectedIds});

  final List<OrganizationMember> members;
  final ValueNotifier<Set<String>> selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (members.isEmpty) {
      return const EmptyState(
        icon: MaterialSymbols.groups_2_rounded,
        title: "No members yet",
        description: "Invite someone to get started!",
      );
    }

    final allSelected =
        members.isNotEmpty && selectedIds.value.length == members.length;
    final someSelected =
        selectedIds.value.isNotEmpty &&
        selectedIds.value.length < members.length;

    void handleSelectAll() {
      if (allSelected || someSelected) {
        selectedIds.value = {};
      } else {
        selectedIds.value = members.map((m) => m.id).toSet();
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: handleSelectAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected ? true : (someSelected ? null : false),
                  tristate: true,
                  onChanged: (_) => handleSelectAll(),
                ),
                Text(
                  "Select all",
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        ...members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return _MemberTabletCard(
            key: ValueKey(member.id),
            member: member,
            index: index,
            isSelected: selectedIds.value.contains(member.id),
            onSelectionChanged: (selected) {
              if (selected) {
                selectedIds.value = {...selectedIds.value, member.id};
              } else {
                selectedIds.value = selectedIds.value
                    .where((id) => id != member.id)
                    .toSet();
              }
            },
          );
        }),
      ],
    );
  }
}

class _MemberTabletCard extends HookConsumerWidget {
  const _MemberTabletCard({
    required this.member,
    required this.index,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final OrganizationMember member;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpanded = useState(false);
    final isRemoving = useState(false);

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      child: isRemoving.value
          ? const SizedBox.shrink()
          : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          )
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => isExpanded.value = !isExpanded.value,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => onSelectionChanged(!isSelected),
                                  child: _SelectableAvatar(
                                    avatarUrl:
                                        member.avatarUrl.nullIfEmpty ??
                                        "$userIconUrl&seed=${member.id}",
                                    isSelected: isSelected,
                                    radius: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        member.email,
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded.value
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: isExpanded.value
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      height: 1,
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Roles",
                                            style: TextStyle(
                                              fontVariations: [.weight(500)],
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ref
                                              .watch(organizationRolesProvider)
                                              .when(
                                                data: (allRoles) => RoleMultiselectChips(
                                                  availableRoles: allRoles,
                                                  selectedRoles: member.roles,
                                                  onRolesChanged: (newRoles) {
                                                    ref
                                                        .read(
                                                          organizationMembersProvider
                                                              .notifier,
                                                        )
                                                        .updateMemberRoles(
                                                          member.id,
                                                          newRoles,
                                                        )
                                                        .catchApiExceptionsAndDisplay(
                                                          context,
                                                        );
                                                  },
                                                ),
                                                loading: () =>
                                                    const SizedBox.shrink(),
                                                error: (_, _) =>
                                                    const SizedBox.shrink(),
                                              ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _confirmRemoveMember(
                                                    context,
                                                    ref,
                                                    isRemoving,
                                                  ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    theme.colorScheme.error,
                                                side: BorderSide(
                                                  color: theme.colorScheme.error
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.person_remove_outlined,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                "Remove Member",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(duration: 200.ms)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
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

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRemoving,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Remove ${member.name}?",
      content:
          "Are you sure you want to remove this member from the organization?",
      confirmText: "Remove",
      confirmIcon: Fa6Solid.user_minus,
      onConfirm: () async {
        isRemoving.value = true;
        onSelectionChanged(false);
        await ref
            .read(organizationMembersProvider.notifier)
            .removeMember(member.id);
      },
    );
  }
}
