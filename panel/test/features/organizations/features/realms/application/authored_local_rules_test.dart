import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("nested named fields use the rule subject representation", () {
    final fixture = _nestedRuleFixture();

    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    expect(projection.diagnostics, hasLength(1));
    expect(projection.diagnostics.single.code, "positive");
    expect(
      projection.diagnostics.single.origin,
      fixture.catalog.snapshot.configuration.single.origin,
    );
    expect(
      (projection.diagnostics.single.targets.single
              as PortableValueDiagnosticTarget)
          .location,
      skir.ValueLocation(
        resource: fixture.resource,
        path: skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "placement"),
            skir.PathSegment.createField(name: "width"),
          ],
        ),
      ),
    );
  });

  test("collection patterns use each expanded item field representation", () {
    final fixture = _nestedRuleFixture(collection: true);

    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    expect(projection.diagnostics, hasLength(1));
    expect(projection.diagnostics.single.code, "positive");
    expect(
      (projection.diagnostics.single.targets.single
              as PortableValueDiagnosticTarget)
          .location
          .path
          .segments,
      [
        skir.PathSegment.createField(name: "placements"),
        skir.PathSegment.createItem(id: skir.ItemId(value: "first")),
        skir.PathSegment.createField(name: "width"),
      ],
    );
  });

  test(
    "an explicit target on another field resolves from the nested owner",
    () {
      final fixture = _nestedRuleFixture(
        targets: [
          skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: "height")],
          ),
        ],
      );
      final projection = AuthoredRuleProjection.evaluate(
        draft: fixture.draft,
        catalog: fixture.catalog,
        resource: fixture.resource,
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      );

      expect(projection.diagnostics.single.targets, [
        PortableDiagnosticTarget.value(
          skir.ValueLocation(
            resource: fixture.resource,
            path: editorRootPath.field("placement").field("height"),
          ),
        ),
      ]);
    },
  );

  test("a rule without explicit targets remains on its matched subject", () {
    final fixture = _nestedRuleFixture(targets: const []);
    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    expect(projection.diagnostics.single.targets, [
      PortableDiagnosticTarget.value(
        skir.ValueLocation(
          resource: fixture.resource,
          path: editorRootPath.field("placement").field("width"),
        ),
      ),
    ]);
  });
  test(
    "unknown root configuration does not become a partial presentation binding",
    () {
      final fixture = _nestedRuleFixture();
      final record = fixture.draft.resource(fixture.resource)!;
      final observation = AuthoringDocument(
        catalog: fixture.catalog,
        entries: {
          fixture.resource: skir.AuthoringResource(
            id: fixture.resource,
            definition: skir.ResourceDefinitionId(value: "test.tag"),
            content: skir.AuthoringRecord(
              configuration: skir.TypeSelection.unknown,
              fields: record.fields,
            ),
          ),
        },
        links: const [],
      );
      final host = AuthoredPresentationHost(
        resource: fixture.resource,
        source: observation,
        material: skir.PresentationMaterial.defaultInstance,
        role: skir.PresentationRole.editor,
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        capabilities: const PortablePresentationCapabilities(),
      );
      addTearDown(host.dispose);
      final document = host.document;
      expect(document.bindings.containsKey(configuredValueBindingId), isFalse);
      expect(
        document.bindings[presentationSubjectIdentifierBindingId]!.value,
        fixture.resource.toExpressionValue(),
      );
      expect(
        document.bindings[presentationSubjectIdentifierBindingId]!.schema,
        CompletePortablePresentationBinding(
          skir.TypeUse.wrapNamed(frameworkResourceIdUse),
        ),
      );
      expect(
        document.diagnostics
            .where((finding) => finding.code == "pending_type")
            .single
            .targets,
        [
          PortableDiagnosticTarget.value(
            skir.ValueLocation(
              resource: fixture.resource,
              path: editorRootPath,
            ),
          ),
        ],
      );
      expect(
        document.diagnostics
            .where((finding) => finding.code == "positive")
            .single
            .targets,
        [
          PortableDiagnosticTarget.value(
            skir.ValueLocation(
              resource: fixture.resource,
              path: editorRootPath.field("placement").field("width"),
            ),
          ),
        ],
      );
    },
  );

  test("resource projections retain located initialization findings alongside rules", () {
    final fixture = _nestedRuleFixture();
    final observation = AuthoringDocument(
      catalog: fixture.catalog,
      entries: {
        fixture.resource: skir.AuthoringResource(
          id: fixture.resource,
          definition: skir.ResourceDefinitionId(value: "test.tag"),
          content: fixture.draft.resource(fixture.resource)!,
        ),
      },
      links: const [],
      initializationFindings: [
        LocatedInitializationFinding(
          location: skir.ValueLocation(
            resource: fixture.resource,
            path: editorRootPath.field("otherResourceField"),
          ),
          evidence: skir.DiagnosticEvidence(
            catalog: fixture.draft.generation,
            expectations: [
              skir.EditExpectation.createResource(
                id: fixture.resource,
                expected: fixture.draft.resource(fixture.resource),
              ),
            ],
          ),
          diagnostic: skir.InitializationDiagnostic(
            field: null,
            code: "initialization_pending",
            message: "A default could not be prepared",
            relativePath: editorRootPath.field("otherResourceField"),
          ),
        ),
      ],
    );
    final host = AuthoredPresentationHost(
      resource: fixture.resource,
      source: observation,
      material: skir.PresentationMaterial.defaultInstance,
      role: skir.PresentationRole.editor,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      capabilities: const PortablePresentationCapabilities(),
    );
    addTearDown(host.dispose);
    final document = host.document;
    expect(
      host.projectResource(
        fixture.resource,
        context: PortableInvocationContext(
          catalogGeneration: document.catalog.snapshot.generation,
          bindings: const {},
        ),
      ),
      isNull,
    );
    final projected = host.projectResource(
      fixture.resource,
      context: PortableInvocationContext(
        catalogGeneration: document.catalog.snapshot.generation,
        bindings: const {},
        queries: document.queries,
        resourceDiagnostics: document.resourceDiagnostics,
      ),
    );
    expect(document.diagnostics, hasLength(2));
    expect(projected!.diagnostics, document.diagnostics);
    expect(document.diagnosticFallback, PortableDiagnosticFallback.resource);
    expect(projected.diagnosticFallback, PortableDiagnosticFallback.resource);
    final initialization = document.diagnostics.last;
    expect(initialization.code, "initialization_pending");
    expect(initialization.message, "A default could not be prepared");
    expect(initialization.targets, [
      PortableDiagnosticTarget.value(
        skir.ValueLocation(
          resource: fixture.resource,
          path: editorRootPath.field("otherResourceField"),
        ),
      ),
    ]);
    expect(initialization.severity, skir.DiagnosticSeverity.warning);
    expect(document.diagnostics.first.targets, [
      PortableDiagnosticTarget.value(
        skir.ValueLocation(
          resource: fixture.resource,
          path: editorRootPath.field("placement").field("width"),
        ),
      ),
    ]);
  });

  test("diagnostic templates preserve concrete missing fields and deduplicate targets", () {
    final origin = skir.ValueLocation(
      resource: skir.ResourceId(value: "owner"),
      path: editorRootPath.field("subject"),
    );
    final diagnostic = skir.DiagnosticTemplate(
      code: "related",
      message: "Fix related fields",
      severity: skir.DiagnosticSeverity.warning,
      targets: [
        for (var repeat = 0; repeat < 2; repeat++)
          skir.RelativeFieldPattern(
            segments: [
              skir.FieldPatternSegment.createField(name: "missing"),
              skir.FieldPatternSegment.createField(name: "child"),
            ],
          ),
      ],
    );
    expect(
      skir.ConfigurationRecipe.defaultInstance.resolveDiagnosticTargets(
        diagnostic,
        ownerValue: skir.DataValue.createRecord(fields: const []),
        owner: origin,
        subject: skir.ValueLocation(
          resource: origin.resource,
          path: origin.path.field("checked"),
        ),
      ),
      [
        PortableDiagnosticTarget.value(
          skir.ValueLocation(
            resource: origin.resource,
            path: origin.path.field("missing").field("child"),
          ),
        ),
      ],
    );
  });

  test("diagnostic wildcards retain stable item and map branch addresses", () {
    final origin = skir.ValueLocation(
      resource: skir.ResourceId(value: "owner"),
      path: editorRootPath,
    );
    final first = skir.ItemId(value: "first");
    final second = skir.ItemId(value: "second");
    final value = skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "items",
          value: skir.DataValue.createListValue(
            items: [
              skir.ListItem(id: second, value: skir.DataValue.unfilled),
              skir.ListItem(id: first, value: skir.DataValue.unfilled),
            ],
          ),
        ),
        skir.FieldValue(
          name: "map",
          value: skir.DataValue.createMapValue(
            rows: [
              skir.MapRow(
                id: first,
                key: skir.DataValue.unfilled,
                value: skir.DataValue.unfilled,
              ),
            ],
          ),
        ),
      ],
    );
    final diagnostic = skir.DiagnosticTemplate(
      code: "related",
      message: "Fix related fields",
      severity: skir.DiagnosticSeverity.error,
      targets: [
        skir.RelativeFieldPattern(
          segments: [
            skir.FieldPatternSegment.createField(name: "items"),
            skir.FieldPatternSegment.items,
          ],
        ),
        for (final branch in [
          skir.FieldPatternSegment.keys,
          skir.FieldPatternSegment.values,
        ])
          skir.RelativeFieldPattern(
            segments: [
              skir.FieldPatternSegment.createField(name: "map"),
              branch,
            ],
          ),
      ],
    );
    final paths = skir.ConfigurationRecipe.defaultInstance
        .resolveDiagnosticTargets(
          diagnostic,
          ownerValue: value,
          owner: origin,
          subject: origin,
        )
        .cast<PortableValueDiagnosticTarget>()
        .map((target) => target.location.path)
        .toList();
    expect(paths, [
      for (final id in [second, first])
        skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "items"),
            skir.PathSegment.createItem(id: id),
          ],
        ),
      for (final branch in [skir.PathSegment.mapKey, skir.PathSegment.mapValue])
        skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "map"),
            skir.PathSegment.createItem(id: first),
            branch,
          ],
        ),
    ]);
  });

  test("empty wildcard diagnostics retain their collection owner", () {
    final origin = skir.ValueLocation(
      resource: skir.ResourceId(value: "owner"),
      path: editorRootPath,
    );
    final diagnostic = skir.DiagnosticTemplate(
      code: "empty",
      message: "Needs an item",
      severity: skir.DiagnosticSeverity.error,
      targets: [
        skir.RelativeFieldPattern(segments: [skir.FieldPatternSegment.items]),
      ],
    );
    expect(
      skir.ConfigurationRecipe.defaultInstance.resolveDiagnosticTargets(
        diagnostic,
        ownerValue: skir.DataValue.createListValue(items: const []),
        owner: origin,
        subject: origin,
      ),
      [PortableDiagnosticTarget.value(origin)],
    );
  });
}

