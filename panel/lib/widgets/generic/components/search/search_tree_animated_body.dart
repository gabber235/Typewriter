import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_result_renderers.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_diff.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_model.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_results.dart";

class SearchTreeAnimatedBody extends StatefulWidget {
  const SearchTreeAnimatedBody({
    required this.rows,
    required this.rowRenderers,
    super.key,
  });

  final List<SearchTreeRow> rows;
  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  State<SearchTreeAnimatedBody> createState() => _SearchTreeAnimatedBodyState();
}

class _SearchTreeAnimatedBodyState extends State<SearchTreeAnimatedBody> {
  static const _insertDuration = Duration(milliseconds: 750);
  static const _deleteDuration = Duration(milliseconds: 500);

  final _listKey = GlobalKey<SliverAnimatedListState>();
  late List<SearchTreeRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List.of(widget.rows);
  }

  @override
  void didUpdateWidget(SearchTreeAnimatedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRows(widget.rows);
  }

  void _syncRows(List<SearchTreeRow> nextRows) {
    final state = _listKey.currentState;
    if (state == null) {
      _rows = List.of(nextRows);
      return;
    }

    final diff = diffSearchTreeRows(previous: _rows, next: nextRows);

    for (final removal in diff.removals) {
      final removed = _rows.removeAt(removal.index);
      state.removeItem(
        removal.index,
        (context, animation) => _animatedRow(removed, animation),
        duration: _deleteDuration,
      );
    }

    for (final insertion in diff.insertions) {
      _rows.insert(insertion.index, insertion.row);
      state.insertItem(insertion.index, duration: _insertDuration);
    }

    final nextByKey = {for (final row in nextRows) row.key: row};
    for (var i = 0; i < _rows.length; i++) {
      _rows[i] = nextByKey[_rows[i].key] ?? _rows[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _rows.length,
      itemBuilder: (context, index, animation) {
        return _animatedRow(_rows[index], animation);
      },
    );
  }

  Widget _animatedRow(SearchTreeRow row, Animation<double> animation) {
    final child = SearchTreeRowWidget(
      key: ValueKey(row.key),
      row: row,
      rowRenderers: widget.rowRenderers,
    );

    final size = CurvedAnimation(
      parent: animation,
      curve: ElasticOutCurve(0.9),
      reverseCurve: const Interval(0, 0.9, curve: Cubic(.89, -0.01, .51, 1.11)),
    );

    final scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 1, curve: ElasticOutCurve(0.8)),
        reverseCurve: const Interval(0.5, 1, curve: Curves.ease),
      ),
    );

    final opacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      reverseCurve: const Interval(0.55, 1, curve: Curves.easeIn),
    );

    return FadeTransition(
      key: ValueKey(row.key),
      opacity: opacity,
      child: SizeTransition(
        sizeFactor: size,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }
}
