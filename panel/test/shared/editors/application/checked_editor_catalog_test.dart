import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "type names prefer published display metadata with readable fallback",
    () {
      final displayed = _definition("SequencePage");
      final fallback = _definition("ScenePage");
      final checked = CheckedEditorCatalog(
        skir.EditorCatalogWireSnapshot(
          generation: skir.CatalogGeneration(value: "catalog:display"),
          types: [
            _published(
              displayed,
              const [],
              display: skir.TypeDisplay(
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
          skir.TypeSelection.createComplete(
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
    final selection = skir.TypeSelection.createPending(
      definition: fixture.root,
      arguments: [skir.ArgumentSelection.unfilled],
    );

    final fields = fixture.catalog.fields(selection);

    expect(fields.map((field) => field.template.key), ["title", "payload"]);
    expect(fields.first.type, skir.TypeUse.wrapScalar(skir.ScalarKind.text));
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
    final integer = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );
    final selection = skir.TypeSelection.createComplete(
      definition: fixture.root,
      arguments: [integer],
    );

    final fields = fixture.catalog.fields(selection);
    final applications = fixture.catalog.knownApplications(selection);

    expect(fields.last.type, integer);
    expect(
      applications,
      containsAll([
        skir.NamedTypeUse(definition: fixture.root, arguments: [integer]),
        skir.NamedTypeUse(definition: fixture.base, arguments: [integer]),
        skir.NamedTypeUse(definition: fixture.marker, arguments: const []),
      ]),
    );
  });

  test("selection composition keeps every argument position explicit", () {
    final fixture = _catalog();
    final integer = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );

    final begun = fixture.catalog.beginSelection(fixture.root);
    expect(begun, isA<skir.TypeSelection_pendingWrapper>());
    final chosen = fixture.catalog.chooseArgument(begun, 0, integer);
    expect(chosen, isA<TypeArgumentAccepted>());
    final complete = (chosen as TypeArgumentAccepted).selection;
    expect(complete, isA<skir.TypeSelection_completeWrapper>());

    final cleared = fixture.catalog.clearArgument(complete, 0);
    expect(cleared, isA<skir.TypeSelection_pendingWrapper>());
    final pending = (cleared as skir.TypeSelection_pendingWrapper).value;
    expect(pending.arguments, [skir.ArgumentSelection.unfilled]);
  });

  test("readability follows checked nominal ancestry", () {
    final fixture = _catalog();
    final integer = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );
    final root = skir.TypeUse.createNamed(
      definition: fixture.root,
      arguments: [integer],
    );
    final base = skir.TypeUse.createNamed(
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
    final parameter = skir.ParameterKey(owner: wrapper, index: 0);
    final checked = CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:covariance"),
        types: [
          _published(wrapper, [parameter]),
          _published(reward, const []),
          skir.PublishedType(
            definition: skir.TypeDefinition(
              id: coin,
              parameters: const [],
              representation: skir.RepresentationTemplate.unknown,
              parents: [
                skir.NamedTypeTemplate(definition: reward, arguments: const []),
              ],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: [
              skir.NamedTypeTemplate(definition: reward, arguments: const []),
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
    final actual = skir.TypeUse.createNamed(
      definition: wrapper,
      arguments: [
        skir.TypeUse.createNamed(definition: coin, arguments: const []),
      ],
    );
    final expected = skir.TypeUse.createNamed(
      definition: wrapper,
      arguments: [
        skir.TypeUse.createNamed(definition: reward, arguments: const []),
      ],
    );

    expect(checked.isReadableAs(actual, expected), isTrue);
    expect(checked.isReadableAs(expected, actual), isFalse);
  });

  test("concrete generic presentation beats its readable base target", () {
    final wrapper = _definition("SpecificVariable");
    final reward = _definition("SpecificReward");
    final coin = _definition("SpecificCoinReward");
    final parameter = skir.ParameterKey(owner: wrapper, index: 0);
    final exact = skir.PresentationId(namespace: "test", name: "exact");
    final base = skir.PresentationId(namespace: "test", name: "base");
    final coinTemplate = skir.TypeTemplate.createNamed(
      definition: coin,
      arguments: const [],
    );
    final rewardTemplate = skir.TypeTemplate.createNamed(
      definition: reward,
      arguments: const [],
    );
    final exactTarget = skir.PresentationTarget.createNamed(
      definition: wrapper,
      arguments: [coinTemplate],
    );
    final baseTarget = skir.PresentationTarget.createNamed(
      definition: wrapper,
      arguments: [rewardTemplate],
    );
    final descriptors = [
      skir.PresentationDescriptor(
        id: exact,
        owner: skir.DeclarationOwner.defaultInstance,
        target: exactTarget,
        roles: [skir.PresentationRole.editor],
        priority: 10,
      ),
      skir.PresentationDescriptor(
        id: base,
        owner: skir.DeclarationOwner.defaultInstance,
        target: baseTarget,
        roles: [skir.PresentationRole.editor],
        priority: 100,
      ),
    ];
    final checked = CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:specificity"),
        types: [
          _published(wrapper, [parameter]),
          _published(reward, const []),
          skir.PublishedType(
            definition: skir.TypeDefinition(
              id: coin,
              parameters: const [],
              representation: skir.RepresentationTemplate.unknown,
              parents: [
                skir.NamedTypeTemplate(definition: reward, arguments: const []),
              ],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: [
              skir.NamedTypeTemplate(definition: reward, arguments: const []),
            ],
            display: null,
          ),
        ],
        relations: const [],
        resourceDefinitions: const [],
        presentations: descriptors,
        presentationMaterials: [
          for (final descriptor in descriptors)
            skir.PresentationMaterial(
              provider: descriptor.id,
              target: descriptor.target,
              role: skir.PresentationRole.editor,
              layout: skir.PresentationNode.defaultInstance,
              dependencies: skir.PresentationDependencies.defaultInstance,
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
      skir.TypeSelection.createComplete(
        definition: wrapper,
        arguments: [
          skir.TypeUse.createNamed(definition: coin, arguments: const []),
        ],
      ),
      skir.PresentationRole.editor,
    );

    expect((selected as SelectedEditorPresentation).descriptor.id, exact);
  });

  test("dependent bounds wait for known arguments and validate together", () {
    final fixture = _dependentCatalog();
    final integer = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );
    final text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);

    final begun = fixture.catalog.beginSelection(fixture.root);
    final first = fixture.catalog.chooseArgument(begun, 0, integer);
    expect(first, isA<TypeArgumentAccepted>());
    final pending = (first as TypeArgumentAccepted).selection;
    expect(pending, isA<skir.TypeSelection_pendingWrapper>());

    expect(
      fixture.catalog.chooseArgument(pending, 1, text),
      isA<TypeArgumentRejected>(),
    );
    final accepted = fixture.catalog.chooseArgument(pending, 1, integer);
    expect(
      (accepted as TypeArgumentAccepted).selection,
      isA<skir.TypeSelection_completeWrapper>(),
    );
  });

  test("incomplete inherited endpoint metadata remains discoverable", () {
    final fixture = _catalog();
    final pending = fixture.catalog.beginSelection(fixture.root);

    final pendingBindings = fixture.catalog.endpointBindings(pending);
    expect(pendingBindings, hasLength(1));
    expect(pendingBindings.single.isAvailable, isFalse);
    expect(fixture.catalog.resourceDefinition(pending)?.id.value, "test.base");

    final integer = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );
    final complete = skir.TypeSelection.createComplete(
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
      fixture.catalog.roleFallbackOrder(skir.PresentationRole.inspector),
      [
        skir.PresentationRole.inspector,
        skir.PresentationRole.editor,
        skir.PresentationRole.referenceSummary,
        skir.PresentationRole.catalogOption,
      ],
    );
  });

  test("presentation selection uses fallback specificity then priority", () {
    final fixture = _catalog();
    final actual = skir.TypeSelection.createComplete(
      definition: fixture.root,
      arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
    );

    final selected = fixture.catalog.selectPresentation(
      actual,
      skir.PresentationRole.inspector,
    );

    expect(selected, isA<SelectedEditorPresentation>());
    final value = selected as SelectedEditorPresentation;
    expect(value.requestedRole, skir.PresentationRole.inspector);
    expect(value.resolvedRole, skir.PresentationRole.editor);
    expect(value.descriptor.id, fixture.rootPresentation);
    expect(value.material.provider, fixture.rootPresentation);
  });

  test("generic presentation remains available for a pending root", () {
    final fixture = _catalog();
    final pending = fixture.catalog.beginSelection(fixture.root);

    final selected = fixture.catalog.selectPresentation(
      pending,
      skir.PresentationRole.editor,
    );

    expect(
      (selected as SelectedEditorPresentation).descriptor.id,
      fixture.rootPresentation,
    );
  });

  test("equal maximal presentation candidates report a conflict", () {
    final fixture = _catalog();
    final tie = skir.PresentationId(namespace: "test", name: "root_tie");
    final rootParameter = skir.ParameterKey(owner: fixture.root, index: 0);
    final target = skir.PresentationTarget.createNamed(
      definition: fixture.root,
      arguments: [skir.TypeTemplate.wrapParameter(rootParameter)],
    );
    final original = fixture.catalog.snapshot;
    final checked = CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: original.generation,
        types: original.types,
        relations: original.relations,
        resourceDefinitions: original.resourceDefinitions,
        presentations: [
          ...original.presentations,
          skir.PresentationDescriptor(
            id: tie,
            owner: skir.DeclarationOwner.defaultInstance,
            target: target,
            roles: [skir.PresentationRole.editor],
            priority: 1,
          ),
        ],
        presentationMaterials: [
          ...original.presentationMaterials,
          skir.PresentationMaterial(
            provider: tie,
            target: target,
            role: skir.PresentationRole.editor,
            layout: skir.PresentationNode.defaultInstance,
            dependencies: skir.PresentationDependencies.defaultInstance,
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
    final actual = skir.TypeSelection.createComplete(
      definition: fixture.root,
      arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
    );

    final selected = checked.selectPresentation(
      actual,
      skir.PresentationRole.editor,
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
        skir.PresentationRole.editor,
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
      skir.PresentationRole.editor,
    );

    expect(
      (selected as SelectedEditorPresentation).descriptor.id,
      fixture.first,
    );
  });
}

({
  CheckedEditorCatalog catalog,
  skir.TypeSelection actual,
  skir.PresentationId first,
  skir.PresentationId second,
})
_patternCatalog({required bool repeated}) {
  final pair = _definition("Pair");
  final list = _definition("List");
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
      roles: [skir.PresentationRole.editor],
      priority: repeated ? 1 : 100,
    ),
    skir.PresentationDescriptor(
      id: second,
      owner: skir.DeclarationOwner.defaultInstance,
      target: secondTarget,
      roles: [skir.PresentationRole.editor],
      priority: repeated ? 100 : 1,
    ),
  ];
  final snapshot = skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "catalog:patterns"),
    types: [
      skir.PublishedType(
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
        display: null,
      ),
    ],
    relations: const [],
    resourceDefinitions: const [],
    presentations: descriptors,
    presentationMaterials: [
      for (final descriptor in descriptors)
        skir.PresentationMaterial(
          provider: descriptor.id,
          target: descriptor.target,
          role: skir.PresentationRole.editor,
          layout: skir.PresentationNode.defaultInstance,
          dependencies: skir.PresentationDependencies.defaultInstance,
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

({CheckedEditorCatalog catalog, skir.TypeDefinitionId root})
_dependentCatalog() {
  final root = _definition("Dependent");
  final first = skir.ParameterKey(owner: root, index: 0);
  final second = skir.ParameterKey(owner: root, index: 1);
  final definition = skir.PublishedType(
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
    display: null,
  );
  return (
    catalog: CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:dependent"),
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
  skir.TypeDefinitionId root,
  skir.TypeDefinitionId base,
  skir.TypeDefinitionId marker,
  skir.PresentationId rootPresentation,
})
_catalog() {
  final root = _definition("Root");
  final base = _definition("Base");
  final marker = _definition("Marker");
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
    display: null,
  );
  final baseType = _published(base, [baseParameter]);
  final markerType = _published(marker, const []);
  final snapshot = skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "catalog:1"),
    types: [rootType, baseType, markerType],
    relations: const [],
    resourceDefinitions: [
      skir.AuthoringResourceDefinition(
        id: skir.ResourceDefinitionId(value: "test.base"),
        root: base,
        navigationHandler: "generic",
      ),
    ],
    presentations: [
      skir.PresentationDescriptor(
        id: rootPresentation,
        owner: skir.DeclarationOwner.defaultInstance,
        target: rootTarget,
        roles: [skir.PresentationRole.editor],
        priority: 1,
      ),
      skir.PresentationDescriptor(
        id: basePresentation,
        owner: skir.DeclarationOwner.defaultInstance,
        target: baseTarget,
        roles: [skir.PresentationRole.editor],
        priority: 100,
      ),
      skir.PresentationDescriptor(
        id: recordPresentation,
        owner: skir.DeclarationOwner.defaultInstance,
        target: recordTarget,
        roles: [skir.PresentationRole.editor],
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
          provider: entry.$1,
          target: entry.$2,
          role: skir.PresentationRole.editor,
          layout: skir.PresentationNode.defaultInstance,
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: _subject(entry.$2, root),
        ),
    ],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
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
          skir.PresentationRole.editor,
          skir.PresentationRole.referenceSummary,
        ],
      ),
      skir.RoleFallback(
        role: skir.PresentationRole.editor,
        parents: [skir.PresentationRole.catalogOption],
      ),
      skir.RoleFallback(
        role: skir.PresentationRole.catalogOption,
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

skir.PublishedType _published(
  skir.TypeDefinitionId id,
  List<skir.ParameterKey> parameters, {
  skir.TypeDisplay? display,
}) => skir.PublishedType(
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
  display: display,
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

skir.TypeTemplate _subject(
  skir.PresentationTarget target,
  skir.TypeDefinitionId fallback,
) => switch (target) {
  skir.PresentationTarget_namedWrapper(:final value) =>
    skir.TypeTemplate.wrapNamed(value),
  _ => skir.TypeTemplate.createNamed(definition: fallback, arguments: const []),
};
