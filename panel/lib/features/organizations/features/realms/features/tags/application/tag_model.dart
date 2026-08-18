part of "tags.dart";

@freezed
abstract class Placement with _$Placement {
  const factory Placement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _Placement;

  const Placement._();

  factory Placement.fromSkir(skir.Placement placement) => Placement(
    x: placement.x,
    y: placement.y,
    width: placement.width,
    height: placement.height,
  );

  skir.Placement toSkir() =>
      skir.Placement(x: x, y: y, width: width, height: height);
}

@freezed
abstract class Tag with _$Tag {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Tag({
    required skir.RecordId tagId,
    required int revision,
    required String name,
    required Color color,
    required List<skir.RecordId> parentIds,
    required Placement placement,
  }) = _Tag;

  const Tag._();

  factory Tag.fromSkir(skir.Tag tag) => Tag(
    tagId: tag.tagId,
    revision: tag.revision,
    name: tag.name,
    color: tag.color.toFlutterColor(),
    parentIds: tag.parentIds.toList(),
    placement: Placement.fromSkir(tag.placement),
  );

  skir.Tag toSkir() => skir.Tag(
    tagId: tagId,
    revision: revision,
    name: name,
    color: color.toSkirColor(),
    parentIds: parentIds,
    placement: placement.toSkir(),
  );
}

extension TagInspectorValue on Tag {
  RecordValue get inspectorValue => RecordValue({
    "name": StringValue(name),
    "color": color.integerValue,
    "parents": ListValue(
      parentIds.map((parentId) => StringValue(parentId.id)).toList(),
    ),
    "layout": RecordValue({
      "x": IntegerValue(BigInt.from(placement.x)),
      "y": IntegerValue(BigInt.from(placement.y)),
      "width": IntegerValue(BigInt.from(placement.width)),
      "height": IntegerValue(BigInt.from(placement.height)),
    }),
  });
}

enum TagParentDropAction { link, unlink }

TagParentDropAction? tagParentDropAction(
  Iterable<Tag> tags, {
  required skir.RecordId childId,
  required skir.RecordId parentId,
}) {
  final tagsById = {for (final tag in tags) tag.tagId: tag};
  final child = tagsById[childId];
  if (child == null || !tagsById.containsKey(parentId)) return null;
  if (childId == parentId) return null;
  if (child.parentIds.contains(parentId)) return TagParentDropAction.unlink;

  final parentIsAncestor = _isAncestor(
    tagsById,
    tagId: childId,
    ancestorId: parentId,
  );
  if (parentIsAncestor ?? true) return null;

  final childIsAncestor = _isAncestor(
    tagsById,
    tagId: parentId,
    ancestorId: childId,
  );
  if (childIsAncestor ?? true) return null;

  return TagParentDropAction.link;
}

bool? _isAncestor(
  Map<skir.RecordId, Tag> tagsById, {
  required skir.RecordId tagId,
  required skir.RecordId ancestorId,
}) {
  final pendingIds = [tagId];
  final visitedIds = <skir.RecordId>{};
  while (pendingIds.isNotEmpty) {
    final currentId = pendingIds.removeLast();
    if (!visitedIds.add(currentId)) continue;

    final current = tagsById[currentId];
    if (current == null) return null;
    for (final parentId in current.parentIds) {
      if (parentId == ancestorId) return true;
      pendingIds.add(parentId);
    }
  }

  return false;
}

({List<Tag> values, Tag canonical}) _upsertCanonicalTag(
  List<Tag>? values,
  Tag incoming,
) => reconcileCanonicalRevision(
  values: values,
  incoming: incoming,
  keyOf: (tag) => tag.tagId,
  revisionOf: (tag) => tag.revision,
  identityOf: (tag) => "Tag ${tag.tagId.id}",
  entityName: "Tag",
);
