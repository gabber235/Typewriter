import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
    return ElasticTransition(
      key: ValueKey(row.key),
      animation: animation,
      child: SearchTreeRowWidget(
        key: ValueKey(row.key),
        row: row,
        rowRenderers: widget.rowRenderers,
      ),
    );
  }
}
