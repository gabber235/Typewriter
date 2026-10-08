import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("named scalar payload keeps its checked identity", () {
    final chapter = _definition("ChapterPath");
    final page = _definition("Page");
    final expected = skir.TypeUse.createNamed(
      definition: chapter,
      arguments: const [],
    );
    final checked = _catalog([
      _published(
        chapter,
        representation: skir.RepresentationTemplate.createScalar(
          kind: skir.ScalarKind.text,
        ),
      ),
      _published(
        page,
        effectiveFields: [
          skir.EffectiveFieldTemplate(
            key: "chapter",
            owner: skir.FieldOwner(definition: page, name: "chapter"),
            type: skir.TypeTemplate.createNamed(
              definition: chapter,
              arguments: const [],
            ),
            rules: const [],
          ),
        ],
      ),
    ]);
    final payload = skir.DataValue.wrapStringValue("opening");

    expect(checked.admitsPortableValue(expected, payload), isFalse);
    final admitted = checked.admitPortablePayloadAt(
      skir.TypeSelection.createComplete(definition: page, arguments: const []),
      skir.ValuePath(segments: [skir.PathSegment.createField(name: "chapter")]),
      payload,
    );

    expect(
      admitted,
      skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(definition: chapter, arguments: const []),
        payload: payload,
      ),
    );
    expect(checked.admitsPortableValue(expected, admitted!), isTrue);
  });

  test("rejects an application whose argument violates its bound", () {
    final marker = _definition("Marker");
    final box = _definition("Box");
    final parameter = skir.ParameterKey(owner: box, index: 0);
    final checked = _catalog([
      _published(marker),
      _published(
        box,
        parameters: [
          skir.TypeParameter(
            key: parameter,
            name: "T",
            bounds: [
              skir.TypeTemplate.createNamed(
                definition: marker,
                arguments: const [],
              ),
            ],
          ),
        ],
      ),
    ]);
    final invalid = skir.NamedTypeUse(
      definition: box,
      arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
    );
    final value = _emptyRecord(invalid);

    expect(
      checked.isReadableAs(
        skir.TypeUse.wrapNamed(invalid),
        skir.TypeUse.wrapNamed(invalid),
      ),
      isTrue,
    );
    expect(checked.isReadyApplication(invalid), isFalse);
    expect(
      checked.admitsPortableValue(skir.TypeUse.wrapNamed(invalid), value),
      isFalse,
    );

    final valid = skir.NamedTypeUse(
      definition: box,
      arguments: [
        skir.TypeUse.createNamed(definition: marker, arguments: const []),
      ],
    );
    expect(checked.isReadyApplication(valid), isTrue);
    expect(
      checked.admitsPortableValue(
        skir.TypeUse.wrapNamed(valid),
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
        status: skir.DeclarationStatus.wrapUnavailable(const []),
      ),
    ]);
    final use = skir.NamedTypeUse(definition: unavailable, arguments: const []);

    expect(
      checked.isReadableAs(
        skir.TypeUse.wrapNamed(use),
        skir.TypeUse.wrapNamed(use),
      ),
      isTrue,
    );
    expect(checked.isReadyApplication(use), isFalse);
    expect(
      checked.admitsPortableValue(
        skir.TypeUse.wrapNamed(use),
        _emptyRecord(use),
      ),
      isFalse,
    );
  });

  test("rejects unknown scalar kinds inside named applications", () {
    final box = _definition("Box");
    final parameter = skir.ParameterKey(owner: box, index: 0);
    final checked = _catalog([
      _published(
        box,
        parameters: [
          skir.TypeParameter(key: parameter, name: "T", bounds: const []),
        ],
      ),
    ]);
    final applications = [
      skir.NamedTypeUse(
        definition: box,
        arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.unknown)],
      ),
      skir.NamedTypeUse(
        definition: box,
        arguments: [
          skir.TypeUse.wrapScalar(
            skir.ScalarKind.createInteger(width: skir.IntegerWidth.unknown),
          ),
        ],
      ),
      skir.NamedTypeUse(
        definition: box,
        arguments: [
          skir.TypeUse.wrapScalar(
            skir.ScalarKind.createFloat(width: skir.FloatWidth.unknown),
          ),
        ],
      ),
    ];

    for (final application in applications) {
      expect(checked.isReadyApplication(application), isFalse);
      expect(
        checked.admitsPortableValue(
          skir.TypeUse.wrapNamed(application),
          _emptyRecord(application),
        ),
        isFalse,
      );
    }
  });
}

CheckedEditorCatalog _catalog(List<skir.PublishedType> published) =>
    CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:admission"),
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

skir.PublishedType _published(
  skir.TypeDefinitionId definition, {
  List<skir.TypeParameter> parameters = const [],
  skir.DeclarationStatus status = skir.DeclarationStatus.ready,
  skir.RepresentationTemplate? representation,
  List<skir.EffectiveFieldTemplate> effectiveFields = const [],
}) => skir.PublishedType(
  display: null,
  definition: skir.TypeDefinition(
    id: definition,
    parameters: parameters,
    representation:
        representation ??
        skir.RepresentationTemplate.createRecord(
          fields: const [],
          abstract_: false,
        ),
    parents: const [],
  ),
  status: status,
  effectiveFields: effectiveFields,
  ancestorTemplates: const [],
);

skir.DataValue _emptyRecord(skir.NamedTypeUse type) =>
    skir.DataValue.createNamed(
      actualType: type,
      payload: skir.DataValue.createRecord(fields: const []),
    );

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);
