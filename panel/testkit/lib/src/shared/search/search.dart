import "dart:async";

import "package:flutter/material.dart" hide Page;
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/books.dart";
import "package:typewriter_testkit/src/features/organizations/features/realms/features/tags/tags.dart";

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
    final selectorValues = _valuesForSelector(
      payload,
      selector.selectorId,
    ).map((field) => field.toLowerCase());
    return selectorValues.any((field) => field.contains(value)) ||
        haystack.contains(value);
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

  final payload = result.payload;
  switch (payload) {
    case MockBookRecord():
      yield "book";
      yield payload.book.bookId.id;
      yield payload.book.title;
      yield payload.book.icon;
      yield* payload.tags;
    case MockPageRecord():
      final page = payload.page;
      final book = payload.book;
      yield "page";
      yield page.pageId.id;
      yield page.name;
      yield page.chapter;
      yield _pageKindLabel(page.kind);
      yield book.bookId.id;
      yield book.title;
      yield* book.tagIds.map((tagId) => tagId.id);
    case MockEntryRecord():
      final entry = payload.entry;
      final page = payload.page.page;
      final book = payload.page.book;
      final elementDefinition = entry.elementDefinition;
      yield "entry";
      yield entry.id;
      yield entry.name;
      yield page.pageId.id;
      yield page.name;
      yield page.chapter;
      yield book.bookId.id;
      yield book.title;
      yield elementDefinition.typeId.uuid;
      yield elementDefinition.qualifiedName;
      yield elementDefinition.name;
      yield elementDefinition.namespace;
      yield elementDefinition.description;
      yield* book.tagIds.map((tagId) => tagId.id);
    case ElementDefinition():
      yield "elementDefinition";
      yield payload.typeId.uuid;
      yield payload.qualifiedName;
      yield payload.name;
      yield payload.namespace;
      yield payload.description;
    case Tag():
      yield "tag";
      yield payload.tagId.id;
      yield payload.name;
      yield* payload.parentIds.map((parentId) => parentId.id);
    default:
      yield payload.toString();
  }
}

Iterable<String> _valuesForSelector(Object payload, String selectorId) sync* {
  switch (payload) {
    case MockBookRecord():
      switch (selectorId) {
        case "tag":
          yield* payload.tags;
        case "type":
          yield "book";
      }
    case MockPageRecord():
      final page = payload.page;
      final book = payload.book;
      switch (selectorId) {
        case "tag":
          yield _pageKindLabel(page.kind);
          yield* book.tagIds.map((tagId) => tagId.id);
        case "book":
          yield book.title;
          yield book.bookId.id;
        case "chapter":
          yield page.chapter;
        case "pageKind":
          yield _pageKindLabel(page.kind);
        case "type":
          yield "page";
      }
    case MockEntryRecord():
      final entry = payload.entry;
      final page = payload.page.page;
      final book = payload.page.book;
      final elementDefinition = entry.elementDefinition;
      switch (selectorId) {
        case "tag":
          yield* book.tagIds.map((tagId) => tagId.id);
        case "book":
          yield book.title;
          yield book.bookId.id;
        case "chapter":
          yield page.chapter;
        case "page":
          yield page.name;
          yield page.pageId.id;
        case "entryType":
          yield elementDefinition.name;
        case "namespace":
          yield elementDefinition.namespace;
        case "type":
          yield "entry";
      }
    case ElementDefinition():
      switch (selectorId) {
        case "entryType":
          yield payload.name;
        case "namespace":
          yield payload.namespace;
        case "type":
          yield "elementDefinition";
      }
    case Tag():
      switch (selectorId) {
        case "tag":
          yield payload.name;
          yield payload.tagId.id;
          yield* payload.parentIds.map((parentId) => parentId.id);
        case "type":
          yield "tag";
      }
  }
}

