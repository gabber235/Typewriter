part of "services.dart";

abstract final class _HostInspectorFields {
  static const serviceName = "serviceName";
  static const serviceId = "serviceId";
  static const serviceRoles = "serviceRoles";
  static const connected = "connected";
  static const entrypoint = "entrypoint";
  static const runtimeStatus = "runtimeStatus";
  static const runtimeMessage = "runtimeMessage";
  static const topologyRevision = "topologyRevision";
  static const supportedEngines = "supportedEngines";
  static const realmEnabled = "realmEnabled";
  static const realmTarget = "realmTarget";
  static const engineEnabled = "engineEnabled";
  static const engineTarget = "engineTarget";
  static const realmAssignment = "realmAssignment";
}

abstract final class _RuntimeInspectorFields {
  static const ownerHost = "ownerHost";
  static const target = "target";
  static const assignedRealm = "assignedRealm";
  static const manifestRevision = "manifestRevision";
  static const runtimeStatus = "runtimeStatus";
  static const artifactVersion = "artifactVersion";
  static const runtimeMessage = "runtimeMessage";
  static const updatedAt = "updatedAt";
}

const _hostInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "serviceHost.inspector",
);
const _realmInstanceInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "realmInstance.inspector",
);
const _engineInstanceInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "engineInstance.inspector",
);

const _hostInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "ServiceHost"),
  revision: 1,
);
const _realmInstanceInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "RealmInstance"),
  revision: 1,
);
const _engineInstanceInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "EngineInstance"),
  revision: 1,
);
const _stringListType = ListType(element: StringType());

final _hostInspectorType = TypeDefinition(
  id: _hostInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _hostInspectorPresentationId,
  representation: RecordType(
    fields: {
      _HostInspectorFields.serviceName: _stringField(
        _HostInspectorFields.serviceName,
      ),
      _HostInspectorFields.serviceId: _stringField(
        _HostInspectorFields.serviceId,
      ),
      _HostInspectorFields.serviceRoles: const TypeField(
        name: _HostInspectorFields.serviceRoles,
        type: _stringListType,
      ),
      _HostInspectorFields.connected: const TypeField(
        name: _HostInspectorFields.connected,
        type: BooleanType(),
      ),
      _HostInspectorFields.entrypoint: _stringField(
        _HostInspectorFields.entrypoint,
      ),
      _HostInspectorFields.runtimeStatus: _stringField(
        _HostInspectorFields.runtimeStatus,
      ),
      _HostInspectorFields.runtimeMessage: _stringField(
        _HostInspectorFields.runtimeMessage,
      ),
      _HostInspectorFields.topologyRevision: _stringField(
        _HostInspectorFields.topologyRevision,
      ),
      _HostInspectorFields.supportedEngines: const TypeField(
        name: _HostInspectorFields.supportedEngines,
        type: _stringListType,
      ),
      _HostInspectorFields.realmEnabled: const TypeField(
        name: _HostInspectorFields.realmEnabled,
        type: BooleanType(),
      ),
      _HostInspectorFields.realmTarget: _stringField(
        _HostInspectorFields.realmTarget,
      ),
      _HostInspectorFields.engineEnabled: const TypeField(
        name: _HostInspectorFields.engineEnabled,
        type: BooleanType(),
      ),
      _HostInspectorFields.engineTarget: _stringField(
        _HostInspectorFields.engineTarget,
      ),
      _HostInspectorFields.realmAssignment: _stringField(
        _HostInspectorFields.realmAssignment,
      ),
    },
  ),
);

final _realmInstanceInspectorType = TypeDefinition(
  id: _realmInstanceInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _realmInstanceInspectorPresentationId,
  representation: _runtimeInstanceRecord(
    extraFields: {
      _RuntimeInspectorFields.target: _stringField(
        _RuntimeInspectorFields.target,
      ),
    },
  ),
);

final _engineInstanceInspectorType = TypeDefinition(
  id: _engineInstanceInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _engineInstanceInspectorPresentationId,
  representation: _runtimeInstanceRecord(
    extraFields: {
      _RuntimeInspectorFields.target: _stringField(
        _RuntimeInspectorFields.target,
      ),
      _RuntimeInspectorFields.assignedRealm: _stringField(
        _RuntimeInspectorFields.assignedRealm,
      ),
    },
  ),
);

RecordType _runtimeInstanceRecord({
  required Map<String, TypeField> extraFields,
}) => RecordType(
  fields: {
    _RuntimeInspectorFields.ownerHost: _stringField(
      _RuntimeInspectorFields.ownerHost,
    ),
    ...extraFields,
    _RuntimeInspectorFields.manifestRevision: _stringField(
      _RuntimeInspectorFields.manifestRevision,
    ),
    _RuntimeInspectorFields.runtimeStatus: _stringField(
      _RuntimeInspectorFields.runtimeStatus,
    ),
    _RuntimeInspectorFields.artifactVersion: _stringField(
      _RuntimeInspectorFields.artifactVersion,
    ),
    _RuntimeInspectorFields.runtimeMessage: _stringField(
      _RuntimeInspectorFields.runtimeMessage,
    ),
    _RuntimeInspectorFields.updatedAt: _stringField(
      _RuntimeInspectorFields.updatedAt,
    ),
  },
);

TypeField _stringField(String name) =>
    TypeField(name: name, type: const StringType());

final _hostInspectorCatalog = TypeCatalog([_hostInspectorType]);
final _realmInstanceInspectorCatalog = TypeCatalog([
  _realmInstanceInspectorType,
]);
final _engineInstanceInspectorCatalog = TypeCatalog([
  _engineInstanceInspectorType,
]);
