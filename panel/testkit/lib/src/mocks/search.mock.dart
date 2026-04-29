import "dart:async";

import "package:flutter/material.dart" hide Page;
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_type_extensions.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/src/mocks/books.mock.dart";
import "package:typewriter_testkit/src/mocks/entries.mock.dart";
import "package:typewriter_testkit/src/mocks/pages.mock.dart";
import "package:typewriter_testkit/src/mocks/tag.mock.dart";

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

const mockBlueprintSearchResultType = SearchResultType(
  id: "blueprint",
  rowRendererId: "mockBlueprintRow",
  previewRendererId: "mockBlueprintPreview",
  label: "Blueprint",
);

const mockBookSearchResultType = SearchResultType(
  id: "book",
  rowRendererId: "mockBookRow",
  previewRendererId: "mockBookPreview",
  label: "Book",
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

final class MockSearchPayload {
  const MockSearchPayload({
    required this.kind,
    required this.source,
    required this.fields,
    this.tags = const [],
  });

  final String kind;
  final Object source;
  final Map<String, String> fields;
  final List<String> tags;

  Iterable<String> valuesForSelector(String selectorId) {
    return switch ((kind, selectorId)) {
      ("book", "tag") => tags,
      ("page", "tag") => tags,
      ("page", "book") => [fields["book"] ?? "", fields["bookId"] ?? ""],
      ("page", "chapter") => [fields["chapter"] ?? ""],
      ("page", "pageType") => [fields["pageType"] ?? ""],
      ("entry", "tag") => tags,
      ("entry", "book") => [fields["book"] ?? "", fields["bookId"] ?? ""],
      ("entry", "chapter") => [fields["chapter"] ?? ""],
      ("entry", "page") => [fields["page"] ?? "", fields["pageId"] ?? ""],
      ("entry", "entryType") => [fields["entryType"] ?? ""],
      ("entry", "extension") => [fields["extension"] ?? ""],
      ("blueprint", "tag") => tags,
      ("blueprint", "entryType") => [fields["entryType"] ?? ""],
      ("blueprint", "extension") => [fields["extension"] ?? ""],
      ("tag", "tag") => tags,
      _ => const [],
    };
  }

  Iterable<String> get searchableValues sync* {
    yield kind;
    yield* fields.values;
    yield* tags;
  }

  @override
  String toString() => [...searchableValues].join(" ");
}

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
    final payload = result.payload;
    final searchableValues = payload is MockSearchPayload
        ? payload.searchableValues
        : [
            result.id,
            result.title,
            result.subtitle,
            result.type.id,
            result.type.label,
            result.payload.toString(),
          ].whereType<String>();

    final haystack = searchableValues.join(" ").toLowerCase();
    final queryTerms = query
        .split(RegExp(r"\s+"))
        .where((term) => term.isNotEmpty)
        .map((term) => term.toLowerCase())
        .toList();
    final queryMatches = queryTerms.every(haystack.contains);
    final selectorsMatch = selectors.every((selector) {
      final value = selector.value?.toLowerCase();
      if (value == null || value.isEmpty) return true;
      if (payload case MockSearchPayload payload) {
        return payload
            .valuesForSelector(selector.selectorId)
            .map((field) => field.toLowerCase())
            .any((field) => field.contains(value));
      }
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

final class MockSearchIndex {
  const MockSearchIndex({
    required this.tags,
    required this.books,
    required this.pages,
    required this.entries,
    required this.blueprints,
  });

  final List<Tag> tags;
  final List<Book> books;
  final List<MockPageRecord> pages;
  final List<MockEntryRecord> entries;
  final List<ElementBlueprint> blueprints;

  Map<String, String> get tagNameById => {
    for (final tag in tags) tag.tagId: tag.name,
  };
}

final class MockPageRecord {
  const MockPageRecord({required this.book, required this.page});

  final Book book;
  final Page page;
}

final class MockEntryRecord {
  const MockEntryRecord({required this.page, required this.entry});

  final MockPageRecord page;
  final EntryDefinition entry;
}

MockSearchIndex mockSearchIndex({
  int tagCount = 18,
  int bookCount = 8,
  int pagesPerBook = 5,
  int entryCount = 32,
  int blueprintCount = 18,
}) {
  final tags = generateTagBatch(tagCount);
  final books = List.generate(bookCount, (_) => generateRandomBook(tags)());
  final pages = [
    for (final book in books)
      for (var i = 0; i < pagesPerBook; i++)
        MockPageRecord(book: book, page: generateRandomPage()),
  ];
  final entries = [
    for (var i = 0; i < entryCount; i++)
      MockEntryRecord(
        page: pages[i % pages.length],
        entry: generateRandomEntryDefinition(),
      ),
  ];
  final blueprintsById = <String, ElementBlueprint>{};
  for (final blueprint in <ElementBlueprint>[
    ...entries.map((record) => record.entry.blueprint),
    ...List.generate(blueprintCount, (_) => generateRandomElementBlueprint()),
  ]) {
    blueprintsById[blueprint.id] = blueprint;
  }
  return MockSearchIndex(
    tags: tags,
    books: books,
    pages: pages,
    entries: entries,
    blueprints: blueprintsById.values.toList(),
  );
}

List<QuerySelectorDefinition> mockSearchQuerySelectors(MockSearchIndex index) {
  final tagNames = index.tags.map((tag) => tag.name).toSet().toList();
  final bookTitles = index.books.map((book) => book.title).toSet().toList();
  final chapters = index.pages
      .map((record) => record.page.chapter)
      .where((chapter) => chapter.isNotEmpty)
      .toSet()
      .toList();
  final pageNames = index.pages
      .map((record) => record.page.name)
      .toSet()
      .toList();
  final pageTypes = index.pages
      .map((record) => _pageTypeLabel(record.page.type))
      .toSet()
      .toList();
  final entryTypes = index.blueprints
      .map((blueprint) => blueprint.name)
      .toSet()
      .toList();
  final extensions = index.blueprints
      .map((blueprint) => blueprint.extension)
      .toSet()
      .toList();

  return [
    KeyValueSelectorDefinition(
      id: "tag",
      key: "#",
      value: QuerySelectorValue.enumValue(tagNames),
      color: safeColors[6],
    ),
    KeyValueSelectorDefinition(
      id: "book",
      key: "book:",
      value: QuerySelectorValue.enumValue(bookTitles),
      color: safeColors[2],
    ),
    KeyValueSelectorDefinition(
      id: "chapter",
      key: "chapter:",
      value: QuerySelectorValue.enumValue(chapters),
      color: safeColors[5],
    ),
    KeyValueSelectorDefinition(
      id: "page",
      key: "page:",
      value: QuerySelectorValue.enumValue(pageNames),
      color: safeColors[3],
    ),
    KeyValueSelectorDefinition(
      id: "pageType",
      key: "pageType:",
      value: QuerySelectorValue.enumValue(pageTypes),
      color: safeColors[4],
    ),
    KeyValueSelectorDefinition(
      id: "entryType",
      key: "entryType:",
      value: QuerySelectorValue.enumValue(entryTypes),
      color: safeColors[8],
    ),
    KeyValueSelectorDefinition(
      id: "extension",
      key: "extension:",
      value: QuerySelectorValue.enumValue(extensions),
      color: safeColors[9],
    ),
  ];
}

List<SearchNode> mockMixedGlobalSearchNodes([MockSearchIndex? index]) {
  final searchIndex = index ?? mockSearchIndex();
  return [
    mockSearchSection(
      id: "books",
      title: "Books",
      subtitle: "Books and tags",
      children: searchIndex.books
          .map((book) => _bookSearchNode(book, searchIndex))
          .toList(),
    ),
    mockSearchSection(
      id: "pages",
      title: "Pages",
      subtitle: "Books and chapters",
      children: searchIndex.pages
          .map((record) => _pageSearchNode(record, searchIndex))
          .toList(),
    ),
    mockSearchSection(
      id: "entries",
      title: "Entries",
      subtitle: "Quest logic",
      children: searchIndex.entries
          .map((record) => _entrySearchNode(record, searchIndex))
          .toList(),
    ),
    mockSearchSection(
      id: "blueprints",
      title: "Blueprints",
      subtitle: "Entry definitions",
      children: searchIndex.blueprints.map(_blueprintSearchNode).toList(),
    ),
    mockSearchSection(
      id: "tags",
      title: "Tags",
      subtitle: "Workspace labels",
      children: searchIndex.tags.map(_tagSearchNode).toList(),
    ),
  ];
}

SearchNode _bookSearchNode(Book book, MockSearchIndex index) {
  final tags = _tagNames(book.tagIds, index);
  final payload = MockSearchPayload(
    kind: "book",
    source: book,
    tags: tags,
    fields: {
      "id": book.bookId,
      "bookId": book.bookId,
      "name": book.title,
      "title": book.title,
    },
  );
  return mockSearchResultNode(
    id: "book.${book.bookId}",
    type: mockBookSearchResultType,
    title: book.title.formatted,
    subtitle: "Book / ${tags.length} tags",
    payload: payload,
    actions: const [MockCloseSearchAction, MockUpdateQuerySearchAction],
  );
}

SearchNode _pageSearchNode(MockPageRecord record, MockSearchIndex index) {
  final page = record.page;
  final book = record.book;
  final pageType = _pageTypeLabel(page.type);
  final payload = MockSearchPayload(
    kind: "page",
    source: page,
    tags: [pageType, ..._tagNames(book.tagIds, index)],
    fields: {
      "id": page.pageId,
      "pageId": page.pageId,
      "name": page.name,
      "title": page.name,
      "book": book.title,
      "bookId": book.bookId,
      "chapter": page.chapter,
      "pageType": pageType,
    },
  );
  return mockSearchResultNode(
    id: "page.${page.pageId}",
    type: mockPageSearchResultType,
    title: page.name.formatted,
    subtitle: "${book.title.formatted} / ${page.chapter.formatted} / $pageType",
    payload: payload,
    actions: const [
      MockCloseSearchAction,
      MockUpdateQuerySearchAction,
      MockRefreshSearchAction,
    ],
  );
}

SearchNode _entrySearchNode(MockEntryRecord record, MockSearchIndex index) {
  final entry = record.entry;
  final page = record.page.page;
  final book = record.page.book;
  final blueprint = entry.blueprint;
  final payload = MockSearchPayload(
    kind: "entry",
    source: entry,
    tags: [...blueprint.tags, ..._tagNames(book.tagIds, index)],
    fields: {
      "id": entry.id,
      "name": entry.name,
      "title": entry.name,
      "book": book.title,
      "bookId": book.bookId,
      "page": page.name,
      "pageId": page.pageId,
      "chapter": page.chapter,
      "entryType": blueprint.name,
      "extension": blueprint.extension,
    },
  );
  return mockSearchResultNode(
    id: "entry.${entry.id}",
    type: mockEntrySearchResultType,
    title: entry.name,
    subtitle: "${blueprint.name} / ${page.name.formatted}",
    payload: payload,
    actions: const [MockCloseSearchAction, MockRefreshSearchAction],
  );
}

SearchNode _blueprintSearchNode(ElementBlueprint blueprint) {
  final payload = MockSearchPayload(
    kind: "blueprint",
    source: blueprint,
    tags: blueprint.tags,
    fields: {
      "id": blueprint.id,
      "name": blueprint.name,
      "title": blueprint.name,
      "entryType": blueprint.name,
      "extension": blueprint.extension,
      "description": blueprint.description,
    },
  );
  return mockSearchResultNode(
    id: "blueprint.${blueprint.id}",
    type: mockBlueprintSearchResultType,
    title: blueprint.name,
    subtitle: "${blueprint.extension} / ${blueprint.tags.join(", ")}",
    payload: payload,
    actions: const [MockUpdateQuerySearchAction, MockRefreshSearchAction],
  );
}

SearchNode _tagSearchNode(Tag tag) {
  final payload = MockSearchPayload(
    kind: "tag",
    source: tag,
    tags: [tag.name, tag.tagId, ...tag.parentIds],
    fields: {"id": tag.tagId, "name": tag.name, "title": tag.name},
  );
  return mockSearchResultNode(
    id: "tag.${tag.tagId}",
    type: mockTagSearchResultType,
    title: tag.name.formatted,
    subtitle: "Tag / ${tag.parentIds.length} parents",
    payload: payload,
    actions: const [MockUpdateQuerySearchAction, MockRefreshSearchAction],
  );
}

List<String> _tagNames(Iterable<String> tagIds, MockSearchIndex index) {
  final names = index.tagNameById;
  return tagIds.map((id) => names[id] ?? id).toList();
}

String _pageTypeLabel(PageType type) {
  try {
    return type.displayName;
  } on UnsupportedError {
    return type.name.toLowerCase();
  }
}

Map<String, SearchPreviewRequestResult> mockSearchPreviewResults(
  MockSearchIndex index,
) {
  final nodes = mockMixedGlobalSearchNodes(index);
  final resultNodes = nodes
      .whereType<SearchSectionNode>()
      .expand((section) => section.children)
      .whereType<SearchResultNode>();
  return {
    for (final node in resultNodes)
      node.result.id: SearchPreviewRequestResult.data(
        data: MockSearchPreviewData(
          title: node.result.title ?? node.result.id,
          description: node.result.subtitle ?? "Mock search result",
          fields: node.result.payload is MockSearchPayload
              ? (node.result.payload as MockSearchPayload).fields
              : const {},
        ),
      ),
  };
}

List<SearchGuidance> mockSearchGuidance() {
  return const [
    SearchGuidance(
      id: "selectors",
      title: "Use selectors to narrow results",
      description:
          "Try #quest, book:main, chapter:intro, page:spawn, pageType:sequence, entryType:dialogue, or extension:basic.",
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

SearchSource mockMixedGlobalSearchSource({
  MockSearchDisplayState state = MockSearchDisplayState.ready,
  List<QuerySelectorDefinition> selectors = const [],
  Duration searchDelay = Duration.zero,
}) {
  final index = mockSearchIndex();
  final searchSelectors = selectors.merge(mockSearchQuerySelectors(index));
  return MockSearchSource(
    state: state,
    sourceSelectors: searchSelectors,
    nodes: mockMixedGlobalSearchNodes(index),
    actions: mockSearchActions(),
    guidance: mockSearchGuidance(),
    errorSummaries: mockSearchErrors(),
    previewResults: mockSearchPreviewResults(index),
    searchDelay: searchDelay,
  );
}
