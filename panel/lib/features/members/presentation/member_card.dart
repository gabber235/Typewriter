import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Responsive member row for touch layouts.
///
/// The collapsed header handles selection and keyboard actions. Expansion
/// reveals role editing and removal through the same repository commands as
/// the desktop table. Role choices use the observed catalog's assignable flag;
/// the server remains responsible for validating requested role changes.
class MemberTabletCard extends HookConsumerWidget {
  const MemberTabletCard({
    required this.member,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.hasSelection,
    required this.rows,
    required this.selectedIds,
    required this.nameOf,
    super.key,
  });

  final skir.OrganizationMember member;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool hasSelection;

  /// The members rows [MembersTab] owns; the remove hold sends and refuses
  /// on them.
  final AnimatedRows<Object?> rows;
  final Set<skir.RecordId> selectedIds;
  final String? Function(skir.RecordId member) nameOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final expansibleController = useExpansibleController();
    // One command for the card's key and its Remove button; it acts on the
    // selection when the selection contains this member.
    final removal = memberRemoval(
      id: "remove_member_key_${member.userId}",
      label: hasSelection && isSelected ? "Remove members" : "Remove member",
      targets: () => hasSelection && isSelected ? selectedIds : {member.userId},
      nameOf: nameOf,
      rows: rows,
    );

    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : Surface.colorOf(context);

    return Material(
      color: backgroundColor,
      borderRadius: context.shapes.mediumBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: Surface(
        color: backgroundColor,
        child: GrowingCard(
          controller: expansibleController,
          header: (context, animation) {
            return ManagedActionSet(
              shortcuts: [
                ActionShortcut.intent(
                  id: "select_member_${member.userId}",
                  label: "Select member",
                  description: "Toggle selection for this member",
                  intent: ActivateIntent,
                  priority: 1,
                  run: ActionRun.press((_) => onSelectionChanged(!isSelected)),
                ),
                ActionShortcut.intent(
                  id: "select_all_members_${member.userId}",
                  label: "Select all members",
                  description: "Select all visible members",
                  intent: ActivateAllIntent,
                  priority: 1,
                  run: ActionRun.press((_) => onSelectAll()),
                ),
                // Esc steps out one level: first the card, then the
                // selection.
                if (hasSelection && !expansibleController.isExpanded)
                  ActionShortcut.intent(
                    id: "clear_member_selection_${member.userId}",
                    label: "Clear selection",
                    description: "Clear selected members",
                    intent: DismissIntent,
                    priority: 1,
                    run: ActionRun.press((_) {
                      onClearSelection();
                    }),
                  ),
                ActionShortcut(
                  id: "expand_member_${member.userId}",
                  label: "Toggle details",
                  description: "Toggle member details",
                  activators: const [SingleActivator(LogicalKeyboardKey.space)],
                  priority: 1,
                  run: ActionRun.press((_) => expansibleController.toggle()),
                ),
                removal,
              ],
              // Inside the shortcuts, so they answer while the card is
              // focused. Enter opens the details, as the header did.
              child: RowStop(
                borderRadius: context.shapes.mediumBorderRadius,
                label: member.name ?? member.email ?? "Member",
                onActivate: expansibleController.toggle,
                // In a list the card is the stop; alone it is the header.
                child: ExcludeFocus(
                  excluding: RowEntryScope.maybeOf(context) != null,
                  child: Button(
                    face: ButtonFace.bare,
                    label: expansibleController.isExpanded
                        ? "Hide member details"
                        : "Show member details",
                    onPressed: expansibleController.toggle,
                    child: Padding(
                      padding: EdgeInsets.all(context.spacing.space3),
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
                          SizedBox(width: context.spacing.space3),
                          Expanded(
                            child: PersonSummary(
                              name: member.name,
                              email: member.email,
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
                ),
              ),
            );
          },
          // Part of the row, so focus in it still counts as the card.
          body: (context) {
            return RowStop(
              role: RowRole.part,
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
                    padding: EdgeInsets.all(context.spacing.space3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Roles",
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontVariations: [.weight(500)],
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                        ),
                        SizedBox(height: context.spacing.space2),
                        ref
                            .watch(organizationRolesProvider)
                            .when(
                              data: (allRoles) => RoleMultiselectChips(
                                availableRoles: allRoles,
                                selectedRoles: member.roles.toList(),
                                onRolesChanged: (newRoles) =>
                                    ref.assignMemberRoles(
                                      context,
                                      member.userId,
                                      newRoles,
                                    ),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                        SizedBox(height: context.spacing.space4),
                        SizedBox(
                          width: double.infinity,
                          child: CommandButton(
                            command: removal,
                            face: ButtonFace.outlined,
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              size: 18,
                            ),
                            label: "Remove member",
                            color: context.colors.dangerText,
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
}
