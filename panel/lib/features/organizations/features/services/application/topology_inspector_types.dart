part of "services.dart";

abstract final class _HostInspectorFields {
  static const service = "service";
  static const host = "host";
  static const configuration = "configuration";
  static const name = "name";
  static const version = "version";
  static const state = "state";
  static const lastSeen = "lastSeen";
  static const entrypoint = "entrypoint";
  static const canHostRealm = "canHostRealm";
  static const supportedEngines = "supportedEngines";
  static const message = "message";
  static const updatedAt = "updatedAt";
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
  revision: 2,
);
const _realmInstanceInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "RealmInstance"),
  revision: 2,
);
const _engineInstanceInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "EngineInstance"),
  revision: 2,
);
const _stringListType = ListType(element: StringType());

final _hostInspectorType = TypeDefinition(
  id: _hostInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _hostInspectorPresentationId,
  representation: RecordType(
    fields: {
      _HostInspectorFields.service: TypeField(
        name: _HostInspectorFields.service,
        type: RecordType(
          fields: {
            _HostInspectorFields.name: _stringField(_HostInspectorFields.name),
            _HostInspectorFields.version: _stringField(
              _HostInspectorFields.version,
            ),
            _HostInspectorFields.state: _stringField(
              _HostInspectorFields.state,
            ),
            _HostInspectorFields.lastSeen: TypeField(
              name: _HostInspectorFields.lastSeen,
              type: NamedType(standardTypeRefs.optionOf(const TimestampType())),
            ),
          },
        ),
      ),
      _HostInspectorFields.host: TypeField(
        name: _HostInspectorFields.host,
        type: RecordType(
          fields: {
            _HostInspectorFields.entrypoint: _stringField(
              _HostInspectorFields.entrypoint,
            ),
            _HostInspectorFields.canHostRealm: const TypeField(
              name: _HostInspectorFields.canHostRealm,
              type: BooleanType(),
            ),
            _HostInspectorFields.supportedEngines: const TypeField(
              name: _HostInspectorFields.supportedEngines,
              type: _stringListType,
            ),
            _HostInspectorFields.state: _stringField(
              _HostInspectorFields.state,
            ),
            _HostInspectorFields.message: _stringField(
              _HostInspectorFields.message,
            ),
            _HostInspectorFields.updatedAt: const TypeField(
              name: _HostInspectorFields.updatedAt,
              type: TimestampType(),
            ),
          },
        ),
      ),
      _HostInspectorFields.configuration: TypeField(
        name: _HostInspectorFields.configuration,
        type: RecordType(
          fields: {
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
    _RuntimeInspectorFields.runtimeStatus: _stringField(
      _RuntimeInspectorFields.runtimeStatus,
    ),
    _RuntimeInspectorFields.artifactVersion: _stringField(
      _RuntimeInspectorFields.artifactVersion,
    ),
    _RuntimeInspectorFields.runtimeMessage: _stringField(
      _RuntimeInspectorFields.runtimeMessage,
    ),
    _RuntimeInspectorFields.updatedAt: const TypeField(
      name: _RuntimeInspectorFields.updatedAt,
      type: TimestampType(),
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
