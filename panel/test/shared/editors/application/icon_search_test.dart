import "dart:async";
import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("IconifySearchSource", () {
    test("shows recent and default icons without a network request", () async {
      var requests = 0;
      final source = IconifySearchSource(
        client: MockClient((_) async {
          requests++;
          return http.Response("{}", 200);
        }),
        recentIdentifiers: () => ["lucide:wand", "mdi:home"],
        onSelected: (_) {},
      );
      addTearDown(source.dispose);

      final snapshot = await _nextSnapshot(source, source.initialize);
      final ids = snapshot.nodes.findResults(
        snapshot.nodes
            .walk()
            .whereType<SearchResultNode>()
            .map((node) => node.result.id)
            .toSet(),
      );

      expect(requests, 0);
      expect(ids.map((result) => result.id).take(3), [
        "lucide:wand",
        "mdi:home",
        "mdi:account",
      ]);
    });

    test("searches by collection and ranks an exact name first", () async {
      late Uri requestUri;
      final source = IconifySearchSource(
        client: MockClient((request) async {
          requestUri = request.url;
          return http.Response(
            jsonEncode({
              "icons": ["mdi:home-outline", "mdi:home", "mdi:home-account"],
              "collections": {
                "mdi": {"name": "Material Design Icons"},
              },
            }),
            200,
          );
        }),
        recentIdentifiers: () => const [],
        onSelected: (_) {},
      );
      addTearDown(source.dispose);

      final snapshot = await _nextSnapshot(
        source,
        () => source.search(_context("mdi:home")),
        where: (value) => value.status == SearchSourceStatus.ready,
      );
      final results = snapshot.nodes
          .walk()
          .whereType<SearchResultNode>()
          .map((node) => node.result)
          .toList();

      expect(requestUri.path, "/search");
      expect(requestUri.queryParameters, {
        "query": "home",
        "limit": "32",
        "prefix": "mdi",
      });
      expect(results.first.id, "mdi:home");
      expect(results.first.subtitle, "Material Design Icons");
    });

    test("ignores a late response from an older query", () async {
      final first = Completer<http.Response>();
      final source = IconifySearchSource(
        client: MockClient((request) {
          if (request.url.queryParameters["query"] == "first") {
            return first.future;
          }
          return Future.value(_responseFor("mdi:second"));
        }),
        recentIdentifiers: () => const [],
        onSelected: (_) {},
      );
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source
        ..search(_context("first"))
        ..search(_context("second"));
      await _waitUntil(
        () => snapshots.any(
          (snapshot) => snapshot.nodes.any(
            (node) =>
                node is SearchResultNode && node.result.id == "mdi:second",
          ),
        ),
      );
      first.complete(_responseFor("mdi:first"));
      await Future<void>.delayed(Duration.zero);

      final resultIds = snapshots
          .expand((snapshot) => snapshot.nodes)
          .whereType<SearchResultNode>()
          .map((node) => node.result.id);
      expect(resultIds, contains("mdi:second"));
      expect(resultIds, isNot(contains("mdi:first")));
    });
  });

  test("ranking keeps the first five results diverse", () {
    final ranked = rankIconCandidates("home", [
      _candidate("mdi:home", 0),
      _candidate("mdi:home-outline", 1),
      _candidate("mdi:home-filled", 2),
      _candidate("mdi:home-account", 3),
      _candidate("lucide:home", 4),
      _candidate("tabler:home", 5),
    ]);

    expect(ranked.first.identifier, "mdi:home");
    expect(ranked.take(5).map((value) => value.prefix).toSet().length, 3);
  });
}

SearchQueryContext _context(String query) =>
    SearchQueryContext(normalizedQuery: query, selectors: const []);

http.Response _responseFor(String identifier) => http.Response(
  jsonEncode({
    "icons": [identifier],
    "collections": {
      "mdi": {"name": "Material Design Icons"},
    },
  }),
  200,
);

IconSearchCandidate _candidate(String identifier, int index) {
  final parts = identifier.split(":");
  return IconSearchCandidate(
    identifier: identifier,
    prefix: parts.first,
    name: parts.last,
    collection: parts.first,
    apiIndex: index,
  );
}

Future<SearchSourceSnapshot> _nextSnapshot(
  IconifySearchSource source,
  void Function() invoke, {
  bool Function(SearchSourceSnapshot value)? where,
}) {
  final completer = Completer<SearchSourceSnapshot>();
  late StreamSubscription<SearchSourceSnapshot> subscription;
  subscription = source.snapshots.listen((snapshot) {
    if (where?.call(snapshot) ?? true) {
      completer.complete(snapshot);
      unawaited(subscription.cancel());
    }
  });
  invoke();
  return completer.future;
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail("Condition was not reached");
}
