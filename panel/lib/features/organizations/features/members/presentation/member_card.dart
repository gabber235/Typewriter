import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_constants.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/role_multiselect_chips.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/selectable_avatar.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/async.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class MemberTabletCard extends HookConsumerWidget {
  const MemberTabletCard({
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
                        : Surface.colorOf(context),
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
                                  child: SelectableAvatar(
                                    avatarUrl:
                                        member.avatarUrl?.nullIfEmpty ??
                                        "$userIconUrl&seed=${member.userId}",
                                    isSelected: isSelected,
                                    radius: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 2,
                                    children: [
                                      if (member.name != null)
                                        Text(
                                          member.name!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      if (member.email != null)
                                        Text(
                                          member.email!,
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
                                                          member.userId,
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
            .removeMember(member.userId);
      },
    );
  }
}
