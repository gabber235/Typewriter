import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// A shared widget for displaying interaction mode information in the app bar.
///
/// This widget provides consistent styling for mode displays across different
/// interaction modes, with customizable label and color parameters.
class ModeDisplayChip extends StatelessWidget {
  const ModeDisplayChip({
    required this.label,
    required this.color,
    this.backgroundColor,
    super.key,
  });

  /// The text label to display in the chip
  final String label;

  /// The color theme for the chip
  final Color color;

  /// The background color for the chip
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            color.withValues(alpha: context.isDarkMode ? .1 : .2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
