part of "icon_search.dart";

List<IconSearchCandidate> rankIconCandidates(
  String rawQuery,
  List<IconSearchCandidate> candidates,
) {
  final query = _parseQuery(rawQuery).name.replaceAll(RegExp(r"[_\s]+"), "-");
  final ranked =
      candidates
          .map((candidate) => (candidate, _scoreCandidate(query, candidate)))
          .toList()
        ..sort((left, right) {
          final score = right.$2.compareTo(left.$2);
          return score != 0
              ? score
              : left.$1.apiIndex.compareTo(right.$1.apiIndex);
        });

  final result = <IconSearchCandidate>[];
  final delayed = <IconSearchCandidate>[];
  for (final entry in ranked) {
    final candidate = entry.$1;
    final repeatedName = result.any(
      (item) => _baseName(item.name) == _baseName(candidate.name),
    );
    final repeatedCollection =
        result.where((item) => item.prefix == candidate.prefix).length >= 2;
    if (result.length < 5 && (repeatedName || repeatedCollection)) {
      delayed.add(candidate);
      continue;
    }
    result.add(candidate);
  }
  result.addAll(delayed);
  return result;
}

int _scoreCandidate(String query, IconSearchCandidate candidate) {
  final name = candidate.name;
  if (candidate.identifier == query || name == query) return 10000;
  if (name.startsWith(query)) return 8000 - name.length;
  if (name.split("-").contains(query)) return 7000 - name.length;
  if (name.contains(query)) return 6000 - name.indexOf(query);
  final distance = _levenshtein(query, name);
  if (distance <= 2) return 4000 - distance * 100;
  return 1000 - candidate.apiIndex;
}

int _levenshtein(String left, String right) {
  var previous = List<int>.generate(right.length + 1, (index) => index);
  for (var i = 0; i < left.length; i++) {
    final current = <int>[i + 1];
    for (var j = 0; j < right.length; j++) {
      current.add(
        [
          current[j] + 1,
          previous[j + 1] + 1,
          previous[j] + (left[i] == right[j] ? 0 : 1),
        ].reduce((a, b) => a < b ? a : b),
      );
    }
    previous = current;
  }
  return previous.last;
}

String _baseName(String name) => name.replaceAll(
  RegExp(r"-(outline|filled|fill|solid|bold|light|thin)$"),
  "",
);
