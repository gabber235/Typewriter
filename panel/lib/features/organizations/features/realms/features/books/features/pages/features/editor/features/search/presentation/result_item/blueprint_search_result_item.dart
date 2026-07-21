import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
    this.loading = false,
    this.onTap,
    this.shortcutActivator,
    super.key,
  });

  factory BlueprintSearchResultItem.fromBlueprint({
    required ElementBlueprint blueprint,
    bool selected = false,
    bool focused = false,
    bool loading = false,
    VoidCallback? onTap,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    return BlueprintSearchResultItem(
      name: blueprint.name,
      extensionName: blueprint.extension,
      shortDescription: blueprint.description,
      color: blueprint.color,
      icon: blueprint.icon,
      tags: blueprint.tags,
      deprecated: blueprint.hasModifier<DeprecatedModifier>(),
      selected: selected,
      focused: focused,
      onTap: onTap,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final String extensionName;
  final String shortDescription;
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
    return SearchResultCard(
      color: color,
      prefix: SearchResultIconTile(
        color: color,
        onColor: color.onBrightness(Brightness.dark),
        icon: icon,
        focused: focused,
        loading: loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
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
