import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:duration/duration.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/bi.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/app/presentation/shell/sidebar.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/app/presentation/shortcuts/shortcuts.dart";
import "package:typewriter_panel/features/organizations/organizations.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as skir;
import "package:typewriter_panel/shared/ui/components/blur_reveal.dart";
import "package:typewriter_panel/shared/ui/components/content_size_tab_bar_view.dart";
import "package:typewriter_panel/shared/ui/components/countdown_badge.dart";
import "package:typewriter_panel/shared/ui/components/empty_state.dart";
import "package:typewriter_panel/shared/ui/components/focus_highlight.dart";
import "package:typewriter_panel/shared/ui/components/loading_button.dart";
import "package:typewriter_panel/shared/ui/components/loading_indicator.dart";
import "package:typewriter_panel/shared/ui/components/multiselect_dropdown.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/ui/components/secret_field.dart";
import "package:typewriter_panel/shared/ui/components/section.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/ui/screens/error_screen.dart";
import "package:typewriter_panel/shared/utilities/async.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

part "join_codes.dart";
part "join_requests.dart";
part "members.dart";

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
                    "Manage who can access and edit content in your organization. Invite team members by creating join codes or approving incoming requests, and assign roles to control what each person can view or modify across your books and realms.",
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

    return Surface(
      color: Surface.colorOf(context),
      child: Material(
        color: Colors.transparent,
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
      ),
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
  final ValueNotifier<Set<skir.RecordId>> selectedIds;

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

    return Surface(
      color: Surface.colorOf(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
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
              decoration: BoxDecoration(color: Surface.colorOf(context)),
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
                          selectedIds.value = members
                              .map((m) => m.userId)
                              .toSet();
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
                selectedIds.value.contains(member.userId),
                focusedRowIndex,
                theme,
              ),
          ],
        ),
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
      key: ValueKey(member.userId),
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
                        .where((id) => id != member.userId)
                        .toSet();
                  } else {
                    selectedIds.value = {...selectedIds.value, member.userId};
                  }
                },
                child: _SelectableAvatar(
                  avatarUrl:
                      member.avatarUrl?.nullIfEmpty ??
                      "$userIconUrl&seed=${member.userId}",
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
                      .where((id) => id != member.userId)
                      .toSet();
                } else {
                  selectedIds.value = {...selectedIds.value, member.userId};
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
                    if (member.name != null)
                      Text(
                        member.name!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (member.email != null)
                      BlurReveal(
                        blurSigma: 3,
                        child: Text(
                          member.email!,
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
                    .updateMemberRoles(member.userId, newRoles)
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

  final List<OrganizationRole> selectedRoles;
  final ValueChanged<List<OrganizationRole>> onRolesChanged;
  final String? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(organizationRolesProvider);
    final focusNode = useFocusNode();
    return rolesAsync(
      name: "Roles",
      builder: (availableRoles) {
        return MultiselectDropdown<OrganizationRole>(
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
                      selectedRoles
                          .where((r) => r.roleId != role.roleId)
                          .toList(),
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

  Widget _roleMenuEntry(BuildContext context, OrganizationRole role) {
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
