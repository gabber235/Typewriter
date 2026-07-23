import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SearchTreeSectionHeader extends StatelessWidget {
  const SearchTreeSectionHeader({
    required this.row,
    required this.onToggle,
    super.key,
  });

  final SearchTreeSectionRow row;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: context.shapes.largeBorderRadius,
      child: InkWell(
        borderRadius: context.shapes.largeBorderRadius,
        onTap: onToggle,
        child: Padding(
          padding: EdgeInsets.only(
            left: context.spacing.space3 + row.depth * context.spacing.space4,
            right: context.spacing.space3,
            top: context.spacing.space2,
            bottom: context.spacing.space2,
          ),
          child: Row(
            spacing: context.spacing.space2,
            children: [
              AnimatedRotation(
                turns: row.expanded ? 0.25 : 0,
                duration: 750.ms,
                curve: ElasticOutCurve(0.4),
                child: const Icon(Icons.keyboard_arrow_right_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (row.subtitle != null)
                      Text(
                        row.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Text(
                "(${row.resultCount})",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
