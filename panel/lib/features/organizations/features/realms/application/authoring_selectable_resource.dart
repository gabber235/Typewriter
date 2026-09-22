import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Stable selection identity for any Realm supplied authored resource.
final class AuthoringResourceIdentifier extends SelectableIdentifier {
  const AuthoringResourceIdentifier({
    required this.organizationId,
    required this.realmId,
    required this.resourceId,
  });

  final skir.RecordId organizationId;
  final skir.RecordId realmId;
  @override
  final skir.ResourceId resourceId;

  @override
  String get id => resourceId.value;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    ref.watch(
      authoringSelectionLeaseProvider(
        organizationId,
        realmId,
        resourceId.resourceAuthoringSelection,
      ),
    );
    final session = ref.watch(
      authoringSessionProvider(organizationId, realmId),
    );
    final resource = session.resources[resourceId];
    if (resource == null) {
      if (session.sequence == null) return const AsyncLoading();
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final catalog = ref.watch(realmEditorCatalogProvider).value?.snapshot;
    if (catalog == null || session.sequence == null) {
      return const AsyncLoading();
    }
    final codec = TypedAuthoringCodec(catalog);
    final decoded = codec.decodeResource(resource);
    final value = decoded.valueOrNull;
    if (value == null) {
      return AsyncError(
        StateError(decoded.diagnostics.map((item) => item.message).join("; ")),
        StackTrace.current,
      );
    }
    final collections = decodeAuthoringCollections(
      session: session,
      catalog: catalog,
      presentations: catalog.presentations.values,
    );
    return AsyncData(
      AuthoringSelectableResource(
        id: this,
        resource: TypedAuthoringEditorResource(
          ref
              .watch(resourceRepositoriesProvider)
              .authoring(organizationId, realmId),
          resourceId,
        ),
        snapshot: TypedAuthoringEditorSnapshot(
          resource: resource,
          content: value.content,
          revision: session.sequence!,
          codec: codec,
        ),
        presentations: catalog.presentations.values.toList(growable: false),
        collections: collections.sources.values.toList(growable: false),
        diagnostics: collections.diagnostics,
        onDelete: () => ref
            .read(authoringSessionProvider(organizationId, realmId).notifier)
            .deleteResource(
              resourceId,
              conflictMessage: "The resource changed",
            ),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthoringResourceIdentifier &&
      organizationId == other.organizationId &&
      realmId == other.realmId &&
      resourceId == other.resourceId;

  @override
  int get hashCode => Object.hash(organizationId, realmId, resourceId);
}

/// Generic inspector adapter backed entirely by Realm catalog metadata.
final class AuthoringSelectableResource
    extends EditableSelectable<AuthoringResourceIdentifier> {
  const AuthoringSelectableResource({
    required this.id,
    required this.resource,
    required this.snapshot,
    required this.presentations,
    required this.collections,
    required this.diagnostics,
    required this.onDelete,
  });

  @override
  final AuthoringResourceIdentifier id;
  @override
  final EditableResource resource;
  @override
  final TypedAuthoringEditorSnapshot snapshot;
  @override
  final List<PresentationDefinition> presentations;
  @override
  final List<PresentationCollectionSource> collections;
  final List<TypeDiagnostic> diagnostics;
  final Future<void> Function() onDelete;

  @override
  String get name => id.resourceId.value;

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(onDelete: onDelete),
  ];

  @override
  PresentationModel buildPresentation(EditorOwnerScope owners) =>
      PresentationModel.editor(
        owner: owners.editor(this),
        presentations: presentations,
        collections: collections,
        diagnostics: [...document.diagnostics, ...diagnostics],
      );

  @override
  Widget? buildInspectorHeader(EditOwner owner) => AuthoringSubjectRole(
    resourceId: id.resourceId,
    resourceType: rootType,
    role: PresentationRole.inspectorHeader,
    historyNamespace: "resource.inspector.header.${id.resourceId.value}",
  );
}
