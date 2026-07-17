import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/hooks/animated_list.dart";

import "../test_utils.dart";

void main() {
  group("useSliverAnimatedList", () {
    testWidgets("renders initial items with completed animations", (
      tester,
    ) async {
      final source = _TestSource([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "b", label: "Beta"),
      ]);
      addTearDown(source.dispose);

      await _pumpSliverList(tester, source);

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(_opacity(tester, "a"), 1);
      expect(_opacity(tester, "b"), 1);
    });

    testWidgets("inserts in the middle using the configured duration", (
      tester,
    ) async {
      final source = _TestSource([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "c", label: "Gamma"),
      ]);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      source.update([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "b", label: "Beta"),
        const _TestItem(id: "c", label: "Gamma"),
      ]);
      await tester.pump();

      expect(find.text("Beta"), findsOneWidget);
      expect(_opacity(tester, "b"), 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(_opacity(tester, "b"), closeTo(0.5, 0.01));

      await tester.pump(const Duration(milliseconds: 100));
      expect(_opacity(tester, "b"), 1);
      expect(source.renderedIds, ["a", "b", "c"]);
      expect(tester.takeException(), isNull);
    });

    testWidgets("keeps captured removed item for the removal duration", (
      tester,
    ) async {
      final source = _TestSource([
        const _TestItem(id: "a", label: "Old Alpha"),
        const _TestItem(id: "b", label: "Beta"),
      ]);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      source.update([const _TestItem(id: "b", label: "Beta")]);
      await tester.pump();

      expect(find.text("Old Alpha"), findsOneWidget);
      expect(_opacity(tester, "removed-a"), 1);

      await tester.pump(const Duration(milliseconds: 399));
      expect(find.text("Old Alpha"), findsOneWidget);
      expect(_opacity(tester, "removed-a"), greaterThan(0));

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      expect(find.text("Old Alpha"), findsNothing);
      expect(find.text("Beta"), findsOneWidget);
    });

    testWidgets("handles mixed changes and reorder without index errors", (
      tester,
    ) async {
      final source = _TestSource([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "b", label: "Beta"),
        const _TestItem(id: "c", label: "Gamma"),
        const _TestItem(id: "d", label: "Delta"),
      ]);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      source.update([
        const _TestItem(id: "d", label: "Delta"),
        const _TestItem(id: "b", label: "Beta"),
        const _TestItem(id: "e", label: "Epsilon"),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(source.renderedIds, ["d", "b", "e"]);
      expect(find.text("Delta"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Epsilon"), findsOneWidget);
      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Gamma"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("stays synchronized across rapid updates", (tester) async {
      final source = _TestSource([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "b", label: "Beta"),
      ]);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      source.update([
        const _TestItem(id: "b", label: "Beta"),
        const _TestItem(id: "c", label: "Gamma"),
      ]);
      await tester.pump(const Duration(milliseconds: 50));
      source.update([
        const _TestItem(id: "d", label: "Delta"),
        const _TestItem(id: "c", label: "Gamma"),
        const _TestItem(id: "b", label: "Beta"),
      ]);
      await tester.pump(const Duration(milliseconds: 50));
      source.update([
        const _TestItem(id: "d", label: "Delta"),
        const _TestItem(id: "e", label: "Epsilon"),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(source.renderedIds, ["d", "e"]);
      expect(find.text("Delta"), findsOneWidget);
      expect(find.text("Epsilon"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("updates payload without a structural animation", (
      tester,
    ) async {
      final source = _TestSource([const _TestItem(id: "a", label: "Old")]);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      source.update([const _TestItem(id: "a", label: "New")]);
      await tester.pump();

      expect(find.text("Old"), findsNothing);
      expect(find.text("New"), findsOneWidget);
      expect(_opacity(tester, "a"), 1);
      expect(source.removedIds, isEmpty);
    });

    testWidgets("snapshots a mutable source list", (tester) async {
      final mutableItems = <_TestItem>[
        const _TestItem(id: "a", label: "Alpha"),
      ];
      final source = _TestSource(mutableItems);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      final previousSnapshot = source.renderedItems;
      mutableItems.add(const _TestItem(id: "b", label: "Beta"));

      expect(previousSnapshot.map((item) => item.id), ["a"]);
      expect(
        () => previousSnapshot.add(const _TestItem(id: "c", label: "Gamma")),
        throwsUnsupportedError,
      );

      source.rebuild();
      await tester.pump();

      expect(source.renderedIds, ["a", "b"]);
      expect(find.text("Beta"), findsOneWidget);
    });

    testWidgets("rejects duplicate identities on initial build", (
      tester,
    ) async {
      final source = _TestSource([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "a", label: "Duplicate"),
      ]);
      addTearDown(source.dispose);

      await _pumpSliverList(tester, source);

      expect(tester.takeException(), isArgumentError);
    });

    testWidgets("rejects duplicate identities before changing state", (
      tester,
    ) async {
      final source = _TestSource([const _TestItem(id: "a", label: "Alpha")]);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      source.update([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "a", label: "Duplicate"),
      ]);
      await tester.pump();

      expect(tester.takeException(), isArgumentError);
      expect(source.renderedIds, ["a"]);

      source.update([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "b", label: "Beta"),
      ]);
      await tester.pump();

      expect(source.renderedIds, ["a", "b"]);
      expect(tester.takeException(), isNull);
    });

    testWidgets("synchronizes while unmounted and remounts latest items", (
      tester,
    ) async {
      final source = _TestSource([const _TestItem(id: "a", label: "Alpha")]);
      addTearDown(source.dispose);
      await _pumpSliverList(tester, source);

      source.visible.value = false;
      await tester.pump();
      source.update([
        const _TestItem(id: "b", label: "Beta"),
        const _TestItem(id: "c", label: "Gamma"),
      ]);
      await tester.pump();

      source.visible.value = true;
      await tester.pump();

      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
      expect(_opacity(tester, "b"), 1);
      expect(_opacity(tester, "c"), 1);
      expect(tester.takeException(), isNull);
    });
  });

  for (final variant in _Variant.values) {
    testWidgets("${variant.name} uses its typed key and synchronizes", (
      tester,
    ) async {
      final source = _TestSource([const _TestItem(id: "a", label: "Alpha")]);
      addTearDown(source.dispose);

      await tester.pumpTestApp(
        settle: false,
        child: SizedBox(
          width: 400,
          height: 400,
          child: _VariantHarness(variant: variant, source: source),
        ),
      );

      source.update([
        const _TestItem(id: "a", label: "Alpha"),
        const _TestItem(id: "b", label: "Beta"),
      ]);
      await tester.pump();
      source.update([const _TestItem(id: "b", label: "Beta")]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Beta"), findsOneWidget);
      expect(source.renderedIds, ["b"]);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpSliverList(WidgetTester tester, _TestSource source) async {
  await tester.pumpTestApp(
    settle: false,
    child: SizedBox(
      width: 400,
      height: 400,
      child: _SliverListHarness(source: source),
    ),
  );
}

double _opacity(WidgetTester tester, String id) {
  return tester.widget<FadeTransition>(find.byKey(ValueKey(id))).opacity.value;
}

class _SliverListHarness extends HookWidget {
  const _SliverListHarness({required this.source});

  final _TestSource source;

  @override
  Widget build(BuildContext context) {
    useValueListenable(source.revision);
    final visible = useValueListenable(source.visible);
    final animated = useSliverAnimatedList<_TestItem>(
      items: source.items,
      identity: (item) => item.id,
      insertDuration: const Duration(milliseconds: 200),
      removeDuration: const Duration(milliseconds: 400),
      removedItemBuilder: (context, item, animation) {
        source.removedIds.add(item.id);
        return _item(item, animation, id: "removed-${item.id}");
      },
    );
    source.renderedItems = animated.items;

    if (!visible) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        SliverAnimatedList(
          key: _sliverListKey(animated.key),
          initialItemCount: animated.items.length,
          itemBuilder: (context, index, animation) {
            final item = animated.items[index];
            return _item(item, animation, id: item.id);
          },
        ),
      ],
    );
  }
}

class _VariantHarness extends HookWidget {
  const _VariantHarness({required this.variant, required this.source});

  final _Variant variant;
  final _TestSource source;

  @override
  Widget build(BuildContext context) {
    useValueListenable(source.revision);
    return switch (variant) {
      _Variant.list => _buildList(),
      _Variant.sliverList => _buildSliverList(),
      _Variant.grid => _buildGrid(),
      _Variant.sliverGrid => _buildSliverGrid(),
    };
  }

  Widget _buildList() {
    final result = useAnimatedList<_TestItem>(
      items: source.items,
      identity: (item) => item.id,
      removedItemBuilder: _removedItem,
    );
    source.renderedItems = result.items;
    return AnimatedList(
      key: _listKey(result.key),
      initialItemCount: result.items.length,
      itemBuilder: (context, index, animation) {
        return _item(result.items[index], animation);
      },
    );
  }

  Widget _buildSliverList() {
    final result = useSliverAnimatedList<_TestItem>(
      items: source.items,
      identity: (item) => item.id,
      removedItemBuilder: _removedItem,
    );
    source.renderedItems = result.items;
    return CustomScrollView(
      slivers: [
        SliverAnimatedList(
          key: _sliverListKey(result.key),
          initialItemCount: result.items.length,
          itemBuilder: (context, index, animation) {
            return _item(result.items[index], animation);
          },
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final result = useAnimatedGrid<_TestItem>(
      items: source.items,
      identity: (item) => item.id,
      removedItemBuilder: _removedItem,
    );
    source.renderedItems = result.items;
    return AnimatedGrid(
      key: _gridKey(result.key),
      initialItemCount: result.items.length,
      gridDelegate: _gridDelegate,
      itemBuilder: (context, index, animation) {
        return _item(result.items[index], animation);
      },
    );
  }

  Widget _buildSliverGrid() {
    final result = useSliverAnimatedGrid<_TestItem>(
      items: source.items,
      identity: (item) => item.id,
      removedItemBuilder: _removedItem,
    );
    source.renderedItems = result.items;
    return CustomScrollView(
      slivers: [
        SliverAnimatedGrid(
          key: _sliverGridKey(result.key),
          initialItemCount: result.items.length,
          gridDelegate: _gridDelegate,
          itemBuilder: (context, index, animation) {
            return _item(result.items[index], animation);
          },
        ),
      ],
    );
  }

  Widget _removedItem(
    BuildContext context,
    _TestItem item,
    Animation<double> animation,
  ) {
    return _item(item, animation);
  }
}

Widget _item(_TestItem item, Animation<double> animation, {String? id}) {
  return FadeTransition(
    key: ValueKey(id ?? item.id),
    opacity: animation,
    child: SizedBox(height: 48, child: Text(item.label)),
  );
}

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
);

GlobalKey<AnimatedListState> _listKey(GlobalKey<AnimatedListState> key) => key;

GlobalKey<SliverAnimatedListState> _sliverListKey(
  GlobalKey<SliverAnimatedListState> key,
) => key;

GlobalKey<AnimatedGridState> _gridKey(GlobalKey<AnimatedGridState> key) => key;

GlobalKey<SliverAnimatedGridState> _sliverGridKey(
  GlobalKey<SliverAnimatedGridState> key,
) => key;

enum _Variant { list, sliverList, grid, sliverGrid }

class _TestSource {
  _TestSource(this.items);

  final List<_TestItem> items;
  final revision = ValueNotifier(0);
  final visible = ValueNotifier(true);
  final removedIds = <String>[];
  List<_TestItem> renderedItems = const [];

  List<String> get renderedIds => [for (final item in renderedItems) item.id];

  void update(List<_TestItem> next) {
    items
      ..clear()
      ..addAll(next);
    rebuild();
  }

  void rebuild() {
    revision.value++;
  }

  void dispose() {
    revision.dispose();
    visible.dispose();
  }
}

class _TestItem {
  const _TestItem({required this.id, required this.label});

  final String id;
  final String label;
}
