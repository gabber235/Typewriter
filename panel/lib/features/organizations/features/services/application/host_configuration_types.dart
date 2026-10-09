part of "services.dart";

skir.TypeDefinitionId _draftType(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "panel.host", name: name),
  revision: 1,
);

final _realmDraft = _draftType("Realm");
final _realmDisabled = _draftType("RealmDisabled");
final _realmHosted = _draftType("RealmHosted");
final _engineDraft = _draftType("Engine");
final _engineDisabled = _draftType("EngineDisabled");
final _engineEnabled = _draftType("EngineEnabled");

skir.NamedTypeUse _draftUse(skir.TypeDefinitionId type) =>
    skir.NamedTypeUse(definition: type, arguments: const []);

skir.DataValue _draftVariant(
  skir.TypeDefinitionId type, [
  Map<String, skir.DataValue> fields = const {},
]) => skir.DataValue.createNamed(
  actualType: _draftUse(type),
  payload: skir.DataValue.createRecord(
    fields: fields.entries.map(
      (entry) => skir.FieldValue(name: entry.key, value: entry.value),
    ),
  ),
);

final _hostConfigurationDefinition = _draftType("HostConfiguration");
final _hostConfigurationType = skir.TypeUse.wrapNamed(
  _draftUse(_hostConfigurationDefinition),
);

skir.NamedTypeTemplate _draftTemplate(skir.TypeDefinitionId definition) =>
    skir.NamedTypeTemplate(definition: definition, arguments: const []);

skir.TypeTemplate _draftNamedTemplate(skir.TypeDefinitionId definition) =>
    skir.TypeTemplate.wrapNamed(_draftTemplate(definition));

final _hostConfigurationTextTemplate = skir.TypeTemplate.wrapScalar(
  skir.ScalarKind.text,
);

skir.EffectiveFieldTemplate _draftField(
  skir.TypeDefinitionId definition,
  String name,
  skir.TypeTemplate type,
) => skir.EffectiveFieldTemplate(
  key: name,
  owner: skir.FieldOwner(definition: definition, name: name),
  type: type,
  rules: const [],
);

skir.PublishedType _draftPublished(
  skir.TypeDefinitionId definition, {
  bool abstract = false,
  List<skir.NamedTypeTemplate> parents = const [],
  List<skir.EffectiveFieldTemplate> fields = const [],
}) => skir.PublishedType(
  definition: skir.TypeDefinition(
    id: definition,
    parameters: const [],
    representation: skir.RepresentationTemplate.createRecord(
      fields: fields.map(
        (field) => skir.FieldDeclaration(
          owner: field.owner,
          type: field.type,
          overrides: const [],
          hasConstructorDefault: false,
        ),
      ),
      abstract_: abstract,
    ),
    parents: parents,
  ),
  status: skir.DeclarationStatus.ready,
  effectiveFields: fields,
  ancestorTemplates: parents,
  display: null,
);

final _hostConfigurationCatalog = skir.EditorCatalogWireSnapshot(
  generation: skir.CatalogGeneration(value: "panel.host.configuration"),
  types: [
    _draftPublished(
      _hostConfigurationDefinition,
      fields: [
        _draftField(
          _hostConfigurationDefinition,
          "realm",
          _draftNamedTemplate(_realmDraft),
        ),
        _draftField(
          _hostConfigurationDefinition,
          "engine",
          _draftNamedTemplate(_engineDraft),
        ),
      ],
    ),
    _draftPublished(_realmDraft, abstract: true),
    _draftPublished(_realmDisabled, parents: [_draftTemplate(_realmDraft)]),
    _draftPublished(
      _realmHosted,
      parents: [_draftTemplate(_realmDraft)],
      fields: [
        _draftField(_realmHosted, "target", _hostConfigurationTextTemplate),
      ],
    ),
    _draftPublished(_engineDraft, abstract: true),
    _draftPublished(_engineDisabled, parents: [_draftTemplate(_engineDraft)]),
    _draftPublished(
      _engineEnabled,
      parents: [_draftTemplate(_engineDraft)],
      fields: [
        _draftField(_engineEnabled, "target", _hostConfigurationTextTemplate),
        _draftField(_engineEnabled, "realm", _hostConfigurationTextTemplate),
      ],
    ),
  ],
  presentations: const [],
  presentationMaterials: const [],
  configuration: const [],
  capabilities: const [],
  relations: const [],
  endpointBindings: const [],
  resourceDefinitions: const [],
  recommendations: const [],
  roleFallbacks: const [],
  initialization: const [],
  diagnostics: const [],
).asTrustedLocalCatalog();
