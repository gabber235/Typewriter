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
class TagIdentifier extends SelectableIdentifier
    implements GraphDragData, ReferenceResourceDragData {
  const TagIdentifier(this.tagId);

  final skir.ResourceId tagId;

  @override
  String get id => tagId.id;

  @override
  GraphIdentifier get graphId => GraphIdentifier(id);

  @override
  Object get resourceId => tagId;

  @override
  skir.ResourceId get referenceId => tagId;

  @override
  List<ResolvedTypeRef> get referenceTypes => const [];

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
    ref.watch(
      realmEditorCatalogLeaseProvider(
        RealmEditorCatalogRequest(types: {referenceResourceTypes.tag}),
      ),
    );
    final catalogState = ref.watch(realmEditorCatalogProvider).value;
    final catalog = catalogState?.snapshot;
    if (catalog == null) return const AsyncLoading();
    final codec = TypedAuthoringCodec(catalog);
    final tagValue = session.tagEditorValue(tagId, codec);
    if (tagValue == null) {
      if (session.sequence == null) return const AsyncLoading();
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final tag = tagValue.value;
    final collections = decodeAuthoringCollections(
      session: session,
      catalog: catalog,
      presentations: catalog.presentations.values,
    );
    final tags = collections.sources[authoringTagCollectionSourceId];
    if (tags == null) {
      return AsyncError(
        StateError(
          collections.diagnostics.map((item) => item.message).join("; "),
        ),
        StackTrace.current,
      );
    }
    final content = codec.decodeResource(session.resources[tagId]!);
    if (content.valueOrNull == null) {
      return AsyncError(
        StateError(content.diagnostics.map((item) => item.message).join("; ")),
        StackTrace.current,
      );
    }
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
        snapshot: TypedAuthoringEditorSnapshot(
          resource: session.resources[tagId]!,
          content: content.valueOrNull!.content,
          revision: tagValue.revision,
          codec: codec,
        ),
        catalogPresentations: catalog.presentations.values.toList(
          growable: false,
        ),
        tagCollection: tags,
        presentationDiagnostics: collections.diagnostics,
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
    required this.snapshot,
    required this.catalogPresentations,
    required this.tagCollection,
    this.presentationDiagnostics = const [],
  });

  @override
  final TagIdentifier id;

  final Tag tag;
  @override
  final EditorSnapshot snapshot;
  final PresentationCollectionSource tagCollection;
  final List<PresentationDefinition> catalogPresentations;
  final List<TypeDiagnostic> presentationDiagnostics;

  @override
  MultiInspectionDefinition get multiInspection =>
      const TagMultiInspectionDefinition();

  @override
  String get name => tag.name;

  @override
  final EditableResource resource;
  final Future<void> Function() onDelete;

  @override
  List<PresentationDefinition> get presentations => catalogPresentations;
  @override
  List<PresentationCollectionSource> get collections => [tagCollection];

  @override
  PresentationModel buildPresentation(EditorOwnerScope owners) =>
      PresentationModel.editor(
        owner: owners.editor(this),
        presentations: presentations,
        collections: collections,
        diagnostics: [...document.diagnostics, ...presentationDiagnostics],
      );

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(onDelete: onDelete),
  ];

  @override
  Widget? buildInspectorHeader(EditOwner owner) => AuthoringSubjectRole(
    resourceId: tag.tagId,
    resourceType: rootType,
    role: PresentationRole.inspectorHeader,
    historyNamespace: "tag.inspector.header.${tag.tagId.id}",
  );

  @override
  String toString() => "TagSelectable(id: $id, tag: $tag)";
}
