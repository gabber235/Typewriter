import "package:typewriter_panel/typewriter_panel.dart";

export "query.dart";

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

final class MockSearchPreviewData {
  const MockSearchPreviewData({
    required this.title,
    required this.description,
    this.fields = const {},
  });

  final String title;
  final String description;
  final Map<String, String> fields;

  @override
  String toString() {
    final details = fields.entries
        .map((e) => "${e.key}: ${e.value}")
        .join("\n");
    if (details.isEmpty) return "$title\n\n$description";
    return "$title\n\n$description\n\n$details";
  }
}

final class MockSearchSource implements SearchSource {
  MockSearchSource({
    this.state = MockSearchDisplayState.ready,
    this.sourceSelectors = const [],
    this.nodes = const [],
    this.guidance = const [],
    this.errorSummaries = const [],
    this.previewResults = const {},
    this.searchDelay = Duration.zero,
  });

  final MockSearchDisplayState state;
  final List<QuerySelectorDefinition> sourceSelectors;
  final List<SearchNode> nodes;
  final List<SearchGuidance> guidance;
  final List<SearchErrorSummary> errorSummaries;
  final Map<String, SearchPreviewRequestResult> previewResults;
  final Duration searchDelay;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  Timer? _searchTimer;
  var initializeCount = 0;
  var disposeCount = 0;
  final searches = <SearchQueryContext>[];
  final previewRequests = <SearchPreviewRequest>[];

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => sourceSelectors;

  @override
  void initialize(SearchQueryContext context) {
    initializeCount++;
    scheduleMicrotask(() {
      if (_snapshots.isClosed) return;
      _snapshots.add(_snapshotForState(nodes));
    });
  }

  @override
  void search(SearchQueryContext context) {
    searches.add(context);
    _searchTimer?.cancel();
    if (searchDelay == Duration.zero) {
      _emitSearchResult(context);
      return;
    }
    _snapshots.add(
      SearchSourceSnapshot.loading(nodes: nodes, guidance: guidance),
    );
    _searchTimer = Timer(searchDelay, () => _emitSearchResult(context));
  }

  void _emitSearchResult(SearchQueryContext context) {
    if (_snapshots.isClosed) return;
    _snapshots.add(_snapshotForState(_filterNodes(context)));
  }

  SearchSourceSnapshot _snapshotForState(List<SearchNode> nextNodes) {
    return switch (state) {
      MockSearchDisplayState.ready => SearchSourceSnapshot.ready(
        nodes: nextNodes,
        guidance: guidance,
      ),
      MockSearchDisplayState.loading => SearchSourceSnapshot.loading(
        nodes: nextNodes,
        guidance: guidance,
      ),
      MockSearchDisplayState.error => SearchSourceSnapshot.error(
        nodes: nextNodes,
        guidance: guidance,
        errorSummaries: errorSummaries.isEmpty
            ? const [
                SearchErrorSummary(
                  id: "mockError",
                  message: "Search source failed",
                  severity: SearchErrorSeverity.error,
                  sourceLabel: "Mock source",
                ),
              ]
            : errorSummaries,
      ),
    };
  }

  List<SearchNode> _filterNodes(SearchQueryContext context) {
    final query = context.normalizedQuery.trim().toLowerCase();
    if (query.isEmpty && context.selectors.isEmpty) return nodes;
    return nodes
        .map(
          (node) => _filterNode(
            node,
            query,
            context.selectors,
            context.selectorExpression,
          ),
        )
        .nonNulls
        .toList();
  }

  SearchNode? _filterNode(
    SearchNode node,
    String query,
    List<SearchParsedSelector> selectors,
    SearchSelectorExpression? selectorExpression,
  ) {
    return switch (node) {
      SearchSectionNode(
        :final id,
        :final title,
        :final subtitle,
        :final children,
      ) =>
        _filterSection(
          id,
          title,
          subtitle,
          children,
          query,
          selectors,
          selectorExpression,
        ),
      SearchResultNode(:final result) =>
        _matches(result, query, selectors, selectorExpression) ? node : null,
    };
  }

