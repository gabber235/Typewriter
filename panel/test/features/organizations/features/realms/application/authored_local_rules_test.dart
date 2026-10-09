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
      projection.diagnostics.single.location,
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
    expect(projection.diagnostics.single.location.path.segments, [
      skir.PathSegment.createField(name: "placements"),
      skir.PathSegment.createItem(id: skir.ItemId(value: "first")),
      skir.PathSegment.createField(name: "width"),
    ]);
  });
}

({skir.ResourceId resource, AuthoringEdit draft, CheckedEditorCatalog catalog})
_nestedRuleFixture({bool collection = false}) {
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
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
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
          relativePath: skir.RelativeFieldPattern(
            segments: collection
                ? [
                    skir.FieldPatternSegment.createField(name: "placements"),
                    skir.FieldPatternSegment.items,
                    skir.FieldPatternSegment.createField(name: "width"),
                  ]
                : [skir.FieldPatternSegment.createField(name: "width")],
          ),
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
                targets: const [],
              ),
            ),
          ],
        ),
      ],
      diagnostics: const [],
      initialization: const [],
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

skir.DataValue _placementValue(skir.NamedTypeUse use) =>
    skir.DataValue.createNamed(
      actualType: use,
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "width",
            value: skir.DataValue.wrapInteger("0"),
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
