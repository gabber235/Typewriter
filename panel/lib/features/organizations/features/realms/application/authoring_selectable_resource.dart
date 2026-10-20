import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_selectable_resource.freezed.dart";

@freezed
abstract class AuthoringResourceIdentifier extends SelectableIdentifier
    with _$AuthoringResourceIdentifier
    implements GraphDragData {
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
  AsyncValue<Selectable> create(Ref ref) {
    final source = ref.watch(workingAuthoringDocumentProvider(scope));
    if (source.mapUnready<Selectable>() case final pending?) return pending;
    final document = source.requireValue;
    final workspace = ref.watch(realmEditingProvider(scope));
    final commands = ref.watch(authoredResourceCommandsProvider(scope));
    final resource = document.entry(resourceId);
    if (resource == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    return AsyncData(
      AuthoringSelectableResource(
        id: this,
        resource: resource,
        appearance: document.catalog.appearanceOf(resource.content),
        workspace: workspace,
        commands: commands,
      ),
    );
  }
}

final class AuthoringSelectableResource
    extends InspectableSelectable<AuthoringResourceIdentifier> {
  const AuthoringSelectableResource({
    required this.id,
    required this.resource,
    required this.appearance,
    required this.workspace,
    required this.commands,
  });

  @override
  final AuthoringResourceIdentifier id;
  final skir.AuthoringResource resource;

  /// How the resource names and marks itself, from its declared display.
  final ResourceAppearance appearance;
  final RealmEditing workspace;
  final AuthoredResourceCommands commands;

  @override
  String get name => appearance.label;

  Color get color => appearance.accent;

  @override
  List<SelectionCapability> get capabilities => const [];

  /// The side inspector knows the routed resource, so `active_resource` and
  /// the routed member state reach it as they reach the main surface.
  @override
  InspectionContent buildInspection(InspectionBindingScope owners) =>
      InspectionContent(
        body: Consumer(
          key: ValueKey((id.resourceId, skir.PresentationRole.inspector)),
          builder: (context, ref, _) => AuthoredResourceInspection(
            resource: id.resourceId,
            workspace: workspace,
            commands: commands,
            routedResource: ref.watch(routedResourceProvider(id.scope)),
            openResource: (target) =>
                ref.read(realmSurfaceNavigationProvider).open(id.scope, target),
          ),
        ),
      );
}
