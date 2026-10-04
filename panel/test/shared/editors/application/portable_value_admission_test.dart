import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("named scalar payload keeps its checked identity", () {
    final chapter = _definition("ChapterPath");
    final page = _definition("Page");
    final expected = types.TypeUse.createNamed(
      definition: chapter,
      arguments: const [],
    );
    final checked = _catalog([
      _published(
        chapter,
        representation: types.RepresentationTemplate.createScalar(
          kind: types.ScalarKind.text,
        ),
      ),
      _published(
        page,
        effectiveFields: [
          catalog_wire.EffectiveFieldTemplate(
            key: "chapter",
            owner: types.FieldOwner(definition: page, name: "chapter"),
            type: types.TypeTemplate.createNamed(
              definition: chapter,
              arguments: const [],
            ),
            rules: const [],
          ),
        ],
      ),
    ]);
    final payload = types.DataValue.wrapStringValue("opening");

    expect(checked.admitsPortableValue(expected, payload), isFalse);
    final admitted = checked.admitPortablePayloadAt(
      types.TypeSelection.createComplete(definition: page, arguments: const []),
      types.ValuePath(
        segments: [types.PathSegment.createField(name: "chapter")],
      ),
      payload,
    );

    expect(
      admitted,
      types.DataValue.createNamed(
        actualType: types.NamedTypeUse(
          definition: chapter,
          arguments: const [],
        ),
        payload: payload,
      ),
    );
    expect(checked.admitsPortableValue(expected, admitted!), isTrue);
  });

  test("rejects an application whose argument violates its bound", () {
    final marker = _definition("Marker");
    final box = _definition("Box");
    final parameter = types.ParameterKey(owner: box, index: 0);
    final checked = _catalog([
      _published(marker),
      _published(
        box,
        parameters: [
          types.TypeParameter(
            key: parameter,
            name: "T",
            bounds: [
              types.TypeTemplate.createNamed(
                definition: marker,
                arguments: const [],
              ),
            ],
          ),
        ],
      ),
    ]);
    final invalid = types.NamedTypeUse(
      definition: box,
      arguments: [types.TypeUse.wrapScalar(types.ScalarKind.text)],
    );
    final value = _emptyRecord(invalid);

    expect(
      checked.isReadableAs(
        types.TypeUse.wrapNamed(invalid),
        types.TypeUse.wrapNamed(invalid),
      ),
      isTrue,
    );
    expect(checked.isReadyApplication(invalid), isFalse);
    expect(
      checked.admitsPortableValue(types.TypeUse.wrapNamed(invalid), value),
      isFalse,
    );

    final valid = types.NamedTypeUse(
      definition: box,
      arguments: [
        types.TypeUse.createNamed(definition: marker, arguments: const []),
      ],
    );
    expect(checked.isReadyApplication(valid), isTrue);
    expect(
      checked.admitsPortableValue(
        types.TypeUse.wrapNamed(valid),
        _emptyRecord(valid),
      ),
      isTrue,
    );
  });

  test("rejects values whose declaration is unavailable", () {
    final unavailable = _definition("Unavailable");
    final checked = _catalog([
      _published(
        unavailable,
        status: catalog_wire.DeclarationStatus.wrapUnavailable(const []),
      ),
    ]);
    final use = types.NamedTypeUse(
      definition: unavailable,
      arguments: const [],
    );

    expect(
      checked.isReadableAs(
        types.TypeUse.wrapNamed(use),
        types.TypeUse.wrapNamed(use),
      ),
      isTrue,
    );
    expect(checked.isReadyApplication(use), isFalse);
    expect(
      checked.admitsPortableValue(
        types.TypeUse.wrapNamed(use),
        _emptyRecord(use),
      ),
      isFalse,
    );
  });

  test("rejects unknown scalar kinds inside named applications", () {
    final box = _definition("Box");
    final parameter = types.ParameterKey(owner: box, index: 0);
    final checked = _catalog([
      _published(
        box,
        parameters: [
          types.TypeParameter(key: parameter, name: "T", bounds: const []),
        ],
      ),
    ]);
    final applications = [
      types.NamedTypeUse(
        definition: box,
        arguments: [types.TypeUse.wrapScalar(types.ScalarKind.unknown)],
      ),
      types.NamedTypeUse(
        definition: box,
        arguments: [
          types.TypeUse.wrapScalar(
            types.ScalarKind.createInteger(width: types.IntegerWidth.unknown),
          ),
        ],
      ),
      types.NamedTypeUse(
        definition: box,
        arguments: [
          types.TypeUse.wrapScalar(
            types.ScalarKind.createFloat(width: types.FloatWidth.unknown),
          ),
        ],
      ),
    ];

    for (final application in applications) {
      expect(checked.isReadyApplication(application), isFalse);
      expect(
        checked.admitsPortableValue(
          types.TypeUse.wrapNamed(application),
          _emptyRecord(application),
        ),
        isFalse,
      );
    }
  });
}

CheckedEditorCatalog _catalog(List<catalog_wire.PublishedType> published) =>
    CheckedEditorCatalog(
      catalog_wire.EditorCatalogWireSnapshot(
        generation: types.CatalogGeneration(value: "catalog:admission"),
        types: published,
        relations: const [],
        resourceDefinitions: const [],
        presentations: const [],
        presentationMaterials: const [],
        configuration: const [],
        diagnostics: const [],
        initialization: const [],
        endpointBindings: const [],
        capabilities: const [],
        recommendations: const [],
        roleFallbacks: const [],
      ),
    );

catalog_wire.PublishedType _published(
  types.TypeDefinitionId definition, {
  List<types.TypeParameter> parameters = const [],
  catalog_wire.DeclarationStatus status = catalog_wire.DeclarationStatus.ready,
  types.RepresentationTemplate? representation,
  List<catalog_wire.EffectiveFieldTemplate> effectiveFields = const [],
}) => catalog_wire.PublishedType(
  display: null,
  definition: types.TypeDefinition(
    id: definition,
    parameters: parameters,
    representation:
        representation ??
        types.RepresentationTemplate.createRecord(
          fields: const [],
          abstract_: false,
        ),
    parents: const [],
  ),
  status: status,
  effectiveFields: effectiveFields,
  ancestorTemplates: const [],
);

types.DataValue _emptyRecord(types.NamedTypeUse type) =>
    types.DataValue.createNamed(
      actualType: type,
      payload: types.DataValue.createRecord(fields: const []),
    );

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);
