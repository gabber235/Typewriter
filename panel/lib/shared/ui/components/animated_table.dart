import "package:flutter/material.dart";

/// Builds a row in an [AnimatedTable].
typedef AnimatedTableRowBuilder =
    TableRow Function(
      BuildContext context,
      int index,
      Animation<double> animation,
    );

/// Builds a row while it is being removed from an [AnimatedTable].
typedef AnimatedTableRemovedRowBuilder =
    TableRow Function(BuildContext context, Animation<double> animation);

/// Builds a transition for a table cell or empty state.
typedef AnimatedTableTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Widget child,
    );

typedef AnimatedTableBuilder =
    Widget Function(BuildContext context, Table table);

class AnimatedTable extends StatefulWidget {
  const AnimatedTable({
    required this.initialItemCount,
    required this.rowBuilder,
    required this.transitionBuilder,
    this.headerRows = const [],
    this.emptyBuilder,
    this.emptyTransitionBuilder,
    this.tableBuilder,
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(),
    this.textDirection,
    this.border,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.textBaseline,
    super.key,
  }) : assert(initialItemCount >= 0);

  final int initialItemCount;
  final AnimatedTableRowBuilder rowBuilder;
  final AnimatedTableTransitionBuilder transitionBuilder;
  final List<TableRow> headerRows;
  final WidgetBuilder? emptyBuilder;
  final AnimatedTableTransitionBuilder? emptyTransitionBuilder;
  final AnimatedTableBuilder? tableBuilder;
  final Map<int, TableColumnWidth>? columnWidths;
  final TableColumnWidth defaultColumnWidth;
  final TextDirection? textDirection;
  final TableBorder? border;
  final TableCellVerticalAlignment defaultVerticalAlignment;
  final TextBaseline? textBaseline;

  @override
  AnimatedTableState createState() => AnimatedTableState();
}

class AnimatedTableState extends State<AnimatedTable>
    with TickerProviderStateMixin {
  final List<_RowEntry> _rows = [];
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    for (var index = 0; index < widget.initialItemCount; index++) {
      _rows.add(_RowEntry(index: index, animation: kAlwaysCompleteAnimation));
    }
  }

  void insertItem(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    assert(index >= 0 && index <= _activeCount);
    final controller = AnimationController(duration: duration, vsync: this);
    final visualIndex = _visualIndexForInsertion(index);
    setState(() {
      _rows.insert(
        visualIndex,
        _RowEntry(index: index, animation: controller, controller: controller),
      );
      _reindexActiveRows();
    });
    controller.forward().then<void>((_) {
      if (_disposed || !_rows.any((row) => row.controller == controller)) {
        return;
      }
      setState(() {
        _rows.firstWhere((row) => row.controller == controller)
          ..animation = kAlwaysCompleteAnimation
          ..controller = null;
      });
      controller.dispose();
    });
  }

  void removeItem(
    int index,
    AnimatedTableRemovedRowBuilder builder, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    assert(index >= 0 && index < _activeCount);
    final row = _rows.firstWhere((row) => !row.outgoing && row.index == index);
    final controller =
        row.controller ??
        AnimationController(duration: duration, value: 1, vsync: this);
    setState(() {
      row
        ..outgoing = true
        ..removedBuilder = builder
        ..controller = controller
        ..animation = controller;
      _reindexActiveRows();
    });
    controller.reverse().then<void>((_) {
      if (_disposed || !_rows.contains(row)) return;
      setState(() => _rows.remove(row));
      controller.dispose();
    });
  }

  int get _activeCount => _rows.where((row) => !row.outgoing).length;

  int _visualIndexForInsertion(int index) {
    var activeIndex = 0;
    for (var visualIndex = 0; visualIndex < _rows.length; visualIndex++) {
      if (_rows[visualIndex].outgoing) continue;
      if (activeIndex == index) return visualIndex;
      activeIndex++;
    }
    return _rows.length;
  }

  void _reindexActiveRows() {
    var index = 0;
    for (final row in _rows) {
      if (row.outgoing) continue;
      row.index = index++;
    }
  }

  TableRow _buildRow(_RowEntry entry) {
    final source = entry.outgoing
        ? entry.removedBuilder!(context, entry.animation)
        : widget.rowBuilder(context, entry.index, entry.animation);
    return TableRow(
      key: entry.outgoing ? ObjectKey(entry) : source.key ?? ObjectKey(entry),
      decoration: source.decoration,
      children: source.children.map((child) {
        final content = child is TableCell ? child.child : child;
        var transitioned = widget.transitionBuilder(
          context,
          entry.animation,
          content,
        );
        if (entry.outgoing) {
          transitioned = ExcludeSemantics(
            child: ExcludeFocus(child: IgnorePointer(child: transitioned)),
          );
        }
        if (child is! TableCell) return transitioned;
        return TableCell(
          key: entry.outgoing && child.key != null
              ? ValueKey((entry, child.key))
              : child.key,
          verticalAlignment: child.verticalAlignment,
          child: transitioned,
        );
      }).toList(),
    );
  }

  Widget _buildTable() {
    final table = Table(
      columnWidths: widget.columnWidths,
      defaultColumnWidth: widget.defaultColumnWidth,
      textDirection: widget.textDirection,
      border: widget.border,
      defaultVerticalAlignment: widget.defaultVerticalAlignment,
      textBaseline: widget.textBaseline,
      children: [...widget.headerRows, ..._rows.map(_buildRow)],
    );
    return widget.tableBuilder?.call(context, table) ?? table;
  }

  @override
  Widget build(BuildContext context) {
    final isVisuallyEmpty = _rows.isEmpty;
    if (widget.emptyBuilder == null) {
      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: _buildTable(),
      );
    }
    final child = isVisuallyEmpty
        ? KeyedSubtree(
            key: const ValueKey("empty"),
            child: widget.emptyBuilder!(context),
          )
        : KeyedSubtree(key: const ValueKey("table"), child: _buildTable());
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              if (previousChildren.isNotEmpty) previousChildren.last,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final transition =
              widget.emptyTransitionBuilder ?? widget.transitionBuilder;
          return transition(context, animation, child);
        },
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    for (final row in _rows) {
      row.controller?.dispose();
    }
    super.dispose();
  }
}

class _RowEntry {
  _RowEntry({required this.index, required this.animation, this.controller});

  int index;
  Animation<double> animation;
  AnimationController? controller;
  bool outgoing = false;
  AnimatedTableRemovedRowBuilder? removedBuilder;
}
