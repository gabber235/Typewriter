import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class MemberTabletCard extends HookConsumerWidget {
  const MemberTabletCard({
    required this.member,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.hasSelection,
    required this.onRemoveSelection,
    super.key,
  });

  final OrganizationMember member;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool hasSelection;
  final Future<void> Function() onRemoveSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final expansibleController = useExpansibleController();

    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
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
            return ManagedActionSet(
              shortcuts: [
                ActionShortcut.intent(
                  id: "select_member_${member.userId}",
                  label: "Select member",
                  description: "Toggle selection for this member",
                  intent: ActivateIntent,
                  priority: 1,
                  onInvoke: (_) => onSelectionChanged(!isSelected),
                ),
                ActionShortcut.intent(
                  id: "select_all_members_${member.userId}",
                  label: "Select all members",
                  description: "Select all visible members",
                  intent: ActivateAllIntent,
                  priority: 1,
                  onInvoke: (_) => onSelectAll(),
                ),
                if (hasSelection)
                  ActionShortcut.intent(
                    id: "clear_member_selection_${member.userId}",
                    label: "Clear selection",
                    description: "Clear selected members",
                    intent: DismissIntent,
                    priority: 1,
                    onInvoke: (_) {
                      onClearSelection();
                    },
                  ),
                ActionShortcut(
                  id: "expand_member_${member.userId}",
                  label: "Toggle details",
                  description: "Toggle member details",
                  activators: const [SingleActivator(LogicalKeyboardKey.space)],
                  priority: 1,
                  onInvoke: (_) => expansibleController.toggle(),
                ),
                ActionShortcut.intent(
                  id: "remove_member_key_${member.userId}",
                  label: "Remove member",
                  description: "Remove this member",
                  intent: DeleteIntent,
                  priority: 1,
                  onInvoke: (_) => hasSelection && isSelected
                      ? onRemoveSelection()
                      : _confirmRemoveMember(context, ref),
                ),
              ],
              child: InkWell(
                onTap: expansibleController.toggle,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      RotationTransition(
                        turns: Tween<double>(
                          begin: 0.0,
                          end: 0.5,
                        ).animate(animation),
                        child: Icon(
                          Icons.expand_less_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          bodyBuilder: (context, animation) {
            return ElasticMessageTransition(
              animation: animation,
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Roles",
                          style: TextStyle(
                            fontVariations: [.weight(500)],
                            color: theme.colorScheme.onSurfaceVariant,
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
                                        organizationMembersProvider.notifier,
                                      )
                                      .updateMemberRoles(
                                        member.userId,
                                        newRoles,
                                      )
                                      .catchApiExceptionsAndDisplay(context);
                                },
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmRemoveMember(context, ref),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              size: 18,
                            ),
                            label: const Text("Remove Member"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmRemoveMember(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Remove ${member.name}?",
      content:
          "Are you sure you want to remove this member from the organization?",
      confirmText: "Remove",
      confirmIcon: Fa6Solid.user_minus,
      onConfirm: () async {
        onSelectionChanged(false);
        await ref
            .read(organizationMembersProvider.notifier)
            .removeMember(member.userId);
      },
    );
  }
}
