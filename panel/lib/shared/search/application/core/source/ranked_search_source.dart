import "dart:math";

import "package:typewriter_panel/typewriter_panel.dart";

typedef SearchRankText = String? Function(SearchResult result);

final class SearchRankField {
  const SearchRankField({required this.text, required this.weight})
    : assert(weight > 0);

  final SearchRankText text;
  final int weight;
}

final class RankedSearchSource extends DelegatingSearchSource {
  RankedSearchSource({required super.source, required this.fields})
    : assert(fields.isNotEmpty);

  final List<SearchRankField> fields;

  String _query = "";

  @override
  void search(SearchQueryContext context) {
    _query = _normalize(context.normalizedQuery);
    source.search(context);
  }

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) {
    if (_query.isEmpty) {
      emit(snapshot);
      return;
    }

    emit(snapshot.copyWith(nodes: _rankTree(snapshot.nodes).nodes));
  }

  ({List<SearchNode> nodes, int? highestScore}) _rankTree(
    List<SearchNode> nodes,
  ) {
    final ranked = <({SearchNode node, int score, int index})>[];
    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      switch (node) {
        case SearchResultNode(:final result):
          final score = _scoreResult(result);
          if (score >= 0) {
            ranked.add((node: node, score: score, index: index));
          }
        case SearchSectionNode():
          final children = _rankTree(node.children);
          final highestScore = children.highestScore;
          if (highestScore == null) continue;
          ranked.add((
            node: node.copyWith(children: children.nodes),
            score: highestScore,
            index: index,
          ));
      }
    }

    ranked.sort((left, right) {
      final byScore = right.score.compareTo(left.score);
      return byScore == 0 ? left.index.compareTo(right.index) : byScore;
    });
    return (
      nodes: ranked.map((entry) => entry.node).toList(growable: false),
      highestScore: ranked.isEmpty ? null : ranked.first.score,
    );
  }

  int _scoreResult(SearchResult result) {
    var total = 0;
    var matched = false;
    for (final field in fields) {
      final value = field.text(result);
      if (value == null || value.isEmpty) continue;
      final score = scoreFuzzySearchMatch(_query, value);
      if (score < 0) continue;
      matched = true;
      total += score * field.weight;
    }
    return matched ? total : -1;
  }
}

int scoreFuzzySearchMatch(String rawQuery, String rawCandidate) {
  final query = _normalize(rawQuery);
  final candidate = _normalize(rawCandidate);
  if (query.isEmpty) return 0;
  if (candidate == query) return 10000;
  if (candidate.startsWith(query)) return 9000 - candidate.length;

  final tokens = candidate.split(" ");
  if (tokens.any((token) => token.startsWith(query))) {
    return 8000 - candidate.length;
  }

  final substringIndex = candidate.indexOf(query);
  if (substringIndex >= 0) return 7000 - substringIndex;

  final acronym = tokens.where((token) => token.isNotEmpty).map((token) {
    return token[0];
  }).join();
  if (acronym.startsWith(query)) return 6000 - acronym.length;

  final gaps = _subsequenceGaps(query, candidate);
  if (gaps != null) return 5000 - gaps;

  if (query.length > 64 || candidate.length > 128) return -1;
  final threshold = max(2, query.length ~/ 4);
  final distance = _boundedEditDistance(query, candidate, threshold);
  if (distance <= threshold) return 4000 - distance * 100;
  return -1;
}

String _normalize(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r"[\s_.:/\\-]+"), " ");
}

int? _subsequenceGaps(String query, String candidate) {
  var queryIndex = 0;
  var previousIndex = -1;
  var gaps = 0;
  for (var index = 0; index < candidate.length; index++) {
    if (candidate[index] != query[queryIndex]) continue;
    if (previousIndex >= 0) gaps += index - previousIndex - 1;
    previousIndex = index;
    queryIndex++;
    if (queryIndex == query.length) return gaps;
  }
  return null;
}

int _boundedEditDistance(String left, String right, int maximum) {
  if ((left.length - right.length).abs() > maximum) return maximum + 1;

  var previous = List<int>.generate(right.length + 1, (index) => index);
  for (var leftIndex = 0; leftIndex < left.length; leftIndex++) {
    final current = <int>[leftIndex + 1];
    var rowMinimum = current.first;
    for (var rightIndex = 0; rightIndex < right.length; rightIndex++) {
      final value = min(
        min(current[rightIndex] + 1, previous[rightIndex + 1] + 1),
        previous[rightIndex] + (left[leftIndex] == right[rightIndex] ? 0 : 1),
      );
      current.add(value);
      rowMinimum = min(rowMinimum, value);
    }
    if (rowMinimum > maximum) return maximum + 1;
    previous = current;
  }
  return previous.last;
}

extension RankedSearchSourceX on SearchSource {
  SearchSource ranked(List<SearchRankField> fields) {
    return RankedSearchSource(source: this, fields: fields);
  }
}
