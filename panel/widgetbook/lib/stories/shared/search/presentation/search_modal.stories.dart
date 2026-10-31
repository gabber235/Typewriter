import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: SearchModal)
Widget searchModalDirectUseCase(BuildContext context) {
  final config = _configFromKnobs(context);
  final initialQuery = context.knobs.string(
    label: "Initial query",
    initialValue: "",
  );

  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox.expand(
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

  final searchDelay = context.knobs.duration(
    label: "Search delay",
    initialValue: 750.ms,
  );

  return _SearchStoryConfig(
    state: state,
    hasData: hasData,
    includeGuidance: includeGuidance,
    searchDelay: searchDelay,
  );
}

final _mockRowRenderers = <String, SearchResultRowBuilder>{
  "mockPageRow": _mockResultRow,
  "mockEntryRow": _mockResultRow,
  "mockElementDefinitionRow": _mockResultRow,
  "mockBookRow": _mockResultRow,
  "mockTagRow": _mockResultRow,
};

final _mockPreviewRenderers = <String, SearchResultPreviewBuilder>{
  "mockElementDefinitionPreview": _mockElementDefinitionPreview,
};

Widget _mockElementDefinitionPreview(SearchResultPreviewContext context) {
  return switch (context) {
    SearchResultPreviewContextLoading() => const Center(
      child: CircularProgressIndicator(),
    ),
    SearchResultPreviewContextData(:final result, :final data) => ListTile(
      title: Text(result.title ?? result.id),
      subtitle: Text(data.toString()),
    ),
    SearchResultPreviewContextError(:final message) => Center(
      child: Text(message),
    ),
  };
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

SearchSource _sourceFromConfig(_SearchStoryConfig config) {
  final source = mockMixedGlobalSearchSource(
    state: config.state,
    hasData: config.hasData,
    includeGuidance: config.includeGuidance,
    selectors: [],
    searchDelay: config.searchDelay,
  );
  return source.debounced(250.ms).cached();
}

class _SearchStoryConfig {
  const _SearchStoryConfig({
    required this.state,
    required this.hasData,
    required this.includeGuidance,
    required this.searchDelay,
  });

  final MockSearchDisplayState state;
  final bool hasData;
  final bool includeGuidance;
  final Duration searchDelay;
}
