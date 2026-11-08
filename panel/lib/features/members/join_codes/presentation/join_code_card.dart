import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Expandable mobile card for one invitation code.
///
/// The code URL is deliberately blurred until the user chooses to copy or
/// inspect it. Selection belongs to the route. Revoking holds, over the
/// selection when it contains this code.
class JoinCodeCard extends HookConsumerWidget {
  const JoinCodeCard({
    required this.code,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.hasSelection,
    required this.rows,
    required this.selectedIds,
    super.key,
  });

  final skir.JoinCode code;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool hasSelection;

  /// The join code rows the tab owns.
  final AnimatedRows<Object?> rows;
  final Set<skir.RecordId> selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expansibleController = useExpansibleController();
    final fullUrl = joinCodeUrl(code.code);
    // One command for the card's key and its Revoke button.
    final revocation = joinCodeRevocation(
      id: "revoke_join_code_key_${code.code}",
      label: hasSelection && isSelected
          ? "Revoke join codes"
          : "Revoke join code",
      targets: () => hasSelection && isSelected ? selectedIds : {code.code},
      rows: rows,
    );

    useListenable(expansibleController);

    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : expansibleController.isExpanded
        ? theme.cardColor
        : Surface.colorOf(context);

    return Material(
      color: backgroundColor,
      borderRadius: context.shapes.mediumBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: Surface(
        color: backgroundColor,
        child: GrowingCard(
          controller: expansibleController,
          header: (context, animation) => ManagedActionSet(
            shortcuts: [
              ActionShortcut.intent(
                id: "select_join_code_${code.code}",
                label: "Select join code",
                description: "Toggle selection for this join code",
                intent: ActivateIntent,
                priority: 1,
                run: ActionRun.press((_) => onSelectionChanged(!isSelected)),
              ),
              ActionShortcut.intent(
                id: "select_all_join_codes_${code.code}",
                label: "Select all join codes",
                description: "Select all visible join codes",
                intent: ActivateAllIntent,
                priority: 1,
                run: ActionRun.press((_) => onSelectAll()),
              ),
              // Esc steps out one level: first the card, then the selection.
              if (!expansibleController.isExpanded)
                ActionShortcut.intent(
                  id: "clear_join_code_selection_${code.code}",
                  label: "Clear selection",
                  description: "Clear selected join codes",
                  intent: DismissIntent,
                  priority: 1,
                  run: ActionRun.press((_) => onClearSelection()),
                ),
              if (!hasSelection)
                ActionShortcut(
                  id: "copy_join_code_${code.code}",
                  label: "Copy join code",
                  description: "Copy this join code",
                  activators: const [SingleActivator(LogicalKeyboardKey.keyC)],
                  priority: 1,
                  run: ActionRun.press(
                    (_) => _copyToClipboard(context, fullUrl),
                  ),
                ),
              revocation,
            ],
            // Inside the shortcuts, so they answer while the card is
            // focused. Enter opens the details, as the header did.
            child: RowStop(
              borderRadius: context.shapes.mediumBorderRadius,
              label: fullUrl,
              onActivate: expansibleController.toggle,
              // In a list the card is the stop; alone it is the header.
              child: ExcludeFocus(
                excluding: RowEntryScope.maybeOf(context) != null,
                child: Button(
                  face: ButtonFace.bare,
                  label: expansibleController.isExpanded
                      ? "Hide join code details"
                      : "Show join code details",
                  onPressed: expansibleController.toggle,
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.space3),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => onSelectionChanged(!isSelected),
                          child: CircleAvatar(
                            backgroundColor: isSelected
                                ? context.colors.success
                                : theme.colorScheme.primaryContainer,
                            child: Icon(
                              isSelected ? Icons.check : Icons.link,
                              color: isSelected
                                  ? context.colors.onSuccess
                                  : theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: context.spacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlurReveal(
                                blurSigma: 3,
                                child: Text(
                                  fullUrl,
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  CountdownBadge(
                                    endDate: code.expiresAt,
                                    onExpired: () {
                                      onSelectionChanged(false);
                                    },
                                  ),
                                  JoinCodeTypeBadges(code: code),
                                ],
                              ),
                            ],
                          ),
                        ),
                        RotationTransition(
                          turns: Tween<double>(
                            begin: 0,
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
          ),
          // Part of the row, so focus in it still counts as the card.
          body: (context) => RowStop(
            role: RowRole.part,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(context.spacing.space3),
                  child: Wrap(
                    alignment: .center,
                    spacing: context.spacing.space2,
                    runSpacing: context.spacing.space2,
                    children: [
                      Button(
                        face: ButtonFace.outlined,
                        icon: const Icon(Icons.copy, size: 18),
                        label: "Copy Join Code",
                        color: context.colors.brandText,
                        onPressed: () => _copyToClipboard(context, fullUrl),
                      ),
                      CommandButton(
                        command: revocation,
                        face: ButtonFace.outlined,
                        icon: const Icon(Icons.link_off, size: 18),
                        label: "Revoke",
                        color: context.colors.dangerText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackBar(context, "Join code copied to clipboard");
  }
}