({skir.ResourceId resource, AuthoringEdit draft, CheckedEditorCatalog catalog})
_nestedRuleFixture({
  bool collection = false,
  List<skir.RelativeFieldPattern>? targets,
}) {
  final generation = skir.CatalogGeneration(value: "catalog:nested_rules");
  final tag = _definition("Tag");
  final placement = _definition("GraphPlacement");
  final placementList = _definition("GraphPlacementList");
  final rootFieldName = collection ? "placements" : "placement";
  final placementOwner = skir.FieldOwner(definition: tag, name: rootFieldName);
  final widthOwner = skir.FieldOwner(definition: placement, name: "width");
  final placementTemplate = skir.TypeTemplate.createNamed(
    definition: placement,
    arguments: const [],
  );
  final placementListTemplate = skir.TypeTemplate.createNamed(
    definition: placementList,
    arguments: const [],
  );
  final integer = skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
  );
  final ruleOrigin = skir.RuleOrigin(
    owner: collection ? tag : placement,
    ordinal: 0,
  );
  final ruleId = skir.RuleId(origin: ruleOrigin, localIndex: 0);
  final subjectPattern = skir.RelativeFieldPattern(
    segments: collection
        ? [
            skir.FieldPatternSegment.createField(name: "placements"),
            skir.FieldPatternSegment.items,
            skir.FieldPatternSegment.createField(name: "width"),
          ]
        : [skir.FieldPatternSegment.createField(name: "width")],
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      resourceOperations: const [],
      resourceOperationContributions: const [],
      generation: generation,
      types: [
        _publishedRecord(
          definition: tag,
          fields: [
            skir.FieldDeclaration(
              owner: placementOwner,
              type: collection ? placementListTemplate : placementTemplate,
              overrides: const [],
              hasConstructorDefault: false,
            ),
          ],
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: rootFieldName,
              owner: placementOwner,
              type: collection ? placementListTemplate : placementTemplate,
              rules: const [],
            ),
          ],
        ),
        _publishedRecord(
          definition: placement,
          fields: [
            skir.FieldDeclaration(
              owner: widthOwner,
              type: integer,
              overrides: const [],
              hasConstructorDefault: false,
            ),
          ],
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: "width",
              owner: widthOwner,
              type: integer,
              rules: [ruleId],
            ),
          ],
        ),
        if (collection)
          skir.PublishedType(
            display: null,
            definition: skir.TypeDefinition(
              id: placementList,
              parameters: const [],
              representation: skir.RepresentationTemplate.createSequence(
                item: placementTemplate,
                kind: skir.CollectionKind.list,
              ),
              parents: const [],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: const [],
          ),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: [
        skir.ConfigurationRecipe(
          origin: ruleOrigin,
          relativePath: subjectPattern,
          representationCondition: skir.RepresentationKind.integer,
          rules: [
            skir.OwnedRule(
              id: ruleId,
              descriptor: skir.RuleDescriptor(
                predicate: skir.ExpressionNode.createCall(
                  operation: skir.OperationId(
                    value: "typewriter.rule.positive",
                  ),
                  arguments: [
                    skir.ExpressionNode.createRead(
                      binding: skir.ExpressionBindingId(
                        value: "configured_value",
                      ),
                      path: skir.ValuePath(segments: const []),
                    ),
                  ],
                ),
              ),
              diagnostic: skir.DiagnosticTemplate(
                code: "positive",
                message: "Must be positive",
                severity: skir.DiagnosticSeverity.error,
                targets: targets ?? [subjectPattern],
              ),
            ),
          ],
        ),
      ],
      diagnostics: const [],

      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final resource = skir.ResourceId(value: "tag:nested_rules");
  final placementUse = skir.NamedTypeUse(
    definition: placement,
    arguments: const [],
  );
  final draft = AuthoringEdit(
    generation: generation,
    resources: [
      skir.AuthoringResource(
        id: resource,
        definition: skir.ResourceDefinitionId(value: "test.tag"),
        content: skir.AuthoringRecord(
          configuration: skir.TypeSelection.createComplete(
            definition: tag,
            arguments: const [],
          ),
          fields: [
            skir.FieldValue(
              name: rootFieldName,
              value: collection
                  ? skir.DataValue.createNamed(
                      actualType: skir.NamedTypeUse(
                        definition: placementList,
                        arguments: const [],
                      ),
                      payload: skir.DataValue.createListValue(
                        items: [
                          skir.ListItem(
                            id: skir.ItemId(value: "first"),
                            value: _placementValue(placementUse),
                          ),
                          skir.ListItem(
                            id: skir.ItemId(value: "second"),
                            value: _placementValue(placementUse, width: "1"),
                          ),
                        ],
                      ),
                    )
                  : _placementValue(placementUse),
            ),
          ],
        ),
      ),
    ],
    links: const [],
    catalog: checked,
  );
  return (resource: resource, draft: draft, catalog: checked);
}

skir.DataValue _placementValue(skir.NamedTypeUse use, {String width = "0"}) =>
    skir.DataValue.createNamed(
      actualType: use,
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "width",
            value: skir.DataValue.wrapInteger(width),
          ),
        ],
      ),
    );

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

skir.PublishedType _publishedRecord({
  required skir.TypeDefinitionId definition,
  required List<skir.FieldDeclaration> fields,
  required List<skir.EffectiveFieldTemplate> effectiveFields,
}) => skir.PublishedType(
  display: null,
  definition: skir.TypeDefinition(
    id: definition,
    parameters: const [],
    representation: skir.RepresentationTemplate.createRecord(
      fields: fields,
      abstract_: false,
    ),
    parents: const [],
  ),
  status: skir.DeclarationStatus.ready,
  effectiveFields: effectiveFields,
  ancestorTemplates: const [],
);