  SearchNode? _filterSection(
    String id,
    String title,
    String? subtitle,
    List<SearchNode> children,
    String query,
    List<SearchParsedSelector> selectors,
    SearchSelectorExpression? selectorExpression,
  ) {
    final filtered = children
        .map((node) => _filterNode(node, query, selectors, selectorExpression))
        .nonNulls
        .toList();
    if (filtered.isEmpty) return null;
    return SearchNode.section(
      id: id,
      title: title,
      subtitle: subtitle,
      children: filtered,
    );
  }

  bool _matches(
    SearchResult result,
    String query,
    List<SearchParsedSelector> selectors,
    SearchSelectorExpression? selectorExpression,
  ) {
    final payload = result.payload;
    final haystack = _searchableValuesForResult(result).join(" ").toLowerCase();
    final queryTerms = query
        .split(RegExp(r"\s+"))
        .where((term) => term.isNotEmpty)
        .map((term) => term.toLowerCase())
        .toList();
    final queryMatches = queryTerms.every(haystack.contains);
    final selectorsMatch = selectorExpression == null
        ? selectors.every(
            (selector) => _matchesSelector(payload, haystack, selector),
          )
        : _matchesSelectorExpression(payload, haystack, selectorExpression);
    return queryMatches && selectorsMatch;
  }

  bool _matchesSelectorExpression(
    Object payload,
    String haystack,
    SearchSelectorExpression expression,
  ) {
    return switch (expression) {
      SearchSelectorLeafExpression(:final selector) => _matchesSelector(
        payload,
        haystack,
        selector,
      ),
      SearchSelectorBinaryExpression(
        :final operator,
        :final left,
        :final right,
      ) =>
        switch (operator) {
          SearchSelectorOperator.and =>
            _matchesSelectorExpression(payload, haystack, left) &&
                _matchesSelectorExpression(payload, haystack, right),
          SearchSelectorOperator.or =>
            _matchesSelectorExpression(payload, haystack, left) ||
                _matchesSelectorExpression(payload, haystack, right),
        },
      SearchSelectorNotExpression(:final expression) =>
        !_matchesSelectorExpression(payload, haystack, expression),
    };
  }

  bool _matchesSelector(
    Object payload,
    String haystack,
    SearchParsedSelector selector,
  ) {
    final value = selector.value?.toLowerCase();
    if (value == null || value.isEmpty) return true;
    return haystack.contains(value);
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async {
    previewRequests.add(request);
    await Future<void>.delayed(2.seconds);
    return previewResults[request.resultId] ??
        const SearchPreviewRequestResult.error(
          message: "No preview data found",
        );
  }

  @override
  void dispose() {
    disposeCount++;
    _searchTimer?.cancel();
    unawaited(_snapshots.close());
  }
}

Iterable<String> _searchableValuesForResult(SearchResult result) sync* {
  yield result.id;
  yield result.type.id;
  if (result.type.label case final label?) yield label;
  if (result.title case final title?) yield title;
  if (result.subtitle case final subtitle?) yield subtitle;
  yield result.payload.toString();
}

SearchSession<void> mockSearchSession(SearchSource source) => SearchSession(
  source: source,
  interaction: SearchInteraction(
    activation: SearchActivation.custom(
      dependencies: const [],
      evaluate: (context, result) => const SearchActivationState.hidden(),
      activate: (context, result) async =>
          const SearchActivationResult.keepOpen(),
    ),
    selectionMode: SearchSelectionMode.single,
  ),
);

SearchSource mockMixedGlobalSearchSource({
  MockSearchDisplayState state = MockSearchDisplayState.ready,
  bool hasData = true,
  bool includeGuidance = false,
  List<QuerySelectorDefinition> selectors = const [],
  Duration searchDelay = Duration.zero,
}) => MockSearchSource(
  state: state,
  sourceSelectors: selectors,
  searchDelay: searchDelay,
  guidance: includeGuidance
      ? const [
          SearchGuidance(
            id: "widgetbook.search.help",
            title: "Search resources by name",
          ),
        ]
      : const [],
  nodes: hasData
      ? [
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
        ]
      : const [],
);
