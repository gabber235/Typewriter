import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const _tagInspectorType = TypeDefinition(
  id: ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "panel", name: "Tag"),
    revision: 1,
  ),
  kind: NominalTypeKind.concrete,
  representation: RecordType(
    fields: {"name": TypeField(name: "name", type: StringType())},
  ),
);

const _tagInspectorCatalog = TypeCatalog([_tagInspectorType]);

class TagIdentifier extends SelectableIdentifier implements GraphDragData {
  const TagIdentifier(this.tagId);

  final skir.RecordId tagId;

  @override
  String get id => tagId.id;

  @override
  GraphIdentifier get graphId => GraphIdentifier(id);

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final tagAsync = ref.watch(tagProvider(tagId));
    return tagAsync.whenData((value) {
      if (value == null) {
        throw SelectableNotFoundException(this);
      }
      return TagSelectable(ref: ref, id: this, tag: value);
    });
  }

  @override
  int get hashCode => tagId.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagIdentifier && other.tagId == tagId;
  }

  @override
  String toString() => "TagIdentifier(tagId: $tagId)";
}

class TagSelectable extends InspectableSelectable<TagIdentifier> {
  TagSelectable({required this.ref, required this.id, required this.tag})
    : _data = RecordValue({"name": StringValue(tag.name)});

  @override
  final TagIdentifier id;

  final Tag tag;

  @override
  String get name => tag.name;

  final Ref ref;

  final RecordValue _data;

  @override
  ResolvedTypeRef get rootType => _tagInspectorType.id;

  @override
  TypeCatalog get typeCatalog => _tagInspectorCatalog;

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(
      onDelete: () => ref.read(tagsProvider.notifier).deleteTag(tag.tagId),
    ),
  ];

  @override
  Widget? buildInspectorHeader() => TagHeader(tag: tag);

  @override
  EditorValue value(DataPath path) => _data.readEditorValue(path);

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    final result = validateUpdate(path, value);
    if (result is! AppliedEditorMutation || value is! StringValue) {
      return result;
    }
    ref.read(tagsProvider.notifier).updateTag(tag.copyWith(name: value.value));
    return result;
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
