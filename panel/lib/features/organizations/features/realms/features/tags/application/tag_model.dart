part of "tags.dart";

/// Immutable panel model of the wire level Realm tag.
///
/// [parentIds] names direct parents. The relationship is treated as a directed
/// acyclic graph by the panel, and drag validation rejects self links, cycles,
/// and unknown nodes. Unfinished authored fields receive display values here
/// without changing the authoring record. Inspector values omit the identity
/// because the editor resource owns it.
@freezed
abstract class Tag with _$Tag {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Tag({
    required skir.ResourceId tagId,
    required String name,
    required Color color,
    required List<skir.ResourceId> parentIds,
    required GraphPlacement placement,
  }) = _Tag;

  const Tag._();

  factory Tag.fromAuthoring(skir.AuthoringResource resource) {
    final value = decodeAuthoredTag(resource);
    return Tag(
      tagId: value.id,
      name: value.name,
      color: Color(value.argb),
      parentIds: value.parents,
      placement: GraphPlacement(
        x: value.x,
        y: value.y,
        width: value.width,
        height: value.height,
      ),
    );
  }
}

/// Relationship mutation requested by dropping one tag onto another.
enum TagParentDropAction { link, unlink }

/// Determines whether a graph drop links or unlinks two existing tags.
///
/// Null means the drop must be rejected. The check requires both nodes to be
/// present, rejects self links and either direction of cycle, and treats an
/// existing direct link as an unlink action. Unknown ancestry is rejected
/// conservatively because accepting it could create a cycle.
TagParentDropAction? tagParentDropAction(
  Iterable<Tag> tags, {
  required skir.ResourceId childId,
  required skir.ResourceId parentId,
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
  Map<skir.ResourceId, Tag> tagsById, {
  required skir.ResourceId tagId,
  required skir.ResourceId ancestorId,
}) {
  final pendingIds = [tagId];
  final visitedIds = <skir.ResourceId>{};
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
