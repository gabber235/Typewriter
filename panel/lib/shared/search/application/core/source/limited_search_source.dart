import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps at most [maximum] results while preserving tree order and sections.
///
/// A section survives only when it contains a retained result. The limit is
/// counted across descendants, not only at the top level.
final class LimitedSearchSource extends DelegatingSearchSource {
  LimitedSearchSource({required super.source, required this.maximum});

  final int Function(SearchQueryContext context) maximum;
  int _activeMaximum = 0;

  void _selectContext(SearchQueryContext context) {
    final resolved = maximum(context);
    if (resolved < 0) {
      throw ArgumentError.value(resolved, "maximum", "must not be negative");
    }
    _activeMaximum = resolved;
  }

  @override
  void initialize(SearchQueryContext context) {
    _selectContext(context);
    super.initialize(context);
  }

  @override
  void search(SearchQueryContext context) {
    _selectContext(context);
    super.search(context);
  }

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) {
    emit(snapshot.copyWith(nodes: _limit(snapshot.nodes, _activeMaximum)));
  }

  List<SearchNode> _limit(List<SearchNode> nodes, int available) {
    if (available == 0) return const [];

    final limited = <SearchNode>[];
    var remaining = available;
    for (final node in nodes) {
      if (remaining == 0) break;

      switch (node) {
        case SearchResultNode():
          limited.add(node);
          remaining--;
        case SearchSectionNode():
          final children = _limit(node.children, remaining);
          if (children.isEmpty) continue;
          limited.add(node.copyWith(children: children));
          remaining -= children.walk().whereType<SearchResultNode>().length;
      }
    }
    return limited;
  }
}

/// Adds a result count limit to a source.
extension LimitedSearchSourceX on SearchSource {
  SearchSource limited(int Function(SearchQueryContext context) maximum) {
    return LimitedSearchSource(source: this, maximum: maximum);
  }
}
