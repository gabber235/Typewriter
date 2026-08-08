import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class RejectedTagDropTarget extends StatelessWidget {
  const RejectedTagDropTarget({required this.tag, super.key});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final backgroundColor = Color.alphaBlend(
      errorColor.withValues(alpha: 0.14),
      Surface.colorOf(context),
    );

    return Semantics(
      label: "Cannot connect ${tag.name.formatted}",
      child: MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: AnimatedContainer(
          duration: 100.ms,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: context.shapes.largeBorderRadius,
            border: Border.all(color: errorColor, width: 2),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space3,
            vertical: context.spacing.space2,
          ),
          child: AdaptiveLeadingLayout(
            leading: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: errorColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.link_off_rounded,
                size: 16,
                color: theme.colorScheme.onError,
              ),
            ),
            center: Text(
              tag.name.formatted,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: errorColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
