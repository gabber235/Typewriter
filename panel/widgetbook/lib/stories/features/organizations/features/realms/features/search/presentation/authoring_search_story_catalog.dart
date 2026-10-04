import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
        roles: [skir.PresentationRole.authoringResult],
        priority: 0,
      ),
    );
    materials.add(
      skir.PresentationMaterial(
        provider: presentation,
        target: target,
        role: skir.PresentationRole.authoringResult,
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
            navigationHandler: entry.key,
          ),
      ],
      presentations: descriptors,
      presentationMaterials: materials,
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
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
        skir.AxisChild.wrapFixed(_text("$kind.name", "name")),
        skir.AxisChild.wrapFixed(_text("$kind.summary", "summary")),
      ],
      layout: skir.AxisChildrenLayout(
        spacing: 2,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.start,
      ),
    ),
  ),
  header: null,
);

skir.PresentationNode _text(String id, String field) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.createText(
    value: skir.ExpressionNode.createRead(
      binding: configuredValueBindingId,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: field)],
      ),
    ),
    color: null,
    fontSize: null,
    fontWeight: null,
    fontItalic: null,
    fontOpticalSize: null,
    fontSlant: null,
    fontWidth: null,
    textAlignment: null,
    lineHeight: null,
    letterSpacing: null,
    decoration: null,
    semanticLabel: null,
    paragraph: skir.TextParagraph.defaultInstance,
  ),
  header: null,
);
