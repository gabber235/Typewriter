import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";

/// A catalog of the two parameter type `Pair` with two workspace
/// presentations whose targets overlap. With [repeated], `first` targets
/// `Pair<T, T>` at priority 1 and `second` targets `Pair<T, U>` at priority
/// 100; otherwise `first` targets `Pair<String, T>` at priority 100 and
/// `second` targets `Pair<T, List<String>>` at priority 1. `actual` matches
/// both targets.
({
  CheckedEditorCatalog catalog,
  skir.TypeSelection actual,
  skir.PresentationId first,
  skir.PresentationId second,
})
repeatedParameterCatalog({required bool repeated}) {
  final pair = typeDefinition("Pair");
  final list = typeDefinition("List");
  final firstParameter = skir.ParameterKey(owner: pair, index: 0);
  final secondParameter = skir.ParameterKey(owner: pair, index: 1);
  final string = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final stringList = skir.TypeTemplate.createNamed(
    definition: list,
    arguments: [string],
  );
  final firstTarget = skir.PresentationTarget.createNamed(
    definition: pair,
    arguments: repeated
        ? [
            skir.TypeTemplate.wrapParameter(firstParameter),
            skir.TypeTemplate.wrapParameter(firstParameter),
          ]
        : [string, skir.TypeTemplate.wrapParameter(firstParameter)],
  );
  final secondTarget = skir.PresentationTarget.createNamed(
    definition: pair,
    arguments: repeated
        ? [
            skir.TypeTemplate.wrapParameter(firstParameter),
            skir.TypeTemplate.wrapParameter(secondParameter),
          ]
        : [skir.TypeTemplate.wrapParameter(firstParameter), stringList],
  );
  final first = skir.PresentationId(namespace: "test", name: "first");
  final second = skir.PresentationId(namespace: "test", name: "second");
  final descriptors = [
    skir.PresentationDescriptor(
      id: first,
      owner: skir.DeclarationOwner.defaultInstance,
      target: firstTarget,
      roles: [skir.PresentationRole.workspace],
      priority: repeated ? 1 : 100,
    ),
    skir.PresentationDescriptor(
      id: second,
      owner: skir.DeclarationOwner.defaultInstance,
      target: secondTarget,
      roles: [skir.PresentationRole.workspace],
      priority: repeated ? 100 : 1,
    ),
  ];
  final snapshot = skir.EditorCatalog(
    resourceDisplays: const [],
    resourceOperations: const [],
    generation: skir.CatalogGeneration(value: "catalog:patterns"),
    types: [
      skir.PublishedType(
        searchKey: null,
        placementField: null,
        definition: skir.TypeDefinition(
          id: pair,
          parameters: [
            skir.TypeParameter(
              key: firstParameter,
              name: "A",
              bounds: const [],
            ),
            skir.TypeParameter(
              key: secondParameter,
              name: "B",
              bounds: const [],
            ),
          ],
          representation: skir.RepresentationTemplate.createRecord(
            fields: const [],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: const [],
        ancestorTemplates: const [],
        display: defaultTypeDisplay(""),
      ),
    ],
    relations: const [],
    realmRoot: skir.TypeDefinitionId.defaultInstance,
    presentations: descriptors,
    presentationMaterials: [
      for (final descriptor in descriptors)
        skir.PresentationMaterial(
          inheritableNodes: const [],

          provider: descriptor.id,
          target: descriptor.target,
          role: skir.PresentationRole.workspace,
          layout: skir.PresentationNode.defaultInstance,
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: presentationSubject(descriptor.target, pair),
        ),
    ],
    configuration: const [],
    diagnostics: const [],

    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final stringUse = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
  final listUse = skir.TypeUse.createNamed(
    definition: list,
    arguments: [stringUse],
  );
  return (
    catalog: CheckedEditorCatalog(snapshot),
    actual: skir.TypeSelection.createComplete(
      definition: pair,
      arguments: repeated ? [stringUse, stringUse] : [stringUse, listUse],
    ),
    first: first,
    second: second,
  );
}

/// A catalog of one type `Dependent<T extends U, U>` whose first parameter is
/// bounded by its second.
({CheckedEditorCatalog catalog, skir.TypeDefinitionId root})
dependentParameterCatalog() {
  final root = typeDefinition("Dependent");
  final first = skir.ParameterKey(owner: root, index: 0);
  final second = skir.ParameterKey(owner: root, index: 1);
  final definition = skir.PublishedType(
    searchKey: null,
    placementField: null,
    definition: skir.TypeDefinition(
      id: root,
      parameters: [
        skir.TypeParameter(
          key: first,
          name: "T",
          bounds: [skir.TypeTemplate.wrapParameter(second)],
        ),
        skir.TypeParameter(key: second, name: "U", bounds: const []),
      ],
      representation: skir.RepresentationTemplate.unknown,
      parents: const [],
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: const [],
    display: defaultTypeDisplay(""),
  );
  return (
    catalog: CheckedEditorCatalog(
      skir.EditorCatalog(
        resourceDisplays: const [],
        resourceOperations: const [],
        generation: skir.CatalogGeneration(value: "catalog:dependent"),
        types: [definition],
        relations: const [],
        realmRoot: skir.TypeDefinitionId.defaultInstance,
        presentations: const [],
        presentationMaterials: const [],
        configuration: const [],
        diagnostics: const [],

        endpointBindings: const [],
        capabilities: const [],
        recommendations: const [],
        roleFallbacks: const [],
      ),
    ),
    root: root,
  );
}

/// A catalog of `Root<T>` refining `Base<T>` and `Marker`, with a title field
/// of its own and the `payload: T` field `Base` declares. Workspace
/// presentations target `Root<T>` (priority 1), `Base<T>` (priority 100) and
/// every record (priority 1000); an endpoint binds a `Base` value, and role
/// fallbacks chain inspector, workspace and search result.
({
  CheckedEditorCatalog catalog,
  skir.TypeDefinitionId root,
  skir.TypeDefinitionId base,
  skir.TypeDefinitionId marker,
  skir.PresentationId rootPresentation,
})
inheritedPresentationCatalog() {
  final root = typeDefinition("Root");
  final base = typeDefinition("Base");
  final marker = typeDefinition("Marker");
  final rootParameter = skir.ParameterKey(owner: root, index: 0);
  final baseParameter = skir.ParameterKey(owner: base, index: 0);
  final rootPresentation = skir.PresentationId(namespace: "test", name: "root");
  final basePresentation = skir.PresentationId(namespace: "test", name: "base");
  final recordPresentation = skir.PresentationId(
    namespace: "test",
    name: "record",
  );
  final rootTarget = skir.PresentationTarget.createNamed(
    definition: root,
    arguments: [skir.TypeTemplate.wrapParameter(rootParameter)],
  );
  final baseTarget = skir.PresentationTarget.createNamed(
    definition: base,
    arguments: [skir.TypeTemplate.wrapParameter(baseParameter)],
  );
  final recordTarget = skir.PresentationTarget.wrapRepresentation(
    skir.RepresentationKind.record,
  );
  final rootType = skir.PublishedType(
    searchKey: null,
    placementField: null,
    definition: skir.TypeDefinition(
      id: root,
      parameters: [
        skir.TypeParameter(key: rootParameter, name: "T", bounds: const []),
      ],
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: false,
      ),
      parents: [
        skir.NamedTypeTemplate(
          definition: base,
          arguments: [skir.TypeTemplate.wrapParameter(rootParameter)],
        ),
        skir.NamedTypeTemplate(definition: marker, arguments: const []),
      ],
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: [
      skir.EffectiveFieldTemplate(
        key: "title",
        owner: skir.FieldOwner(definition: root, name: "title"),
        type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        rules: const [],
      ),
      skir.EffectiveFieldTemplate(
        key: "payload",
        owner: skir.FieldOwner(definition: base, name: "payload"),
        type: skir.TypeTemplate.wrapParameter(baseParameter),
        rules: const [],
      ),
    ],
    ancestorTemplates: [
      skir.NamedTypeTemplate(
        definition: base,
        arguments: [skir.TypeTemplate.wrapParameter(rootParameter)],
      ),
      skir.NamedTypeTemplate(definition: marker, arguments: const []),
    ],
    display: defaultTypeDisplay(""),
  );
  final baseType = opaqueType(base, [baseParameter]);
  final markerType = opaqueType(marker, const []);
  final snapshot = skir.EditorCatalog(
    resourceDisplays: const [],
    resourceOperations: const [],
    generation: skir.CatalogGeneration(value: "catalog:1"),
    types: [rootType, baseType, markerType],
    relations: const [],
    realmRoot: skir.TypeDefinitionId.defaultInstance,
    presentations: [
      skir.PresentationDescriptor(
        id: rootPresentation,
        owner: skir.DeclarationOwner.defaultInstance,
        target: rootTarget,
        roles: [skir.PresentationRole.workspace],
        priority: 1,
      ),
      skir.PresentationDescriptor(
        id: basePresentation,
        owner: skir.DeclarationOwner.defaultInstance,
        target: baseTarget,
        roles: [skir.PresentationRole.workspace],
        priority: 100,
      ),
      skir.PresentationDescriptor(
        id: recordPresentation,
        owner: skir.DeclarationOwner.defaultInstance,
        target: recordTarget,
        roles: [skir.PresentationRole.workspace],
        priority: 1000,
      ),
    ],
    presentationMaterials: [
      for (final entry in [
        (rootPresentation, rootTarget),
        (basePresentation, baseTarget),
        (recordPresentation, recordTarget),
      ])
        skir.PresentationMaterial(
          inheritableNodes: const [],

          provider: entry.$1,
          target: entry.$2,
          role: skir.PresentationRole.workspace,
          layout: skir.PresentationNode.defaultInstance,
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: presentationSubject(entry.$2, root),
        ),
    ],
    configuration: const [],
    diagnostics: const [],

    endpointBindings: [
      skir.EndpointBindingTemplate(
        endpoint: skir.EndpointId(value: "test.endpoint"),
        containingResource: skir.NamedTypeTemplate(
          definition: base,
          arguments: [skir.TypeTemplate.wrapParameter(baseParameter)],
        ),
        valueOwner: base,
        relativePath: skir.RelativeFieldPattern(segments: const []),
        target: skir.TypeTemplate.wrapParameter(baseParameter),
        containsCollection: false,
      ),
    ],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: [
      skir.RoleFallback(
        role: skir.PresentationRole.inspector,
        parents: [
          skir.PresentationRole.workspace,
          skir.PresentationRole.referencePreview,
        ],
      ),
      skir.RoleFallback(
        role: skir.PresentationRole.workspace,
        parents: [skir.PresentationRole.resourceSearchResult],
      ),
      skir.RoleFallback(
        role: skir.PresentationRole.resourceSearchResult,
        parents: [skir.PresentationRole.inspector],
      ),
    ],
  );
  return (
    catalog: CheckedEditorCatalog(snapshot),
    root: root,
    base: base,
    marker: marker,
    rootPresentation: rootPresentation,
  );
}

/// A ready type [id] of unknown representation, with one unbounded
/// parameter per key in [parameters], and [display] or the default display.
skir.PublishedType opaqueType(
  skir.TypeDefinitionId id,
  List<skir.ParameterKey> parameters, {
  skir.TypeDisplay? display,
}) => skir.PublishedType(
  searchKey: null,
  placementField: null,
  definition: skir.TypeDefinition(
    id: id,
    parameters: [
      for (var index = 0; index < parameters.length; index++)
        skir.TypeParameter(
          key: parameters[index],
          name: "T$index",
          bounds: const [],
        ),
    ],
    representation: skir.RepresentationTemplate.unknown,
    parents: const [],
  ),
  status: skir.DeclarationStatus.ready,
  effectiveFields: const [],
  ancestorTemplates: const [],
  display: display ?? defaultTypeDisplay(""),
);

/// The subject a presentation for [target] reads: the named target itself,
/// or [fallback] for a representation target.
skir.TypeTemplate presentationSubject(
  skir.PresentationTarget target,
  skir.TypeDefinitionId fallback,
) => switch (target) {
  skir.PresentationTarget_namedWrapper(:final value) =>
    skir.TypeTemplate.wrapNamed(value),
  _ => skir.TypeTemplate.createNamed(definition: fallback, arguments: const []),
};
