import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/document_builder.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";

/// One authored Page resource `page`, bound to portable expressions as the
/// input `resource`, the way a presentation of that resource sees it.
final boundPage = BoundPage._();

/// The resource, types and catalog [boundPage] describes.
final class BoundPage {
  BoundPage._();

  /// The bound resource.
  final resource = skir.ResourceId(value: "page");

  /// The input binding the resource is bound to.
  final binding = skir.ExpressionBindingId(value: "resource");

  /// The resource's configured type `test.Page`, a record with a text `name`.
  final type = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Page"),
    revision: 1,
  );

  /// A second record type `test.Other` without fields.
  final otherType = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Other"),
    revision: 1,
  );

  /// A budget no expression over the resource exhausts.
  final budget = skir.EvaluationBudget(
    maxSteps: 1000,
    maxCollectionItems: 1000,
  );

  /// The root of the resource's value.
  late final root = skir.ValueLocation(
    resource: resource,
    path: editorRootPath,
  );

  /// The expression inputs: the resource under [binding].
  Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings => {
    binding: resource.toExpressionBinding(),
  };

  /// The bound resource's identity as an expression.
  skir.ExpressionNode get identity =>
      skir.ExpressionNode.createInput(binding: binding, path: editorRootPath);

  /// The configured value of the bound resource read as a Page, or as
  /// `Page<String>` when [generic].
  skir.ExpressionNode valueOf({bool generic = false}) => portableCall(
    "resource.value_of",
    [identity],
    typeArguments: [
      skir.TypeTemplate.createNamed(
        definition: type,
        arguments: generic
            ? [skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)]
            : const [],
      ),
    ],
  );

  /// The published declaration of the bound resource's configured type.
  skir.ExpressionNode get declaration => portableCall("catalog.declaration", [
    portableCall("resource.configuration", [identity]),
  ]);

  /// A catalog publishing Page, Other and the resource id type. Page takes
  /// one parameter `T` when [generic], and shows a blue `page` icon display
  /// named "Page" unless [display] is false.
  CheckedEditorCatalog catalog({bool generic = false, bool display = true}) {
    final name = skir.FieldDeclaration(
      owner: skir.FieldOwner(definition: type, name: "name"),
      type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      overrides: const [],
      hasConstructorDefault: false,
    );
    final page = skir.TypeDefinition(
      id: type,
      parameters: generic
          ? [
              skir.TypeParameter(
                key: skir.ParameterKey(owner: type, index: 0),
                name: "T",
                bounds: const [],
              ),
            ]
          : const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: [name],
        abstract_: false,
      ),
      parents: const [],
    );
    final other = skir.TypeDefinition(
      id: otherType,
      parameters: const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: false,
      ),
      parents: const [],
    );
    final resourceId = skir.TypeDefinition(
      id: skir.resourceIdType.definition,
      parameters: const [],
      representation: skir.RepresentationTemplate.createScalar(
        kind: skir.ScalarKind.text,
      ),
      parents: const [],
    );
    return testCheckedCatalog(
      types: [
        declaredDefinition(
          page,
          display: display
              ? skir.TypeDisplay(
                  name: "Page",
                  description: "Page type",
                  icon: skir.Icon.wrapIconify("page"),
                  color: skir.Color(argb: 0xff336699.toSigned(32)),
                )
              : null,
        ),
        declaredDefinition(other),
        declaredDefinition(resourceId),
      ],
    );
  }

  /// A document over [catalog] holding the resource named [name], configured
  /// as a complete Page unless [configuration] says otherwise.
  AuthoringDocument document(
    CheckedEditorCatalog catalog,
    String name, {
    skir.TypeSelection? configuration,
  }) => AuthoringDocument(
    catalog: catalog,
    entries: {
      resource: skir.AuthoringResource(
        id: resource,
        content: skir.AuthoringRecord(
          configuration:
              configuration ??
              skir.TypeSelection.createComplete(
                definition: type,
                arguments: const [],
              ),
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue(name),
            ),
          ],
        ),
      ),
    },
    links: const [],
  );

  /// Evaluates [expression] over [bindings] against [catalog] and
  /// [document], and expects a value.
  PortableExpressionAvailable evaluate(
    CheckedEditorCatalog catalog,
    AuthoringDocument document,
    skir.ExpressionNode expression,
  ) {
    final result = PortableExpressionEvaluator.located(
      bindings,
      budget: budget,
      queries: PortableExpressionQueries(catalog: catalog, authored: document),
    ).evaluate(expression);
    expect(
      result,
      isA<PortableExpressionAvailable>(),
      reason: result is PortableExpressionFailed
          ? "${result.failure.value}: ${result.message}"
          : "$result",
    );
    return result as PortableExpressionAvailable;
  }
}

/// A ready link type [id] whose values point at a [target] resource through
/// the endpoint `target`.
skir.PublishedType linkType(
  skir.TypeDefinitionId id,
  skir.TypeDefinitionId target,
) => declaredDefinition(
  skir.TypeDefinition(
    id: id,
    parameters: const [],
    parents: const [],
    representation: skir.RepresentationTemplate.createLink(
      endpoint: skir.EndpointId(value: "target"),
      target: skir.TypeTemplate.createNamed(
        definition: target,
        arguments: const [],
      ),
    ),
  ),
);

/// An expression input holding a list of one [link] value, item `one`, that
/// points at [target] with the opposite field `reciprocal`.
PortableExpressionBinding linkListBinding(
  skir.TypeDefinitionId link,
  skir.ResourceId target,
) {
  final use = skir.NamedTypeUse(definition: link, arguments: const []);
  return PortableExpressionBinding(
    schema: CompletePortablePresentationBinding(
      skir.TypeUse.createNamed(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "typewriter",
            name: "List",
          ),
          revision: 1,
        ),
        arguments: [skir.TypeUse.wrapNamed(use)],
      ),
    ),
    value: skir.DataValue.createListValue(
      items: [
        skir.ListItem(
          id: skir.ItemId(value: "one"),
          value: skir.DataValue.createNamed(
            actualType: use,
            payload: skir.DataValue.createLink(
              endpoint: skir.EndpointId(value: "target"),
              target: skir.LinkTarget(
                resource: target,
                opposite: skir.ValuePath(
                  segments: [skir.PathSegment.createField(name: "reciprocal")],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
