import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/utils/async.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/organization/members/role_multiselect_chips.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";
import "package:typewriter_panel/widgets/generic/components/blur_reveal.dart";
import "package:typewriter_panel/widgets/generic/components/contentsize_tabbarview.dart";
import "package:typewriter_panel/widgets/generic/components/countdown_badge.dart";
import "package:typewriter_panel/widgets/generic/components/empty_state.dart";
import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/loading_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/multiselect_dropdown.dart";
import "package:typewriter_panel/widgets/generic/components/page_heading.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";
import "package:typewriter_panel/widgets/generic/components/secret_field.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

@RoutePage()
class MembersPage extends HookConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3);
    final scrollController = useScrollController();
    final joinRequestCount = ref.watch(joinRequestCountProvider);
    final joinCodeCount = ref.watch(joinCodeCountProvider);

    final paddingAmount = context.responsive(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Pane(
      id: "members",
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.only(
        top: 8,
        left: 8,
        right: context.isDesktop ? 0 : 8,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeading(
                title: "Organization Members",
                subtext:
                    "Manage who has access to your organization. Invite new members and approve requests.",
                padding: EdgeInsets.all(paddingAmount),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: paddingAmount,
                  vertical: 8,
                ),
                child: _MembersTabBar(
                  controller: tabController,
                  joinRequestCount: joinRequestCount,
                  joinCodeCount: joinCodeCount,
                ),
              ),
              ContentSizeTabBarView(
                controller: tabController,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingAmount),
                    child: _MembersTab(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingAmount),
                    child: _JoinRequestsTab(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingAmount),
                    child: _JoinCodesTab(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersTabBar extends HookWidget {
  const _MembersTabBar({
    required this.controller,
    required this.joinRequestCount,
    required this.joinCodeCount,
  });

  final TabController controller;
  final int joinRequestCount;
  final int joinCodeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFocus = useState(false);

    final showCount = context.responsive(mobile: false, tablet: true);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: StadiumBorder(
        side: FocusHighlight.focusBorder(
          context,
          hasFocus.value ? FocusType.focus : FocusType.none,
        ),
      ),
      animationDuration: 200.ms,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: TabBar(
          controller: controller,
          onFocusChange: (focused, index) => hasFocus.value = focused,
          tabs: [
            const Tab(text: "Members"),
            Tab(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Join Requests"),
                    if (joinRequestCount > 0 && showCount)
                      TextSpan(
                        text: " [$joinRequestCount]",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Tab(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Active Links"),
                    if (joinCodeCount > 0 && showCount)
                      TextSpan(
                        text: " [$joinCodeCount]",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SelectedChip extends HookWidget {
  const _SelectedChip({
    required this.selectedCount,
    required this.onClearSelection,
  });

  final int selectedCount;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusNode = useFocusNode();

    return Chip(
      focusNode: focusNode,
      label: Text(
        "$selectedCount selected",
        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      ),
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.4,
      ),
      deleteIconColor: theme.colorScheme.onPrimaryContainer,
      onDeleted: onClearSelection,
      deleteButtonTooltipMessage: "Unselect all",
      side: FocusHighlight.stateBorder(
        context,
        focusColor: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _MembersTable extends HookConsumerWidget {
  const _MembersTable({required this.members, required this.selectedIds});

  final List<OrganizationMember> members;
  final ValueNotifier<Set<String>> selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final focusedRowIndex = useState(-1);

    if (members.isEmpty) {
      return EmptyState(
        title: "No members yet",
        description: "Invite someone to get started!",
        icon: MaterialSymbols.groups_2_rounded,
      );
    }

    final allSelected =
        members.isNotEmpty && selectedIds.value.length == members.length;
    final someSelected =
        selectedIds.value.isNotEmpty &&
        selectedIds.value.length < members.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(48),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(1),
          3: FixedColumnWidth(80),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (value) {
                      if (allSelected || someSelected) {
                        selectedIds.value = {};
                      } else {
                        selectedIds.value = members.map((m) => m.id).toSet();
                      }
                    },
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Member",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Roles",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const TableCell(child: SizedBox.shrink()),
            ],
          ),
          for (final (index, member) in members.indexed)
            _buildMemberRow(
              context,
              ref,
              member,
              index,
              selectedIds.value.contains(member.id),
              focusedRowIndex,
              theme,
            ),
        ],
      ),
    );
  }

  TableRow _buildMemberRow(
    BuildContext context,
    WidgetRef ref,
    OrganizationMember member,
    int index,
    bool isSelected,
    ValueNotifier<int> focusedRowIndex,
    ThemeData theme,
  ) {
    final isFocused = focusedRowIndex.value == index;
    return TableRow(
      key: ValueKey(member.id),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(
                alpha: isFocused ? 0.24 : 0.12,
              )
            : isFocused
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Material(
              color: Colors.transparent,
              shape: CircleBorder(),
              child: InkWell(
                customBorder: CircleBorder(),
                onFocusChange: (focused) {
                  focusedRowIndex.value = focused ? index : -1;
                },
                onTap: () {
                  if (isSelected) {
                    selectedIds.value = selectedIds.value
                        .where((id) => id != member.id)
                        .toSet();
                  } else {
                    selectedIds.value = {...selectedIds.value, member.id};
                  }
                },
                child: _SelectableAvatar(
                  avatarUrl:
                      member.avatarUrl.nullIfEmpty ??
                      "$userIconUrl&seed=${member.id}",
                  isSelected: isSelected,
                  radius: 16,
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onFocusChange: (focused) {
                focusedRowIndex.value = focused ? index : -1;
              },
              onTap: () {
                if (isSelected) {
                  selectedIds.value = selectedIds.value
                      .where((id) => id != member.id)
                      .toSet();
                } else {
                  selectedIds.value = {...selectedIds.value, member.id};
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    BlurReveal(
                      blurSigma: 3,
                      child: Text(
                        member.email,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _RoleMultiselectDropdown(
              selectedRoles: member.roles,
              onRolesChanged: (newRoles) {
                ref
                    .read(organizationMembersProvider.notifier)
                    .updateMemberRoles(member.id, newRoles)
                    .catchApiExceptionsAndDisplay(context);
              },
              placeholder: "Select roles",
            ),
          ),
        ),
        TableCell(child: _MemberRowActions(member: member)),
      ],
    );
  }
}

class _RoleMultiselectDropdown extends HookConsumerWidget {
  const _RoleMultiselectDropdown({
    required this.selectedRoles,
    required this.onRolesChanged,
    required this.placeholder,
  });

  final List<MemberRole> selectedRoles;
  final ValueChanged<List<MemberRole>> onRolesChanged;
  final String? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(organizationRolesProvider);
    final focusNode = useFocusNode();
    return rolesAsync(
      name: "Roles",
      builder: (availableRoles) {
        return MultiselectDropdown<MemberRole>(
          focusNode: focusNode,
          dropdownMenuEntries: [
            for (final role in availableRoles)
              DropdownMenuEntry(
                value: role,
                label: role.name,
                labelWidget: _roleMenuEntry(context, role),
                enabled: role.assignable,
              ),
          ],
          selectedItems: selectedRoles,
          onSelectionChanged: onRolesChanged,
          placeholder: placeholder,
          itemBuilder: (role) => SmallChip(
            label: role.name,
            color: role.color,
            onDelete: role.assignable
                ? () {
                    onRolesChanged(
                      selectedRoles.where((r) => r.id != role.id).toList(),
                    );
                  }
                : null,
          ),
        );
      },
      loading: (_) => ShimmerBox.stadium(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _roleMenuEntry(BuildContext context, MemberRole role) {
    final isSelected = selectedRoles.contains(role);
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: role.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(role.name),
        const Spacer(),
        if (isSelected)
          Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
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
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainer;

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

class _SelectableAvatar extends StatelessWidget {
  const _SelectableAvatar({
    required this.avatarUrl,
    required this.isSelected,
    this.radius = 24,
  });

  final String avatarUrl;
  final bool isSelected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundImage: isSelected ? null : NetworkImage(avatarUrl),
      backgroundColor: isSelected
          ? Colors.green
          : theme.inputDecorationTheme.fillColor,
      child: isSelected
          ? Icon(Icons.check, color: Colors.white, size: radius)
          : null,
    );
  }
}

class _JoinCodesTab extends HookConsumerWidget {
  const _JoinCodesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codesAsync = ref.watch(organizationJoinCodesProvider);
    final selectedCodes = useState<Set<String>>({});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SecretField(
              title: "Invite Link",
              description:
                  "Generate a unique link to invite new members to your organization. The link automatically expires for security reasons.",
              prefix: "https://panel.typewritermc.com/join/",
              onGenerate: () =>
                  ref.read(organizationProvider.notifier).generateInviteLink(),
              generateButtonText: "Generate Link",
              regenerateButtonText: "New Link",
              copyButtonText: "Copy Link",
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Text("Active Links", style: theme.textTheme.titleMedium),
              if (selectedCodes.value.isNotEmpty)
                _BulkJoinCodeActions(
                  selectedCount: selectedCodes.value.length,
                  selectedCodes: selectedCodes.value,
                  onClearSelection: () => selectedCodes.value = {},
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        codesAsync(
          name: "Join Codes",
          builder: (codes) => context.isDesktop
              ? _JoinCodesTable(codes: codes, selectedCodes: selectedCodes)
              : _JoinCodesCardList(codes: codes, selectedCodes: selectedCodes),
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

class _BulkJoinCodeActions extends HookConsumerWidget {
  const _BulkJoinCodeActions({
    required this.selectedCount,
    required this.selectedCodes,
    required this.onClearSelection,
  });

  final int selectedCount;
  final Set<String> selectedCodes;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        _SelectedChip(
          selectedCount: selectedCount,
          onClearSelection: onClearSelection,
        ),
        LoadingButton.outlinedIcon(
          onPressed: () => _confirmBulkRevoke(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          icon: const Icon(Icons.link_off, size: 18),
          label: const Text("Revoke All"),
        ),
      ],
    );
  }

  Future<void> _confirmBulkRevoke(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke $selectedCount link(s)?",
      content:
          "Are you sure you want to revoke these invite links? They will no longer work.",
      confirmText: "Revoke All",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        for (final code in selectedCodes) {
          await ref
              .read(organizationJoinCodesProvider.notifier)
              .revokeCode(code);
        }
        onClearSelection();
      },
    );
  }
}

class _JoinCodesTable extends HookConsumerWidget {
  const _JoinCodesTable({required this.codes, required this.selectedCodes});

  final List<JoinCode> codes;
  final ValueNotifier<Set<String>> selectedCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusedRowIndex = useState(-1);

    if (codes.isEmpty) {
      return const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active invite links",
        description: "Generate an invite link above to get started!",
      );
    }

    final allSelected =
        codes.isNotEmpty && selectedCodes.value.length == codes.length;
    final someSelected =
        selectedCodes.value.isNotEmpty &&
        selectedCodes.value.length < codes.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(48),
          1: FlexColumnWidth(2),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
          4: FixedColumnWidth(80),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (value) {
                      if (allSelected || someSelected) {
                        selectedCodes.value = {};
                      } else {
                        selectedCodes.value = codes.map((c) => c.code).toSet();
                      }
                    },
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Invite Link",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Created",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    "Expires",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const TableCell(child: SizedBox.shrink()),
            ],
          ),
          for (final (index, code) in codes.indexed)
            _buildCodeRow(
              context,
              ref,
              code,
              index,
              selectedCodes.value.contains(code.code),
              focusedRowIndex,
              theme,
            ),
        ],
      ),
    );
  }

  TableRow _buildCodeRow(
    BuildContext context,
    WidgetRef ref,
    JoinCode code,
    int index,
    bool isSelected,
    ValueNotifier<int> focusedRowIndex,
    ThemeData theme,
  ) {
    final isFocused = focusedRowIndex.value == index;
    final fullUrl = "https://panel.typewritermc.com/join/${code.code}";

    return TableRow(
      key: ValueKey(code.code),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(
                alpha: isFocused ? 0.24 : 0.12,
              )
            : isFocused
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                if (isSelected) {
                  selectedCodes.value = selectedCodes.value
                      .where((c) => c != code.code)
                      .toSet();
                } else {
                  selectedCodes.value = {...selectedCodes.value, code.code};
                }
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: BlurReveal(
                    blurSigma: 3,
                    child: SelectableText(
                      fullUrl,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyToClipboard(context, fullUrl),
                  tooltip: "Copy link",
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              _formatDate(code.createdAt),
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: CountdownBadge(
              endDate: code.expiresAt,
              onExpired: () => ref.invalidate(organizationJoinCodesProvider),
            ),
          ),
        ),
        TableCell(child: _JoinCodeRowActions(code: code)),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Link copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return "Today";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} days ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}

class _JoinCodeRowActions extends HookConsumerWidget {
  const _JoinCodeRowActions({required this.code});

  final JoinCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRevoking = useState(false);

    if (isRevoking.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(Icons.link_off, size: 20, color: theme.colorScheme.error),
        onPressed: () => _confirmRevokeCode(context, ref, isRevoking),
        tooltip: "Revoke link",
      ),
    );
  }

  Future<void> _confirmRevokeCode(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRevoking,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this invite link?",
      content:
          "Are you sure you want to revoke this link? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        isRevoking.value = true;
        await ref
            .read(organizationJoinCodesProvider.notifier)
            .revokeCode(code.code);
      },
    );
  }
}

class _JoinCodesCardList extends HookConsumerWidget {
  const _JoinCodesCardList({required this.codes, required this.selectedCodes});

  final List<JoinCode> codes;
  final ValueNotifier<Set<String>> selectedCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (codes.isEmpty) {
      return const EmptyState(
        icon: MaterialSymbols.link_off_rounded,
        title: "No active invite links",
        description: "Generate an invite link above to get started!",
      );
    }

    final allSelected =
        codes.isNotEmpty && selectedCodes.value.length == codes.length;
    final someSelected =
        selectedCodes.value.isNotEmpty &&
        selectedCodes.value.length < codes.length;

    void handleSelectAll() {
      if (allSelected || someSelected) {
        selectedCodes.value = {};
      } else {
        selectedCodes.value = codes.map((c) => c.code).toSet();
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
        ...codes.asMap().entries.map((entry) {
          final index = entry.key;
          final code = entry.value;
          return _JoinCodeCard(
            key: ValueKey(code.code),
            code: code,
            index: index,
            isSelected: selectedCodes.value.contains(code.code),
            onSelectionChanged: (selected) {
              if (selected) {
                selectedCodes.value = {...selectedCodes.value, code.code};
              } else {
                selectedCodes.value = selectedCodes.value
                    .where((c) => c != code.code)
                    .toSet();
              }
            },
          );
        }),
      ],
    );
  }
}

class _JoinCodeCard extends HookConsumerWidget {
  const _JoinCodeCard({
    required this.code,
    required this.index,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final JoinCode code;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpanded = useState(false);
    final isRevoking = useState(false);
    final fullUrl = "https://panel.typewritermc.com/join/${code.code}";

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      child: isRevoking.value
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
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green
                                          : theme.colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSelected ? Icons.check : Icons.link,
                                      color: isSelected
                                          ? Colors.white
                                          : theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BlurReveal(
                                        blurSigma: 3,
                                        child: Text(
                                          fullUrl,
                                          style: TextStyle(
                                            fontFamily: "monospace",
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CountdownBadge(
                                        endDate: code.expiresAt,
                                        onExpired: () => ref.invalidate(
                                          organizationJoinCodesProvider,
                                        ),
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
                                            "Created: ${_formatDate(code.createdAt)}",
                                            style: TextStyle(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _copyToClipboard(
                                                        context,
                                                        fullUrl,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.copy,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    "Copy Link",
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _confirmRevokeCode(
                                                        context,
                                                        ref,
                                                        isRevoking,
                                                      ),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        foregroundColor: theme
                                                            .colorScheme
                                                            .error,
                                                        side: BorderSide(
                                                          color: theme
                                                              .colorScheme
                                                              .error
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                        ),
                                                      ),
                                                  icon: const Icon(
                                                    Icons.link_off,
                                                    size: 18,
                                                  ),
                                                  label: const Text("Revoke"),
                                                ),
                                              ),
                                            ],
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

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Link copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return "Today";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} days ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  Future<void> _confirmRevokeCode(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRevoking,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this invite link?",
      content:
          "Are you sure you want to revoke this link? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        isRevoking.value = true;
        onSelectionChanged(false);
        await ref
            .read(organizationJoinCodesProvider.notifier)
            .revokeCode(code.code);
      },
    );
  }
}
