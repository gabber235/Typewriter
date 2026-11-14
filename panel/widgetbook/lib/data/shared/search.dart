/// The search results the search stories show, and a source serving them in
/// each display state a story knob picks.
library;

import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";

const mockPageSearchResultType = SearchResultType(
  id: "page",
  rowRendererId: "mockPageRow",
  label: "Page",
);

const mockEntrySearchResultType = SearchResultType(
  id: "entry",
  rowRendererId: "mockEntryRow",
  label: "Entry",
);

const mockElementDefinitionSearchResultType = SearchResultType(
  id: "elementDefinition",
  rowRendererId: "mockElementDefinitionRow",
  previewRendererId: "mockElementDefinitionPreview",
  label: "Element definition",
);

const mockBookSearchResultType = SearchResultType(
  id: "book",
  rowRendererId: "mockBookRow",
  label: "Book",
);

const mockTagSearchResultType = SearchResultType(
  id: "tag",
  rowRendererId: "mockTagRow",
  label: "Tag",
);

enum MockSearchDisplayState { ready, loading, error }

/// A source that answers every query with [snapshot], keeping the results
/// whose title, subtitle or kind holds every typed word, after
/// [answerDelay]. Previews answer with [previewAnswer], or never when it is
/// null.
FakeSearchSource storySearchSource(
  SearchSourceSnapshot snapshot, {
  SearchPreviewRequestResult? previewAnswer,
  List<QuerySelectorDefinition> selectors = const [],
  Duration answerDelay = Duration.zero,
}) => FakeSearchSource(
  selectors: selectors,
  answerDelay: answerDelay,
  answer: (context) {
    final words = context.normalizedQuery
        .toLowerCase()
        .split(RegExp(r"\s+"))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return snapshot;
    return snapshot.copyWith(nodes: _matching(snapshot.nodes, words));
  },
)..previewResult = previewAnswer;

List<SearchNode> _matching(List<SearchNode> nodes, List<String> words) {
  final matching = <SearchNode>[];
  for (final node in nodes) {
    switch (node) {
      case SearchResultNode(:final result):
        final text = [
          result.title,
          result.subtitle,
          result.type.label,
        ].nonNulls.join(" ").toLowerCase();
        if (words.every(text.contains)) matching.add(node);
      case SearchSectionNode(:final children):
        final kept = _matching(children, words);
        if (kept.isNotEmpty) matching.add(node.copyWith(children: kept));
    }
  }
  return matching;
}

/// A single selection [searchSession] over [source], as the stories show it.
SearchSession<void> mockSearchSession(SearchSource source) =>
    searchSession(source, selectionMode: SearchSelectionMode.single);

SearchSource mockMixedGlobalSearchSource({
  MockSearchDisplayState state = MockSearchDisplayState.ready,
  bool hasData = true,
  bool includeGuidance = false,
  List<QuerySelectorDefinition> selectors = const [],
  Duration searchDelay = Duration.zero,
}) {
  final guidance = includeGuidance
      ? const [
          SearchGuidance(
            id: "widgetbook.search.help",
            title: "Search resources by name",
          ),
        ]
      : const <SearchGuidance>[];
  final nodes = hasData ? _mixedGlobalResults : const <SearchNode>[];
  return storySearchSource(
    switch (state) {
      MockSearchDisplayState.ready => SearchSourceSnapshot.ready(
        nodes: nodes,
        guidance: guidance,
      ),
      MockSearchDisplayState.loading => SearchSourceSnapshot.loading(
        nodes: nodes,
        guidance: guidance,
      ),
      MockSearchDisplayState.error => SearchSourceSnapshot.error(
        nodes: nodes,
        guidance: guidance,
        errorSummaries: const [
          SearchErrorSummary(
            id: "mockError",
            message: "Search source failed",
            severity: SearchErrorSeverity.error,
            sourceLabel: "Mock source",
          ),
        ],
      ),
    },
    selectors: selectors,
    answerDelay: searchDelay,
  );
}

