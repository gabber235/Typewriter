part of "services.dart";

ResolvedTypeRef _draftType(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel.host", name: name),
  revision: 1,
);

final _realmDraft = _draftType("Realm");
final _realmDisabled = _draftType("RealmDisabled");
final _realmHosted = _draftType("RealmHosted");
final _engineDraft = _draftType("Engine");
final _engineDisabled = _draftType("EngineDisabled");
final _engineEnabled = _draftType("EngineEnabled");

PolymorphicValue _draftVariant(
  ResolvedTypeRef type, [
  Map<String, DataValue> fields = const {},
]) => PolymorphicValue(concreteType: type, value: RecordValue(fields));

TypeField _draftField(
  String name,
  ResolvedTypeRef type,
  ResolvedTypeRef initial,
) => TypeField(
  name: name,
  type: NamedType(type),
  initialValue: _draftVariant(initial),
);

TypeField _hostConfigurationStringField(String name) =>
    TypeField(name: name, type: const StringType());

final _hostConfigurationType = RecordType(
  fields: {
    "realm": _draftField("realm", _realmDraft, _realmDisabled),
    "engine": _draftField("engine", _engineDraft, _engineDisabled),
  },
);

final _hostConfigurationDefinitions = [
  for (final type in [_realmDraft, _engineDraft])
    TypeDefinition(id: type, kind: NominalTypeKind.sealedAbstract),
  for (final (type, parent) in [
    (_realmDisabled, _realmDraft),
    (_engineDisabled, _engineDraft),
  ])
    TypeDefinition(
      id: type,
      kind: NominalTypeKind.concrete,
      parents: [parent],
      representation: const RecordType(fields: {}),
    ),
  TypeDefinition(
    id: _realmHosted,
    kind: NominalTypeKind.concrete,
    parents: [_realmDraft],
    representation: RecordType(
      fields: {"target": _hostConfigurationStringField("target")},
    ),
  ),
  TypeDefinition(
    id: _engineEnabled,
    kind: NominalTypeKind.concrete,
    parents: [_engineDraft],
    representation: RecordType(
      fields: {
        "target": _hostConfigurationStringField("target"),
        "realm": _hostConfigurationStringField("realm"),
      },
    ),
  ),
];

final _hostConfigurationCatalog = panelPresentationTypeCatalog([
  ..._hostConfigurationDefinitions,
]);
