import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("nested named fields use the rule subject representation", () {
    final fixture = _nestedRuleFixture();

    final projection = AuthoredRuleProjection.evaluate(
      draft: fixture.draft,
      catalog: fixture.catalog,
      resource: fixture.resource,
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
    );

    expect(projection.diagnostics, hasLength(1));
    expect(projection.diagnostics.single.code, "positive");
    expect(
      projection.diagnostics.single.location,
      types.ValueLocation(
        resource: fixture.resource,
        path: types.ValuePath(
          segments: [
            types.PathSegment.createField(name: "placement"),
            types.PathSegment.createField(name: "width"),
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
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
    );

    expect(projection.diagnostics, hasLength(1));
    expect(projection.diagnostics.single.code, "positive");
    expect(projection.diagnostics.single.location.path.segments, [
      types.PathSegment.createField(name: "placements"),
      types.PathSegment.createItem(id: types.ItemId(value: "first")),
      types.PathSegment.createField(name: "width"),
    ]);
  });
}

({types.ResourceId resource, AuthoredDraft draft, CheckedEditorCatalog catalog})
_nestedRuleFixture({bool collection = false}) {
  final generation = types.CatalogGeneration(value: "catalog:nested_rules");
  final tag = _definition("Tag");
  final placement = _definition("GraphPlacement");
  final placementList = _definition("GraphPlacementList");
  final rootFieldName = collection ? "placements" : "placement";
  final placementOwner = types.FieldOwner(definition: tag, name: rootFieldName);
  final widthOwner = types.FieldOwner(definition: placement, name: "width");
  final placementTemplate = types.TypeTemplate.createNamed(
    definition: placement,
    arguments: const [],
  );
  final placementListTemplate = types.TypeTemplate.createNamed(
    definition: placementList,
    arguments: const [],
  );
  final integer = types.TypeTemplate.wrapScalar(
    types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
  );
  final ruleOrigin = types.RuleOrigin(
    owner: collection ? tag : placement,
    ordinal: 0,
  );
  final ruleId = types.RuleId(origin: ruleOrigin, localIndex: 0);
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        _publishedRecord(
          definition: tag,
          fields: [
            types.FieldDeclaration(
              owner: placementOwner,
              type: collection ? placementListTemplate : placementTemplate,
              overrides: const [],
              hasConstructorDefault: false,
            ),
          ],
          effectiveFields: [
            catalog.EffectiveFieldTemplate(
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
            types.FieldDeclaration(
              owner: widthOwner,
              type: integer,
              overrides: const [],
              hasConstructorDefault: false,
            ),
          ],
          effectiveFields: [
            catalog.EffectiveFieldTemplate(
              key: "width",
              owner: widthOwner,
              type: integer,
              rules: [ruleId],
            ),
          ],
        ),
        if (collection)
          catalog.PublishedType(
            display: null,
            definition: types.TypeDefinition(
              id: placementList,
              parameters: const [],
              representation: types.RepresentationTemplate.createSequence(
                item: placementTemplate,
                kind: types.CollectionKind.list,
              ),
              parents: const [],
            ),
            status: catalog.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: const [],
          ),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: [
        catalog.ConfigurationRecipe(
          origin: ruleOrigin,
          relativePath: types.RelativeFieldPattern(
            segments: collection
                ? [
                    types.FieldPatternSegment.createField(name: "placements"),
                    types.FieldPatternSegment.items,
                    types.FieldPatternSegment.createField(name: "width"),
                  ]
                : [types.FieldPatternSegment.createField(name: "width")],
          ),
          representationCondition: catalog.RepresentationKind.integer,
          rules: [
            catalog.OwnedRule(
              id: ruleId,
              descriptor: catalog.RuleDescriptor(
                predicate: expression.ExpressionNode.createCall(
                  operation: types.OperationId(
                    value: "typewriter.rule.positive",
                  ),
                  arguments: [
                    expression.ExpressionNode.createRead(
                      binding: types.ExpressionBindingId(
                        value: "configured_value",
                      ),
                      path: types.ValuePath(segments: const []),
                    ),
                  ],
                ),
              ),
              diagnostic: diagnostic.DiagnosticTemplate(
                code: "positive",
                message: "Must be positive",
                severity: diagnostic.DiagnosticSeverity.error,
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
  final resource = types.ResourceId(value: "tag:nested_rules");
  final placementUse = types.NamedTypeUse(
    definition: placement,
    arguments: const [],
  );
  final draft = AuthoredDraft(
    generation: generation,
    resources: [
      authoring.AuthoringResource(
        id: resource,
        definition: catalog.ResourceDefinitionId(value: "test.tag"),
        content: types.AuthoringRecord(
          configuration: types.TypeSelection.createComplete(
            definition: tag,
            arguments: const [],
          ),
          fields: [
            types.FieldValue(
              name: rootFieldName,
              value: collection
                  ? types.DataValue.createNamed(
                      actualType: types.NamedTypeUse(
                        definition: placementList,
                        arguments: const [],
                      ),
                      payload: types.DataValue.createListValue(
                        items: [
                          types.ListItem(
                            id: types.ItemId(value: "first"),
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

types.DataValue _placementValue(types.NamedTypeUse use) =>
    types.DataValue.createNamed(
      actualType: use,
      payload: types.DataValue.createRecord(
        fields: [
          types.FieldValue(
            name: "width",
            value: types.DataValue.wrapInteger("0"),
          ),
        ],
      ),
    );

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

catalog.PublishedType _publishedRecord({
  required types.TypeDefinitionId definition,
  required List<types.FieldDeclaration> fields,
  required List<catalog.EffectiveFieldTemplate> effectiveFields,
}) => catalog.PublishedType(
  display: null,
  definition: types.TypeDefinition(
    id: definition,
    parameters: const [],
    representation: types.RepresentationTemplate.createRecord(
      fields: fields,
      abstract_: false,
    ),
    parents: const [],
  ),
  status: catalog.DeclarationStatus.ready,
  effectiveFields: effectiveFields,
  ancestorTemplates: const [],
);
