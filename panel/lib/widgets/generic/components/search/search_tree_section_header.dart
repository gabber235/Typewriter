import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_model.dart";

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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: EdgeInsets.only(
            left: 12 + row.depth * 16,
            right: 12,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            spacing: 8,
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
                style: TextStyle(
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
