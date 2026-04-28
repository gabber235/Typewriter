import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/logic/search/search.dart";

const mockPageSearchResultType = SearchResultType(
  id: "page",
  rowRendererId: "mockPageRow",
  previewRendererId: "mockPagePreview",
  label: "Page",
);

const mockEntrySearchResultType = SearchResultType(
  id: "entry",
  rowRendererId: "mockEntryRow",
  previewRendererId: "mockEntryPreview",
  label: "Entry",
);

const mockTagSearchResultType = SearchResultType(
  id: "tag",
  rowRendererId: "mockTagRow",
  previewRendererId: "mockTagPreview",
  label: "Tag",
);

const mockServiceSearchResultType = SearchResultType(
  id: "service",
  rowRendererId: "mockServiceRow",
  previewRendererId: "mockServicePreview",
  label: "Service",
);

const mockMemberSearchResultType = SearchResultType(
  id: "member",
  rowRendererId: "mockMemberRow",
  label: "Member",
);

enum MockSearchDisplayState { ready, empty, loading, error }

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
    this.actions = const {},
    this.guidance = const [],
    this.errorSummaries = const [],
    this.previewResults = const {},
    this.searchDelay = Duration.zero,
  });

  final MockSearchDisplayState state;
  final List<QuerySelectorDefinition> sourceSelectors;
  final List<SearchNode> nodes;
  final Map<Type, SearchAction> actions;
  final List<SearchGuidance> guidance;
  final List<SearchErrorSummary> errorSummaries;
  final Map<String, SearchPreviewRequestResult> previewResults;
  final Duration searchDelay;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  final _selectors = StreamController<List<QuerySelectorDefinition>>.broadcast(
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
  Stream<List<QuerySelectorDefinition>> get selectors => _selectors.stream;

  @override
  void initialize() {
    initializeCount++;
    scheduleMicrotask(() {
      if (_selectors.isClosed || _snapshots.isClosed) return;
      _selectors.add(sourceSelectors);
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
      SearchSourceSnapshot.loading(
        nodes: nodes,
        actions: actions,
        guidance: guidance,
        errorSummaries: errorSummaries,
      ),
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
        actions: actions,
        guidance: guidance,
      ),
      MockSearchDisplayState.empty => SearchSourceSnapshot.ready(
        nodes: const [],
        actions: actions,
        guidance: guidance,
      ),
      MockSearchDisplayState.loading => SearchSourceSnapshot.loading(
        nodes: nextNodes,
        actions: actions,
        guidance: guidance,
      ),
      MockSearchDisplayState.error => SearchSourceSnapshot.error(
        nodes: nextNodes,
        actions: actions,
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
        .map((node) => _filterNode(node, query, context.selectors))
        .nonNulls
        .toList();
  }

  SearchNode? _filterNode(
    SearchNode node,
    String query,
    List<SearchParsedSelector> selectors,
  ) {
    return switch (node) {
      SearchSectionNode(
        :final id,
        :final title,
        :final subtitle,
        :final children,
      ) =>
        _filterSection(id, title, subtitle, children, query, selectors),
      SearchResultNode(:final result) =>
        _matches(result, query, selectors) ? node : null,
    };
  }

  SearchNode? _filterSection(
    String id,
    String title,
    String? subtitle,
    List<SearchNode> children,
    String query,
    List<SearchParsedSelector> selectors,
  ) {
    final filtered = children
        .map((node) => _filterNode(node, query, selectors))
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
  ) {
    final haystack = [
      result.id,
      result.title,
      result.subtitle,
      result.type.id,
      result.type.label,
      result.payload.toString(),
    ].whereType<String>().join(" ").toLowerCase();

    final queryMatches = query.isEmpty || haystack.contains(query);
    final selectorsMatch = selectors.every((selector) {
      final value = selector.value?.toLowerCase();
      if (value == null || value.isEmpty) return true;
      return haystack.contains(value);
    });
    return queryMatches && selectorsMatch;
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async {
    previewRequests.add(request);
    await Future<void>.delayed(180.ms);
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
    unawaited(_selectors.close());
  }
}

SearchResult mockSearchResult({
  required String id,
  required SearchResultType type,
  required String title,
  String? subtitle,
  Object? payload,
  List<Type> actions = const [],
}) {
  return SearchResult(
    id: id,
    type: type,
    payload: payload ?? title,
    actions: actions,
    title: title,
    subtitle: subtitle,
  );
}

SearchNode mockSearchResultNode({
  required String id,
  required SearchResultType type,
  required String title,
  String? subtitle,
  Object? payload,
  List<Type> actions = const [],
}) {
  return SearchNode.result(
    result: mockSearchResult(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      payload: payload,
      actions: actions,
    ),
  );
}

SearchNode mockSearchSection({
  required String id,
  required String title,
  String? subtitle,
  required List<SearchNode> children,
}) {
  return SearchNode.section(
    id: id,
    title: title,
    subtitle: subtitle,
    children: children,
  );
}

final class MockCloseSearchAction extends SingleSearchAction {
  MockCloseSearchAction();

  @override
  String get label => "Open";

  @override
  int get priority => 0;

  @override
  Future<SearchActionResult> execute(SearchResult result) async {
    await Future<void>.delayed(250.ms);
    return const SearchActionResult.completed();
  }
}

final class MockRefreshSearchAction extends BatchSearchAction {
  MockRefreshSearchAction();

  @override
  String get label => "Refresh";

  @override
  int get priority => 20;

  @override
  Future<SearchActionResult> executeBatch(List<SearchResult> results) async {
    await Future<void>.delayed(300.ms);
    return const SearchActionResult.completed(
      effect: SearchActionEffect.refresh(),
    );
  }
}

final class MockUpdateQuerySearchAction extends SingleSearchAction {
  MockUpdateQuerySearchAction();

  @override
  String get label => "Related";

  @override
  int get priority => 10;

  @override
  Future<SearchActionResult> execute(SearchResult result) async {
    await Future<void>.delayed(250.ms);
    return SearchActionResult.completed(
      effect: SearchActionEffect.updateQuery(
        updateQuery: result.type.label ?? result.title ?? "",
      ),
    );
  }
}

final class MockFailSearchAction extends RepeatedSearchAction {
  MockFailSearchAction();

  @override
  String get label => "Fail";

  @override
  int get priority => 30;

  @override
  Color? get color => Colors.red;

  @override
  Future<SearchActionResult> execute(SearchResult result) async {
    await Future<void>.delayed(250.ms);
    return SearchActionResult.failed(
      message: "Could not process ${result.title ?? result.id}",
    );
  }
}

Map<Type, SearchAction> mockSearchActions() {
  final close = MockCloseSearchAction();
  final refresh = MockRefreshSearchAction();
  final updateQuery = MockUpdateQuerySearchAction();
  final fail = MockFailSearchAction();
  return {
    MockCloseSearchAction: close,
    MockRefreshSearchAction: refresh,
    MockUpdateQuerySearchAction: updateQuery,
    MockFailSearchAction: fail,
  };
}

List<SearchNode> mockMixedGlobalSearchNodes() {
  return [
    mockSearchSection(
      id: "pages",
      title: "Pages",
      subtitle: "Books and chapters",
      children: [
        mockSearchResultNode(
          id: "page.intro",
          type: mockPageSearchResultType,
          title: "Welcome Quest",
          subtitle: "Starter Book / Chapter 1",
          actions: const [
            MockCloseSearchAction,
            MockUpdateQuerySearchAction,
            MockRefreshSearchAction,
          ],
        ),
        mockSearchResultNode(
          id: "page.market",
          type: mockPageSearchResultType,
          title: "Market Day",
          subtitle: "Town Book / Side Stories",
          actions: const [
            MockCloseSearchAction,
            MockUpdateQuerySearchAction,
            MockFailSearchAction,
          ],
        ),
      ],
    ),
    mockSearchSection(
      id: "entries",
      title: "Entries",
      subtitle: "Quest logic",
      children: [
        mockSearchResultNode(
          id: "entry.dialogue.winston",
          type: mockEntrySearchResultType,
          title: "Winston Dialogue",
          subtitle: "Dialogue entry / active",
          actions: const [MockCloseSearchAction, MockRefreshSearchAction],
        ),
        mockSearchResultNode(
          id: "entry.objective.zombie",
          type: mockEntrySearchResultType,
          title: "Kill Zombie Objective",
          subtitle: "Objective entry / draft",
          actions: const [MockCloseSearchAction, MockUpdateQuerySearchAction],
        ),
      ],
    ),
    mockSearchSection(
      id: "workspace",
      title: "Workspace",
      subtitle: "Tags, services, and members",
      children: [
        mockSearchResultNode(
          id: "tag.quest",
          type: mockTagSearchResultType,
          title: "quest",
          subtitle: "Tag / 18 entries",
          actions: const [MockUpdateQuerySearchAction, MockRefreshSearchAction],
        ),
        mockSearchResultNode(
          id: "service.minecraft",
          type: mockServiceSearchResultType,
          title: "Minecraft Realm",
          subtitle: "Service / online",
          actions: const [MockCloseSearchAction, MockFailSearchAction],
        ),
        mockSearchResultNode(
          id: "member.ava",
          type: mockMemberSearchResultType,
          title: "Ava Stone",
          subtitle: "Member / editor",
          actions: const [MockCloseSearchAction],
        ),
      ],
    ),
  ];
}

List<SearchGuidance> mockSearchGuidance() {
  return const [
    SearchGuidance(
      id: "selectors",
      title: "Use selectors to narrow results",
      description: "Try type:entry, status:active, #quest, or @editor.",
      visibility: SearchGuidanceVisibility.always,
      priority: 0,
    ),
    SearchGuidance(
      id: "empty",
      title: "No matching results",
      description: "Try a broader query or remove one selector.",
      visibility: SearchGuidanceVisibility.emptyOnly,
      priority: 10,
    ),
  ];
}

List<SearchErrorSummary> mockSearchErrors() {
  return const [
    SearchErrorSummary(
      id: "entriesUnavailable",
      message: "Entry index timed out. Showing cached results.",
      severity: SearchErrorSeverity.warning,
      sourceLabel: "Entries",
    ),
    SearchErrorSummary(
      id: "membersUnavailable",
      message: "Member search failed.",
      severity: SearchErrorSeverity.error,
      sourceLabel: "Members",
    ),
  ];
}

Map<String, SearchPreviewRequestResult> mockSearchPreviewResults() {
  return const {
    "page.intro": SearchPreviewRequestResult.data(
      data: MockSearchPreviewData(
        title: "Welcome Quest",
        description: "Main onboarding page shown to new players.",
        fields: {
          "Book": "Starter Book",
          "Chapter": "Chapter 1",
          "Status": "Published",
        },
      ),
    ),
    "page.market": SearchPreviewRequestResult.data(
      data: MockSearchPreviewData(
        title: "Market Day",
        description: "Optional page that introduces trading NPCs.",
        fields: {
          "Book": "Town Book",
          "Chapter": "Side Stories",
          "Status": "Draft",
        },
      ),
    ),
    "entry.dialogue.winston": SearchPreviewRequestResult.data(
      data: MockSearchPreviewData(
        title: "Winston Dialogue",
        description: "Branching dialogue used near spawn.",
        fields: {"Type": "Dialogue", "Speakers": "Winston, Player"},
      ),
    ),
    "entry.objective.zombie": SearchPreviewRequestResult.error(
      message: "Objective preview renderer failed",
    ),
    "tag.quest": SearchPreviewRequestResult.data(
      data: MockSearchPreviewData(
        title: "quest",
        description: "Tag used by quest pages and entries.",
        fields: {"Entries": "18", "Pages": "6"},
      ),
    ),
    "service.minecraft": SearchPreviewRequestResult.data(
      data: MockSearchPreviewData(
        title: "Minecraft Realm",
        description: "Primary live service connection.",
        fields: {"Status": "Online", "Latency": "43 ms"},
      ),
    ),
  };
}

SearchSource mockMixedGlobalSearchSource({
  MockSearchDisplayState state = MockSearchDisplayState.ready,
  List<QuerySelectorDefinition> selectors = const [],
  Duration searchDelay = Duration.zero,
}) {
  return MockSearchSource(
    state: state,
    sourceSelectors: selectors,
    nodes: mockMixedGlobalSearchNodes(),
    actions: mockSearchActions(),
    guidance: mockSearchGuidance(),
    errorSummaries: mockSearchErrors(),
    previewResults: mockSearchPreviewResults(),
    searchDelay: searchDelay,
  );
}
