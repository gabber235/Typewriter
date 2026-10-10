import "package:typewriter_panel/typewriter_panel.dart";

part "tree_diff.freezed.dart";

/// Row changes required to transform one visible tree list into another.
///
/// Removals are ordered from the end toward the start because consumers apply
/// them directly to an indexed animated list. Insertions use their target
/// indices in the next list.
@freezed
abstract class SearchTreeDiff with _$SearchTreeDiff {
  const factory SearchTreeDiff({
    required List<SearchTreeRemoval> removals,
    required List<SearchTreeInsertion> insertions,
  }) = _SearchTreeDiff;
}

/// One row removed from the previous visible list.
@freezed
abstract class SearchTreeRemoval with _$SearchTreeRemoval {
  const factory SearchTreeRemoval({
    required int index,
    required SearchTreeRow row,
  }) = _SearchTreeRemoval;
}

/// One row inserted into the next visible list.
@freezed
abstract class SearchTreeInsertion with _$SearchTreeInsertion {
  const factory SearchTreeInsertion({
    required int index,
    required SearchTreeRow row,
  }) = _SearchTreeInsertion;
}

/// Computes keyed additions and removals while retaining the longest stable
/// subsequence in place.
SearchTreeDiff diffSearchTreeRows({
  required List<SearchTreeRow> previous,
  required List<SearchTreeRow> next,
}) {
  final previousKeys = previous.map((row) => row.key).toList();
  final nextKeys = next.map((row) => row.key).toList();
  final stableKeys = _longestCommonSubsequence(previousKeys, nextKeys).toSet();

  final removals = <SearchTreeRemoval>[];
  for (var i = previous.length - 1; i >= 0; i--) {
    final row = previous[i];
    if (!stableKeys.contains(row.key)) {
      removals.add(SearchTreeRemoval(index: i, row: row));
    }
  }

  final insertions = <SearchTreeInsertion>[];
  for (var i = 0; i < next.length; i++) {
    final row = next[i];
    if (!stableKeys.contains(row.key)) {
      insertions.add(SearchTreeInsertion(index: i, row: row));
    }
  }

  return SearchTreeDiff(removals: removals, insertions: insertions);
}

List<String> _longestCommonSubsequence(
  List<String> previous,
  List<String> next,
) {
  final lengths = List.generate(
    previous.length + 1,
    (_) => List.filled(next.length + 1, 0),
  );

  for (var i = previous.length - 1; i >= 0; i--) {
    for (var j = next.length - 1; j >= 0; j--) {
      if (previous[i] == next[j]) {
        lengths[i][j] = lengths[i + 1][j + 1] + 1;
      } else {
        lengths[i][j] = lengths[i + 1][j] >= lengths[i][j + 1]
            ? lengths[i + 1][j]
            : lengths[i][j + 1];
      }
    }
  }

  final sequence = <String>[];
  var i = 0;
  var j = 0;
  while (i < previous.length && j < next.length) {
    if (previous[i] == next[j]) {
      sequence.add(previous[i]);
      i++;
      j++;
    } else if (lengths[i + 1][j] >= lengths[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  return sequence;
}
