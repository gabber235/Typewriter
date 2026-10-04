import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "type names prefer published display metadata with readable fallback",
    () {
      final displayed = _definition("SequencePage");
      final fallback = _definition("ScenePage");
      final checked = CheckedEditorCatalog(
        catalog.EditorCatalogWireSnapshot(
          generation: types.CatalogGeneration(value: "catalog:display"),
          types: [
            _published(
              displayed,
              const [],
              display: catalog.TypeDisplay(
                name: "Sequence",
                description: "A branching page",
                icon: "material-symbols:account-tree",
                color: "#2196F3",
              ),
            ),
            _published(fallback, const []),
          ],
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

      expect(checked.typeDefinitionName(displayed), "Sequence");
      expect(checked.typeDefinitionName(fallback), "ScenePage");
      expect(
        checked.typeSelectionName(
          types.TypeSelection.createComplete(
            definition: displayed,
            arguments: const [],
          ),
        ),
        "Sequence",
      );
      expect(checked.typeDisplay(displayed)?.description, "A branching page");
    },
  );

  test("pending arguments leave independent fields available", () {
    final fixture = _catalog();
    final selection = types.TypeSelection.createPending(
      definition: fixture.root,
      arguments: [types.ArgumentSelection.unfilled],
    );

    final fields = fixture.catalog.fields(selection);

    expect(fields.map((field) => field.template.key), ["title", "payload"]);
    expect(fields.first.type, types.TypeUse.wrapScalar(types.ScalarKind.text));
    expect(fields.first.isAvailable, isTrue);
    expect(fields.last.type, isNull);
    expect(fields.last.isAvailable, isFalse);
    expect(
      fixture.catalog
          .knownApplications(selection)
          .map((application) => application.definition),
      [fixture.marker],
    );
  });

  test("chosen arguments apply fields and inherited applications", () {
    final fixture = _catalog();
    final integer = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
    );
    final selection = types.TypeSelection.createComplete(
      definition: fixture.root,
      arguments: [integer],
    );

    final fields = fixture.catalog.fields(selection);
    final applications = fixture.catalog.knownApplications(selection);

    expect(fields.last.type, integer);
    expect(
      applications,
      containsAll([
        types.NamedTypeUse(definition: fixture.root, arguments: [integer]),
        types.NamedTypeUse(definition: fixture.base, arguments: [integer]),
        types.NamedTypeUse(definition: fixture.marker, arguments: const []),
      ]),
    );
  });

  test("selection composition keeps every argument position explicit", () {
    final fixture = _catalog();
    final integer = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
    );

    final begun = fixture.catalog.beginSelection(fixture.root);
    expect(begun, isA<types.TypeSelection_pendingWrapper>());
    final chosen = fixture.catalog.chooseArgument(begun, 0, integer);
    expect(chosen, isA<TypeArgumentAccepted>());
    final complete = (chosen as TypeArgumentAccepted).selection;
    expect(complete, isA<types.TypeSelection_completeWrapper>());

    final cleared = fixture.catalog.clearArgument(complete, 0);
    expect(cleared, isA<types.TypeSelection_pendingWrapper>());
    final pending = (cleared as types.TypeSelection_pendingWrapper).value;
    expect(pending.arguments, [types.ArgumentSelection.unfilled]);
  });

  test("readability follows checked nominal ancestry", () {
    final fixture = _catalog();
    final integer = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
    );
    final root = types.TypeUse.createNamed(
      definition: fixture.root,
      arguments: [integer],
    );
    final base = types.TypeUse.createNamed(
      definition: fixture.base,
      arguments: [integer],
    );

    expect(fixture.catalog.isReadableAs(root, base), isTrue);
    expect(fixture.catalog.isReadableAs(base, root), isFalse);
  });

  test("readability is covariant through matching generic arguments", () {
    final wrapper = _definition("Wrapper");
    final reward = _definition("Reward");
    final coin = _definition("CoinReward");
    final parameter = types.ParameterKey(owner: wrapper, index: 0);
    final checked = CheckedEditorCatalog(
      catalog.EditorCatalogWireSnapshot(
        generation: types.CatalogGeneration(value: "catalog:covariance"),
        types: [
          _published(wrapper, [parameter]),
          _published(reward, const []),
          catalog.PublishedType(
            definition: types.TypeDefinition(
              id: coin,
              parameters: const [],
              representation: types.RepresentationTemplate.unknown,
              parents: [
                types.NamedTypeTemplate(
                  definition: reward,
                  arguments: const [],
                ),
              ],
            ),
            status: catalog.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: [
              types.NamedTypeTemplate(definition: reward, arguments: const []),
            ],
            display: null,
          ),
        ],
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
    final actual = types.TypeUse.createNamed(
      definition: wrapper,
      arguments: [
        types.TypeUse.createNamed(definition: coin, arguments: const []),
      ],
    );
    final expected = types.TypeUse.createNamed(
      definition: wrapper,
      arguments: [
        types.TypeUse.createNamed(definition: reward, arguments: const []),
      ],
    );

    expect(checked.isReadableAs(actual, expected), isTrue);
    expect(checked.isReadableAs(expected, actual), isFalse);
  });

  test("concrete generic presentation beats its readable base target", () {
    final wrapper = _definition("SpecificVariable");
    final reward = _definition("SpecificReward");
    final coin = _definition("SpecificCoinReward");
    final parameter = types.ParameterKey(owner: wrapper, index: 0);
    final exact = types.PresentationId(namespace: "test", name: "exact");
    final base = types.PresentationId(namespace: "test", name: "base");
    final coinTemplate = types.TypeTemplate.createNamed(
      definition: coin,
      arguments: const [],
    );
    final rewardTemplate = types.TypeTemplate.createNamed(
      definition: reward,
      arguments: const [],
    );
    final exactTarget = catalog.PresentationTarget.createNamed(
      definition: wrapper,
      arguments: [coinTemplate],
    );
    final baseTarget = catalog.PresentationTarget.createNamed(
      definition: wrapper,
      arguments: [rewardTemplate],
    );
    final descriptors = [
      catalog.PresentationDescriptor(
        id: exact,
        owner: types.DeclarationOwner.defaultInstance,
        target: exactTarget,
        roles: [catalog.PresentationRole.editor],
        priority: 10,
      ),
      catalog.PresentationDescriptor(
        id: base,
        owner: types.DeclarationOwner.defaultInstance,
        target: baseTarget,
        roles: [catalog.PresentationRole.editor],
        priority: 100,
      ),
    ];
    final checked = CheckedEditorCatalog(
      catalog.EditorCatalogWireSnapshot(
        generation: types.CatalogGeneration(value: "catalog:specificity"),
        types: [
          _published(wrapper, [parameter]),
          _published(reward, const []),
          catalog.PublishedType(
            definition: types.TypeDefinition(
              id: coin,
              parameters: const [],
              representation: types.RepresentationTemplate.unknown,
              parents: [
                types.NamedTypeTemplate(
                  definition: reward,
                  arguments: const [],
                ),
              ],
            ),
            status: catalog.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: [
              types.NamedTypeTemplate(definition: reward, arguments: const []),
            ],
            display: null,
          ),
        ],
        relations: const [],
        resourceDefinitions: const [],
        presentations: descriptors,
        presentationMaterials: [
          for (final descriptor in descriptors)
            catalog.PresentationMaterial(
              provider: descriptor.id,
              target: descriptor.target,
              role: catalog.PresentationRole.editor,
              layout: presentation.PresentationNode.defaultInstance,
              dependencies:
                  presentation.PresentationDependencies.defaultInstance,
              subject: _subject(descriptor.target, wrapper),
            ),
        ],
        configuration: const [],
        diagnostics: const [],
        initialization: const [],
        endpointBindings: const [],
        capabilities: const [],
        recommendations: const [],
        roleFallbacks: const [],
      ),
    );
    final selected = checked.selectPresentation(
      types.TypeSelection.createComplete(
        definition: wrapper,
        arguments: [
          types.TypeUse.createNamed(definition: coin, arguments: const []),
        ],
      ),
      catalog.PresentationRole.editor,
    );

    expect((selected as SelectedEditorPresentation).descriptor.id, exact);
  });

  test("dependent bounds wait for known arguments and validate together", () {
    final fixture = _dependentCatalog();
    final integer = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
    );
    final text = types.TypeUse.wrapScalar(types.ScalarKind.text);

    final begun = fixture.catalog.beginSelection(fixture.root);
    final first = fixture.catalog.chooseArgument(begun, 0, integer);
    expect(first, isA<TypeArgumentAccepted>());
    final pending = (first as TypeArgumentAccepted).selection;
    expect(pending, isA<types.TypeSelection_pendingWrapper>());

    expect(
      fixture.catalog.chooseArgument(pending, 1, text),
      isA<TypeArgumentRejected>(),
    );
    final accepted = fixture.catalog.chooseArgument(pending, 1, integer);
    expect(
      (accepted as TypeArgumentAccepted).selection,
      isA<types.TypeSelection_completeWrapper>(),
    );
  });

  test("incomplete inherited endpoint metadata remains discoverable", () {
    final fixture = _catalog();
    final pending = fixture.catalog.beginSelection(fixture.root);

    final pendingBindings = fixture.catalog.endpointBindings(pending);
    expect(pendingBindings, hasLength(1));
    expect(pendingBindings.single.isAvailable, isFalse);
    expect(fixture.catalog.resourceDefinition(pending)?.id.value, "test.base");

    final integer = types.TypeUse.wrapScalar(
      types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
    );
    final complete = types.TypeSelection.createComplete(
      definition: fixture.root,
      arguments: [integer],
    );
    final applied = fixture.catalog.endpointBindings(complete).single;
    expect(applied.isAvailable, isTrue);
    expect(applied.target, integer);
    expect(applied.containingResource?.definition, fixture.base);
  });

  test("role fallbacks preserve published breadth first order", () {
    final fixture = _catalog();

    expect(
      fixture.catalog.roleFallbackOrder(
        catalog.PresentationRole.inspectorHeader,
      ),
      [
        catalog.PresentationRole.inspectorHeader,
        catalog.PresentationRole.editor,
        catalog.PresentationRole.referenceSummary,
        catalog.PresentationRole.catalogOption,
      ],
    );
  });

  test("presentation selection uses fallback specificity then priority", () {
    final fixture = _catalog();
    final actual = types.TypeSelection.createComplete(
      definition: fixture.root,
      arguments: [types.TypeUse.wrapScalar(types.ScalarKind.text)],
    );

    final selected = fixture.catalog.selectPresentation(
      actual,
      catalog.PresentationRole.inspectorHeader,
    );

    expect(selected, isA<SelectedEditorPresentation>());
    final value = selected as SelectedEditorPresentation;
    expect(value.requestedRole, catalog.PresentationRole.inspectorHeader);
    expect(value.resolvedRole, catalog.PresentationRole.editor);
    expect(value.descriptor.id, fixture.rootPresentation);
    expect(value.material.provider, fixture.rootPresentation);
  });

  test("generic presentation remains available for a pending root", () {
    final fixture = _catalog();
    final pending = fixture.catalog.beginSelection(fixture.root);

    final selected = fixture.catalog.selectPresentation(
      pending,
      catalog.PresentationRole.editor,
    );

    expect(
      (selected as SelectedEditorPresentation).descriptor.id,
      fixture.rootPresentation,
    );
  });

  test("equal maximal presentation candidates report a conflict", () {
    final fixture = _catalog();
    final tie = types.PresentationId(namespace: "test", name: "root_tie");
    final rootParameter = types.ParameterKey(owner: fixture.root, index: 0);
    final target = catalog.PresentationTarget.createNamed(
      definition: fixture.root,
      arguments: [types.TypeTemplate.wrapParameter(rootParameter)],
    );
    final original = fixture.catalog.snapshot;
    final checked = CheckedEditorCatalog(
      catalog.EditorCatalogWireSnapshot(
        generation: original.generation,
        types: original.types,
        relations: original.relations,
        resourceDefinitions: original.resourceDefinitions,
        presentations: [
          ...original.presentations,
          catalog.PresentationDescriptor(
            id: tie,
            owner: types.DeclarationOwner.defaultInstance,
            target: target,
            roles: [catalog.PresentationRole.editor],
            priority: 1,
          ),
        ],
        presentationMaterials: [
          ...original.presentationMaterials,
          catalog.PresentationMaterial(
            provider: tie,
            target: target,
            role: catalog.PresentationRole.editor,
            layout: presentation.PresentationNode.defaultInstance,
            dependencies: presentation.PresentationDependencies.defaultInstance,
            subject: _subject(target, fixture.root),
          ),
        ],
        configuration: original.configuration,
        diagnostics: original.diagnostics,
        initialization: original.initialization,
        endpointBindings: original.endpointBindings,
        capabilities: original.capabilities,
        recommendations: original.recommendations,
        roleFallbacks: original.roleFallbacks,
      ),
    );
    final actual = types.TypeSelection.createComplete(
      definition: fixture.root,
      arguments: [types.TypeUse.wrapScalar(types.ScalarKind.text)],
    );

    final selected = checked.selectPresentation(
      actual,
      catalog.PresentationRole.editor,
    );

    expect(selected, isA<ConflictingEditorPresentation>());
    expect(
      (selected as ConflictingEditorPresentation).candidates,
      containsAll([fixture.rootPresentation, tie]),
    );
  });

  test(
    "incomparable generic presentation targets conflict before priority",
    () {
      final fixture = _patternCatalog(repeated: false);

      final selected = fixture.catalog.selectPresentation(
        fixture.actual,
        catalog.PresentationRole.editor,
      );

      expect(
        fixture.catalog.snapshot.presentations.map(
          (candidate) => fixture.catalog.isPresentationCompatible(
            candidate.target,
            fixture.actual,
          ),
        ),
        everyElement(isTrue),
      );
      expect(
        selected,
        isA<ConflictingEditorPresentation>(),
        reason: selected is SelectedEditorPresentation
            ? selected.descriptor.id.name
            : selected.runtimeType.toString(),
      );
      expect(
        (selected as ConflictingEditorPresentation).candidates,
        containsAll([fixture.first, fixture.second]),
      );
    },
  );

  test("repeated template parameters are semantically narrower", () {
    final fixture = _patternCatalog(repeated: true);

    final selected = fixture.catalog.selectPresentation(
      fixture.actual,
      catalog.PresentationRole.editor,
    );

    expect(
      (selected as SelectedEditorPresentation).descriptor.id,
      fixture.first,
    );
  });
}

