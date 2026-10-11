import "package:typewriter_panel/typewriter_panel.dart";

part "tree_model.freezed.dart";

/// A visible row in the flattened result tree.
///
/// Rows keep stable keys and source depth so animated list state can survive
/// snapshot updates while presentation supplies the actual widgets.
@freezed
sealed class SearchTreeRow with _$SearchTreeRow {
  const factory SearchTreeRow.section({
    required String key,
    required int depth,
    required String id,
    required String title,
    required String? subtitle,
    required bool expanded,
    required int resultCount,
    required bool topLevel,
  }) = SearchTreeSectionRow;
  const factory SearchTreeRow.result({
    required String key,
    required int depth,
    required SearchResult result,
    required int? shortcutNumber,
  }) = SearchTreeResultRow;
}

/// One top level sliver group, with an optional pinned section header.
@freezed
abstract class SearchTreeTopLevelGroup with _$SearchTreeTopLevelGroup {
  const factory SearchTreeTopLevelGroup({
    required SearchTreeSectionRow? section,
    required List<SearchTreeRow> rows,
  }) = _SearchTreeTopLevelGroup;
}

/// Flattened tree projection consumed by the animated result list.
@freezed
abstract class SearchTreeViewModel with _$SearchTreeViewModel {
  const factory SearchTreeViewModel({
    required List<SearchTreeTopLevelGroup> groups,
    required int rowCount,
  }) = _SearchTreeViewModel;
}

/// Builds the stable key used for a section row.
String searchTreeSectionKey(String id) => "section:$id";

/// Builds the stable key used for a result row.
String searchTreeResultKey(String id) => "result:$id";

/// Flattens [nodes] into visible rows while retaining nested section counts.
///
/// [isCollapsed] owns expansion state outside this pure projection. Collapsed
/// sections keep their header and count descendants, but hide descendant rows.
/// Result shortcut numbers follow visible depth first order and stop at nine.
SearchTreeViewModel buildSearchTreeViewModel({
  required List<SearchNode> nodes,
  required bool Function(String sectionId) isCollapsed,
}) {
  final builder = _SearchTreeBuilder(isCollapsed);
  return builder.build(nodes);
}

class _SearchTreeBuilder {
  _SearchTreeBuilder(this.isCollapsed);

  final bool Function(String sectionId) isCollapsed;
  var _visibleResultIndex = 0;

  SearchTreeViewModel build(List<SearchNode> nodes) {
    final groups = <SearchTreeTopLevelGroup>[];
    final looseRows = <SearchTreeRow>[];

    void flushLooseRows() {
      if (looseRows.isEmpty) return;
      groups.add(
        SearchTreeTopLevelGroup(section: null, rows: List.of(looseRows)),
      );
      looseRows.clear();
    }

    for (final node in nodes) {
      switch (node) {
        case SearchSectionNode():
          flushLooseRows();
          final built = _buildSection(node, depth: 0, topLevel: true);
          groups.add(
            SearchTreeTopLevelGroup(
              section: built.section,
              rows: built.visibleRows,
            ),
          );
        case SearchResultNode(:final result):
          looseRows.add(_resultRow(result, depth: 0));
      }
    }

    flushLooseRows();
    final rowCount = groups.fold<int>(
      0,
      (count, group) =>
          count + (group.section == null ? 0 : 1) + group.rows.length,
    );
    return SearchTreeViewModel(groups: groups, rowCount: rowCount);
  }

  _BuiltSection _buildSection(
    SearchSectionNode node, {
    required int depth,
    required bool topLevel,
  }) {
    final collapsed = isCollapsed(node.id);
    final childBuild = _buildChildren(
      node.children,
      depth: depth + 1,
      visible: !collapsed,
    );
    final section = SearchTreeSectionRow(
      key: searchTreeSectionKey(node.id),
      depth: depth,
      id: node.id,
      title: node.title,
      subtitle: node.subtitle,
      expanded: !collapsed,
      resultCount: childBuild.resultCount,
      topLevel: topLevel,
    );
    return _BuiltSection(section: section, visibleRows: childBuild.visibleRows);
  }

  _BuiltChildren _buildChildren(
    List<SearchNode> nodes, {
    required int depth,
    required bool visible,
  }) {
    var resultCount = 0;
    final visibleRows = <SearchTreeRow>[];
    for (final node in nodes) {
      switch (node) {
        case SearchSectionNode():
          final built = _buildSection(node, depth: depth, topLevel: false);
          resultCount += built.section.resultCount;
          if (visible) {
            visibleRows
              ..add(built.section)
              ..addAll(built.visibleRows);
          }
        case SearchResultNode(:final result):
          resultCount++;
          if (visible) visibleRows.add(_resultRow(result, depth: depth));
      }
    }
    return _BuiltChildren(resultCount: resultCount, visibleRows: visibleRows);
  }

  SearchTreeResultRow _resultRow(SearchResult result, {required int depth}) {
    _visibleResultIndex++;
    return SearchTreeResultRow(
      key: searchTreeResultKey(result.id),
      depth: depth,
      result: result,
      shortcutNumber: _visibleResultIndex <= 9 ? _visibleResultIndex : null,
    );
  }
}

class _BuiltSection {
  const _BuiltSection({required this.section, required this.visibleRows});

  final SearchTreeSectionRow section;
  final List<SearchTreeRow> visibleRows;
}

class _BuiltChildren {
  const _BuiltChildren({required this.resultCount, required this.visibleRows});

  final int resultCount;
  final List<SearchTreeRow> visibleRows;
}
