import "package:flutter/material.dart" hide Page;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class AuthoringBookSearchResultItem extends StatelessWidget {
  const AuthoringBookSearchResultItem({
    required this.book,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final skir.AuthoringSearchBook book;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color = book.color.toFlutterColor();
    return SearchResultCard(
      color: color,
      prefix: _iconTile(
        context,
        color,
        Icones(book.icon.isEmpty ? "fa6-solid:book-open" : book.icon),
        focused,
        loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        spacing: context.spacing.space2,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchResultTitle(title: book.title.formatted),
          if (book.tags.isNotEmpty)
            SearchResultTags(
              tags: book.tags.map((tag) => tag.name).toList(growable: false),
              selected: selected,
              focused: focused,
              color: color,
            ),
        ],
      ),
      suffix: _suffix("book", shortcutActivator, selected),
    );
  }
}

class AuthoringTagSearchResultItem extends StatelessWidget {
  const AuthoringTagSearchResultItem({
    required this.tag,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final skir.AuthoringSearchTag tag;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color = tag.color.toFlutterColor();
    return SearchResultCard(
      color: color,
      prefix: _iconTile(
        context,
        color,
        const Icones("fa6-solid:tag"),
        focused,
        loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: SearchResultTitle(title: tag.name.formatted),
      suffix: _suffix("tag", shortcutActivator, selected),
    );
  }
}

class AuthoringPageSearchResultItem extends ConsumerWidget {
  const AuthoringPageSearchResultItem({
    required this.page,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final skir.AuthoringSearchPage page;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = ref
        .watch(realmEditorCatalogProvider)
        .value
        ?.snapshot
        ?.pageCatalog
        .definitions[PageKindRef.fromSkir(page.kind)];

    final current = _currentPage(ref);
    final color = definition?.color ?? Theme.of(context).colorScheme.primary;
    final contextParts = _pageContext(page, current);
    return SearchResultCard(
      color: color,
      prefix: _iconTile(
        context,
        color,
        definition == null
            ? const Icones("fa6-solid:file-lines")
            : Icones.value(definition.icon),
        focused,
        loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space2,
        children: [
          SearchResultTitle(title: page.name.formatted),
          Row(
            spacing: context.spacing.space2,
            children: [
              SearchResultDescription(
                description: definition?.name ?? page.name.formatted,
              ),
              if (contextParts.isNotEmpty) ...[
                SearchResultTags(
                  tags: contextParts,
                  selected: selected,
                  focused: focused,
                  color: color,
                  seperatorBuilder: () =>
                      Icones(MaterialSymbols.chevron_right_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
      suffix: _suffix("page", shortcutActivator, selected),
    );
  }
}

class AuthoringElementSearchResultItem extends ConsumerWidget {
  const AuthoringElementSearchResultItem({
    required this.element,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final skir.AuthoringSearchElement element;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = ref
        .watch(realmEditorCatalogProvider)
        .value
        ?.snapshot
        ?.elements[element.elementType]
        ?.definition;
    final current = _currentPage(ref);
    final color = definition?.color ?? Theme.of(context).colorScheme.tertiary;
    final contextParts = _elementContext(element.page, current);
    return SearchResultCard(
      color: color,
      prefix: _iconTile(
        context,
        color,
        definition == null
            ? const Icones("fa6-solid:cube")
            : Icones.value(definition.icon),
        focused,
        loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space2,
        children: [
          SearchResultTitle(title: element.name.formatted),
          SearchResultDescription(
            description: [
              definition?.name ?? element.elementType,
              ...contextParts,
            ].join(" • "),
          ),
          if (element.match case final match?) _MatchText(match: match),
        ],
      ),
      suffix: _suffix("element", shortcutActivator, selected),
    );
  }
}

Page? _currentPage(WidgetRef ref) {
  final id = ref.watch(pageIdProvider);
  return id == null ? null : ref.watch(projectedPageProvider(id)).value;
}

List<String> _pageContext(skir.AuthoringSearchPage page, Page? current) {
  if (current == null || current.bookId != page.book.id) {
    return [
      page.book.title.formatted,
      page.chapter.formatted,
    ].where((part) => part.isNotEmpty).toList();
  }
  return current.chapter == page.chapter || page.chapter.isEmpty
      ? const []
      : [page.chapter.formatted].where((part) => part.isNotEmpty).toList();
}

List<String> _elementContext(skir.AuthoringSearchPage page, Page? current) {
  final parts = _pageContext(page, current).toList();
  if (current?.pageId != page.id) parts.add(page.name);
  return parts;
}

SearchResultIconTile _iconTile(
  BuildContext context,
  Color color,
  Widget icon,
  bool focused,
  bool loading,
) => SearchResultIconTile(
  color: color,
  onColor: color.on(context),
  icon: icon,
  focused: focused,
  loading: loading,
);

SearchResultSuffix _suffix(
  String label,
  ShortcutActivator? shortcut,
  bool selected,
) => SearchResultSuffix(
  label: label,
  shortcutActivator: shortcut,
  selected: selected,
);

class _MatchText extends StatelessWidget {
  const _MatchText({required this.match});
  final skir.AuthoringSearchMatch match;

  @override
  Widget build(BuildContext context) {
    final start = match.start.clamp(0, match.text.length);
    final end = match.end.clamp(start, match.text.length);
    final style = Theme.of(context).textTheme.bodySmall;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: match.text.substring(0, start)),
          TextSpan(
            text: match.text.substring(start, end),
            style: style?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: match.text.substring(end)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
