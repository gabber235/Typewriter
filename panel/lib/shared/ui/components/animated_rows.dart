import "package:typewriter_panel/typewriter_panel.dart";

/// One row of an animated collection, in the order the rows are shown.
class AnimatedRow<R> {
  AnimatedRow({required this.index, required this.animation, this.controller});

  /// The row's logical index among the rows that have not been removed.
  int index;
  Animation<double> animation;

  /// The controller while the row animates; null once it has settled.
  AnimationController? controller;
  bool outgoing = false;

  /// Builds the row while it leaves, since its data is already gone.
  R Function(BuildContext context, Animation<double> animation)? removedBuilder;
}

/// The rows of an animated collection and the animations that move them in and
/// out. Row indices are logical active indices: a row that is leaving stays in
/// [rows] until its reverse animation completes, without taking up an index.
///
/// The state owns every controller. Each one is disposed exactly once, by the
/// animation that finishes it or by [dispose], whichever comes first. The two
/// can meet in one frame: the web engine runs a frame's two halves without
/// flushing microtasks between them, so the collection can leave the tree after
/// an animation ended and before the code awaiting that animation runs.
mixin AnimatedRows<W extends StatefulWidget, R> on TickerProviderStateMixin<W> {
  /// Every row on screen, with leaving rows where they were.
  @protected
  final List<AnimatedRow<R>> rows = [];
  bool _disposed = false;

  /// The number of rows the collection starts with.
  @protected
  int get initialRowCount;

  @override
  void initState() {
    super.initState();
    for (var index = 0; index < initialRowCount; index++) {
      rows.add(AnimatedRow(index: index, animation: kAlwaysCompleteAnimation));
    }
  }

  /// Inserts an active row at [index] and animates it in.
  ///
  /// The builder receives the new logical index. A still animating outgoing row
  /// does not consume an active index.
  void insertItem(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    assert(index >= 0 && index <= _activeCount);
    final controller = AnimationController(duration: duration, vsync: this);
    final visualIndex = _visualIndexForInsertion(index);
    setState(() {
      rows.insert(
        visualIndex,
        AnimatedRow(
          index: index,
          animation: controller,
          controller: controller,
        ),
      );
      _reindexActiveRows();
    });
    controller.forward().then<void>((_) {
      if (_disposed || !rows.any((row) => row.controller == controller)) return;
      setState(() {
        rows.firstWhere((row) => row.controller == controller)
          ..animation = kAlwaysCompleteAnimation
          ..controller = null;
      });
      controller.dispose();
    });
  }

  /// Removes the active row at [index], keeping [builder] alive for the reverse
  /// animation.
  void removeItem(
    int index,
    R Function(BuildContext context, Animation<double> animation) builder, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    assert(index >= 0 && index < _activeCount);
    final row = rows.firstWhere((row) => !row.outgoing && row.index == index);
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
      if (_disposed || !rows.contains(row)) return;
      setState(() => rows.remove(row));
      controller.dispose();
    });
  }

  int get _activeCount => rows.where((row) => !row.outgoing).length;

  int _visualIndexForInsertion(int index) {
    var activeIndex = 0;
    for (var visualIndex = 0; visualIndex < rows.length; visualIndex++) {
      if (rows[visualIndex].outgoing) continue;
      if (activeIndex == index) return visualIndex;
      activeIndex++;
    }
    return rows.length;
  }

  void _reindexActiveRows() {
    var index = 0;
    for (final row in rows) {
      if (row.outgoing) continue;
      row.index = index++;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final row in rows) {
      row.controller?.dispose();
    }
    super.dispose();
  }
}

/// Builds one active row of an [SliverAnimatedRows]. The animation is complete
/// for settled rows and runs forward for inserted rows.
typedef SliverAnimatedRowBuilder = Widget Function(
  BuildContext context,
  int index,
  Animation<double> animation,
);

/// A sliver list that animates rows in and out, the sliver form of
/// [AnimatedTable].
///
/// Flutter's `SliverAnimatedList` is not used because it disposes a finished
/// row's controller a second time when the list leaves the tree in that frame;
/// see [AnimatedRows]. Callers own the data source and keep it consistent with
/// the state methods.
class SliverAnimatedRows extends StatefulWidget {
  const SliverAnimatedRows({
    required this.initialItemCount,
    required this.itemBuilder,
    super.key,
  }) : assert(initialItemCount >= 0);

  final int initialItemCount;
  final SliverAnimatedRowBuilder itemBuilder;

  @override
  SliverAnimatedRowsState createState() => SliverAnimatedRowsState();
}

class SliverAnimatedRowsState extends State<SliverAnimatedRows>
    with TickerProviderStateMixin, AnimatedRows<SliverAnimatedRows, Widget> {
  @override
  int get initialRowCount => widget.initialItemCount;

  Widget _buildRow(BuildContext context, int visualIndex) {
    final row = rows[visualIndex];
    return row.outgoing
        ? row.removedBuilder!(context, row.animation)
        : widget.itemBuilder(context, row.index, row.animation);
  }

  @override
  Widget build(BuildContext context) => SliverList(
    delegate: SliverChildBuilderDelegate(_buildRow, childCount: rows.length),
  );
}
