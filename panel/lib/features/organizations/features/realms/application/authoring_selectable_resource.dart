import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
    final provider = authoringSessionProvider(organizationId, realmId);
    final state = ref.watch(provider);
    if (state.failure case final failure?) {
      return AsyncError(failure, StackTrace.current);
    }
    final resource = state.resources[resourceId];
    if (resource == null) {
      if (state.snapshot == null) return const AsyncLoading();
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final draft = state.draft;
    final catalog = state.catalog;
    if (draft == null || catalog == null) return const AsyncLoading();
    return AsyncData(
      AuthoringSelectableResource(
        id: this,
        resource: resource,
        draft: draft,
        catalog: catalog,
        session: ref.watch(provider.notifier),
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

final class AuthoringSelectableResource
    extends InspectableSelectable<AuthoringResourceIdentifier> {
  const AuthoringSelectableResource({
    required this.id,
    required this.resource,
    required this.draft,
    required this.catalog,
    required this.session,
  });

  @override
  final AuthoringResourceIdentifier id;
  final skir.AuthoringResource resource;
  final AuthoredDraft draft;
  final CheckedEditorCatalog catalog;
  final AuthoringSession session;

  @override
  String get name =>
      resource.content.authoredField("name")?.authoredString ??
      resource.content.authoredField("title")?.authoredString ??
      id.resourceId.value;

  Color get color {
    final value = resource.content.authoredField("color")?.authoredInteger;
    return value == null
        ? Colors.blueGrey
        : Color(value.toUnsigned(32).toInt());
  }

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(
      onDelete: () => session.deleteResource(id.resourceId),
    ),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        body: AuthoredResourceInspection(
          key: ValueKey((id.resourceId, skir.PresentationRole.inspector)),
          resource: id.resourceId,
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
}
