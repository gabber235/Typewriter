import "package:typewriter_panel/shared/search/search_engine.dart";

sealed class SearchTreeRow {
  const SearchTreeRow({required this.key, required this.depth});

  final String key;
  final int depth;
}

class SearchTreeSectionRow extends SearchTreeRow {
  const SearchTreeSectionRow({
    required super.key,
    required super.depth,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.resultCount,
    required this.topLevel,
  });

  final String id;
  final String title;
  final String? subtitle;
  final bool expanded;
  final int resultCount;
  final bool topLevel;
}

class SearchTreeResultRow extends SearchTreeRow {
  const SearchTreeResultRow({
    required super.key,
    required super.depth,
    required this.result,
    required this.shortcutNumber,
  });

  final SearchResult result;
  final int? shortcutNumber;
}

class SearchTreeTopLevelGroup {
  const SearchTreeTopLevelGroup({required this.section, required this.rows});

  final SearchTreeSectionRow? section;
  final List<SearchTreeRow> rows;
}

class SearchTreeViewModel {
  const SearchTreeViewModel({required this.groups, required this.rowCount});

  final List<SearchTreeTopLevelGroup> groups;
  final int rowCount;
}

String searchTreeSectionKey(String id) => "section:$id";
String searchTreeResultKey(String id) => "result:$id";

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
