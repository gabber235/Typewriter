import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/generated/models/book.pb.dart" hide Book;
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/routes/organization/book/route.dart";
import "package:typewriter_panel/widgets/app/components/search_result_item/search_result_item.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_modal.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_result_renderers.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Direct", type: SearchModal)
Widget searchModalDirectUseCase(BuildContext context) {
  final config = _configFromKnobs(context);
  final initialQuery = context.knobs.string(
    label: "Initial query",
    initialValue: "",
  );

  return FakeApp(
    child: SizedBox.expand(
      child: Center(
        child: SearchModal(
          source: _sourceFromConfig(config),
          baseSelectors: const [],
          initialQuery: initialQuery,
          searchHint: "Search entries, pages, books, organizations",
          rowRenderers: _mockRowRenderers,
          previewRenderers: const {},
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Route", type: SearchModal)
Widget searchModalRouteUseCase(BuildContext context) {
  final config = _configFromKnobs(context);
  final initialQuery = context.knobs.string(
    label: "Initial query",
    initialValue: "",
  );

  return FakeApp(
    overrides: [
      ...bookPagesProviderOverrides(state: DisplayState.manyItems),
      ...pagesProviderOverrides(),
      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...booksProviderOverrides(state: DisplayState.manyItems),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(
      child: Section(
        child: Center(
          child: Builder(
            builder: (context) {
              return FilledButton.icon(
                onPressed: () => showSearchModal(
                  context,
                  _sourceFromConfig(config),
                  baseSelectors: const [],
                  initialQuery: initialQuery,
                  searchHint: "Search entries, pages, books, organizations",
                  rowRenderers: _mockRowRenderers,
                  previewRenderers: const {},
                ),
                icon: const Icon(Icons.search),
                label: const Text("Open search modal"),
              );
            },
          ),
        ),
      ),
    ),
  );
}

_SearchStoryConfig _configFromKnobs(BuildContext context) {
  final state = context.knobs.object.dropdown(
    label: "Source state",
    options: MockSearchDisplayState.values,
    labelBuilder: (value) => value.name,
    initialOption: MockSearchDisplayState.ready,
  );
  final hasData = context.knobs.boolean(label: "Has data", initialValue: true);
  final includeGuidance = context.knobs.boolean(
    label: "Include guidance",
    initialValue: false,
  );
  final cache = context.knobs.boolean(label: "Cache", initialValue: true);
  final debounce = context.knobs.boolean(label: "Debounce", initialValue: true);
  final debounceDuration = context.knobs.duration(
    label: "Debounce duration",
    initialValue: 250.ms,
  );
  final searchDelay = context.knobs.duration(
    label: "Search delay",
    initialValue: 750.ms,
  );

  return _SearchStoryConfig(
    state: state,
    hasData: hasData,
    includeGuidance: includeGuidance,
    cache: cache,
    debounce: debounce,
    debounceDuration: debounceDuration,
    searchDelay: searchDelay,
  );
}

final _mockRowRenderers = <String, SearchResultRowBuilder>{
  "mockPageRow": _mockPageResultRow,
  "mockEntryRow": _mockEntryResultRow,
  "mockBlueprintRow": _mockBlueprintResultRow,
  "mockBookRow": _mockBookResultRow,
  "mockTagRow": _mockTagResultRow,
};

Widget _mockPageResultRow(SearchResultRowContext context) {
  final payload = context.result.payload;
  if (payload is! MockPageRecord) {
    return MissingSearchResultRendererRow(result: context.result);
  }

  return PageSearchResultItem.fromPage(
    page: payload.page,
    bookName: payload.book.title,
    color: payload.book.color.toFlutterColor(),
    icon: payload.book.icon,
    selected: context.selected,
    focused: context.focused,
    onTap: context.onTap,
    onLongPress: context.onLongPress,
    shortcutActivator: context.shortcutActivator,
  );
}

Widget _mockEntryResultRow(SearchResultRowContext context) {
  final payload = context.result.payload;
  if (payload is! MockEntryRecord) {
    return MissingSearchResultRendererRow(result: context.result);
  }

  return EntrySearchResultItem.fromEntry(
    entry: payload.entry,
    pageTitle: payload.page.page.name,
    chapter: payload.page.page.chapter,
    bookTitle: payload.page.book.title,
    selected: context.selected,
    focused: context.focused,
    onTap: context.onTap,
    onLongPress: context.onLongPress,
    shortcutActivator: context.shortcutActivator,
  );
}

Widget _mockBlueprintResultRow(SearchResultRowContext context) {
  final payload = context.result.payload;
  if (payload is! ElementBlueprint) {
    return MissingSearchResultRendererRow(result: context.result);
  }

  return BlueprintSearchResultItem.fromBlueprint(
    blueprint: payload,
    selected: context.selected,
    focused: context.focused,
    onTap: context.onTap,
    onLongPress: context.onLongPress,
    shortcutActivator: context.shortcutActivator,
  );
}

Widget _mockBookResultRow(SearchResultRowContext context) {
  final payload = context.result.payload;
  if (payload is! MockBookRecord) {
    return MissingSearchResultRendererRow(result: context.result);
  }

  return BookSearchResultItem(
    name: payload.book.title,
    color: payload.book.color.toFlutterColor(),
    icon: payload.book.icon,
    tags: payload.tags,
    selected: context.selected,
    focused: context.focused,
    onTap: context.onTap,
    onLongPress: context.onLongPress,
    shortcutActivator: context.shortcutActivator,
  );
}

Widget _mockTagResultRow(SearchResultRowContext context) {
  final payload = context.result.payload;
  if (payload is! Tag) {
    return MissingSearchResultRendererRow(result: context.result);
  }

  return TagSearchResultItem.fromTag(
    tag: payload,
    selected: context.selected,
    focused: context.focused,
    onTap: context.onTap,
    onLongPress: context.onLongPress,
    shortcutActivator: context.shortcutActivator,
  );
}

SearchSource _sourceFromConfig(_SearchStoryConfig config) {
  var source = mockMixedGlobalSearchSource(
    state: config.state,
    hasData: config.hasData,
    includeGuidance: config.includeGuidance,
    selectors: [],
    searchDelay: config.searchDelay,
  );
  if (config.cache) {
    source = source.cached();
  }
  if (config.debounce) {
    source = source.debounced(config.debounceDuration);
  }
  return source;
}

class _SearchStoryConfig {
  const _SearchStoryConfig({
    required this.state,
    required this.hasData,
    required this.includeGuidance,
    required this.cache,
    required this.debounce,
    required this.debounceDuration,
    required this.searchDelay,
  });

  final MockSearchDisplayState state;
  final bool hasData;
  final bool includeGuidance;
  final bool cache;
  final bool debounce;
  final Duration debounceDuration;
  final Duration searchDelay;
}
