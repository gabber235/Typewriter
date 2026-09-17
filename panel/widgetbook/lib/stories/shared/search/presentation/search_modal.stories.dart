import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";
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
          contributionBuilder: (ref, context) => SearchContribution(
            session: mockSearchSession(_sourceFromConfig(config))
                .copyWith(initialQuery: initialQuery),
          ),
          searchHint: "Search entries, pages, books, organizations",
          rowRenderers: _mockRowRenderers,
          previewRenderers: _mockPreviewRenderers,
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
                  (ref, context) => SearchContribution(
                    session: mockSearchSession(_sourceFromConfig(config))
                        .copyWith(initialQuery: initialQuery),
                  ),
                  searchHint: "Search entries, pages, books, organizations",
                  rowRenderers: _mockRowRenderers,
                  previewRenderers: _mockPreviewRenderers,
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
  "mockPageRow": _mockResultRow,
  "mockEntryRow": _mockResultRow,
  "mockElementDefinitionRow": _mockElementDefinitionResultRow,
  "mockBookRow": _mockResultRow,
  "mockTagRow": _mockResultRow,
};

final _mockPreviewRenderers = <String, SearchResultPreviewBuilder>{
  "mockElementDefinitionPreview": _mockElementDefinitionPreview,
};

Widget _mockElementDefinitionPreview(SearchResultPreviewContext context) {
  return ElementDefinitionSearchPreview(context: context);
}

Widget _mockResultRow(SearchResultRowContext context) =>
    _MockResultRow(searchContext: context);

class _MockResultRow extends StatelessWidget {
  const _MockResultRow({required this.searchContext});

  final SearchResultRowContext searchContext;

  @override
  Widget build(BuildContext context) => SearchResultCard(
    color: Theme.of(context).colorScheme.primary,
    selected: searchContext.selected,
    focused: searchContext.focused,
    onTap: searchContext.onTap,
    content: SearchResultTitle(
      title: searchContext.result.title ?? searchContext.result.id,
    ),
    suffix: SearchResultSuffix(
      label: searchContext.result.type.label ?? "result",
      shortcutActivator: searchContext.shortcutActivator,
      selected: searchContext.selected,
    ),
  );
}

Widget _mockElementDefinitionResultRow(SearchResultRowContext context) {
  final payload = context.result.payload;
  if (payload is! ElementDefinition) {
    return MissingSearchResultRendererRow(result: context.result);
  }

  return ElementDefinitionSearchResultItem.fromDefinition(
    elementDefinition: payload,
    selected: context.selected,
    focused: context.focused,
    loading: context.loading,
    onTap: context.onTap,
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
  if (config.debounce) {
    source = source.debounced(config.debounceDuration);
  }
  if (config.cache) {
    source = source.cached();
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
