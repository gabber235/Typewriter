import "dart:async";
import "dart:convert";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:http/http.dart" as http;
import "package:typewriter_panel/typewriter_panel.dart";

part "icon_search.freezed.dart";
part "icon_search_ranking.dart";

const iconSearchResultType = SearchResultType(
  id: "iconifyIcon",
  rowRendererId: "iconifyIcon",
  label: "Icon",
);

const defaultIconIdentifiers = [
  "mdi:home",
  "mdi:account",
  "mdi:star",
  "mdi:map-marker",
  "game-icons:broad-dagger",
];

@freezed
abstract class IconSearchResultPayload with _$IconSearchResultPayload {
  const factory IconSearchResultPayload({
    required String identifier,
    required String name,
    required String collection,
  }) = _IconSearchResultPayload;
}

typedef IconSearchSelection = FutureOr<void> Function(String identifier);

final class IconifySearchSource implements SearchSource {
  IconifySearchSource({
    required this.client,
    required this.recentIdentifiers,
    required this.onSelected,
    Uri? baseUri,
    this.requestTimeout = const Duration(seconds: 5),
  }) : baseUri = baseUri ?? Uri.https("api.iconify.design");

  final http.Client client;
  final List<String> Function() recentIdentifiers;
  final IconSearchSelection onSelected;
  final Uri baseUri;
  final Duration requestTimeout;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  final _queryCache = <String, SearchSourceSnapshot>{};
  var _revision = 0;
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => Stream.value(const []);

  @override
  void initialize() {
    scheduleMicrotask(() {
      if (_disposed) return;
      _snapshots.add(_defaultSnapshot());
    });
  }

  @override
  void search(SearchQueryContext context) {
    final rawQuery = context.normalizedQuery.trim().toLowerCase();
    if (rawQuery.length < 2 || rawQuery.trimLeft().startsWith("<")) {
      _revision++;
      _snapshots.add(_defaultSnapshot());
      return;
    }

    final cached = _queryCache[rawQuery];
    if (cached != null) {
      _snapshots.add(cached);
      return;
    }

    final revision = ++_revision;
    _snapshots.add(SearchSourceSnapshot.loading());
    unawaited(_search(rawQuery, revision));
  }

  Future<void> _search(String rawQuery, int revision) async {
    try {
      final parsed = _parseQuery(rawQuery);
      final parameters = <String, String>{
        "query": parsed.name,
        "limit": "32",
        if (parsed.prefix != null) "prefix": parsed.prefix!,
      };
      final uri = baseUri.replace(path: "/search", queryParameters: parameters);
      final response = await client
          .get(uri, headers: const {"Accept": "application/json"})
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw FormatException("Icon search returned ${response.statusCode}");
      }

      final snapshot = _decodeSnapshot(rawQuery, response.body);
      _remember(rawQuery, snapshot);
      if (_disposed || revision != _revision) return;
      _snapshots.add(snapshot);
    } on Object {
      if (_disposed || revision != _revision) return;
      _snapshots.add(
        SearchSourceSnapshot.error(
          errorSummaries: const [
            SearchErrorSummary(
              id: "iconifyUnavailable",
              message: "Icon search is temporarily unavailable",
              severity: SearchErrorSeverity.error,
              sourceLabel: "Iconify",
            ),
          ],
        ),
      );
    }
  }

  SearchSourceSnapshot _decodeSnapshot(String query, String body) {
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException("Icon search response must be an object");
    }
    final icons = data["icons"];
    final collections = data["collections"];
    if (icons is! List || collections is! Map<String, dynamic>) {
      throw const FormatException("Icon search response is incomplete");
    }

    final candidates = <IconSearchCandidate>[];
    for (final value in icons.whereType<String>()) {
      final parsed = _parseIdentifier(value);
      if (parsed == null) continue;
      final collectionData = collections[parsed.prefix];
      final collection = collectionData is Map<String, dynamic>
          ? collectionData["name"] as String? ?? parsed.prefix
          : parsed.prefix;
      candidates.add(
        IconSearchCandidate(
          identifier: value,
          prefix: parsed.prefix,
          name: parsed.name,
          collection: collection,
          apiIndex: candidates.length,
        ),
      );
    }

    final ranked = rankIconCandidates(query, candidates);
    return SearchSourceSnapshot.ready(
      nodes: ranked.map(_resultNode).toList(growable: false),
      actions: {SelectIconSearchAction: SelectIconSearchAction(onSelected)},
    );
  }

  SearchSourceSnapshot _defaultSnapshot() {
    final identifiers = <String>[
      ...recentIdentifiers().take(3),
      ...defaultIconIdentifiers,
    ];
    final seen = <String>{};
    final candidates = identifiers
        .where(seen.add)
        .take(32)
        .map((identifier) {
          final parsed = _parseIdentifier(identifier)!;
          return IconSearchCandidate(
            identifier: identifier,
            prefix: parsed.prefix,
            name: parsed.name,
            collection: parsed.prefix.titleCase(),
            apiIndex: seen.length - 1,
          );
        })
        .toList(growable: false);
    return SearchSourceSnapshot.ready(
      nodes: candidates.map(_resultNode).toList(growable: false),
      actions: {SelectIconSearchAction: SelectIconSearchAction(onSelected)},
    );
  }

  SearchNode _resultNode(IconSearchCandidate candidate) => SearchNode.result(
    result: SearchResult(
      id: candidate.identifier,
      type: iconSearchResultType,
      payload: IconSearchResultPayload(
        identifier: candidate.identifier,
        name: candidate.name,
        collection: candidate.collection,
      ),
      actions: const [SelectIconSearchAction],
      title: candidate.name.replaceAll("-", " ").titleCase(),
      subtitle: candidate.collection,
    ),
  );

  void _remember(String query, SearchSourceSnapshot snapshot) {
    _queryCache.remove(query);
    _queryCache[query] = snapshot;
    if (_queryCache.length <= 100) return;
    _queryCache.remove(_queryCache.keys.first);
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Icon results do not use detached previews",
  );

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    unawaited(_snapshots.close());
  }
}

final class SelectIconSearchAction extends SingleSearchAction {
  SelectIconSearchAction(this.onSelected);

  final IconSearchSelection onSelected;

  @override
  String get label => "Select icon";

  @override
  int get priority => 100;

  @override
  Future<SearchActionResult> execute(SearchResult result) async {
    final payload = result.payload;
    if (payload is! IconSearchResultPayload) {
      return const SearchActionResult.failed(message: "Invalid icon result");
    }
    await onSelected(payload.identifier);
    return const SearchActionResult.completed();
  }
}

({String? prefix, String name}) _parseQuery(String query) {
  final separator = query.indexOf(":");
  if (separator <= 0 || separator == query.length - 1) {
    return (prefix: null, name: query);
  }
  return (
    prefix: query.substring(0, separator),
    name: query.substring(separator + 1),
  );
}

({String prefix, String name})? _parseIdentifier(String identifier) {
  final separator = identifier.indexOf(":");
  if (separator <= 0 || separator == identifier.length - 1) return null;
  return (
    prefix: identifier.substring(0, separator),
    name: identifier.substring(separator + 1),
  );
}

final class IconSearchCandidate {
  const IconSearchCandidate({
    required this.identifier,
    required this.prefix,
    required this.name,
    required this.collection,
    required this.apiIndex,
  });

  final String identifier;
  final String prefix;
  final String name;
  final String collection;
  final int apiIndex;
}
