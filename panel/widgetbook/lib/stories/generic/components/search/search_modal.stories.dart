import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/routes/organization/book/route.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_modal.dart";
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
          baseSelectors: mockQuerySelectors,
          initialQuery: initialQuery,
          searchHint: "Search entries, pages, books, organizations",
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
                  baseSelectors: mockQuerySelectors,
                  initialQuery: initialQuery,
                  searchHint: "Search entries, pages, books, organizations",
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
  final cache = context.knobs.boolean(label: "Cache", initialValue: true);
  final debounce = context.knobs.boolean(label: "Debounce", initialValue: true);
  final debounceDuration = context.knobs.duration(
    label: "Debounce duration",
    initialValue: 250.ms,
  );
  final searchDelay = context.knobs.duration(
    label: "Search delay",
    initialValue: 250.ms,
  );

  return _SearchStoryConfig(
    state: state,
    cache: cache,
    debounce: debounce,
    debounceDuration: debounceDuration,
    searchDelay: searchDelay,
  );
}

SearchSource _sourceFromConfig(_SearchStoryConfig config) {
  var source = mockMixedGlobalSearchSource(
    state: config.state,
    selectors: mockQuerySelectors,
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
    required this.cache,
    required this.debounce,
    required this.debounceDuration,
    required this.searchDelay,
  });

  final MockSearchDisplayState state;
  final bool cache;
  final bool debounce;
  final Duration debounceDuration;
  final Duration searchDelay;
}
