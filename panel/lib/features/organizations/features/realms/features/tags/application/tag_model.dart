part of "tags.dart";

/// Persistent graph coordinates and dimensions for a tag node.
///
/// Coordinates are grid units interpreted by the tag graph. Width and height
/// must remain positive because the inspector and graph require a visible
/// node; [TagEditorSnapshot] enforces that rule for draft changes.
@freezed
abstract class Placement with _$Placement {
  const factory Placement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _Placement;

  const Placement._();

  factory Placement.fromWire(skir.GraphPlacement placement) => Placement(
    x: placement.x,
    y: placement.y,
    width: placement.width,
    height: placement.height,
  );

  skir.GraphPlacement toWire() =>
      skir.GraphPlacement(x: x, y: y, width: width, height: height);
}

/// Immutable panel model of the wire level Realm tag.
///
/// [parentIds] names direct parents. The relationship is treated as a directed
/// acyclic graph by the panel, and drag validation rejects self links, cycles,
/// and unknown nodes. Wire conversion is lossless for the fields represented
/// here. Inspector values omit the identity because the editor resource owns it.
@freezed
abstract class Tag with _$Tag {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Tag({
    required skir.RecordId tagId,
    required String name,
    required Color color,
    required List<skir.RecordId> parentIds,
    required Placement placement,
  }) = _Tag;

  const Tag._();

  factory Tag.fromWire(skir.Tag tag) => Tag(
    tagId: tag.id,
    name: tag.name,
    color: tag.color.toFlutterColor(),
    parentIds: tag.parents.toList(),
    placement: Placement.fromWire(tag.placement),
  );

  skir.Tag toWire() => skir.Tag(
    id: tagId,
    name: name,
    color: color.toSkirColor(),
    parents: parentIds,
    placement: placement.toWire(),
  );
}

/// Converts a tag to and from the structural value used by the editor.
///
/// Decoding is deliberately strict. Wrong field types, malformed parent IDs,
/// invalid colors, or nonpositive dimensions return null, allowing the shared
/// editor to keep an invalid draft visible without creating an invalid Tag.
extension TagInspectorValue on Tag {
  RecordValue get inspectorValue => RecordValue({
    "name": name.asValue,
    "color": color.asValue,
    "parents": ListValue(parentIds.map(ReferenceValue.new).toList()),
    "layout": RecordValue({
      "x": placement.x.asValue,
      "y": placement.y.asValue,
      "width": placement.width.asValue,
      "height": placement.height.asValue,
    }),
  });

  Tag? withInspectorValue(DataValue value) {
    if (value is! RecordValue) return null;
    final name = value.fields["name"];
    final color = value.fields["color"];
    final parents = value.fields["parents"];
    final layout = value.fields["layout"];
    if (name is! StringValue ||
        name.value.trim().isEmpty ||
        color is! IntegerValue ||
        parents is! ListValue ||
        layout is! RecordValue) {
      return null;
    }

    final decodedColor = color.asColorOrNull;
    final parentIds = parents.values
        .whereType<ReferenceValue>()
        .map((parent) => parent.id)
        .toList();
    final x = layout.fields["x"];
    final y = layout.fields["y"];
    final width = layout.fields["width"];
    final height = layout.fields["height"];

    if (decodedColor == null ||
        parentIds.length != parents.values.length ||
        x is! IntegerValue ||
        y is! IntegerValue ||
        width is! IntegerValue ||
        height is! IntegerValue ||
        width.value < BigInt.one ||
        height.value < BigInt.one) {
      return null;
    }
    return copyWith(
      name: name.value,
      color: decodedColor,
      parentIds: parentIds,
      placement: Placement(
        x: x.value.toInt(),
        y: y.value.toInt(),
        width: width.value.toInt(),
        height: height.value.toInt(),
      ),
    );
  }

  Tag projected(LocalEditorValue? local) {
    if (local == null) return this;
    return withInspectorValue(local.projectOnto(inspectorValue)) ?? this;
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
