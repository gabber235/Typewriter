import "package:typewriter_panel/typewriter_panel.dart";

/// Actions shown while one or more visible codes are selected. The route
/// builds the revoke hold over its rows, so this control stays independent
/// of the live projection.
class BulkJoinCodeActions extends StatelessWidget {
  const BulkJoinCodeActions({
    required this.selectedCount,
    required this.revocation,
    required this.onClearSelection,
    super.key,
  });

  final int selectedCount;

  /// The revoke hold over the selected codes.
  final ActionShortcut revocation;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return ManagedActionSet(
      shortcuts: [
        revocation,
        ActionShortcut.intent(
          id: "clear_bulk_join_codes",
          label: "Clear selection",
          description: "Clear selected join codes",
          intent: DismissIntent,
          priority: 2,
          run: ActionRun.press((_) => onClearSelection()),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space2,
        children: [
          SelectedChip(
            selectedCount: selectedCount,
            onClearSelection: onClearSelection,
          ),
          CommandButton(
            command: revocation,
            face: ButtonFace.outlined,
            color: context.colors.dangerText,
            icon: const Icon(Icons.link_off, size: 18),
            label: "Revoke all",
          ),
        ],
      ),
    );
  }
}