final _mixedGlobalResults = <SearchNode>[
  SearchNode.result(
    result: SearchResult(
      id: "book:story",
      type: mockBookSearchResultType,
      payload: "Story book",
      title: "Story book",
      subtitle: "Book",
    ),
  ),
  SearchNode.result(
    result: SearchResult(
      id: "tag:quest",
      type: mockTagSearchResultType,
      payload: "Quest",
      title: "Quest",
      subtitle: "Tag",
    ),
  ),
];

/// The result type of the results in [storySearchTrees]: its rows draw
/// through [storySearchRowRenderers] and its previews through
/// [storySearchPreviewRenderers].
const storyResultType = SearchResultType(
  id: "story.page",
  rowRendererId: "story.row",
  previewRendererId: "story.preview",
  label: "Page",
);

/// The command that opens a story result, the one activating a row runs.
const storyOpenCommandId = SearchCommandId("story.open");

/// The commands every story result offers: Open page, and Duplicate page,
/// which the Realm refuses.
final List<SearchCommand> storySearchCommands = [
  SearchCommand.single<String>(
    id: storyOpenCommandId,
    presentation: const SearchCommandPresentation(
      label: "Open page",
      priority: 10,
      icon: MaterialSymbols.open_in_new_rounded,
    ),
    matcher: const SearchResultMatcher(storyResultType),
    execute: (context, value, target) async =>
        const SearchCommandResult.completed(
          surfaceEffect: SearchSurfaceEffect.refresh(),
        ),
  ),
  SearchCommand.single<String>(
    id: const SearchCommandId("story.duplicate"),
    presentation: const SearchCommandPresentation(
      label: "Duplicate page",
      icon: MaterialSymbols.content_copy_rounded,
    ),
    matcher: const SearchResultMatcher(storyResultType),
    evaluate: (value, target) =>
        const SearchCommandState.disabled("The Realm is read only"),
    execute: (context, value, target) async =>
        const SearchCommandResult.cancelled(),
  ),
];

SearchNode _storyResult(String id, String title, {String? subtitle}) =>
    SearchNode.result(
      result: SearchResult(
        id: id,
        type: storyResultType,
        payload: id,
        title: title,
        subtitle: subtitle,
      ),
    );

const _storyPages = [
  "Arrival",
  "Market",
  "Meet the Mayor",
  "The Old Mill",
  "Finale",
];

/// The result trees a search story shows, by the name a story knob shows.
/// The first result of each has the id [storyFirstResultId].
Map<String, List<SearchNode>> get storySearchTrees => {
  "Few": [
    _storyResult(storyFirstResultId, "Arrival", subtitle: "The Lost Village"),
    for (final page in _storyPages.skip(1).take(2))
      _storyResult(page, page, subtitle: "The Lost Village"),
  ],
  "Sections": [
    SearchNode.section(
      id: "village",
      title: "The Lost Village",
      subtitle: "Book",
      children: [
        _storyResult(storyFirstResultId, "Arrival", subtitle: "Act 1"),
        for (final page in _storyPages.skip(1).take(2))
          _storyResult("village.$page", page, subtitle: "Act 1"),
      ],
    ),
    SearchNode.section(
      id: "atlas",
      title: "Atlas of Echoes",
      subtitle: "Book",
      children: [
        for (final page in _storyPages.skip(3))
          _storyResult("atlas.$page", page, subtitle: "Act 2"),
      ],
    ),
  ],
  "Nested sections": [
    SearchNode.section(
      id: "village",
      title: "The Lost Village",
      subtitle: "Book",
      children: [
        SearchNode.section(
          id: "village.act1",
          title: "Act 1",
          children: [
            _storyResult(storyFirstResultId, "Arrival"),
            _storyResult("act1.market", "Market"),
          ],
        ),
        SearchNode.section(
          id: "village.act2",
          title: "Act 2",
          children: [
            for (final page in _storyPages.skip(2))
              _storyResult("act2.$page", page),
          ],
        ),
      ],
    ),
  ],
  "Many": [
    SearchNode.section(
      id: "pages",
      title: "Pages",
      children: [
        for (var index = 0; index < 40; index++)
          _storyResult(
            index == 0 ? storyFirstResultId : "page.$index",
            "${_storyPages[index % _storyPages.length]} ${index + 1}",
            subtitle: "The Lost Village",
          ),
      ],
    ),
  ],
  "Long names": [
    SearchNode.section(
      id: "long",
      title:
          "The Remarkably Long Chronicle of the Village That Was Lost Twice "
          "and Found Again",
      subtitle: "A Book whose name runs past every column of the search",
      children: [
        _storyResult(
          storyFirstResultId,
          "Arrival at the gates of the old village after the long winter "
          "journey across the frozen mountains",
          subtitle:
              "Act 1. Chapter 3. The part where the traveller first meets "
              "the mayor and hears about the mill",
        ),
        _storyResult("long.market", "Market"),
      ],
    ),
  ],
};

