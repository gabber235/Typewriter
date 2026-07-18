import "package:flutter/material.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/element_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/entries.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/search/presentation/result_item/search_result_item.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/color.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class EntrySearchResultItem extends StatelessWidget {
  const EntrySearchResultItem({
    required this.name,
    required this.blueprintName,
    required this.bookTitle,
    required this.chapter,
    required this.pageTitle,
    required this.color,
    required this.icon,
    this.tags = const [],
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
    final blueprint = entry.blueprint;
    return EntrySearchResultItem(
      name: entry.name,
      blueprintName: blueprint.name,
      bookTitle: bookTitle,
      chapter: chapter,
      pageTitle: pageTitle,
      color: blueprint.color,
      icon: blueprint.icon,
      tags: blueprint.tags,
      deprecated: blueprint.hasModifier<DeprecatedModifier>(),
      selected: selected,
      focused: focused,
      loading: loading,
      onTap: onTap,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final String blueprintName;
  final String bookTitle;
  final String chapter;
  final String pageTitle;
  final Color color;
  final String icon;
  final List<String> tags;
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
      prefix: SearchResultIconTile(
        color: color,
        onColor: Colors.white,
        icon: icon,
        focused: focused,
        loading: loading,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Row(
            spacing: 4,
            children: [
              SearchResultTitle(title: name.formatted, deprecated: deprecated),
              if (tags.isNotEmpty)
                SearchResultTags(
                  tags: tags,
                  selected: selected,
                  focused: focused,
                  color: color,
                ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: blueprintName.formatted),
                TextSpan(
                  text: " • ",
                  style: TextStyle(
                    color: descriptionColor.withValues(alpha: 0.5),
                  ),
                ),
                TextSpan(
                  text: pageTitle.formatted,
                  style: TextStyle(
                    color: descriptionColor.withValues(alpha: 0.9),
                  ),
                ),
                if (chapter.isNotEmpty) ...[
                  TextSpan(
                    text: " ◀ ",
                    style: TextStyle(
                      color: descriptionColor.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                  TextSpan(
                    text: chapter.formatted,
                    style: TextStyle(
                      color: descriptionColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (bookTitle.isNotEmpty) ...[
                  TextSpan(
                    text: " ◀ ",
                    style: TextStyle(
                      color: descriptionColor.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                  TextSpan(
                    text: bookTitle.formatted,
                    style: TextStyle(
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
