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
    final scope = AuthoringScope(
      organizationId: organizationId,
      realmId: realmId,
    );
    final source = ref.watch(workingAuthoringDocumentProvider(scope));
    if (source.mapUnready<Selectable>() case final pending?) return pending;
    final document = source.requireValue;
    final workspace = ref.watch(authoringWorkspaceProvider(scope));
    final commands = ref.watch(authoredResourceCommandsProvider(scope));
    final resource = document.entry(resourceId);
    if (resource == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    return AsyncData(
      AuthoringSelectableResource(
        id: this,
        resource: resource,
        workspace: workspace,
        commands: commands,
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
    required this.workspace,
    required this.commands,
  });

  @override
  final AuthoringResourceIdentifier id;
  final skir.AuthoringResource resource;
  final AuthoringWorkspace workspace;
  final AuthoredResourceCommands commands;

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
      onDelete: () async => workspace
          .edit(
            label: "Delete resource",
            apply: (edit) => edit.delete(id.resourceId),
          )
          .requireAccepted(),
    ),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        body: AuthoredResourceInspection(
          key: ValueKey((id.resourceId, skir.PresentationRole.inspector)),
          resource: id.resourceId,
          workspace: workspace,
          commands: commands,
        ),
      );
}
