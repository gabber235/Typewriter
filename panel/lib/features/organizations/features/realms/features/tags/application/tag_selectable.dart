import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "tag_inspector_definition.dart";

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
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    return tagAsync.whenData((value) {
      if (value == null) {
        throw SelectableNotFoundException(this);
      }
      return TagSelectable(
        ref: ref,
        id: this,
        tag: value,
        tagCollection: tagPresentationCollection(
          tags,
          editingTagId: value.tagId,
          existingParentIds: value.parentIds,
        ),
      );
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
  TagSelectable({
    required this.ref,
    required this.id,
    required this.tag,
    required this.tagCollection,
  }) : _data = tag.inspectorValue;

  @override
  final TagIdentifier id;

  final Tag tag;
  final PresentationCollectionSource tagCollection;

  @override
  String get name => tag.name;

  final Ref ref;

  final RecordValue _data;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(tagInspectorTypeRef),
    typeCatalog: _tagInspectorCatalog,
    confirmedValue: _data,
    revision: tag.revision,
    mergePolicies: {DataPath.root.field("parents"): EditorMergePolicy.set},
    collections: [tagCollection],
    presentations: [_tagInspectorPresentation],
  );

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(
      onDelete: () => ref.read(tagsProvider.notifier).deleteTag(tag.tagId),
    ),
  ];

  @override
  Widget? buildInspectorHeader() => TagHeader(tag: tag);

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    final result = super.validate(path, value);
    if (result is! AppliedEditorMutation || value is! IntegerValue) {
      return result;
    }
    final widthPath = DataPath.root.field("layout").field("width");
    final heightPath = DataPath.root.field("layout").field("height");
    if ((path == widthPath || path == heightPath) && value.value < BigInt.one) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Tag dimensions must be greater than zero",
          path: path,
        ),
      ]);
    }
    return result;
  }

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) {
    final next = _tagFromInspectorValue(
      commit.rootValue,
      expectedRevision: commit.expectedRevision,
    );
    if (next == null) {
      return Future.value(
        TypedMutationResult.invalid([
          const TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "The Tag inspector value is invalid",
          ),
        ]),
      );
    }
    return ref.read(tagsProvider.notifier).updateTag(next);
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

  Tag? _tagFromInspectorValue(
    DataValue value, {
    required int expectedRevision,
  }) {
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
    final decodedColor = color.colorOrNull;
    final parentIds = parents.values
        .whereType<StringValue>()
        .map((parent) => recordId("tag:${parent.value}"))
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
    return tag.copyWith(
      revision: expectedRevision,
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
}
