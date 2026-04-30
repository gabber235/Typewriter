import "package:flutter/material.dart" hide Page;
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/search_result_item/search_result_item.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

class PageSearchResultItem extends StatelessWidget {
  const PageSearchResultItem({
    required this.name,
    required this.bookName,
    required this.chapter,
    required this.color,
    this.icon = "fa6-solid:file-lines",
    this.selected = false,
    this.focused = false,
    this.onTap,
    this.onLongPress,
    this.shortcutActivator,
    super.key,
  });

  factory PageSearchResultItem.fromPage({
    required Page page,
    required String bookName,
    required Color color,
    String? icon,
    bool selected = false,
    bool focused = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    return PageSearchResultItem(
      name: page.name,
      bookName: bookName,
      chapter: page.chapter,
      color: color,
      icon: icon == null || icon.isEmpty ? "fa6-solid:file-lines" : icon,
      selected: selected,
      focused: focused,
      onTap: onTap,
      onLongPress: onLongPress,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final String bookName;
  final String chapter;
  final Color color;
  final String icon;
  final bool selected;
  final bool focused;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

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
      onLongPress: onLongPress,
      prefix: SearchResultIconTile(
        color: color,
        onColor: Colors.white,
        icon: icon,
        focused: focused,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          SearchResultTitle(title: name.formatted),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: chapter.formatted,
                  style: TextStyle(
                    color: descriptionColor.withValues(alpha: 0.8),
                  ),
                ),
                TextSpan(
                  text: " ◀ ",
                  style: TextStyle(
                    color: descriptionColor.withValues(alpha: 0.5),
                    fontSize: 9,
                  ),
                ),
                TextSpan(
                  text: bookName.formatted,
                  style: TextStyle(
                    color: descriptionColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: descriptionColor,
                fontSize: 11,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "page",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
