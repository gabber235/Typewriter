import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/shared/ui/components/focus_highlight.dart";

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
