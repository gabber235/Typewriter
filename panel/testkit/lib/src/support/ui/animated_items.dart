import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";
import "package:typewriter_testkit/src/support/ui/reduced_motion.dart";

/// One item an animated collection shows: its identity and visible label.
final class AnimatedItem {
  /// An item identified by [id] that shows [label].
  const AnimatedItem({required this.id, required this.label});

  /// The identity the animated collection keys the item by.
  final String id;

  /// The text the item shows.
  final String label;
}

/// [count] items with ids `0` to `count - 1`, labelled "Row 0" onwards.
List<AnimatedItem> numberedItems(int count) => [
  for (var index = 0; index < count; index++)
    AnimatedItem(id: "$index", label: "Row $index"),
];

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

  /// Whether the items arrived; false shows the collection still loading.
  bool ready = true;

  /// Whether the collection is mounted; false unmounts it while its rows
  /// stay.
  final visible = ValueNotifier(true);

  final _revision = ValueNotifier(0);

  /// The rows the collection renders, as of its last build.
  late AnimatedRows<AnimatedItem> rows;

  /// The ids of the rows a tap reached, in order.
  final tapped = <String>[];

  /// The identities of the items in the data, in order, as of the last build.
  List<String> get renderedIds => [for (final item in rows.items) item.id];

  /// Replaces the items with [next] and rebuilds.
  void update(List<AnimatedItem> next) {
    ready = true;
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

/// The collection widget an [AnimatedItems] renders its rows through.
enum AnimatedItemsLayout { sliverList, table }

/// A 400 by 400 scroll view of [AnimatedItemSource] items on one
/// [useAnimatedRows], rendered as [layout]. Each row is 48 px high, one
/// focus stop holding a small field, and records taps in
/// [AnimatedItemSource.tapped].
final class AnimatedItems extends HookWidget {
  /// Shows [source] as [layout], with [columns] cells per table row.
  const AnimatedItems({
    required this.source,
    this.layout = AnimatedItemsLayout.sliverList,
    this.columns = 1,
    super.key,
  });

  /// The items shown.
  final AnimatedItemSource source;

  /// The collection widget used.
  final AnimatedItemsLayout layout;

  /// How many cells each table row shows; past one they read
  /// `<label> cell <n>`.
  final int columns;

  /// The label of the row that holds keyboard focus, on the row itself or
  /// in a control inside it, or null.
  static String? focusedLabel(WidgetTester tester) {
    for (
      FocusNode? node = FocusManager.instance.primaryFocus;
      node != null;
      node = node.parent
    ) {
      if (node case RowFocusNode(:final entry)) {
        return (entry.item as AnimatedItem?)?.label;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    useValueListenable(source._revision);
    final visible = useValueListenable(source.visible);
    final rows = useAnimatedRows<AnimatedItem>(
      items: List.of(source.items),
      identity: (item) => item.id,
      ready: source.ready,
    );
    source.rows = rows;
    if (!visible) return const SizedBox(width: 400, height: 400);
    return SizedBox(
      width: 400,
      height: 400,
      child: CustomScrollView(
        slivers: [
          switch (layout) {
            AnimatedItemsLayout.sliverList => SliverAnimatedRows(
              rows: rows,
              itemBuilder: (context, entry) => RowStop(
                child: _tappable(entry.item, _withField(entry.item.label)),
              ),
            ),
            AnimatedItemsLayout.table => SliverRowAnchor(
              sliver: SliverToBoxAdapter(
                child: AnimatedTable(
                  rows: rows,
                  rowBuilder: (context, entry) => TableRow(
                    children: [
                      for (var column = 0; column < columns; column++)
                        RowStop(
                          role: column == 0 ? RowRole.stop : RowRole.part,
                          bounds: RingBounds.tableRow,
                          child: _tappable(
                            entry.item,
                            column == 0
                                ? _withField(
                                    columns == 1
                                        ? entry.item.label
                                        : "${entry.item.label} cell $column",
                                  )
                                : Text("${entry.item.label} cell $column"),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          },
        ],
      ),
    );
  }

  // The label and a field Tab passes over, focused by a test the way a
  // pointer would.
  Widget _withField(String label) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label)),
      Focus(
        debugLabel: "$label field",
        skipTraversal: true,
        child: const SizedBox(width: 8, height: 8),
      ),
    ],
  );

  Widget _tappable(AnimatedItem item, Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => source.tapped.add(item.id),
    child: SizedBox(height: 48, child: child),
  );
}

/// Showing an animated collection in the panel.
extension ShowAnimatedItems on WidgetTester {
  /// Shows [items] as [layout] through [ShowComponent.showComponent] and
  /// returns the source that changes them. [inPane] places the collection in
  /// a [Pane], whose run plays the load; [reducedMotion] renders it for a
  /// user who asked for reduced motion; [settle] false renders only the
  /// first frame of a fresh mount.
  Future<AnimatedItemSource> showAnimatedItems(
    List<AnimatedItem> items, {
    AnimatedItemsLayout layout = AnimatedItemsLayout.sliverList,
    int columns = 1,
    bool inPane = false,
    bool reducedMotion = false,
    bool settle = true,
  }) async {
    final source = AnimatedItemSource(items);
    Widget shown = AnimatedItems(
      source: source,
      layout: layout,
      columns: columns,
    );
    if (inPane) {
      shown = Pane(id: "items", margin: EdgeInsets.zero, child: shown);
    }
    if (reducedMotion) shown = ReducedMotion(child: shown);
    if (settle) {
      await showComponent(shown);
    } else {
      await mountComponent(shown);
    }
    return source;
  }
}

/// Moving keyboard focus in an [AnimatedItems] collection, and covering it
/// with a dialog.
extension FocusAnimatedItems on WidgetTester {
  AnimatedItemSource get _shownSource =>
      widget<AnimatedItems>(find.byType(AnimatedItems)).source;

  /// Focuses the row of [id], the way a pointer or a key landing on it
  /// does.
  Future<void> focusAnimatedItem(String id) async {
    _shownSource.rows[id]!.focus.requestFocus();
    await pump();
  }

  /// Focuses the field inside the row of [id].
  Future<void> focusAnimatedItemField(String id) async {
    final row = _shownSource.rows[id]!.focus;
    row.descendants.last.requestFocus();
    await pump();
    expect(row.hasFocus && !row.hasPrimaryFocus, isTrue);
  }

  /// Opens a dialog over the collection that takes focus.
  Future<void> openTestDialog() async {
    unawaited(
      showAdvancedDialog<void>(
        context: element(find.byType(AnimatedItems)),
        builder: (context) => Center(
          child: Button(
            label: "Close test dialog",
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
    await pumpAndSettle();
    expect(AnimatedItems.focusedLabel(this), isNull);
  }

  /// Closes the dialog [openTestDialog] opened, the way its button does.
  Future<void> closeTestDialog() async {
    await tap(find.text("Close test dialog"));
    await pumpAndSettle();
  }
}

/// Showing a page whose primary pane opens on its first item.
extension ShowOpenFocusPane on WidgetTester {
  /// Shows a primary [Pane] with open focus on its first item, holding a
  /// button labelled [fallback], an [AnimatedItems] list still loading and a
  /// button labelled "Other", and returns the source whose
  /// [AnimatedItemSource.update] delivers the items.
  Future<AnimatedItemSource> showOpenFocusPane({
    required String fallback,
  }) async {
    final source = AnimatedItemSource([])..ready = false;
    await showComponent(
      Pane(
        id: "page",
        primary: true,
        openFocus: PaneOpenFocus.firstItem,
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(label: fallback, onPressed: () {}),
            AnimatedItems(source: source),
            Button(label: "Other", onPressed: () {}),
          ],
        ),
      ),
    );
    return source;
  }
}

/// Showing a bare animated table in the panel.
extension ShowActiveRowTable on WidgetTester {
  /// Shows an [AnimatedTable] of the rows of [source], each reading its
  /// label, that reads "Empty" once it has no rows, and returns the source.
  Future<AnimatedItemSource> showActiveRowTable({
    List<AnimatedItem> items = const [AnimatedItem(id: "a", label: "Active")],
  }) async {
    final source = AnimatedItemSource(List.of(items));
    await showComponent(_EmptyingTable(source: source));
    return source;
  }
}

final class _EmptyingTable extends HookWidget {
  const _EmptyingTable({required this.source});

  final AnimatedItemSource source;

  @override
  Widget build(BuildContext context) {
    useValueListenable(source._revision);
    final rows = useAnimatedRows<AnimatedItem>(
      items: List.of(source.items),
      identity: (item) => item.id,
    );
    source.rows = rows;
    return SizedBox(
      width: 400,
      child: AnimatedTable(
        rows: rows,
        emptyBuilder: (context) => const Text("Empty"),
        rowBuilder: (context, entry) => TableRow(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => source.tapped.add(entry.id as String),
              child: Text(entry.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
