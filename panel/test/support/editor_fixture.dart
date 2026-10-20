import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "catalog_fixture.dart";

EditorDocument recordEditorDocument(
  Map<String, skir.DataValue> values,
  Map<String, skir.TypeTemplate> fieldTypes,
  int revision,
) {
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Fixture"),
    revision: 1,
  );
  final fields = [
    for (final entry in fieldTypes.entries)
      skir.EffectiveFieldTemplate(
        key: entry.key,
        owner: skir.FieldOwner(definition: definition, name: entry.key),
        type: entry.value,
        rules: const [],
      ),
  ];
  final catalog = testCheckedCatalog(
    generation: skir.CatalogGeneration(value: "fixture"),
    types: [
      skir.PublishedType(
        placementField: null,
        display: null,
        definition: skir.TypeDefinition(
          id: definition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              for (final field in fields)
                skir.FieldDeclaration(
                  owner: field.owner,
                  type: field.type,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: fields,
        ancestorTemplates: const [],
      ),
    ],
  );
  return EditorDocument(
    rootType: skir.TypeUse.wrapNamed(
      skir.NamedTypeUse(definition: definition, arguments: const []),
    ),
    catalog: catalog,
    confirmedValue: recordEditorValue(values),
    revision: revision,
  );
}

skir.DataValue recordEditorValue(Map<String, skir.DataValue> values) =>
    skir.DataValue.createRecord(
      fields: [
        for (final entry in values.entries)
          skir.FieldValue(name: entry.key, value: entry.value),
      ],
    );
