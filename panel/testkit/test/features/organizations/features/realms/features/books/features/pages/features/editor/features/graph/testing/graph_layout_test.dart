import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/features/organizations.dart";

EntryDefinition _entry(String id) => EntryDefinition(
  id: id,
  elementDefinition: ElementDefinition(
    rootType: ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "test", name: id),
      revision: 1,
    ),
    name: id,
    description: "Graph fixture entry",
    color: safeColors.first,
    icon: const IconValue.iconify("fa-solid:star"),
  ),
  placement: const EntryPlacement(x: 0, y: 0, width: 3, height: 2),
  data: RecordValue({"id": StringValue(id), "name": StringValue(id)}),
  inwardEdges: const [],
  outwardEdges: const [],
);

void main() {
  test("empty input stays empty", () {
    expect(
      layoutGraphEntries(const [], direction: GraphDirection.leftToRight),
      isEmpty,
    );
  });

  test("layout is deterministic and supports identifiers with underscores", () {
    final entries = List.generate(8, (index) => _entry("entry_with_$index"));
    final first = layoutGraphEntries(
      entries,
      direction: GraphDirection.leftToRight,
    );
    final second = layoutGraphEntries(
      entries,
      direction: GraphDirection.leftToRight,
    );

    expect(first, second);
    expect(first.first.outwardEdges, hasLength(1));
    final target = first.first.outwardEdges.single.otherId;
    expect(
      first
          .singleWhere((entry) => entry.id == target)
          .inwardEdges
          .single
          .otherId,
      first.first.id,
    );
  });

  for (final direction in GraphDirection.values) {
    test("${direction.name} follows its main axis", () {
      final entries = List.generate(8, (index) => _entry("entry_$index"));
      final result = layoutGraphEntries(entries, direction: direction);
      final firstMain = direction.main(
        result.first.placement.x,
        result.first.placement.y,
      );
      final secondLayerMain = direction.main(
        result[4].placement.x,
        result[4].placement.y,
      );

      switch (direction) {
        case GraphDirection.leftToRight || GraphDirection.topToBottom:
          expect(secondLayerMain, greaterThan(firstMain));
        case GraphDirection.rightToLeft || GraphDirection.bottomToTop:
          expect(secondLayerMain, lessThan(firstMain));
      }
      expect(result.every((entry) => entry.placement.width > 0), isTrue);
      expect(result.every((entry) => entry.placement.height > 0), isTrue);
    });
  }

  test("entries do not overlap", () {
    final result = layoutGraphEntries(
      List.generate(12, (index) => _entry("entry_$index")),
      direction: GraphDirection.topToBottom,
    );

    for (var first = 0; first < result.length; first++) {
      for (var second = first + 1; second < result.length; second++) {
        final a = result[first].placement;
        final b = result[second].placement;
        final overlaps =
            a.x < b.x + b.width &&
            a.x + a.width > b.x &&
            a.y < b.y + b.height &&
            a.y + a.height > b.y;
        expect(overlaps, isFalse);
      }
    }
  });
}