Map<String, String> _previewFieldsForPayload(Object payload) {
  return switch (payload) {
    MockBookRecord() => {
      "id": payload.book.bookId.id,
      "bookId": payload.book.bookId.id,
      "name": payload.book.title,
      "title": payload.book.title,
    },
    MockPageRecord() => {
      "id": payload.page.pageId.id,
      "pageId": payload.page.pageId.id,
      "name": payload.page.name,
      "title": payload.page.name,
      "book": payload.book.title,
      "bookId": payload.book.bookId.id,
      "chapter": payload.page.chapter,
      "pageKind": _pageKindLabel(payload.page.kind),
    },
    MockEntryRecord() => {
      "id": payload.entry.id,
      "name": payload.entry.name,
      "title": payload.entry.name,
      "book": payload.page.book.title,
      "bookId": payload.page.book.bookId.id,
      "page": payload.page.page.name,
      "pageId": payload.page.page.pageId.id,
      "chapter": payload.page.page.chapter,
      "entryType": payload.entry.elementDefinition.name,
      "namespace": payload.entry.elementDefinition.namespace,
    },
    ElementDefinition() => {
      "id": payload.typeId.uuid,
      "name": payload.name,
      "title": payload.name,
      "entryType": payload.name,
      "namespace": payload.namespace,
      "description": payload.description,
    },
    Tag() => {
      "id": payload.tagId.id,
      "name": payload.name,
      "title": payload.name,
    },
    _ => const {},
  };
}

