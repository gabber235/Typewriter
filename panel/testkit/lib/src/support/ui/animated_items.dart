import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";

/// One item an animated collection shows: its identity and visible label.
final class AnimatedItem {
  /// An item identified by [id] that shows [label].
  const AnimatedItem({required this.id, required this.label});

  /// The identity the animated collection keys the item by.
  final String id;

  /// The text the item shows.
  final String label;
}

/// The items an [AnimatedItems] collection shows, changed the way a parent
/// rebuilding it with new data does.
final class AnimatedItemSource {
  /// A source showing [items]; the list is the source's own and changes with
  /// [update].
  AnimatedItemSource(this.items) {
    addTearDown(_dispose);
  }

  /// The items the next build reads.
  final List<AnimatedItem> items;

  /// Whether the collection is mounted; false unmounts it.
  final visible = ValueNotifier(true);

  final _revision = ValueNotifier(0);

  /// The identities of every item the removal builder showed.
  final removedIds = <String>[];

  /// The items the collection rendered on its last build.
  List<AnimatedItem> renderedItems = const [];

  /// The identities of [renderedItems], in order.
  List<String> get renderedIds => [for (final item in renderedItems) item.id];

  /// Replaces the items with [next] and rebuilds.
  void update(List<AnimatedItem> next) {
    items
      ..clear()
      ..addAll(next);
    rebuild();
  }

  /// Rebuilds the collection over the current items.
  void rebuild() => _revision.value++;

  void _dispose() {
    _revision.dispose();
    visible.dispose();
  }
}

/// The collection widget an [AnimatedItems] renders through its hook.
enum AnimatedItemsLayout { sliverList, table }

/// A collection of [AnimatedItemSource] items driven by the panel's animated
/// collection hook for [layout].
///
/// Each item fades with its animation; [opacityOf] reads that fade. Removed
/// items render under the identity `removed-<id>` except in a table, whose
/// rows keep their identity.
final class AnimatedItems extends HookWidget {
  /// Shows [source] as [layout], animating insertions over [insertDuration]
  /// and removals over [removeDuration].
  const AnimatedItems({
    required this.source,
    this.layout = AnimatedItemsLayout.sliverList,
    this.insertDuration = const Duration(milliseconds: 300),
    this.removeDuration = const Duration(milliseconds: 300),
    super.key,
  });

  /// The items shown.
  final AnimatedItemSource source;

  /// The collection widget and hook used.
  final AnimatedItemsLayout layout;

  /// How long an inserted item takes to appear.
  final Duration insertDuration;

  /// How long a removed item stays while it leaves.
  final Duration removeDuration;

  /// The fade opacity of the item rendered under [id].
  static double opacityOf(WidgetTester tester, String id) =>
      tester.widget<FadeTransition>(find.byKey(ValueKey(id))).opacity.value;

  @override
  Widget build(BuildContext context) {
    useValueListenable(source._revision);
    final visible = useValueListenable(source.visible);
    final collection = switch (layout) {
      AnimatedItemsLayout.sliverList => CustomScrollView(
        slivers: [_sliverList()],
      ),
      AnimatedItemsLayout.table => _table(),
    };
    if (!visible) return const SizedBox.shrink();
    return SizedBox(width: 400, height: 400, child: collection);
  }

  Widget _removed(
    BuildContext context,
    AnimatedItem item,
    Animation<double> animation,
  ) {
    source.removedIds.add(item.id);
    return _item(item, animation, id: "removed-${item.id}");
  }

  Widget _sliverList() {
    final result = useSliverAnimatedList<AnimatedItem>(
      items: source.items,
      identity: (item) => item.id,
      insertDuration: insertDuration,
      removeDuration: removeDuration,
      removedItemBuilder: _removed,
    );
    source.renderedItems = result.items;
    return SliverAnimatedRows(
      key: result.key,
      initialItemCount: result.items.length,
      itemBuilder: (context, index, animation) =>
          _item(result.items[index], animation),
    );
  }

  Widget _table() {
    final result = useAnimatedTable<AnimatedItem>(
      items: source.items,
      identity: (item) => item.id,
      insertDuration: insertDuration,
      removeDuration: removeDuration,
      removedItemBuilder: (context, item, animation) {
        source.removedIds.add(item.id);
        return _row(item);
      },
    );
    source.renderedItems = result.items;
    return AnimatedTable(
      key: result.key,
      initialItemCount: result.items.length,
      rowBuilder: (context, index, animation) => _row(result.items[index]),
      transitionBuilder: fadeIn,
    );
  }

  static TableRow _row(AnimatedItem item) => TableRow(
    key: ValueKey(item.id),
    children: [
      TableCell(key: ValueKey("cell-${item.id}"), child: Text(item.label)),
    ],
  );

  static Widget _item(
    AnimatedItem item,
    Animation<double> animation, {
    String? id,
  }) => FadeTransition(
    key: ValueKey(id ?? item.id),
    opacity: animation,
    child: SizedBox(height: 48, child: Text(item.label)),
  );
}

/// A transition that fades [child] in with [animation].
Widget fadeIn(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) => FadeTransition(opacity: animation, child: child);

/// Showing an animated collection in the panel.
extension ShowAnimatedItems on WidgetTester {
  /// Shows [items] as [layout] through [ShowComponent.showComponent],
  /// animating insertions over [insertDuration] and removals over
  /// [removeDuration], and returns the source that changes them.
  Future<AnimatedItemSource> showAnimatedItems(
    List<AnimatedItem> items, {
    AnimatedItemsLayout layout = AnimatedItemsLayout.sliverList,
    Duration insertDuration = const Duration(milliseconds: 300),
    Duration removeDuration = const Duration(milliseconds: 300),
  }) async {
    final source = AnimatedItemSource(items);
    await showComponent(
      AnimatedItems(
        source: source,
        layout: layout,
        insertDuration: insertDuration,
        removeDuration: removeDuration,
      ),
    );
    return source;
  }
}

/// Showing a bare animated table in the panel.
extension ShowActiveRowTable on WidgetTester {
  /// Shows an [AnimatedTable] of one row reading "Active" that reads
  /// "Empty" once it has no rows, and returns its state.
  Future<AnimatedTableState> showActiveRowTable() async {
    final key = GlobalKey<AnimatedTableState>();
    await showComponent(
      AnimatedTable(
        key: key,
        initialItemCount: 1,
        emptyBuilder: (context) => const Text("Empty"),
        rowBuilder: (context, index, animation) =>
            const TableRow(children: [Text("Active")]),
        transitionBuilder: fadeIn,
      ),
    );
    return key.currentState!;
  }
}
