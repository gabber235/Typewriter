import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "representation field subjects match generic complete and pending owners",
    () {
      final fixture = inheritedPresentationCatalog();
      final original = fixture.catalog.snapshot;
      final descriptor =
          (original.presentations.first.toMutable()
                ..target = skir.PresentationTarget.wrapRepresentation(
                  skir.RepresentationKind.record,
                ))
              .toFrozen();
      final binding = skir.BindingRef(
        bindingId: skir.ExpressionBindingId(value: "configured_value"),
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "title")],
        ),
      );
      final node =
          (skir.PresentationNode.defaultInstance.toMutable()
                ..nodeId = "title"
                ..element = skir.PresentationElement.wrapTextInput(
                  (skir.TextControl.defaultInstance.toMutable()
                        ..control =
                            (skir.BoundControl.defaultInstance.toMutable()
                              ..binding = binding))
                      .toFrozen(),
                ))
              .toFrozen();
      final material =
          (original.presentationMaterials.first.toMutable()
                ..target = descriptor.target
                ..layout = node
                ..inheritableNodes = ["title"])
              .toFrozen();
      final catalog = CheckedEditorCatalog(
        (original.toMutable()
              ..presentations = [descriptor]
              ..presentationMaterials = [material])
            .toFrozen(),
      );
      for (final actual in [
        fixture.catalog.beginSelection(fixture.root),
        skir.TypeSelection.createComplete(
          definition: fixture.root,
          arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
        ),
      ]) {
        final selected = catalog.fieldPresentation(
          actual,
          "title",
          skir.PresentationRole.workspace,
        ) as SelectedEditorFieldPresentation;
        expect(selected.identity.provider, descriptor.id);
        expect(selected.identity.field, "title");
        expect(selected.node, node);
      }
    },
  );

  test(
    "type names prefer published display metadata with readable fallback",
    () {
      final displayed = typeDefinition("SequencePage");
      final fallback = typeDefinition("ScenePage");
      final checked = CheckedEditorCatalog(
        testCatalogSnapshot(
          generation: skir.CatalogGeneration(value: "catalog:display"),
          types: [
            opaqueType(
              displayed,
              const [],
              display: skir.TypeDisplay(
                name: "Sequence",
                description: "A branching page",
                icon: skir.Icon.wrapIconify("material-symbols:account-tree"),
                color: skir.Color(argb: 0xff2196f3.toSigned(32)),
              ),
            ),
            opaqueType(fallback, const []),
          ],
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
    final fixture = inheritedPresentationCatalog();
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
    final fixture = inheritedPresentationCatalog();
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
    final fixture = inheritedPresentationCatalog();
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
    final fixture = inheritedPresentationCatalog();
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

  test("a function type shows as (level: Text) -> Boolean", () {
    final fixture = inheritedPresentationCatalog();
    final function = skir.TypeUse.createFunction(
      context: const [],
      parameters: [
        skir.FunctionParameterUse(
          name: "level",
          type: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        ),
      ],
      result: skir.TypeUse.wrapScalar(skir.ScalarKind.boolean),
    );

    expect(fixture.catalog.typeUseName(function), "(level: Text) -> Boolean");
  });

  test("readability is covariant through matching generic arguments", () {
    final wrapper = typeDefinition("Wrapper");
    final reward = typeDefinition("Reward");
    final coin = typeDefinition("CoinReward");
    final parameter = skir.ParameterKey(owner: wrapper, index: 0);
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:covariance"),
        types: [
          opaqueType(wrapper, [parameter]),
          opaqueType(reward, const []),
          subtypeOf(coin, reward),
        ],
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
    final wrapper = typeDefinition("SpecificVariable");
    final reward = typeDefinition("SpecificReward");
    final coin = typeDefinition("SpecificCoinReward");
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
        roles: [skir.PresentationRole.workspace],
        priority: 10,
      ),
      skir.PresentationDescriptor(
        id: base,
        owner: skir.DeclarationOwner.defaultInstance,
        target: baseTarget,
        roles: [skir.PresentationRole.workspace],
        priority: 100,
      ),
    ];
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: skir.CatalogGeneration(value: "catalog:specificity"),
        types: [
          opaqueType(wrapper, [parameter]),
          opaqueType(reward, const []),
          subtypeOf(coin, reward),
        ],
        presentations: descriptors,
        presentationMaterials: [
          for (final descriptor in descriptors)
            emptyWorkspaceMaterial(descriptor.id, descriptor.target, wrapper),
        ],
      ),
    );
    final selected = checked.selectPresentation(
      skir.TypeSelection.createComplete(
        definition: wrapper,
        arguments: [
          skir.TypeUse.createNamed(definition: coin, arguments: const []),
        ],
      ),
      skir.PresentationRole.workspace,
    );

    expect((selected as SelectedEditorPresentation).descriptor.id, exact);
  });

  test("dependent bounds wait for known arguments and validate together", () {
    final fixture = dependentParameterCatalog();
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
    final fixture = inheritedPresentationCatalog();
    final pending = fixture.catalog.beginSelection(fixture.root);

    final pendingBindings = fixture.catalog.endpointBindings(pending);
    expect(pendingBindings, hasLength(1));
    expect(pendingBindings.single.isAvailable, isFalse);

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
    final fixture = inheritedPresentationCatalog();

    expect(fixture.catalog.roleFallbackOrder(skir.PresentationRole.inspector), [
      skir.PresentationRole.inspector,
      skir.PresentationRole.workspace,
      skir.PresentationRole.referencePreview,
      skir.PresentationRole.resourceSearchResult,
    ]);
  });

  test("presentation selection uses fallback specificity then priority", () {
    final fixture = inheritedPresentationCatalog();
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
    expect(value.resolvedRole, skir.PresentationRole.workspace);
    expect(value.descriptor.id, fixture.rootPresentation);
    expect(value.material.provider, fixture.rootPresentation);
  });

  test("generic presentation remains available for a pending root", () {
    final fixture = inheritedPresentationCatalog();
    final pending = fixture.catalog.beginSelection(fixture.root);

    final selected = fixture.catalog.selectPresentation(
      pending,
      skir.PresentationRole.workspace,
    );

    expect(
      (selected as SelectedEditorPresentation).descriptor.id,
      fixture.rootPresentation,
    );
  });

  test("equal maximal presentation candidates report a conflict", () {
    final fixture = inheritedPresentationCatalog();
    final tie = skir.PresentationId(namespace: "test", name: "root_tie");
    final rootParameter = skir.ParameterKey(owner: fixture.root, index: 0);
    final target = skir.PresentationTarget.createNamed(
      definition: fixture.root,
      arguments: [skir.TypeTemplate.wrapParameter(rootParameter)],
    );
    final original = fixture.catalog.snapshot;
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: original.generation,
        types: original.types,
        relations: original.relations,
        presentations: [
          ...original.presentations,
          skir.PresentationDescriptor(
            id: tie,
            owner: skir.DeclarationOwner.defaultInstance,
            target: target,
            roles: [skir.PresentationRole.workspace],
            priority: 1,
          ),
        ],
        presentationMaterials: [
          ...original.presentationMaterials,
          emptyWorkspaceMaterial(tie, target, fixture.root),
        ],
        configuration: original.configuration,
        diagnostics: original.diagnostics,
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
      skir.PresentationRole.workspace,
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
      final fixture = repeatedParameterCatalog(repeated: false);

      final selected = fixture.catalog.selectPresentation(
        fixture.actual,
        skir.PresentationRole.workspace,
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
    final fixture = repeatedParameterCatalog(repeated: true);

    final selected = fixture.catalog.selectPresentation(
      fixture.actual,
      skir.PresentationRole.workspace,
    );

    expect(
      (selected as SelectedEditorPresentation).descriptor.id,
      fixture.first,
    );
  });
}
