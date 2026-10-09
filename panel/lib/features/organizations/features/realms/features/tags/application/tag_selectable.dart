import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Stable selection and graph drag identity for one tag record.
///
/// The record ID is also the editor resource identity, so selection, graph
/// nodes, shared work, and authoring reservations address the same resource.
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
  List<skir.TypeDefinitionId> get referenceTypes => const [];

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    if (scope == null) {
      return AsyncError(
        ApiException.badRequest("No realm selected"),
        StackTrace.current,
      );
    }
    final source = ref.watch(workingAuthoringDocumentProvider(scope));
    if (source.mapUnready<Selectable>() case final pending?) return pending;
    final document = source.requireValue;
    final workspace = ref.watch(authoringWorkspaceProvider(scope));
    final commands = ref.watch(authoredResourceCommandsProvider(scope));
    final resource = document.entry(tagId);
    if (resource == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final tag = Tag.fromAuthoring(resource);
    return AsyncValue.data(
      TagSelectable(
        onDelete: () async => workspace
            .edit(label: "Delete tag", apply: (edit) => edit.delete(tagId))
            .requireAccepted(),
        id: this,
        tag: tag,
        workspace: workspace,
        commands: commands,
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
/// This object is a read model assembled from the working revision.
/// The workspace owns persistence, while the selectable exposes the
/// presentation, collection, deletion capability, and snapshot needed by
/// selection consumers.
class TagSelectable extends InspectableSelectable<TagIdentifier> {
  const TagSelectable({
    required this.onDelete,
    required this.id,
    required this.tag,
    required this.workspace,
    required this.commands,
  });

  @override
  final TagIdentifier id;

  final Tag tag;
  final AuthoringWorkspace workspace;
  final AuthoredResourceCommands commands;

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
        body: AuthoredResourceInspection(
          key: ValueKey((tag.tagId, skir.PresentationRole.inspector)),
          resource: tag.tagId,
          workspace: workspace,
          commands: commands,
        ),
      );

  @override
  String toString() => "TagSelectable(id: $id, tag: $tag)";
}
