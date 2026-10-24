import "package:typewriter_panel/typewriter_panel.dart";

/// Compact summary and clear action for the current member selection.
///
/// It reflects transient selection owned by the surrounding list and never
/// mutates membership data. Clearing delegates to the list coordinator so
/// table and tablet layouts retain identical selection semantics.
class SelectedChip extends HookWidget {
  const SelectedChip({
    required this.selectedCount,
    required this.onClearSelection,
    super.key,
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
        style: Theme.of(context).textTheme.labelMedium!
            .copyWith(color: theme.colorScheme.onPrimaryContainer),
      ),
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.4,
      ),
      deleteIconColor: theme.colorScheme.onPrimaryContainer,
      onDeleted: onClearSelection,
      deleteButtonTooltipMessage: "Unselect all",
      side: FocusHighlight.stateBorder(context),
    );
  }
}
