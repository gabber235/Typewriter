import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/tags/tag_header.dart";

part "tag_selectable.g.dart";

class TagIdentifier extends SelectableIdentifier implements GraphDragData {
  const TagIdentifier(this.id);

  @override
  final String id;

  @override
  GraphIdentifier get graphId => GraphIdentifier(id);

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final tag = ref.watch(tagProvider(id));
    if (tag == null) {
      throw SelectableNotFoundException(this);
    }
    return AsyncValue.data(TagSelectable(ref: ref, id: this, tag: tag));
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagIdentifier && other.id == id;
  }

  @override
  String toString() => "TagIdentifier(id: $id)";
}

@riverpod
TagSelectable? tagSelectable(Ref ref, String tagId) {
  final tag = ref.watch(tagProvider(tagId));
  if (tag == null) return null;

  return TagSelectable(ref: ref, id: TagIdentifier(tagId), tag: tag);
}

class TagSelectable extends Selectable<TagIdentifier> {
  TagSelectable({required this.ref, required this.id, required this.tag})
    : _data = DynamicData(tag.toProto3Json() as Map<String, dynamic>);

  @override
  final TagIdentifier id;

  final Tag tag;

  @override
  String get name => tag.name;

  final Ref ref;

  final DynamicData _data;

  @override
  ObjectBlueprint get objectBlueprint {
    return ObjectBlueprint(fields: {"name": DataBlueprint.string()});
  }

  @override
  List<SelectableOperation> get operations => [
    DeleteSelectableOperation(
      onDelete: () => ref.read(tagsProvider.notifier).deleteTag(tag.id),
    ),
  ];

  @override
  Widget? header() => TagHeader(tag: tag);

  @override
  dynamic fieldValue(String path) {
    return _data.get(path);
  }

  @override
  void setFieldValue(String path, dynamic value) {
    final newData = _data.copyWith(path, value);
    final newTag = Tag()..mergeFromProto3Json(newData.toJson());
    ref.read(tagsProvider.notifier).updateTag(newTag);
  }

  @override
  int get hashCode => Object.hash(id, tag);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagSelectable) return false;
    return other.id == id && other.tag == tag;
  }

  @override
  String toString() => "TagSelectable(id: $id, tag: $tag)";
}