SearchResult mockSearchResult({
  required String id,
  required SearchResultType type,
  required String title,
  String? subtitle,
  Object? payload,
}) {
  return SearchResult(
    id: id,
    type: type,
    payload: payload ?? title,
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
}) {
  return SearchNode.result(
    result: mockSearchResult(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      payload: payload,
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

const mockCloseSearchCommandId = SearchCommandId("mock.close");
const mockRefreshSearchCommandId = SearchCommandId("mock.refresh");
const mockUpdateQuerySearchCommandId = SearchCommandId("mock.related");
const mockFailSearchCommandId = SearchCommandId("mock.fail");

List<SearchCommand> mockSearchCommands() => [
  _mockCommand(
    id: mockCloseSearchCommandId,
    presentation: const SearchCommandPresentation(
      label: "Open",
      priority: 100,
      icon: MaterialSymbols.open_in_new_rounded,
    ),
    applies: (result) => {
      mockBookSearchResultType,
      mockPageSearchResultType,
      mockEntrySearchResultType,
    }.contains(result.type),
    execute: (target) async {
      await Future<void>.delayed(250.ms);
      return const SearchCommandResult.completed();
    },
  ),
  _mockCommand(
    id: mockRefreshSearchCommandId,
    presentation: const SearchCommandPresentation(
      label: "Refresh",
      priority: 20,
      icon: MaterialSymbols.refresh_rounded,
      shortcut: SingleActivator(LogicalKeyboardKey.keyR),
    ),
    applies: (result) => result.type != mockBookSearchResultType,
    execute: (target) async {
      await Future<void>.delayed(300.ms);
      return const SearchCommandResult.completed(
        surfaceEffect: SearchSurfaceEffect.refresh(),
      );
    },
  ),
  _mockCommand(
    id: mockUpdateQuerySearchCommandId,
    presentation: const SearchCommandPresentation(
      label: "Related",
      priority: 10,
      icon: Fa6Solid.link,
      shortcut: SingleActivator(LogicalKeyboardKey.keyU),
    ),
    applies: (result) => result.type != mockEntrySearchResultType,
    execute: (target) async {
      await Future<void>.delayed(4.seconds);
      final result = target.primary;
      return SearchCommandResult.completed(
        surfaceEffect: SearchSurfaceEffect.updateQuery(
          updateQuery: result.type.label ?? result.title ?? "",
        ),
      );
    },
  ),
  _mockCommand(
    id: mockFailSearchCommandId,
    presentation: const SearchCommandPresentation(
      label: "Fail",
      color: Colors.red,
      icon: Ic.round_dangerous,
      shortcut: SingleActivator(LogicalKeyboardKey.keyX),
    ),
    applies: (result) => result.type == mockBookSearchResultType,
    execute: (target) async {
      await Future<void>.delayed(4.seconds);
      return SearchCommandResult.failed(
        message:
            "Could not process ${target.primary.title ?? target.primary.id}",
      );
    },
  ),
];

SearchCommand _mockCommand({
  required SearchCommandId id,
  required SearchCommandPresentation presentation,
  required bool Function(SearchResult result) applies,
  required Future<SearchCommandResult> Function(SearchCommandTarget target)
  execute,
}) => SearchCommand.custom(
  id: id,
  presentation: presentation,
  evaluate: (target) => target.selection.every(applies)
      ? const SearchCommandState.enabled()
      : const SearchCommandState.hidden(),
  execute: (context, target) => execute(target),
);

SearchCommandId? mockSearchActivationCommandId(SearchResult result) =>
    switch (result.type) {
      mockBookSearchResultType ||
      mockPageSearchResultType ||
      mockEntrySearchResultType => mockCloseSearchCommandId,
      mockElementDefinitionSearchResultType ||
      mockTagSearchResultType => mockUpdateQuerySearchCommandId,
      _ => null,
    };

SearchSession<void> mockSearchSession(
  SearchSource source, {
  SearchSelectionMode selectionMode = SearchSelectionMode.multiple,
}) => SearchSession(
  source: source,
  interaction: SearchInteraction(
    activation: SearchActivation.command(
      resolve: mockSearchActivationCommandId,
      dependencies: const [],
    ),
    selectionMode: selectionMode,
    commands: mockSearchCommands(),
  ),
);

final class MockSearchIndex {
  const MockSearchIndex({
    required this.tags,
    required this.books,
    required this.pages,
    required this.entries,
    required this.elementDefinitions,
  });

  final List<Tag> tags;
  final List<Book> books;
  final List<MockPageRecord> pages;
  final List<MockEntryRecord> entries;
  final List<ElementDefinition> elementDefinitions;

  Map<String, String> get tagNameById => {
    for (final tag in tags) tag.tagId.id: tag.name,
  };
}

final class MockBookRecord {
  const MockBookRecord({required this.book, required this.tags});

  final Book book;
  final List<String> tags;
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
  int elementDefinitionCount = 18,
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
  final definitionsById = <ResolvedTypeRef, ElementDefinition>{};
  for (final elementDefinition in <ElementDefinition>[
    ...entries.map((record) => record.entry.elementDefinition),
    ...List.generate(
      elementDefinitionCount,
      (_) => generateRandomElementDefinition(),
    ),
  ]) {
    definitionsById[elementDefinition.rootType] = elementDefinition;
  }

  return MockSearchIndex(
    tags: tags,
    books: books,
    pages: pages,
    entries: entries,
    elementDefinitions: definitionsById.values.toList(),
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
  final pageKinds = index.pages
      .map((record) => _pageKindLabel(record.page.kind))
      .toSet()
      .toList();
  final entryTypes = index.elementDefinitions
      .map((elementDefinition) => elementDefinition.name)
      .toSet()
      .toList();

  final namespaces = index.elementDefinitions
      .map((elementDefinition) => elementDefinition.namespace)
      .toSet()
      .toList();
  const resultTypes = ["book", "page", "entry", "elementDefinition", "tag"];

  return [
    KeyValueSelectorDefinition(
      id: "type-symbol",
      key: "#",
      value: QuerySelectorValue.enumValue(resultTypes),
      color: safeColors[7],
    ),
    KeyValueSelectorDefinition(
      id: "tag",
      key: "tag:",
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
      id: "pageKind",
      key: "pageKind:",
      value: QuerySelectorValue.enumValue(pageKinds),
      color: safeColors[4],
    ),
    KeyValueSelectorDefinition(
      id: "entryType",
      key: "entryType:",
      value: QuerySelectorValue.enumValue(entryTypes),
      color: safeColors[8],
    ),
    KeyValueSelectorDefinition(
      id: "namespace",
      key: "namespace:",
      value: QuerySelectorValue.enumValue(namespaces),
      color: safeColors[9],
    ),
    KeyValueSelectorDefinition(
      id: "type",
      key: "type:",
      value: QuerySelectorValue.enumValue(resultTypes),
      color: safeColors[7],
    ),
  ];
}

List<SearchNode> mockMixedGlobalSearchNodes([MockSearchIndex? index]) {
  final searchIndex = index ?? mockSearchIndex();
  return [
    if (searchIndex.books.isNotEmpty)
      mockSearchSection(
        id: "books",
        title: "Books",
        subtitle: "Books and tags",
        children: searchIndex.books
            .map((book) => _bookSearchNode(book, searchIndex))
            .toList(),
      ),
    if (searchIndex.pages.isNotEmpty)
      mockSearchSection(
        id: "pages",
        title: "Pages",
        subtitle: "Books and chapters",
        children: searchIndex.pages
            .map((record) => _pageSearchNode(record, searchIndex))
            .toList(),
      ),
    if (searchIndex.entries.isNotEmpty)
      mockSearchSection(
        id: "entries",
        title: "Entries",
        subtitle: "Quest logic",
        children: searchIndex.entries
            .map((record) => _entrySearchNode(record, searchIndex))
            .toList(),
      ),
    if (searchIndex.elementDefinitions.isNotEmpty)
      mockSearchSection(
        id: "elementDefinitions",
        title: "Element definitions",
        subtitle: "Entry definitions",
        children: searchIndex.elementDefinitions
            .map(_elementDefinitionSearchNode)
            .toList(),
      ),
    if (searchIndex.tags.isNotEmpty)
      mockSearchSection(
        id: "tags",
        title: "Tags",
        subtitle: "Workspace labels",
        children: searchIndex.tags.map(_tagSearchNode).toList(),
      ),
  ];
}

SearchNode _bookSearchNode(Book book, MockSearchIndex index) {
  final tags = _tagNames(book.tagIds.map((tagId) => tagId.id), index);
  return mockSearchResultNode(
    id: "book.${book.bookId.id}",
    type: mockBookSearchResultType,
    title: book.title.formatted,
    subtitle: "Book / ${tags.join(", ")}",
    payload: MockBookRecord(book: book, tags: tags),
  );
}

SearchNode _pageSearchNode(MockPageRecord record, MockSearchIndex index) {
  final page = record.page;
  final book = record.book;
  final pageKind = _pageKindLabel(page.kind);
  final tags = _tagNames(book.tagIds.map((tagId) => tagId.id), index);
  return mockSearchResultNode(
    id: "page.${page.pageId.id}",
    type: mockPageSearchResultType,
    title: page.name.formatted,
    subtitle:
        "${book.title.formatted} / ${page.chapter.formatted} / $pageKind / ${tags.join(", ")}",
    payload: record,
  );
}

SearchNode _entrySearchNode(MockEntryRecord record, MockSearchIndex index) {
  final entry = record.entry;
  final page = record.page.page;
  final book = record.page.book;
  final elementDefinition = entry.elementDefinition;
  final tags = _tagNames(book.tagIds.map((tagId) => tagId.id), index);
  return mockSearchResultNode(
    id: "entry.${entry.id}",
    type: mockEntrySearchResultType,
    title: entry.name,
    subtitle:
        "${elementDefinition.name} / ${page.name.formatted} / ${tags.join(", ")}",
    payload: record,
  );
}

SearchNode _elementDefinitionSearchNode(ElementDefinition elementDefinition) {
  return mockSearchResultNode(
    id: "elementDefinition.${elementDefinition.typeId.uuid}",
    type: mockElementDefinitionSearchResultType,
    title: elementDefinition.name,
    subtitle: elementDefinition.namespace,
    payload: elementDefinition,
  );
}

SearchNode _tagSearchNode(Tag tag) {
  return mockSearchResultNode(
    id: "tag.${tag.tagId}",
    type: mockTagSearchResultType,
    title: tag.name.formatted,
    subtitle: "Tag / ${tag.parentIds.length} parents",
    payload: tag,
  );
}

List<String> _tagNames(Iterable<String> tagIds, MockSearchIndex index) {
  final names = index.tagNameById;
  return tagIds.map((id) => names[id] ?? id).toList();
}

String _pageKindLabel(PageKindRef kind) => kind.id;

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
          fields: _previewFieldsForPayload(node.result.payload),
        ),
      ),
  };
}

