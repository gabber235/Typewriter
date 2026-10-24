import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

CheckedEditorCatalog authoringSearchStoryCatalog() {
  final definitions = authoringSearchStoryDefinitions;
  final descriptors = <skir.PresentationDescriptor>[];
  final materials = <skir.PresentationMaterial>[];
  for (final entry in definitions.entries) {
    final presentation = skir.PresentationId(
      namespace: "widgetbook",
      name: "${entry.key}.result",
    );
    final target = skir.PresentationTarget.createNamed(
      definition: entry.value,
      arguments: const [],
    );
    descriptors.add(
      skir.PresentationDescriptor(
        id: presentation,
        owner: skir.DeclarationOwner.defaultInstance,
        target: target,
        roles: [skir.PresentationRole.resourceSearchResult],
        priority: 0,
      ),
    );
    materials.add(
      skir.PresentationMaterial(
        inheritableNodes: const [],
        provider: presentation,
        target: target,
        role: skir.PresentationRole.resourceSearchResult,
        layout: _resultLayout(entry.key),
        dependencies: skir.PresentationDependencies.defaultInstance,
        subject: skir.TypeTemplate.createNamed(
          definition: entry.value,
          arguments: const [],
        ),
      ),
    );
  }
  return CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      resourceDisplays: [
        for (final definition in definitions.values)
          nameResourceDisplay(
            skir.TypeTemplate.createNamed(
              definition: definition,
              arguments: const [],
            ),
          ),
      ],
      resourceOperations: const [],
      generation: skir.CatalogGeneration(value: "catalog:widgetbook.search"),
      types: [
        for (final definition in definitions.values)
          skir.PublishedType(
            searchKey: null,
            placementField: null,
            display: _storyDisplay(definition),
            definition: skir.TypeDefinition(
              id: definition,
              parameters: const [],
              representation: skir.RepresentationTemplate.createRecord(
                fields: [
                  _field(definition, "name"),
                  _field(definition, "summary"),
                ],
                abstract_: false,
              ),
              parents: const [],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: [
              _effectiveField(definition, "name"),
              _effectiveField(definition, "summary"),
            ],
            ancestorTemplates: const [],
          ),
      ],
      relations: const [],
      realmRoot: skir.TypeDefinitionId.defaultInstance,
      presentations: descriptors,
      presentationMaterials: materials,
      configuration: const [],
      diagnostics: const [],

      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
}

/// Each story kind's type display, whose name, icon and color the host
/// chrome shows for resources that declare nothing more specific.
skir.TypeDisplay _storyDisplay(skir.TypeDefinitionId definition) {
  final kind = authoringSearchStoryDefinitions.entries
      .firstWhere((entry) => entry.value == definition)
      .key;
  return skir.TypeDisplay(
    name: "${kind[0].toUpperCase()}${kind.substring(1)}",
    description: "",
    icon: skir.Icon.wrapIconify(switch (kind) {
      "book" => "material-symbols:book",
      "tag" => "fa6-solid:tag",
      "page" => "fa6-solid:file-lines",
      _ => "fa6-solid:cube",
    }),
    color: skir.Color(
      argb: switch (kind) {
        "book" => 0xFF3F51B5,
        "tag" => 0xFF009688,
        "page" => 0xFF607D8B,
        _ => 0xFF9C64BD,
      },
    ),
  );
}

final authoringSearchStoryDefinitions = <String, skir.TypeDefinitionId>{
  for (final name in ["book", "tag", "page", "element"])
    name: skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "widgetbook.search",
        name: name,
      ),
      revision: 1,
    ),
};

skir.FieldDeclaration _field(skir.TypeDefinitionId owner, String name) =>
    skir.FieldDeclaration(
      owner: skir.FieldOwner(definition: owner, name: name),
      type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      overrides: const [],
      hasConstructorDefault: false,
    );

skir.EffectiveFieldTemplate _effectiveField(
  skir.TypeDefinitionId owner,
  String name,
) => skir.EffectiveFieldTemplate(
  key: name,
  owner: skir.FieldOwner(definition: owner, name: name),
  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  rules: const [],
);

skir.PresentationNode _resultLayout(String kind) => skir.PresentationNode(
  nodeId: "search.$kind.result",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [
        skir.AxisChild.wrapFixed(
          presentationText(
            "$kind.summary",
            inputExpression(configuredValueBindingId, field: "summary"),
          ),
        ),
      ],
      layout: skir.AxisChildrenLayout(
        clipOverflow: false,

        spacing: 2,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.start,
      ),
    ),
  ),
  header: null,
);
