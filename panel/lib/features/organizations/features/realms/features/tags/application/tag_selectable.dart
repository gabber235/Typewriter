import "package:flutter/foundation.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
    final provider = authoringSessionProvider(organization, realm);
    final state = ref.watch(provider);
    if (state.failure case final failure?) {
      return AsyncError(failure, StackTrace.current);
    }
    final resource = state.resources[tagId];
    if (resource == null) {
      if (state.snapshot == null) return const AsyncLoading();
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final draft = state.draft;
    final catalog = state.catalog;
    if (draft == null || catalog == null) return const AsyncLoading();
    final tag = Tag.fromAuthoring(resource);
    return AsyncValue.data(
      TagSelectable(
        onDelete: () => ref
            .read(provider.notifier)
            .deleteResource(
              tagId,
              conflictMessage: "The tag changed before deletion",
            ),
        id: this,
        tag: tag,
        draft: draft,
        catalog: catalog,
        session: ref.watch(provider.notifier),
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
class TagSelectable extends InspectableSelectable<TagIdentifier> {
  const TagSelectable({
    required this.onDelete,
    required this.id,
    required this.tag,
    required this.draft,
    required this.catalog,
    required this.session,
  });

  @override
  final TagIdentifier id;

  final Tag tag;
  final AuthoredDraft draft;
  final CheckedEditorCatalog catalog;
  final AuthoringSession session;

  @override
  String get name => tag.name;

  final Future<void> Function() onDelete;

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(onDelete: onDelete),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        header: InspectorHeader(
          id: tag.tagId.value,
          name: tag.name,
          color: tag.color,
        ),
        body: AuthoredResourceInspection(
          key: ValueKey((tag.tagId, skir.PresentationRole.inspector)),
          resource: tag.tagId,
          draft: draft,
          catalog: catalog,
          commands: AuthoredResourceCommands(
            commit: session.commit,
            previewTypeArguments: session.previewTypeArguments,
            commitTypeArguments: session.commitTypeArguments,
            prepareCreation: session.prepareCreation,
            invokeCommand: session.invokeCommand,
            watchSearch: session.watchPresentationSearch,
            reload: session.refresh,
            openAutosave: session.openAutosave,
          ),
        ),
      );

  @override
  String toString() => "TagSelectable(id: $id, tag: $tag)";
}