List<SearchGuidance> mockSearchGuidance() {
  return const [
    SearchGuidance(
      id: "selectors",
      title: "Use selectors to narrow results",
      description: "Try #quest, book:main, chapter:intro, page:spawn, pageKind:fixture.page, entryType:dialogue, extension:basic, or type:book OR type:page.",
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
  bool hasData = true,
  bool includeGuidance = true,
  List<QuerySelectorDefinition> selectors = const [],
  Duration searchDelay = Duration.zero,
}) {
  final index = mockSearchIndex(
    tagCount: hasData ? 18 : 0,
    bookCount: hasData ? 8 : 0,
    pagesPerBook: hasData ? 5 : 0,
    entryCount: hasData ? 32 : 0,
    elementDefinitionCount: hasData ? 18 : 0,
  );

  final searchSelectors = selectors.merge(mockSearchQuerySelectors(index));
  return MockSearchSource(
    state: state,
    sourceSelectors: searchSelectors,
    nodes: mockMixedGlobalSearchNodes(index),
    guidance: includeGuidance ? mockSearchGuidance() : const [],
    errorSummaries: state == MockSearchDisplayState.error
        ? mockSearchErrors()
        : const [],
    previewResults: mockSearchPreviewResults(index),
    searchDelay: searchDelay,
  );
}
