import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class TagSearchResultItem extends StatelessWidget {
  const TagSearchResultItem({
    required this.name,
    required this.color,
    this.icon = "fa6-solid:tag",
    this.selected = false,
    this.focused = false,
    this.loading = false,
    this.onTap,
    this.shortcutActivator,
    super.key,
  });

  factory TagSearchResultItem.fromTag({
    required Tag tag,
    bool selected = false,
    bool focused = false,
    bool loading = false,
    VoidCallback? onTap,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    return TagSearchResultItem(
      name: tag.name,
      color: tag.color,
      selected: selected,
      focused: focused,
      loading: loading,
      onTap: onTap,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final Color color;
  final String icon;
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
        onColor: color.on(context),
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
        children: [SearchResultTitle(title: name.formatted)],
      ),
      suffix: SearchResultSuffix(
        label: "tag",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
