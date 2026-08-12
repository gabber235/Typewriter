import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ElementDefinitionSearchResultItem extends StatelessWidget {
  const ElementDefinitionSearchResultItem({
    required this.name,
    required this.namespace,
    required this.shortDescription,
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

  factory ElementDefinitionSearchResultItem.fromDefinition({
    required ElementDefinition elementDefinition,
    bool selected = false,
    bool focused = false,
    bool loading = false,
    VoidCallback? onTap,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    return ElementDefinitionSearchResultItem(
      name: elementDefinition.name,
      namespace: elementDefinition.namespace,
      shortDescription: elementDefinition.description,
      color: elementDefinition.color,
      icon: elementDefinition.icon,
      deprecated: elementDefinition.isDeprecated,
      selected: selected,
      focused: focused,
      onTap: onTap,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final String namespace;
  final String shortDescription;
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
    return SearchResultCard(
      color: color,
      prefix: SearchResultIconTile.value(
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
        spacing: context.spacing.space1,
        children: [
          SearchResultTitle(title: name.formatted, deprecated: deprecated),
          SearchResultDescription(
            description: "$namespace • $shortDescription",
          ),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "element definition",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
