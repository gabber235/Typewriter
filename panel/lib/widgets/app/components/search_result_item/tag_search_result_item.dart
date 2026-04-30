import "package:flutter/material.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/search_result_item/search_result_card.dart";
import "package:typewriter_panel/widgets/app/components/search_result_item/search_result_visuals.dart";

class TagSearchResultItem extends StatelessWidget {
  const TagSearchResultItem({
    required this.name,
    required this.color,
    this.icon = "fa6-solid:tag",
    this.selected = false,
    this.focused = false,
    this.onTap,
    this.onLongPress,
    this.shortcutActivator,
    super.key,
  });

  factory TagSearchResultItem.fromTag({
    required Tag tag,
    bool selected = false,
    bool focused = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    return TagSearchResultItem(
      name: tag.name,
      color: tag.color.toFlutterColor(),
      selected: selected,
      focused: focused,
      onTap: onTap,
      onLongPress: onLongPress,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final Color color;
  final String icon;
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
        onColor: Colors.white,
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
