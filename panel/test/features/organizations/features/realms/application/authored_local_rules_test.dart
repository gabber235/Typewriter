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

    final finding = projection.checks.single.findings.single;
    expect(finding.code, "positive");
    expect(
      finding.origin,
      fixture.catalog.snapshot.configuration.single.origin,
    );
    expect(finding.related, isEmpty);
    expect(
      finding.primary,
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

    expect([
      for (final check in projection.checks) check.outcome,
    ], everyElement(skir.CheckOutcome.finished));
    final finding = projection.checks.expand((check) => check.findings).single;
    expect(finding.code, "positive");
    expect(finding.related, isEmpty);
    expect(finding.primary!.path.segments, [
      skir.PathSegment.createField(name: "placements"),
      skir.PathSegment.createItem(id: skir.ItemId(value: "first")),
      skir.PathSegment.createField(name: "width"),
    ]);
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

      final finding = projection.checks.single.findings.single;
      expect(
        finding.primary,
        skir.ValueLocation(
          resource: fixture.resource,
          path: editorRootPath.field("placement").field("height"),
        ),
      );
      expect(finding.related, isEmpty);
    },
  );

  test("a rule that needs type facts evaluates against the catalog", () {
    // The subject is an int32, so a rule requiring text fails it; without
    // the catalog's type facts the rule could not run at all.
    final fixture = _nestedRuleFixture(
      predicate: portableCall(
        "value.instance_of",
        [
          skir.ExpressionNode.createInput(
            binding: configuredValueBindingId,
            path: editorRootPath,
          ),
        ],
        typeArguments: [skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)],
      ),
    );
    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    final check = projection.checks.single;
    expect(check.outcome, skir.CheckOutcome.finished);
    expect(check.findings.single.code, "positive");
  });

  test("a rule without explicit targets remains on its matched subject", () {
    final fixture = _nestedRuleFixture(targets: const []);
    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );

    final finding = projection.checks.single.findings.single;
    expect(
      finding.primary,
      skir.ValueLocation(
        resource: fixture.resource,
        path: editorRootPath.field("placement").field("width"),
      ),
    );
    expect(finding.related, isEmpty);
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
        role: skir.PresentationRole.workspace,
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
          skir.TypeUse.wrapNamed(skir.resourceIdType),
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
      role: skir.PresentationRole.workspace,
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
}

({skir.ResourceId resource, AuthoringEdit draft, CheckedEditorCatalog catalog})
_nestedRuleFixture({
  bool collection = false,
  List<skir.RelativeFieldPattern>? targets,
  skir.ExpressionNode? predicate,
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
    skir.EditorCatalog(
      resourceDisplays: const [],
      resourceOperations: const [],
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
            searchKey: null,
            placementField: null,
            display: defaultTypeDisplay(""),
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
      realmRoot: skir.TypeDefinitionId.defaultInstance,
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
                predicate:
                    predicate ??
                    portableCall("value.equals", [
                      portableCall("value.compare", [
                        skir.ExpressionNode.createInput(
                          binding: skir.ExpressionBindingId(
                            value: "configured_value",
                          ),
                          path: skir.ValuePath(segments: const []),
                        ),
                        skir.ExpressionNode.wrapLiteral(
                          skir.DataValue.wrapInteger("0"),
                        ),
                      ]),
                      skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapInteger("1"),
                      ),
                    ]),
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
  searchKey: null,
  placementField: null,
  display: defaultTypeDisplay(""),
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
