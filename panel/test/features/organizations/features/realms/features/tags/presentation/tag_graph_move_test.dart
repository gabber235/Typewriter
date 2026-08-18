import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("points parent tag edges into their child", (tester) async {
    final parentId = recordId("tag:parent");
    final childId = recordId("tag:child");
    final tags = [
      _tag(TagIdentifier(parentId), "Parent", x: 0),
      _tag(TagIdentifier(childId), "Child", x: 0, y: 3, parentIds: [parentId]),
    ];

    await tester.pumpTestApp(
      overrides: [tagsProvider.overrideWith(() => _DelayedTags(tags))],
      child: const SizedBox(width: 800, height: 600, child: TagGraph()),
    );

    final edge = tester
        .renderObject<RenderGraphSurface>(find.byType(GraphSurface))
        .visibleEdges
        .single;
    expect(edge.edge.source, GraphIdentifier(parentId.id));
    expect(edge.edge.target, GraphIdentifier(childId.id));
    expect(edge.edge.sourceSide, EdgeSide.bottom);
    expect(edge.edge.targetSide, EdgeSide.top);
  });

  testWidgets("commits selected tag movement through complete updates", (
    tester,
  ) async {
    final firstId = recordId("tag:first");
    final secondId = recordId("tag:second");
    final tags = [
      _tag(TagIdentifier(firstId), "First Tag", x: 0),
      _tag(TagIdentifier(secondId), "Second Tag", x: 3),
    ];
    late _DelayedTags notifier;

    await tester.pumpTestApp(
      settle: false,
      overrides: [
        tagsProvider.overrideWith(() => notifier = _DelayedTags(tags)),
      ],
      child: const SizedBox(width: 800, height: 600, child: TagGraph()),
    );
    await tester.pumpAndSettle();

    final selectors = {
      for (final selector in tester.widgetList<Selector>(find.byType(Selector)))
        selector.selectableId.id: selector,
    };
    tester.container().read(selectionProvider.notifier).selectAll([
      TagIdentifier(firstId),
      TagIdentifier(secondId),
    ]);
    selectors[firstId.id]!.focusNode.requestFocus();
    await tester.pump();
    Actions.invoke(
      selectors[firstId.id]!.focusNode.context!,
      const GraphMoveIntent(direction: TraversalDirection.right),
    );
    await tester.pumpUntil(() {
      expect(notifier.updateCount, 2);
    });
    notifier.release();
    await tester.pumpAndSettle();

    final moved = {
      for (final tag in tester.container().read(tagsProvider).requireValue)
        tag.tagId: tag.placement.x,
    };
    expect(moved[firstId], 1);
    expect(moved[secondId], 4);
  });
}

Tag _tag(
  TagIdentifier identifier,
  String name, {
  required int x,
  int y = 0,
  List<skir.RecordId> parentIds = const [],
}) {
  return Tag(
    tagId: identifier.tagId,
    revision: 1,
    name: name,
    color: Colors.blue,
    parentIds: parentIds,
    placement: Placement(x: x, y: y, width: 2, height: 1),
  );
}

class _DelayedTags extends Tags {
  _DelayedTags(this.initialTags);

  final List<Tag> initialTags;
  final Completer<void> _gate = Completer<void>();
  int updateCount = 0;

  @override
  Stream<List<Tag>> build() async* {
    yield initialTags;
  }

  @override
  Future<TypedMutationResult> updateTag(Tag tag) async {
    updateCount++;
    await _gate.future;
    state = AsyncData(
      state.requireValue.upsertByKey((value) => value.tagId, tag),
    );
    return TypedMutationResult.success(
      revision: tag.revision,
      value: StringValue(tag.name),
    );
  }

  void release() => _gate.complete();
}
