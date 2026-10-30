import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// An expanded top level section row [key], titled [key], holding nothing.
SearchTreeRow searchSectionRow(String key) => SearchTreeSectionRow(
  key: key,
  depth: 0,
  id: key,
  title: key,
  subtitle: null,
  expanded: true,
  resultCount: 0,
  topLevel: false,
);

/// Diffs [previous] against [next] and checks that applying the removals,
/// then the insertions, to [previous] yields exactly [next], the way the
/// animated list replays a diff.
SearchTreeDiff replayedSearchTreeDiff({
  required List<SearchTreeRow> previous,
  required List<SearchTreeRow> next,
}) {
  final diff = diffSearchTreeRows(previous: previous, next: next);
  final rows = [...previous];
  for (final removal in diff.removals) {
    expect(rows[removal.index].key, removal.row.key);
    rows.removeAt(removal.index);
  }
  for (final insertion in diff.insertions) {
    rows.insert(insertion.index, insertion.row);
  }
  expect(
    rows.map((row) => row.key),
    next.map((row) => row.key),
    reason: "replaying the diff must yield the next rows",
  );
  return diff;
}
