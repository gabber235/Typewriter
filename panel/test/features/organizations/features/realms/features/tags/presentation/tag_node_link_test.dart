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
      final childId = skir.ResourceId(value: "child");
      final parentId = skir.ResourceId(value: "parent");
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
      final childId = skir.ResourceId(value: "child");
      final parentId = skir.ResourceId(value: "parent");
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
      final tagId = skir.ResourceId(value: "self");
      await _pumpTagTarget(tester, [_tag(tagId)], tagId);

      expect(
        _target(tester).onWillAcceptWithDetails!(_details(tagId)),
        isFalse,
      );
    });

    testWidgets("rejects an indirect existing parent", (tester) async {
      final childId = skir.ResourceId(value: "child");
      final intermediateId = skir.ResourceId(value: "intermediate");
      final parentId = skir.ResourceId(value: "parent");
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
      final childId = skir.ResourceId(value: "child");
      final parentId = skir.ResourceId(value: "parent");
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
      final childId = skir.ResourceId(value: "child");
      final parentId = skir.ResourceId(value: "parent");
      final ancestorId = skir.ResourceId(value: "ancestor");
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
      final childId = skir.ResourceId(value: "child");
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
        overrides: [
          canonicalTagsProvider.overrideWith(() => _RecordingTags(tags)),
        ],
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

DragTargetDetails<TagIdentifier> _details(skir.ResourceId id) =>
    DragTargetDetails(data: TagIdentifier(id), offset: Offset.zero);

Tag _tag(skir.ResourceId id, {List<skir.ResourceId> parentIds = const []}) =>
    Tag(
      tagId: id,
      name: id.id,
      color: Colors.blue,
      parentIds: parentIds,
      placement: GraphPlacement(x: 0, y: 0, width: 2, height: 1),
    );

Future<_RecordingTags> _pumpTagTarget(
  WidgetTester tester,
  List<Tag> tags,
  skir.ResourceId targetId,
) async {
  late _RecordingTags notifier;
  await tester.pumpTestApp(
    overrides: [
      canonicalTagsProvider.overrideWith(() => notifier = _RecordingTags(tags)),
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

class _RecordingTags extends CanonicalTags {
  _RecordingTags(this.tags);

  final List<Tag> tags;
  Tag? updatedTag;

  @override
  Future<List<Tag>> build() async => tags;

  @override
  Future<TypedMutationResult> updateTag(Tag tag, {Tag? expected}) async {
    updatedTag = tag;
    state = AsyncData(
      state.requireValue
          .map((current) => current.tagId == tag.tagId ? tag : current)
          .toList(),
    );
    return TypedMutationResult.success(
      revision: 1,
      value: StringValue(tag.name),
    );
  }
}
