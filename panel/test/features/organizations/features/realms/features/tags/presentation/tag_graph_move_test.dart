import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
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

Tag _tag(TagIdentifier identifier, String name, {required int x}) {
  return Tag(
    tagId: identifier.tagId,
    revision: 1,
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
