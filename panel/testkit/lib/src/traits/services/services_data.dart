import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The service `service:[id]` of the kind [role], a host by default, named
/// [name] or else [id].
///
/// It reported [status] at [lastSeen], just now by default; a null [status]
/// has never reported.
skir.Service service(
  String id, {
  String? name,
  int revision = 1,
  skir.ServiceRole? role,
  skir.RecordId? organization,
  DateTime? createdAt,
  skir.ServiceStatus? status = skir.ServiceStatus.online,
  DateTime? lastSeen,
}) => skir.Service(
  serviceId: skir.recordId("service:$id"),
  revision: revision,
  name: name ?? id,
  role: role ?? skir.ServiceRole.createHost(version: "1.0.0"),
  createdAt: createdAt ?? DateTime.utc(2026),
  organization: organization,
  state: status == null
      ? null
      : skir.ServiceState(status: status, lastSeen: lastSeen ?? clock.now()),
  registration: null,
);

/// A Paper host `service_host:[id]` that runs the service [service],
/// `service:[id]` by default, and supports [engines].
///
/// Its configuration [revision] is [reconciled], applied in full by default,
/// and it reports [state], active since 2026 by default.
skir.ServiceHost paperHost(
  String id, {
  skir.RecordId? service,
  int revision = 1,
  List<String> engines = const [],
  skir.ReconciledRevision? reconciled,
  skir.HostRuntimeState? state,
}) => skir.ServiceHost(
  hostId: skir.recordId("service_host:$id"),
  serviceId: service ?? skir.recordId("service:$id"),
  revision: revision,
  entrypoint: "PAPER",
  canHostRealm: true,
  supportedEngines: [
    for (final engine in engines) skir.SupportedEngine(engineId: engine),
  ],
  topologyRevision:
      reconciled ??
      skir.ReconciledRevision(desired: revision, applied: revision),
  state: state ?? hostRuntimeState(),
);

/// A host reporting [status], active by default, with [message], as of
/// [updatedAt], 2026 by default.
skir.HostRuntimeState hostRuntimeState({
  skir.HostRuntimeStatus status = skir.HostRuntimeStatus.active,
  String? message,
  DateTime? updatedAt,
}) => skir.HostRuntimeState(
  status: status,
  message: message,
  updatedAt: updatedAt ?? DateTime.utc(2026),
);

/// A Realm `realm_instance:[id]` owned by the host `service_host:[host]`,
/// which the Realm reads as [hostName] or else [id], targeting the engine
/// [engine] at [version] and reporting [state], an unknown one by default.
skir.RealmInstance realmInstance(
  String id, {
  required String host,
  String? hostName,
  String engine = "paper",
  String version = "*",
  int revision = 1,
  skir.ChildRuntimeState? state,
}) => skir.RealmInstance(
  realmId: skir.recordId("realm_instance:$id"),
  ownerHost: skir.OwnerHost(
    id: skir.recordId("service_host:$host"),
    name: hostName ?? id,
  ),
  revision: revision,
  targetEngine: skir.EngineTarget(engineId: engine, versionConstraint: version),
  state: state ?? skir.ChildRuntimeState.defaultInstance,
);

/// An engine `engine_instance:[id]` running for [realm] on the host
/// `service_host:[host]`, read as [hostName], or else on the Realm's own
/// host, targeting the Realm's engine and reporting [state], an unknown one
/// by default.
skir.EngineInstance engineInstance(
  String id, {
  required skir.RealmInstance realm,
  String? host,
  String? hostName,
  int revision = 1,
  skir.ChildRuntimeState? state,
}) => skir.EngineInstance(
  engineId: skir.recordId("engine_instance:$id"),
  ownerHost: host == null
      ? realm.ownerHost
      : skir.OwnerHost(
          id: skir.recordId("service_host:$host"),
          name: hostName ?? host,
        ),
  realm: skir.RealmInfo(realmId: realm.realmId, ownerHost: realm.ownerHost),
  revision: revision,
  target: realm.targetEngine,
  state: state ?? skir.ChildRuntimeState.defaultInstance,
);

/// A Realm or engine reporting [status], active by default, running
/// [artifact] with [message], as of [updatedAt], 2026 by default.
skir.ChildRuntimeState childRuntimeState({
  skir.ChildRuntimeStatus status = skir.ChildRuntimeStatus.active,
  String? artifact = "1.0.0",
  String? message,
  DateTime? updatedAt,
}) => skir.ChildRuntimeState(
  status: status,
  activeArtifactVersion: artifact,
  message: message,
  updatedAt: updatedAt ?? DateTime.utc(2026),
);

/// A workload choice [name] of the host configuration editor with its text
/// [fields], such as `hostWorkload("RealmHosted", {"target": "paper@*"})`.
skir.DataValue hostWorkload(
  String name, [
  Map<String, String> fields = const {},
]) => skir.DataValue.createNamed(
  actualType: skir.NamedTypeUse(
    definition: skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(namespace: "panel.host", name: name),
      revision: 1,
    ),
    arguments: const [],
  ),
  payload: skir.DataValue.createRecord(
    fields: [
      for (final MapEntry(:key, :value) in fields.entries)
        skir.FieldValue(
          name: key,
          value: skir.DataValue.wrapStringValue(value),
        ),
    ],
  ),
);

/// A card [id] of [width] by [height] cells for the services packed layout,
/// drawing nothing.
ServicesPackedNode packedNode(String id, {int width = 4, int height = 4}) =>
    ServicesPackedNode(
      id: GraphIdentifier(id),
      width: width,
      height: height,
      builder: (_) => const SizedBox.shrink(),
    );

/// A connection [id] of the services packed layout from the card [source]
/// to the card [target].
ServicesPackedConnection packedConnection(
  String id,
  String source,
  String target,
) => ServicesPackedConnection(
  id: id,
  source: GraphIdentifier(source),
  target: GraphIdentifier(target),
  color: Colors.blue,
);
