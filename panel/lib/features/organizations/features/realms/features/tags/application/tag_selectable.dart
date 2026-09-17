import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "tag_editor_resource.dart";
part "tag_inspector_definition.dart";

/// Stable selection and graph drag identity for one tag record.
///
/// The record ID is also the editor resource identity, so selection, graph
/// nodes, local drafts, and authoring reservations address the same resource.
class TagIdentifier extends SelectableIdentifier implements GraphDragData {
  const TagIdentifier(this.tagId);

  final skir.RecordId tagId;

  @override
  String get id => tagId.id;

  @override
  GraphIdentifier get graphId => GraphIdentifier(id);

  @override
  Object get resourceId => tagId;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final organization = ref.watch(organizationIdProvider);
    final realm = ref.watch(realmIdProvider);
    if (organization == null || realm == null) {
      return AsyncError(
        ApiException.badRequest("No realm selected"),
        StackTrace.current,
      );
    }
    final tagsCommands = ref.watch(canonicalTagsProvider.notifier);
    final session = ref.watch(authoringSessionProvider(organization, realm));
    final tagValue = session.tagEditorValue(tagId);
    if (tagValue == null) {
      if (session.sequence == null) return const AsyncLoading();
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final tag = tagValue.value;
    final tagsAsync = ref.watch(projectedTagsProvider);
    if (tagsAsync.mapUnready<Selectable>() case final value?) return value;
    final tags = tagsAsync.requireValue;
    return AsyncValue.data(
      TagSelectable(
        resource: TagEditorResource(
          ref
              .watch(resourceRepositoriesProvider)
              .authoring(organization, realm),
          tagId,
        ),
        onDelete: () => tagsCommands.deleteTag(tagId),
        id: this,
        tag: tag,
        revision: tagValue.revision,
        tagCollection: tags.presentationCollection(
          editingTagId: tag.tagId,
          existingParentIds: tag.parentIds,
        ),
      ),
    );
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

/// Binds one tag snapshot to shared inspector and selection infrastructure.
///
/// This object is a read model assembled from the canonical session revision.
/// Its editor resource owns persistence, while the selectable exposes the
/// presentation, collection, deletion capability, and snapshot needed by
/// selection consumers.
class TagSelectable extends EditableSelectable<TagIdentifier> {
  const TagSelectable({
    required this.resource,
    required this.onDelete,
    required this.id,
    required this.tag,
    required this.revision,
    required this.tagCollection,
  });

  @override
  final TagIdentifier id;

  final Tag tag;
  final int revision;
  final PresentationCollectionSource tagCollection;

  @override
  MultiInspectionDefinition get multiInspection =>
      const TagMultiInspectionDefinition();

  @override
  String get name => tag.name;

  @override
  final EditableResource resource;
  final Future<void> Function() onDelete;

  @override
  List<PresentationDefinition> get presentations => [_tagInspectorPresentation];
  @override
  List<PresentationCollectionSource> get collections => [tagCollection];

  @override
  EditorSnapshot get snapshot => TagEditorSnapshot(tag, revision);
  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(onDelete: onDelete),
  ];

  @override
  Widget? buildInspectorHeader(EditOwner owner) => ManagedInspectorHeader(
    id: tag.tagId.id,
    owner: owner,
    fallbackName: tag.name.formatted,
    fallbackColor: tag.color,
  );

  @override
  String toString() => "TagSelectable(id: $id, tag: $tag)";
}
