import "package:flutter/material.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/search/presentation/result_item/search_result_item.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class BookSearchResultItem extends StatelessWidget {
  const BookSearchResultItem({
    required this.name,
    required this.color,
    this.icon,
    this.tags = const [],
    this.selected = false,
    this.focused = false,
    this.loading = false,
    this.onTap,
    this.shortcutActivator,
    super.key,
  });

  final String name;
  final Color color;
  final String? icon;
  final List<String> tags;
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
        onColor: Colors.white,
        icon: icon ?? "fa6-solid:book-open",
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
              SearchResultTitle(title: name.formatted),
              if (tags.isNotEmpty)
                SearchResultTags(
                  tags: tags,
                  selected: selected,
                  focused: focused,
                  color: color,
                ),
            ],
          ),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "book",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
