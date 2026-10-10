import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_selectable_resource.freezed.dart";

@freezed
abstract class AuthoringResourceIdentifier extends SelectableIdentifier
    with _$AuthoringResourceIdentifier
    implements GraphDragData, ReferenceResourceDragData {
  const factory AuthoringResourceIdentifier({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required skir.ResourceId resourceId,
  }) = _AuthoringResourceIdentifier;

  const AuthoringResourceIdentifier._() : super();

  factory AuthoringResourceIdentifier.inScope(
    AuthoringScope scope,
    skir.ResourceId resource,
  ) => AuthoringResourceIdentifier(
    organizationId: scope.organizationId,
    realmId: scope.realmId,
    resourceId: resource,
  );

  @override
  skir.RecordId get organizationId;
  @override
  skir.RecordId get realmId;
  @override
  skir.ResourceId get resourceId;

  AuthoringScope get scope =>
      AuthoringScope(organizationId: organizationId, realmId: realmId);

  @override
  String get id => resourceId.value;

  @override
  GraphIdentifier get graphId => GraphIdentifier(resourceId.value);

  @override
  skir.ResourceId get referenceId => resourceId;

  @override
  List<skir.TypeDefinitionId> get referenceTypes => const [];

  @override
  AsyncValue<Selectable> create(Ref ref) {
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
        onOpen: resource.definition == coreTagResourceDefinition
            ? null
            : _openCapability(ref, document, resource),
      ),
    );
  }

  VoidCallback? _openCapability(
    Ref ref,
    AuthoringDocument document,
    skir.AuthoringResource resource,
  ) {
    final handler = document.catalog.snapshot.resourceDefinitions
        .where((definition) => definition.id == resource.definition)
        .map((definition) => definition.navigationHandler)
        .firstOrNull;
    if (handler == null) return null;
    final registry = ref.read(authoringResourceNavigationRegistryProvider);
    if (!registry.supports(handler)) return null;
    return () => unawaited(
      registry.open(
        ref,
        handler,
        OpenAuthoringResourceEffect(
          organizationId: organizationId,
          realmId: realmId,
          resourceId: resourceId,
          definition: resource.definition,
          configuration: resource.content.configuration,
          navigationHandler: handler,
        ),
      ),
    );
  }
}

final class AuthoringSelectableResource
    extends InspectableSelectable<AuthoringResourceIdentifier> {
  const AuthoringSelectableResource({
    required this.id,
    required this.resource,
    required this.workspace,
    required this.commands,
    this.onOpen,
  });

  @override
  final AuthoringResourceIdentifier id;
  final skir.AuthoringResource resource;
  final AuthoringWorkspace workspace;
  final AuthoredResourceCommands commands;
  final VoidCallback? onOpen;

  @override
  String get name => switch (resource.definition) {
    final definition when definition == coreBookResourceDefinition =>
      Book.fromAuthoring(resource).title,
    final definition when definition == coreTagResourceDefinition =>
      Tag.fromAuthoring(resource).name,
    _ =>
      resource.content.authoredField("name")?.authoredString ??
          resource.content.authoredField("title")?.authoredString ??
          id.resourceId.value,
  };

  Color get color => switch (resource.definition) {
    final definition when definition == coreBookResourceDefinition =>
      Book.fromAuthoring(resource).color,
    final definition when definition == coreTagResourceDefinition =>
      Tag.fromAuthoring(resource).color,
    _ => switch (resource.content.authoredField("color")?.authoredInteger) {
      final value? => Color(value.toUnsigned(32).toInt()),
      null => Colors.blueGrey,
    },
  };

  String get deletionLabel => switch (resource.definition) {
    final definition when definition == coreBookResourceDefinition =>
      "Delete book",
    final definition when definition == coreTagResourceDefinition =>
      "Delete tag",
    _ => "Delete resource",
  };

  @override
  List<SelectionCapability> get capabilities => [
    if (onOpen case final open?)
      OpenSelectionCapability(onOpen: open, allowMultiSelect: false),
    DeleteSelectionCapability(
      onDelete: () async => workspace
          .edit(
            label: deletionLabel,
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
