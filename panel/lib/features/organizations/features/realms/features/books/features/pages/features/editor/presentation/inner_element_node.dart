import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class InnerElementNode extends StatelessWidget {
  const InnerElementNode({
    required this.name,
    required this.blueprint,
    required this.color,
    required this.isDeprecated,
    this.isReference = false,
    this.pageId,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.compactPadding = const EdgeInsets.all(4),
    this.iconSize = 18,
    this.fontSize = 13,
    this.secondaryFontSize = 11,
    super.key,
  });

  final String name;
  final ElementBlueprint blueprint;
  final Color color;
  final bool isDeprecated;
  final bool isReference;
  final String? pageId;
  final EdgeInsets padding;
  final EdgeInsets compactPadding;
  final double iconSize;
  final double fontSize;
  final double secondaryFontSize;

  @override
  Widget build(BuildContext context) {
    final centerContent = isReference && pageId != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: color,
                    fontSize: fontSize,
                    decoration: isDeprecated
                        ? TextDecoration.lineThrough
                        : null,
                    decorationThickness: 2.8,
                    decorationColor: color,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Page: $pageId",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontSize: secondaryFontSize,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        : Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: color,
              fontSize: fontSize,
              decoration: isDeprecated ? TextDecoration.lineThrough : null,
              decorationThickness: 2.8,
              decorationColor: color,
              decorationStyle: TextDecorationStyle.wavy,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          );

    return AdaptiveLeadingLayout(
      padding: padding,
      compactPadding: compactPadding,
      leading: Icones(blueprint.icon, size: iconSize, color: color),
      center: centerContent,
      suffix: isReference
          ? Icon(Icons.open_in_new, color: color, size: iconSize)
          : null,
    );
  }
}
