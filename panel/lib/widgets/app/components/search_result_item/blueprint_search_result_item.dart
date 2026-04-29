import "package:flutter/material.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/search_result_item/search_result_item.dart";

class BlueprintSearchResultItem extends StatelessWidget {
  const BlueprintSearchResultItem({
    required this.name,
    required this.extensionName,
    required this.shortDescription,
    required this.color,
    required this.icon,
    this.tags = const [],
    this.deprecated = false,
    this.selected = false,
    this.focused = false,
    this.onTap,
    this.onLongPress,
    this.shortcutActivator,
    super.key,
  });

  final String name;
  final String extensionName;
  final String shortDescription;
  final Color color;
  final String icon;
  final List<String> tags;
  final bool deprecated;
  final bool selected;
  final bool focused;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    return SearchResultCard(
      color: color,
      prefix: SearchResultIconTile(
        color: color,
        onColor: color.onBrightness(Brightness.dark),
        icon: icon,
        focused: focused,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      onLongPress: onLongPress,
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
          SearchResultDescription(
            description: "$extensionName • $shortDescription",
          ),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "blueprint",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
