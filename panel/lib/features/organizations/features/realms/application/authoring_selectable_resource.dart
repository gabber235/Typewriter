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
    final rootType = SkirTypeCodec(TypeRegistry(const TypeCatalog([])))
        .decodeReference(resource.content.rootType)
        .valueOrNull;
    if (rootType == null) {
      return AsyncError(
        StateError("The resource root type is invalid"),
        StackTrace.current,
      );
    }
    final catalog = ref
        .watch(realmEditorCatalogForTypeProvider(rootType))
        .value
        ?.snapshot;
    if (catalog == null || session.sequence == null) {
      return const AsyncLoading();
    }
    if (session.generation?.value != catalog.generation.value) {
      return const AsyncLoading();
    }
    final presentations = catalog.presentations.values.toList(growable: false);
    if (!ref.retainAuthoringCollections(
      organizationId: organizationId,
      realmId: realmId,
      catalog: catalog,
      presentations: presentations,
      session: session,
    )) {
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
      presentations: presentations,
    );
    return AsyncData(
      AuthoringSelectableResource(
        id: this,
        resourceDefinition: resource.definition.toDomain(),
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
        presentations: presentations,
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
    extends EditableSelectable<AuthoringResourceIdentifier>
    implements RealmAuthoringSelection {
  const AuthoringSelectableResource({
    required this.id,
    required this.resourceDefinition,
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
  final ResourceDefinitionId resourceDefinition;
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
  MultiInspectionDefinition get multiInspection =>
      RealmAuthoringMultiInspectionDefinition(resourceDefinition);

  @override
  List<TypeDiagnostic> get presentationDiagnostics => diagnostics;

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
