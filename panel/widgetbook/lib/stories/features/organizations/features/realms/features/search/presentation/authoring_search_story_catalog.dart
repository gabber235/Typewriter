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
        resultAppearance: skir.ResultAppearance(
          accent: null,

          style: skir.ResultStyle.card,
          kindLabel: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(entry.key),
          ),
          leading: skir.PresentationNode(
            nodeId: "search.${entry.key}.leading",
            header: null,
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.wrapIcon(
              (skir.IconContent.mutable()
                    ..name = skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapStringValue(switch (entry.key) {
                        "book" => "material-symbols:book",
                        "tag" => "fa6-solid:tag",
                        "page" => "fa6-solid:file-lines",
                        _ => "fa6-solid:cube",
                      }),
                    ))
                  .toFrozen(),
            ),
          ),
        ),
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
      resourceOperations: const [],
      resourceOperationContributions: const [],
      generation: skir.CatalogGeneration(value: "catalog:widgetbook.search"),
      types: [
        for (final definition in definitions.values)
          skir.PublishedType(
            display: null,
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
      resourceDefinitions: [
        for (final entry in definitions.entries)
          skir.AuthoringResourceDefinition(
            id: skir.ResourceDefinitionId(value: "widgetbook.${entry.key}"),
            root: entry.value,
            navigationHandler: skir.AuthoringNavigationHandler.generic,
          ),
      ],
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
            "$kind.name",
            inputExpression(configuredValueBindingId, field: "name"),
          ),
        ),
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
