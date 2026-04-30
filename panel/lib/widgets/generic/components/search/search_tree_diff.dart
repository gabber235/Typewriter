import "package:typewriter_panel/widgets/generic/components/search/search_tree_model.dart";

class SearchTreeDiff {
  const SearchTreeDiff({required this.removals, required this.insertions});

  final List<SearchTreeRemoval> removals;
  final List<SearchTreeInsertion> insertions;
}

class SearchTreeRemoval {
  const SearchTreeRemoval({required this.index, required this.row});

  final int index;
  final SearchTreeRow row;
}

class SearchTreeInsertion {
  const SearchTreeInsertion({required this.index, required this.row});

  final int index;
  final SearchTreeRow row;
}

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
