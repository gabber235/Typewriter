import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Shows the icon or loading state that identifies a search result.
///
/// Use the string constructor for an Iconify name and [SearchResultIconTile.value] when the
/// domain already provides an [IconValue]. [focused] changes contrast for the keyboard focused
/// row, while [loading] replaces the icon without changing the result identity.
class SearchResultIconTile extends StatelessWidget {
  const SearchResultIconTile({
    required this.color,
    required this.onColor,
    required this.icon,
    this.focused = false,
    this.loading = false,
    this.padding,
    super.key,
  });

  final Color color;
  final Color onColor;
  final Widget icon;
  final bool focused;
  final bool loading;

  final EdgeInsets? padding;

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
        borderRadius: context.shapes.smallBorderRadius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: padding ?? EdgeInsets.all(context.spacing.space2),
      child: ElasticSwitcher(
        child: loading
            ? CircularProgressIndicator(
                color: focused ? color : onColor,
                padding: EdgeInsets.all(context.spacing.space1),
              )
            : IconTheme(
                data: IconThemeData(color: focused ? color : onColor),
                child: icon,
              ),
      ),
    );
  }
}

/// Displays the primary result label, truncating it to one line.
///
/// Deprecated definitions remain discoverable but receive a wavy strike through. The widget
/// does not decide whether a result is deprecated; its caller maps domain metadata to [deprecated].
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
    return Text(
      description,
      style: contextStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
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
        style: Theme.of(context).textTheme.bodySmall!
            .copyWith(fontSize: 10, color: foregroundColor),
        duration: 300.ms,
        child: Text(label),
      ),
    );
  }
}

/// Displays a result's tags using colors that reflect selection and focus.
///
/// Tags are decorative metadata. The parent result remains responsible for interaction and
/// navigation, so this widget has no callback or mutable state.
class SearchResultTags extends StatelessWidget {
  const SearchResultTags({
    required this.tags,
    required this.selected,
    required this.focused,
    required this.color,
    this.seperatorBuilder,
    super.key,
  });

  final List<String> tags;
  final bool selected;
  final bool focused;
  final Color color;
  final Widget Function()? seperatorBuilder;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Surface.colorOf(context);
    final surfaceBrightness = ThemeData.estimateBrightnessForColor(
      surfaceColor,
    );
    final onSurface = surfaceColor.onBrightness(surfaceBrightness.inverted);

    final backgroundColor = switch ((selected, focused)) {
      (false, false) => Color.alphaBlend(
        color.withValues(alpha: 0.3),
        surfaceColor,
      ),
      (true, false) => Color.alphaBlend(
        color.withValues(alpha: 0.72),
        surfaceColor,
      ),
      (false, true) => Color.alphaBlend(
        onSurface.withValues(alpha: 0.55),
        surfaceColor,
      ),
      (true, true) => Color.alphaBlend(
        onSurface.withValues(alpha: 0.9),
        surfaceColor,
      ),
    };

    final foregroundColor = switch ((selected, focused)) {
      (false, false) => color,
      (true, false) => onSurface,
      (_, true) => color,
    };

    return Flexible(
      child: UnconstrainedBox(
        alignment: Alignment.centerLeft,
        clipBehavior: .antiAlias,
        child: Row(
          spacing: context.spacing.space1,
          children: [
            for (var i = 0; i < tags.length; i++) ...[
              if (i > 0 && seperatorBuilder != null) seperatorBuilder!(),
              SearchResultSoftChip(
                label: tags[i].formatted,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchResultTypeLabel extends StatelessWidget {
  const SearchResultTypeLabel({required this.label, this.color, super.key});
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

/// Displays result type metadata and its optional keyboard shortcut.
///
/// [selected] chooses the shortcut style so the key hint remains legible in the selected row.
/// Shortcut dispatch is owned by the surrounding search controller, not this widget.
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
      spacing: context.spacing.space2,
      children: [
        SearchResultTypeLabel(
          label: label,
          color: onSurface.withValues(alpha: 0.7),
        ),
        if (shortcutActivator != null)
          ShortcutDisplay(
            shortcut: shortcutActivator!,
            style: selected ? const KeyStyle.outline() : const KeyStyle.solid(),
          ),
      ],
    );
  }
}
