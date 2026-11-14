import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Binds row focus to the standard selection, copy, and revoke actions.
///
/// Holding Delete revokes the whole selection when this row is selected, and
/// this code alone otherwise. Selection and copy use table callbacks.
class JoinCodeTableRowShortcuts extends StatelessWidget {
  const JoinCodeTableRowShortcuts({
    required this.code,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.copy,
    required this.isSelected,
    required this.hasSelection,
    required this.rows,
    required this.selectedIds,
    required this.child,
    super.key,
  });

  final skir.JoinCode code;
  final VoidCallback onToggleSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  /// Copies the code; the row's Copy button runs the same command.
  final ActionShortcut copy;
  final bool isSelected;
  final bool hasSelection;

  /// The join code rows the tab owns; the revoke hold sends and refuses on
  /// them.
  final AnimatedRows<Object?> rows;
  final Set<skir.RecordId> selectedIds;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "select_table_join_code_${code.code}",
          label: "Select join code",
          description: "Toggle selection for this join code",
          intent: ActivateIntent,
          priority: 1,
          run: ActionRun.press((_) => onToggleSelection()),
        ),
        ActionShortcut.intent(
          id: "select_all_table_join_codes_${code.code}",
          label: "Select all join codes",
          description: "Select all visible join codes",
          intent: ActivateAllIntent,
          priority: 1,
          run: ActionRun.press((_) => onSelectAll()),
        ),
        ActionShortcut.intent(
          id: "clear_table_join_code_selection_${code.code}",
          label: "Clear selection",
          description: "Clear selected join codes",
          intent: DismissIntent,
          priority: 1,
          run: ActionRun.press((_) => onClearSelection()),
        ),
        if (!hasSelection) copy,
        joinCodeRevocation(
          id: "revoke_table_join_code_${code.code}",
          label: hasSelection && isSelected
              ? "Revoke join codes"
              : "Revoke join code",
          targets: () => hasSelection && isSelected ? selectedIds : {code.code},
          rows: rows,
        ),
      ],
      child: child,
    );
  }
}
