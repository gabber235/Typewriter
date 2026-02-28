import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/utils/map.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/tags/tag_header.dart";

class TagIdentifier extends SelectableIdentifier implements GraphDragData {
  const TagIdentifier(this.id);

  @override
  final String id;

  @override
  GraphIdentifier get graphId => GraphIdentifier(id);

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final tagAsync = ref.watch(tagProvider(id));
    return tagAsync.whenData((value) {
      if (value == null) {
        throw SelectableNotFoundException(this);
      }
      return TagSelectable(ref: ref, id: this, tag: value);
    });
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

class TagSelectable extends Selectable<TagIdentifier> {
  TagSelectable({required this.ref, required this.id, required this.tag})
    : _data = DynamicData(stringMap(tag.toProto3Json()));

  @override
  final TagIdentifier id;

  final Tag tag;

  @override
  String get name => tag.name;

  final Ref ref;

  final DynamicData _data;

  @override
  ObjectBlueprint get objectBlueprint {
    return ObjectBlueprint(
      fields: {
        "name": DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
      },
    );
  }

  @override
  List<SelectableOperation> get operations => [
    DeleteSelectableOperation(
      onDelete: () => ref.read(tagsProvider.notifier).deleteTag(tag.tagId),
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