/// The id of the first result of every [storySearchTrees] tree.
const storyFirstResultId = "arrival";

/// The snapshots a search story's source answers with, by the name a story
/// knob shows: every [storySearchTrees] tree ready, then the loading,
/// empty, guidance and failure states.
Map<String, SearchSourceSnapshot> get storySearchSnapshots => {
  for (final MapEntry(:key, :value) in storySearchTrees.entries)
    key: SearchSourceSnapshot.ready(nodes: value),
  "Loading": SearchSourceSnapshot.loading(nodes: const []),
  "Refreshing": SearchSourceSnapshot.loading(nodes: storySearchTrees["Few"]!),
  "Empty": SearchSourceSnapshot.ready(nodes: const []),
  "Guidance": SearchSourceSnapshot.ready(
    nodes: const [],
    guidance: storySearchGuidance,
  ),
  "Error": SearchSourceSnapshot.error(
    nodes: const [],
    errorSummaries: [storySearchErrors.first],
  ),
  "Errors with results": SearchSourceSnapshot.error(
    nodes: storySearchTrees["Few"]!,
    errorSummaries: storySearchErrors,
  ),
};

/// The guidance a story source offers while nothing matches.
const storySearchGuidance = [
  SearchGuidance(
    id: "story.names",
    title: "Search pages by name",
    description: "Type part of a page name, such as Arrival.",
  ),
  SearchGuidance(
    id: "story.books",
    title: "Narrow by book",
    description: "Type book: and a book name to search one book.",
    priority: 1,
  ),
];

/// The failures a story source reports: one error, one warning.
const storySearchErrors = [
  SearchErrorSummary(
    id: "story.realm",
    message: "The realm did not answer. Search again to retry.",
    severity: SearchErrorSeverity.error,
    sourceLabel: "Realm",
  ),
  SearchErrorSummary(
    id: "story.tags",
    message: "Tags are still loading, so tag results may be missing.",
    severity: SearchErrorSeverity.warning,
    sourceLabel: "Tags",
  ),
];

/// How a story preview answers, by the name a story knob shows; null keeps
/// the preview loading.
const Map<String, SearchPreviewRequestResult?> storyPreviewAnswers = {
  "Data": SearchPreviewRequestResult.data(
    data: "A dialogue page of The Lost Village, in Act 1.",
  ),
  "Loading": null,
  "Error": SearchPreviewRequestResult.error(
    message: "The realm did not answer. Move away and back to retry.",
  ),
};

/// A search surface for the widgets inside a [SearchRoot]: its source
/// answers with [snapshot], each result offers [storySearchCommands], and
/// [commandState] stands for what the last command did. [previewed] names
/// the result shown in the preview, which answers with [previewAnswer].
class StorySearchRoot extends StatelessWidget {
  const StorySearchRoot({
    required this.snapshot,
    required this.child,
    this.commandState = const SearchCommandExecutionState.idle(),
    this.previewed,
    this.previewAnswer = const SearchPreviewRequestResult.data(data: "Preview"),
    super.key,
  });