({
  CheckedEditorCatalog catalog,
  types.TypeSelection actual,
  types.PresentationId first,
  types.PresentationId second,
})
_patternCatalog({required bool repeated}) {
  final pair = _definition("Pair");
  final list = _definition("List");
  final firstParameter = types.ParameterKey(owner: pair, index: 0);
  final secondParameter = types.ParameterKey(owner: pair, index: 1);
  final string = types.TypeTemplate.wrapScalar(types.ScalarKind.text);
  final stringList = types.TypeTemplate.createNamed(
    definition: list,
    arguments: [string],
  );
  final firstTarget = catalog.PresentationTarget.createNamed(
    definition: pair,
    arguments: repeated
        ? [
            types.TypeTemplate.wrapParameter(firstParameter),
            types.TypeTemplate.wrapParameter(firstParameter),
          ]
        : [string, types.TypeTemplate.wrapParameter(firstParameter)],
  );
  final secondTarget = catalog.PresentationTarget.createNamed(
    definition: pair,
    arguments: repeated
        ? [
            types.TypeTemplate.wrapParameter(firstParameter),
            types.TypeTemplate.wrapParameter(secondParameter),
          ]
        : [types.TypeTemplate.wrapParameter(firstParameter), stringList],
  );
  final first = types.PresentationId(namespace: "test", name: "first");
  final second = types.PresentationId(namespace: "test", name: "second");
  final descriptors = [
    catalog.PresentationDescriptor(
      id: first,
      owner: types.DeclarationOwner.defaultInstance,
      target: firstTarget,
      roles: [catalog.PresentationRole.editor],
      priority: repeated ? 1 : 100,
    ),
    catalog.PresentationDescriptor(
      id: second,
      owner: types.DeclarationOwner.defaultInstance,
      target: secondTarget,
      roles: [catalog.PresentationRole.editor],
      priority: repeated ? 100 : 1,
    ),
  ];
  final snapshot = catalog.EditorCatalogWireSnapshot(
    generation: types.CatalogGeneration(value: "catalog:patterns"),
    types: [
      catalog.PublishedType(
        definition: types.TypeDefinition(
          id: pair,
          parameters: [
            types.TypeParameter(
              key: firstParameter,
              name: "A",
              bounds: const [],
            ),
            types.TypeParameter(
              key: secondParameter,
              name: "B",
              bounds: const [],
            ),
          ],
          representation: types.RepresentationTemplate.createRecord(
            fields: const [],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: catalog.DeclarationStatus.ready,
        effectiveFields: const [],
        ancestorTemplates: const [],
        display: null,
      ),
    ],
    relations: const [],
    resourceDefinitions: const [],
    presentations: descriptors,
    presentationMaterials: [
      for (final descriptor in descriptors)
        catalog.PresentationMaterial(
          provider: descriptor.id,
          target: descriptor.target,
          role: catalog.PresentationRole.editor,
          layout: presentation.PresentationNode.defaultInstance,
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: _subject(descriptor.target, pair),
        ),
    ],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
  final stringUse = types.TypeUse.wrapScalar(types.ScalarKind.text);
  final listUse = types.TypeUse.createNamed(
    definition: list,
    arguments: [stringUse],
  );
  return (
    catalog: CheckedEditorCatalog(snapshot),
    actual: types.TypeSelection.createComplete(
      definition: pair,
      arguments: repeated ? [stringUse, stringUse] : [stringUse, listUse],
    ),
    first: first,
    second: second,
  );
}

({CheckedEditorCatalog catalog, types.TypeDefinitionId root})
_dependentCatalog() {
  final root = _definition("Dependent");
  final first = types.ParameterKey(owner: root, index: 0);
  final second = types.ParameterKey(owner: root, index: 1);
  final definition = catalog.PublishedType(
    definition: types.TypeDefinition(
      id: root,
      parameters: [
        types.TypeParameter(
          key: first,
          name: "T",
          bounds: [types.TypeTemplate.wrapParameter(second)],
        ),
        types.TypeParameter(key: second, name: "U", bounds: const []),
      ],
      representation: types.RepresentationTemplate.unknown,
      parents: const [],
    ),
    status: catalog.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: const [],
    display: null,
  );
  return (
    catalog: CheckedEditorCatalog(
      catalog.EditorCatalogWireSnapshot(
        generation: types.CatalogGeneration(value: "catalog:dependent"),
        types: [definition],
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
    ),
    root: root,
  );
}

({
  CheckedEditorCatalog catalog,
  types.TypeDefinitionId root,
  types.TypeDefinitionId base,
  types.TypeDefinitionId marker,
  types.PresentationId rootPresentation,
})
_catalog() {
  final root = _definition("Root");
  final base = _definition("Base");
  final marker = _definition("Marker");
  final rootParameter = types.ParameterKey(owner: root, index: 0);
  final baseParameter = types.ParameterKey(owner: base, index: 0);
  final rootPresentation = types.PresentationId(
    namespace: "test",
    name: "root",
  );
  final basePresentation = types.PresentationId(
    namespace: "test",
    name: "base",
  );
  final recordPresentation = types.PresentationId(
    namespace: "test",
    name: "record",
  );
  final rootTarget = catalog.PresentationTarget.createNamed(
    definition: root,
    arguments: [types.TypeTemplate.wrapParameter(rootParameter)],
  );
  final baseTarget = catalog.PresentationTarget.createNamed(
    definition: base,
    arguments: [types.TypeTemplate.wrapParameter(baseParameter)],
  );
  final recordTarget = catalog.PresentationTarget.wrapRepresentation(
    catalog.RepresentationKind.record,
  );
  final rootType = catalog.PublishedType(
    definition: types.TypeDefinition(
      id: root,
      parameters: [
        types.TypeParameter(key: rootParameter, name: "T", bounds: const []),
      ],
      representation: types.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: false,
      ),
      parents: [
        types.NamedTypeTemplate(
          definition: base,
          arguments: [types.TypeTemplate.wrapParameter(rootParameter)],
        ),
        types.NamedTypeTemplate(definition: marker, arguments: const []),
      ],
    ),
    status: catalog.DeclarationStatus.ready,
    effectiveFields: [
      catalog.EffectiveFieldTemplate(
        key: "title",
        owner: types.FieldOwner(definition: root, name: "title"),
        type: types.TypeTemplate.wrapScalar(types.ScalarKind.text),
        rules: const [],
      ),
      catalog.EffectiveFieldTemplate(
        key: "payload",
        owner: types.FieldOwner(definition: base, name: "payload"),
        type: types.TypeTemplate.wrapParameter(baseParameter),
        rules: const [],
      ),
    ],
    ancestorTemplates: [
      types.NamedTypeTemplate(
        definition: base,
        arguments: [types.TypeTemplate.wrapParameter(rootParameter)],
      ),
      types.NamedTypeTemplate(definition: marker, arguments: const []),
    ],
    display: null,
  );
  final baseType = _published(base, [baseParameter]);
  final markerType = _published(marker, const []);
  final snapshot = catalog.EditorCatalogWireSnapshot(
    generation: types.CatalogGeneration(value: "catalog:1"),
    types: [rootType, baseType, markerType],
    relations: const [],
    resourceDefinitions: [
      catalog.AuthoringResourceDefinition(
        id: catalog.ResourceDefinitionId(value: "test.base"),
        root: base,
        navigationHandler: "generic",
      ),
    ],
    presentations: [
      catalog.PresentationDescriptor(
        id: rootPresentation,
        owner: types.DeclarationOwner.defaultInstance,
        target: rootTarget,
        roles: [catalog.PresentationRole.editor],
        priority: 1,
      ),
      catalog.PresentationDescriptor(
        id: basePresentation,
        owner: types.DeclarationOwner.defaultInstance,
        target: baseTarget,
        roles: [catalog.PresentationRole.editor],
        priority: 100,
      ),
      catalog.PresentationDescriptor(
        id: recordPresentation,
        owner: types.DeclarationOwner.defaultInstance,
        target: recordTarget,
        roles: [catalog.PresentationRole.editor],
        priority: 1000,
      ),
    ],
    presentationMaterials: [
      for (final entry in [
        (rootPresentation, rootTarget),
        (basePresentation, baseTarget),
        (recordPresentation, recordTarget),
      ])
        catalog.PresentationMaterial(
          provider: entry.$1,
          target: entry.$2,
          role: catalog.PresentationRole.editor,
          layout: presentation.PresentationNode.defaultInstance,
          dependencies: presentation.PresentationDependencies.defaultInstance,
          subject: _subject(entry.$2, root),
        ),
    ],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: [
      catalog.EndpointBindingTemplate(
        endpoint: types.EndpointId(value: "test.endpoint"),
        containingResource: types.NamedTypeTemplate(
          definition: base,
          arguments: [types.TypeTemplate.wrapParameter(baseParameter)],
        ),
        valueOwner: base,
        relativePath: types.RelativeFieldPattern(segments: const []),
        target: types.TypeTemplate.wrapParameter(baseParameter),
        containsCollection: false,
      ),
    ],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: [
      catalog.RoleFallback(
        role: catalog.PresentationRole.inspectorHeader,
        parents: [
          catalog.PresentationRole.editor,
          catalog.PresentationRole.referenceSummary,
        ],
      ),
      catalog.RoleFallback(
        role: catalog.PresentationRole.editor,
        parents: [catalog.PresentationRole.catalogOption],
      ),
      catalog.RoleFallback(
        role: catalog.PresentationRole.catalogOption,
        parents: [catalog.PresentationRole.inspectorHeader],
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

catalog.PublishedType _published(
  types.TypeDefinitionId id,
  List<types.ParameterKey> parameters, {
  catalog.TypeDisplay? display,
}) => catalog.PublishedType(
  definition: types.TypeDefinition(
    id: id,
    parameters: [
      for (var index = 0; index < parameters.length; index++)
        types.TypeParameter(
          key: parameters[index],
          name: "T$index",
          bounds: const [],
        ),
    ],
    representation: types.RepresentationTemplate.unknown,
    parents: const [],
  ),
  status: catalog.DeclarationStatus.ready,
  effectiveFields: const [],
  ancestorTemplates: const [],
  display: display,
);

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

types.TypeTemplate _subject(
  catalog.PresentationTarget target,
  types.TypeDefinitionId fallback,
) => switch (target) {
  catalog.PresentationTarget_namedWrapper(:final value) =>
    types.TypeTemplate.wrapNamed(value),
  _ => types.TypeTemplate.createNamed(
    definition: fallback,
    arguments: const [],
  ),
};
