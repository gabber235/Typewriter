import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:okcolor/models/extensions.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    required this.color,
    required this.content,
    this.prefix,
    this.suffix,
    this.selected = false,
    this.focused = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Color color;
  final Widget? prefix;
  final Widget content;
  final Widget? suffix;
  final bool selected;
  final bool focused;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Surface.colorOf(context);
    final surfaceBrightness = ThemeData.estimateBrightnessForColor(
      surfaceColor,
    );
    final alpha = selected ? 0.22 : 0.06;
    final backgroundColor = focused
        ? color
        : Color.alphaBlend(color.withValues(alpha: alpha), surfaceColor);
    final borderColor = selected ? color : Colors.transparent;

    return Surface(
      color: backgroundColor,
      child: Material(
        animationDuration: 180.ms,
        color: backgroundColor,
        borderRadius: context.shapes.mediumBorderRadius,
        child: InkWell(
          borderRadius: context.shapes.mediumBorderRadius,
          onTap: onTap,
          onLongPress: onLongPress,
          hoverColor: switch ((focused, surfaceBrightness)) {
            (true, Brightness.dark) => backgroundColor.lighter(0.1),
            (true, Brightness.light) => backgroundColor.darker(0.1),
            (false, _) => Color.alphaBlend(
              color.withValues(alpha: alpha + 0.1),
              surfaceColor,
            ),
          },
          splashColor: switch ((focused, surfaceBrightness)) {
            (true, Brightness.dark) => backgroundColor.lighter(0.2),
            (true, Brightness.light) => backgroundColor.darker(0.2),
            (false, _) => Color.alphaBlend(
              color.withValues(alpha: alpha + 0.3),
              surfaceColor,
            ),
          },
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: 180.ms,
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              borderRadius: context.shapes.mediumBorderRadius,
              border: Border.all(color: borderColor, width: 1.4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefix != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: prefix,
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      right: 10,
                      bottom: 8,
                      left: 10,
                    ),
                    child: content,
                  ),
                ),
                if (suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      right: 10,
                      bottom: 10,
                    ),
                    child: suffix,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
