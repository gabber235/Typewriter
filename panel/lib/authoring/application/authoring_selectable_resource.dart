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
  final skir.ResourceAppearance appearance;
  final RealmEditing workspace;
  final AuthoredResourceCommands commands;

  @override
  String get name => appearance.label;

  @override
  SelectableNoun get noun =>
      const SelectableNoun(one: "resource", many: "resources");

  Color get color => appearance.accentColor;

  @override
  List<SelectionCapability> get capabilities => const [];

  /// Resources of one complete type in one Realm edit together.
  @override
  List<SharedInspectionSurface> get sharedInspectionSurfaces =>
      switch (resource.content.configuration) {
        skir.TypeSelection_completeWrapper(:final value) => [
          _AuthoredResourceSurface(this, value),
        ],
        _ => const [],
      };

  @override
  InspectionContent buildInspection(InspectionBindingScope owners) =>
      _inspection(const []);

  /// The inspection of this resource edited together with [editedWith].
  ///
  /// The side inspector knows the routed resource, so `active_resource` and
  /// the routed member state reach it as they reach the main surface.
  InspectionContent _inspection(List<skir.ResourceId> editedWith) =>
      InspectionContent(
        body: Consumer(
          key: ValueKey((
            id.resourceId,
            editedWith.map((resource) => resource.value).join("\n"),
            skir.PresentationRole.inspector,
          )),
          builder: (context, ref, _) => AuthoredResourceInspection(
            resource: id.resourceId,
            editedWith: editedWith,
            workspace: workspace,
            commands: commands,
            routedResource: ref.watch(routedResourceProvider(id.scope)),
            openResource: (target) =>
                ref.read(realmSurfaceNavigationProvider).open(id.scope, target),
          ),
        ),
      );
}

/// The configured value of an authored resource, which resources of the same
/// complete type in the same Realm edit together in one form.
final class _AuthoredResourceSurface extends PortableInspectionSurface {
  const _AuthoredResourceSurface(this.selectable, this.type);

  final AuthoringSelectableResource selectable;
  final skir.NamedTypeUse type;

  @override
  Object get id => "authored.resource";

  @override
  skir.TypeUse get rootType => skir.TypeUse.wrapNamed(type);

  @override
  CheckedEditorCatalog get catalog => selectable.workspace.document.catalog;

  @override
  bool sharesEditorWith(PortableInspectionSurface other) =>
      other is _AuthoredResourceSurface &&
      other.selectable.workspace == selectable.workspace;

  @override
  InspectionContent buildShared(
    List<SharedInspectionSurface> members,
    InspectionBuildContext context,
  ) => selectable._inspection([
    for (final member in members.skip(1).cast<_AuthoredResourceSurface>())
      member.selectable.id.resourceId,
  ]);
}
