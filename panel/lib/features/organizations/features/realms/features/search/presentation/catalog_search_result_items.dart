import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Builds the shared element type row used by global and contextual search.
Widget buildElementTypeSearchResultItem(SearchResultRowContext context) =>
    ElementTypeSearchResultItem(
      definition: context.result.payload as ElementDefinition,
      focused: context.focused,
      selected: context.selected,
      loading: context.loading,
      onTap: context.onTap,
      shortcutActivator: context.shortcutActivator,
    );

class PageKindSearchResultItem extends StatelessWidget {
  const PageKindSearchResultItem({
    required this.definition,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final RealmPageDefinition definition;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    return SearchResultCard(
      color: definition.color,
      prefix: SearchResultIconTile(
        color: definition.color,
        onColor: definition.color.on(context),
        icon: Icones.value(definition.icon),
        focused: focused,
        loading: loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.spacing.space2,
        children: [
          SearchResultTitle(title: definition.name.formatted),
          Row(
            spacing: context.spacing.space2,
            children: [
              SearchResultTags(
                tags: [
                  switch (definition.editor) {
                    RealmGraphPageEditor() => "graph",
                    RealmTimelinePageEditor() => "timeline",
                  },
                ],
                selected: selected,
                focused: focused,
                color: definition.color,
              ),
              if (definition.description case final description?
                  when description.isNotEmpty)
                SearchResultDescription(description: description),
            ],
          ),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "page kind",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

class ElementTypeSearchResultItem extends StatelessWidget {
  const ElementTypeSearchResultItem({
    required this.definition,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final ElementDefinition definition;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    return SearchResultCard(
      color: definition.color,
      prefix: SearchResultIconTile(
        color: definition.color,
        onColor: definition.color.on(context),
        icon: Icones.value(definition.icon),
        focused: focused,
        loading: loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.spacing.space2,
        children: [
          SearchResultTitle(title: definition.name.formatted),
          if (definition.description.isNotEmpty)
            SearchResultDescription(description: definition.description),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "element type",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
