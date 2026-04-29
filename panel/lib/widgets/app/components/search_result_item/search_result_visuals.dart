import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/shortcut_display.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

class SearchResultIconTile extends StatelessWidget {
  const SearchResultIconTile({
    required this.color,
    required this.onColor,
    required this.icon,
    this.focused = false,
    super.key,
  });

  final Color color;
  final Color onColor;
  final String icon;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Surface.colorOf(context);
    final surfaceBrightness = ThemeData.estimateBrightnessForColor(
      surfaceColor,
    );
    return AnimatedContainer(
      duration: 180.ms,
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: focused ? color.onBrightness(surfaceBrightness.inverted) : color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Icones(icon, color: focused ? color : onColor),
    );
  }
}

class SearchResultTitle extends StatelessWidget {
  const SearchResultTitle({
    required this.title,
    this.deprecated = false,
    super.key,
  });

  final String title;
  final bool deprecated;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Surface.colorOf(context);
    final theme = Theme.of(context);
    final matchBrightness =
        ThemeData.estimateBrightnessForColor(surfaceColor) == theme.brightness;
    final color = matchBrightness
        ? theme.colorScheme.onSurface
        : surfaceColor.on(context);
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color,
        fontSize: 14,
        height: 1.1,
        decoration: deprecated ? TextDecoration.lineThrough : null,
        decorationThickness: 2.8,
        decorationColor: Theme.of(context).colorScheme.surface,
        decorationStyle: TextDecorationStyle.wavy,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

class SearchResultDescription extends StatelessWidget {
  const SearchResultDescription({required this.description, super.key});

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaceColor = Surface.colorOf(context);

    final matchBrightness =
        ThemeData.estimateBrightnessForColor(surfaceColor) == theme.brightness;

    final descriptionColor = matchBrightness
        ? colors.onSurfaceVariant
        : surfaceColor.on(context);

    final contextStyle = theme.textTheme.bodySmall?.copyWith(
      color: descriptionColor,
      height: 1.2,
    );
    return Text(description, style: contextStyle, maxLines: 1, overflow: .fade);
  }
}

class SearchResultSoftChip extends StatelessWidget {
  const SearchResultSoftChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: StadiumBorder(),
      ),
      child: AnimatedDefaultTextStyle(
        style: Theme.of(
          context,
        ).textTheme.bodySmall!.copyWith(fontSize: 10, color: foregroundColor),
        duration: 300.ms,
        child: Text(label),
      ),
    );
  }
}

class SearchResultTags extends StatelessWidget {
  const SearchResultTags({
    required this.tags,
    required this.selected,
    required this.focused,
    required this.color,
    super.key,
  });

  final List<String> tags;
  final bool selected;
  final bool focused;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final surfaceColor = Surface.colorOf(context);
    final surfaceBrightness = ThemeData.estimateBrightnessForColor(
      surfaceColor,
    );
    final onSurface = surfaceColor.onBrightness(surfaceBrightness.inverted);

    final backgroundColor = switch ((selected, focused)) {
          (false, false) => Color.alphaBlend(color.withValues(alpha: 0.3), surfaceColor),
          (true, false) => Color.alphaBlend(color.withValues(alpha: 0.72), surfaceColor),
          (false, true) => Color.alphaBlend(onSurface.withValues(alpha: 0.55), surfaceColor),
          (true, true) => Color.alphaBlend(onSurface.withValues(alpha: 0.9), surfaceColor),
    };

    final foregroundColor = switch ((selected, focused)) {
          (false, false) => color,
          (true, false) => onSurface,
          (_, true) => color,
    };


    return Flexible(
      child: UnconstrainedBox(
        child: Row(
          spacing: 4,
          children: [
            Text(
              "•",
              style: textTheme.labelSmall?.copyWith(
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
            for (final tag in tags)
              SearchResultSoftChip(
                label: tag,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
              ),
          ],
        ),
      ),
    );
  }
}

class SearchResultType extends StatelessWidget {
  const SearchResultType({required this.label, this.color, super.key});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class SearchResultSuffix extends StatelessWidget {
  const SearchResultSuffix({
    required this.label,
    required this.shortcutActivator,
    required this.selected,
    super.key,
  });

  final String label;
  final ShortcutActivator? shortcutActivator;
  final bool selected;

  @override
  Widget build(BuildContext context) {
      final surfaceColor = Surface.colorOf(context);
      final surfaceBrightness = ThemeData.estimateBrightnessForColor(
        surfaceColor,
      );
      final onSurface = surfaceColor.onBrightness(surfaceBrightness.inverted);
    return Row(
      spacing: 8,
      children: [
        SearchResultType(
          label: label,
          color: onSurface.withValues(alpha: 0.7),
        ),
        if (shortcutActivator != null)
          ShortcutDisplay(
            shortcut: shortcutActivator!,
            style: selected ? KeyStyle.outline : KeyStyle.solid,
          ),
      ],
    );
  }
}
