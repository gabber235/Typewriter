import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("commits selected tag movement in one batch", (tester) async {
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
      expect(notifier.batchCount, 1);
      expect(notifier.movedTagCount, 2);
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

Tag _tag(TagIdentifier identifier, String name, {required int x}) {
  return Tag(
    tagId: identifier.tagId,
    name: name,
    color: Colors.blue,
    parentIds: const [],
    placement: Placement(x: x, y: 0, width: 2, height: 1),
  );
}

class _DelayedTags extends Tags {
  _DelayedTags(this.initialTags);

  final List<Tag> initialTags;
  final Completer<void> _gate = Completer<void>();
  int batchCount = 0;
  int movedTagCount = 0;

  @override
  Stream<List<Tag>> build() async* {
    yield initialTags;
  }

  @override
  Future<void> moveTags(List<TagMovePayload> changes) async {
    final snapshot = await future;
    batchCount++;
    movedTagCount += changes.length;
    final changesById = {for (final change in changes) change.id: change};
    await _gate.future;
    state = AsyncData(
      snapshot.map((tag) {
        final change = changesById[tag.tagId];
        if (change == null) return tag;
        return tag.copyWith(
          placement: tag.placement.copyWith(x: change.x, y: change.y),
        );
      }).toList(),
    );
  }

  void release() => _gate.complete();
}