  final SearchSourceSnapshot snapshot;
  final SearchCommandExecutionState commandState;
  final String? previewed;
  final SearchPreviewRequestResult? previewAnswer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SearchRoot(
      create: (ref) {
        final controller = _StorySearchController(
          commandState: commandState,
          session: SearchSession<void>(
            source: storySearchSource(snapshot, previewAnswer: previewAnswer),
            interaction: SearchInteraction(
              activation: SearchActivation.command(
                resolve: (_) => storyOpenCommandId,
                dependencies: const [],
              ),
              selectionMode: SearchSelectionMode.single,
              commands: storySearchCommands,
            ),
          ),
        );
        final previewedResult = controller.snapshot.nodes
            .walk()
            .whereType<SearchResultNode>()
            .map((node) => node.result)
            .where((result) => result.id == previewed)
            .firstOrNull;
        if (previewedResult != null) controller.preview(previewedResult);
        return controller;
      },
      child: child,
    );
  }
}

/// A search controller whose command state stays [commandState], so a story
/// shows a running, completed or failed command without waiting for one.
final class _StorySearchController extends SearchController<void> {
  _StorySearchController({required this.commandState, required super.session})
    : super(baseSelectors: const []);

  @override
  final SearchCommandExecutionState commandState;
}

/// The command states a story knob picks, by name, each about the
/// [storyFirstResultId] result.
final Map<String, SearchCommandExecutionState> storyCommandStates = {
  "Idle": const SearchCommandExecutionState.idle(),
  "Running": SearchCommandExecutionState.running(
    command: storyOpenCommandId,
    resultIds: {storyFirstResultId},
  ),
  "Completed": SearchCommandExecutionState.completed(
    command: storyOpenCommandId,
    resultIds: {storyFirstResultId},
  ),
  "Failed": SearchCommandExecutionState.failed(
    command: storyOpenCommandId,
    resultIds: {storyFirstResultId},
    message: "The realm did not answer. Press Open page to try again.",
  ),
};

/// Knobs that choose what a search story's source and commands show.
extension SearchStoryKnobs on KnobsBuilder {
  /// The Results knob over [options], names of [storySearchSnapshots] (all
  /// of them when null), starting at [initial]; returns the snapshot.
  SearchSourceSnapshot searchResults({
    String initial = "Sections",
    List<String>? options,
  }) {
    final chosen = object.dropdown<String>(
      label: "Results",
      options: options ?? storySearchSnapshots.keys.toList(),
      initialOption: initial,
    );
    return storySearchSnapshots[chosen]!;
  }

  /// The Command on Arrival knob over [storyCommandStates]; returns the
  /// command state.
  SearchCommandExecutionState searchCommand() {
    final chosen = object.segmented<String>(
      label: "Command on Arrival",
      options: storyCommandStates.keys.toList(),
      initialOption: "Idle",
    );
    return storyCommandStates[chosen]!;
  }
}

/// The row renderers of [storyResultType] results.
final Map<String, SearchResultRowBuilder> storySearchRowRenderers = {
  storyResultType.rowRendererId: (row) => SearchResultRow(
    row: row,
    density: SearchResultDensity.card,
    accent: const Color(0xff3f51b5),
    leading: const Icon(Icons.article_outlined),
    kindLabel: "page",
    title: row.result.title ?? row.result.id,
    body: switch (row.result.subtitle) {
      final subtitle? => SearchResultDescription(description: subtitle),
      null => null,
    },
  ),
};

/// The preview renderers of [storyResultType] results: the result's title
/// above its preview data, a shimmer while it loads, or the failure.
final Map<String, SearchResultPreviewBuilder> storySearchPreviewRenderers = {
  storyResultType.previewRendererId!: _StoryPreview.new,
};

class _StoryPreview extends StatelessWidget {
  const _StoryPreview(this.preview);

  final SearchResultPreviewContext preview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.space4),
      child: switch (preview) {
        SearchResultPreviewContextLoading() => ShimmerBox.rectangle(
          height: 120,
        ),
        SearchResultPreviewContextData(:final result, :final data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: context.spacing.space2,
          children: [
            Text(
              result.title ?? result.id,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(data.toString(), style: context.text.sentence),
          ],
        ),
        SearchResultPreviewContextError(:final message) => Text(
          message,
          style: context.text.sentence.copyWith(
            color: context.colors.dangerText,
          ),
        ),
      },
    );
  }
}
