import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  group("TagNode parent linking", () {
    testWidgets("dropping a parent onto a child links them", (tester) async {
      final childId = recordId("tag:child");
      final parentId = recordId("tag:parent");
      final notifier = await _pumpTagTarget(tester, [
        _tag(childId),
        _tag(parentId),
      ], childId);
      final target = _target(tester);
      final details = _details(parentId);

      expect(target.onWillAcceptWithDetails!(details), isTrue);
      target.onAcceptWithDetails!(details);
      await tester.pump();

      expect(notifier.updatedTag?.tagId, childId);
      expect(notifier.updatedTag?.parentIds, [parentId]);
    });

    testWidgets("dropping a direct parent again unlinks it", (tester) async {
      final childId = recordId("tag:child");
      final parentId = recordId("tag:parent");
      final notifier = await _pumpTagTarget(tester, [
        _tag(childId, parentIds: [parentId]),
        _tag(parentId),
      ], childId);
      final target = _target(tester);
      final details = _details(parentId);

      expect(target.onWillAcceptWithDetails!(details), isTrue);
      target.onAcceptWithDetails!(details);
      await tester.pump();

      expect(notifier.updatedTag?.tagId, childId);
      expect(notifier.updatedTag?.parentIds, isEmpty);
    });

    testWidgets("rejects self links", (tester) async {
      final tagId = recordId("tag:self");
      await _pumpTagTarget(tester, [_tag(tagId)], tagId);

      expect(
        _target(tester).onWillAcceptWithDetails!(_details(tagId)),
        isFalse,
      );
    });

    testWidgets("rejects an indirect existing parent", (tester) async {
      final childId = recordId("tag:child");
      final intermediateId = recordId("tag:intermediate");
      final parentId = recordId("tag:parent");
      await _pumpTagTarget(tester, [
        _tag(childId, parentIds: [intermediateId]),
        _tag(intermediateId, parentIds: [parentId]),
        _tag(parentId),
      ], childId);

      expect(
        _target(tester).onWillAcceptWithDetails!(_details(parentId)),
        isFalse,
      );
    });

    testWidgets("rejects direct tag cycles", (tester) async {
      final childId = recordId("tag:child");
      final parentId = recordId("tag:parent");
      await _pumpTagTarget(tester, [
        _tag(childId),
        _tag(parentId, parentIds: [childId]),
      ], childId);

      expect(
        _target(tester).onWillAcceptWithDetails!(_details(parentId)),
        isFalse,
      );
    });

    testWidgets("rejects transitive tag cycles", (tester) async {
      final childId = recordId("tag:child");
      final parentId = recordId("tag:parent");
      final ancestorId = recordId("tag:ancestor");
      await _pumpTagTarget(tester, [
        _tag(childId),
        _tag(parentId, parentIds: [ancestorId]),
        _tag(ancestorId, parentIds: [childId]),
      ], childId);

      expect(
        _target(tester).onWillAcceptWithDetails!(_details(parentId)),
        isFalse,
      );
    });

    testWidgets("shows clear feedback for rejected parent drops", (
      tester,
    ) async {
      final childId = recordId("tag:child");
      final tags = [_tag(childId)];
      await _pumpTagTarget(tester, tags, childId);
      final target = _target(tester);
      expect(target.onWillAcceptWithDetails!(_details(childId)), isFalse);

      final rejectedTarget = target.builder(
        tester.element(find.byType(DragTarget<TagIdentifier>)),
        const [],
        [TagIdentifier(childId)],
      );
      await tester.pumpTestApp(
        overrides: [tagsProvider.overrideWith(() => _RecordingTags(tags))],
        child: SizedBox(width: 200, height: 100, child: rejectedTarget),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MouseRegion &&
              widget.cursor == SystemMouseCursors.forbidden,
        ),
        findsOneWidget,
      );
    });
  });
}

DragTarget<TagIdentifier> _target(WidgetTester tester) => tester
    .widget<DragTarget<TagIdentifier>>(find.byType(DragTarget<TagIdentifier>));

DragTargetDetails<TagIdentifier> _details(skir.RecordId id) =>
    DragTargetDetails(data: TagIdentifier(id), offset: Offset.zero);

Tag _tag(skir.RecordId id, {List<skir.RecordId> parentIds = const []}) => Tag(
  tagId: id,
  revision: 1,
  name: id.id,
  color: Colors.blue,
  parentIds: parentIds,
  placement: const Placement(x: 0, y: 0, width: 2, height: 1),
);

Future<_RecordingTags> _pumpTagTarget(
  WidgetTester tester,
  List<Tag> tags,
  skir.RecordId targetId,
) async {
  late _RecordingTags notifier;
  await tester.pumpTestApp(
    overrides: [
      tagsProvider.overrideWith(() => notifier = _RecordingTags(tags)),
    ],
    child: Center(
      child: SizedBox(
        width: 200,
        height: 100,
        child: GraphDrag(
          draggingInsideGraph: ValueNotifier(false),
          child: TagNode(tagId: targetId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

class _RecordingTags extends Tags {
  _RecordingTags(this.tags);

  final List<Tag> tags;
  Tag? updatedTag;

  @override
  Stream<List<Tag>> build() async* {
    yield tags;
  }

  @override
  Future<TypedMutationResult> updateTag(Tag tag) async {
    updatedTag = tag;
    state = AsyncData(
      state.requireValue
          .map((current) => current.tagId == tag.tagId ? tag : current)
          .toList(),
    );
    return TypedMutationResult.success(
      revision: tag.revision,
      value: StringValue(tag.name),
    );
  }
}
