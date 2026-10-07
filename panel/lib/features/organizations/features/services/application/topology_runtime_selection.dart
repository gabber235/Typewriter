part of "services.dart";

/// Exposes Realm deployment state through the shared inspector presentation.
///
/// Realm runtime data is observational. Opening the Realm is available only
/// while the owner host service is connected, because all Realm operations use
/// that service connection.
class _RealmInstanceSelectable
    extends InspectableSelectable<RealmInstanceIdentifier> {
  const _RealmInstanceSelectable({
    required this.onOpen,
    required this.id,
    required this.realm,
    required this.connected,
    required this.host,
    required this.service,
  });

  final VoidCallback? onOpen;
  @override
  final RealmInstanceIdentifier id;
  final TopologyRealm realm;
  final bool connected;
  final TopologyHost? host;
  final Service? service;

  @override
  String get name => realm.ownerHost.name.formatted;

  @override
  List<SelectionCapability> get capabilities => [
    if (onOpen case final open?)
      OpenSelectionCapability(onOpen: open, allowMultiSelect: false),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        host: realm.portablePresentationHost(),
        header: InspectorHeader(
          id: realm.realmId.id,
          name: name,
          color: realmServiceRoleColor,
        ),
      );
}

/// Builds the route to a Realm owned by an organization.
///
/// Callers should only expose this route when the owner service is connected;
/// selection resolution enforces that prerequisite before creating the action.
OrganizationRoute realmNavigationRoute(
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => OrganizationRoute(
  organizationId: organizationId.id,
  children: [RealmRoute(realmId: realmId.id)],
);

/// Exposes execution engine deployment state through the shared inspector.
///
/// Engine instances are controlled through their owner host configuration, so
/// their own inspector remains read only and reports assignment and lifecycle
/// state without creating a second mutation path.
class _EngineInstanceSelectable
    extends InspectableSelectable<EngineInstanceIdentifier> {
  _EngineInstanceSelectable({
    required this.id,
    required this.engine,
    required this.host,
    required this.service,
  });

  @override
  final EngineInstanceIdentifier id;
  final TopologyEngine engine;
  final TopologyHost? host;
  final Service? service;

  @override
  String get name => "${engine.target.engineId} engine";

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(
        host: engine.portablePresentationHost(),
        header: InspectorHeader(
          id: engine.engineId.id,
          name: name,
          color: engineServiceRoleColor,
        ),
      );
}
