import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EntrySearchResultItem extends StatelessWidget {
  const EntrySearchResultItem({
    required this.name,
    required this.elementDefinitionName,
    required this.bookTitle,
    required this.chapter,
    required this.pageTitle,
    required this.color,
    required this.icon,
    this.deprecated = false,
    this.selected = false,
    this.focused = false,
    this.loading = false,
    this.onTap,
    this.shortcutActivator,
    super.key,
  });

  factory EntrySearchResultItem.fromEntry({
    required EntryDefinition entry,
    required String pageTitle,
    required String chapter,
    required String bookTitle,
    bool selected = false,
    bool focused = false,
    bool loading = false,
    VoidCallback? onTap,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    final elementDefinition = entry.elementDefinition;
    return EntrySearchResultItem(
      name: entry.name,
      elementDefinitionName: elementDefinition.name,
      bookTitle: bookTitle,
      chapter: chapter,
      pageTitle: pageTitle,
      color: elementDefinition.color,
      icon: elementDefinition.icon,
      deprecated: elementDefinition.isDeprecated,
      selected: selected,
      focused: focused,
      loading: loading,
      onTap: onTap,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final String elementDefinitionName;
  final String bookTitle;
  final String chapter;
  final String pageTitle;
  final Color color;
  final IconValue icon;
  final bool deprecated;
  final bool selected;
  final bool focused;
  final bool loading;

  final VoidCallback? onTap;

  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaceColor = focused ? color : Surface.colorOf(context);

    final matchBrightness =
        ThemeData.estimateBrightnessForColor(surfaceColor) == theme.brightness;

    final descriptionColor = matchBrightness
        ? colors.onSurface
        : surfaceColor.on(context);

    return SearchResultCard(
      color: color,
      selected: selected,
      focused: focused,
      onTap: onTap,
      prefix: SearchResultIconTile.value(
        color: color,
        onColor: color.on(context),
        icon: icon,
        focused: focused,
        loading: loading,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space1,
        children: [
          SearchResultTitle(title: name.formatted, deprecated: deprecated),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: elementDefinitionName.formatted),
                TextSpan(
                  text: " • ",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: descriptionColor.withValues(alpha: 0.5),
                  ),
                ),
                TextSpan(
                  text: pageTitle.formatted,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: descriptionColor.withValues(alpha: 0.9),
                  ),
                ),
                if (chapter.isNotEmpty) ...[
                  TextSpan(
                    text: " ◀ ",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: descriptionColor.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                  TextSpan(
                    text: chapter.formatted,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: descriptionColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (bookTitle.isNotEmpty) ...[
                  TextSpan(
                    text: " ◀ ",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: descriptionColor.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                  TextSpan(
                    text: bookTitle.formatted,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: descriptionColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: descriptionColor,
                fontSize: 11,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "entry",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
