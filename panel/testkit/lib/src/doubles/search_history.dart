import "package:typewriter_panel/typewriter_panel.dart";

/// Search history kept in memory: every replacement counts in [writes] and
/// becomes what loads return. It starts holding [results]; loads remember
/// their key in [loadKeys], return at most the asked capacity, and wait for
/// [pendingLoad] instead when it is given.
final class MemorySearchHistory implements SearchHistoryStorage {
  MemorySearchHistory({this.results = const [], this.pendingLoad});

  /// What every load answers with while it is set, so a test controls when
  /// stored history arrives.
  final Future<List<SearchResult>>? pendingLoad;

  int writes = 0;
  List<SearchResult> results;
  final Map<String, List<SearchResult>> resultsByKey = {};
  final loadKeys = <String>[];

  /// The ids of the results the history holds, newest first.
  List<String> get resultIds => results.map((result) => result.id).toList();

  @override
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  }) async {
    loadKeys.add(key);
    return pendingLoad ?? results.take(capacity).toList();
  }

  @override
  Future<void> replaceResults({
    required String key,
    required List<SearchResult> results,
  }) async {
    writes++;
    this.results = results;
    resultsByKey[key] = results;
  }
}
