import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "package:typewriter_testkit/typewriter_testkit.dart";

enum InheritedFieldVariant { inherited, localLabel, explicitControl, disabled }

/// A declared Element policy consumed by a custom Action inspector.
/// Owns mutable authored data so stories and tests use the real write adapter.
final class InheritedFieldPresentationScenario {
  InheritedFieldPresentationScenario({
    InheritedFieldVariant variant = InheritedFieldVariant.inherited,
    skir.PresentationNode? sourceName,
    skir.PresentationNode? layout,
    String referenceNodeId = "element.name",
    bool nestedOwners = false,
    skir.PresentationDependencies? sourceDependencies,
    skir.PresentationDependencies? customDependencies,
    skir.TypeTemplate? nameType,
    bool publishNameDefault = true,
    bool useSourceInspector = false,
    skir.DataValue? nameValue,
    List<skir.PublishedType> additionalTypes = const [],
  }) {
    final inherited =
        sourceName ??
        inheritedFieldTextInput(
          "element.name",
          control: inheritedFieldControl(label: "Name"),
          trim: true,
        );
    final request = variant == InheritedFieldVariant.explicitControl
        ? inheritedFieldTextInput(
            "action.name",
            control: inheritedFieldControl(label: "Exact name"),
          )
        : inheritedFieldRequest(
            control: inheritedFieldControl(
              label: variant == InheritedFieldVariant.localLabel
                  ? "Action name"
                  : null,
            ),
          );
    final actionLayout =
        layout ??
        inheritedFieldColumn([
          request,
          inheritedFieldTextInput(
            "action.message",
            control: inheritedFieldControl(field: "message", label: "Message"),
          ),
          inheritedFieldRemaining,
        ]);
    final baseLayout = nestedOwners
        ? inheritedFieldColumn([
            for (final field in ["first", "second"])
              presentationNode(
                "envelope.$field",
                skir.PresentationElement.wrapScopedBinding(
                  skir.ScopedBindingElement(
                    binding: skir.BindingRef(
                      bindingId: inheritedConfiguredValue,
                      path: editorRootPath.field(field),
                    ),
                    scopeBindingId: inheritedConfiguredValue,
                    child: actionLayout,
                  ),
                ),
              ),
          ])
        : actionLayout;
    final customLayout = variant == InheritedFieldVariant.disabled
        ? (baseLayout.toMutable()
                ..properties =
                    (skir.PresentationProperties.mutable()
                          ..enabledIf = skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapBoolean(false),
                          ))
                        .toFrozen())
              .toFrozen()
        : baseLayout;
    final source =
        (skir.PresentationMaterial.mutable()
              ..provider = _elementProvider
              ..target = _target(inheritedElementDefinition)
              ..subject = _template(inheritedElementDefinition)
              ..role = skir.PresentationRole.inspector
              ..layout = inherited
              ..dependencies =
                  sourceDependencies ??
                  skir.PresentationDependencies.defaultInstance
              ..inheritableNodes = [if (publishNameDefault) referenceNodeId])
            .toFrozen();
    final custom =
        (skir.PresentationMaterial.mutable()
              ..provider = _actionProvider
              ..target = _target(inheritedActionDefinition)
              ..subject = _template(inheritedActionDefinition)
              ..role = skir.PresentationRole.inspector
              ..layout = customLayout
              ..dependencies =
                  customDependencies ??
                  skir.PresentationDependencies.defaultInstance)
            .toFrozen();
    catalog = CheckedEditorCatalog(
      (skir.EditorCatalog.mutable()
            ..generation = skir.CatalogGeneration(
              value: "inherited field scenario",
            )
            ..types = [
              _published(
                inheritedElementDefinition,
                abstract: true,
                nameType: nameType,
              ),
              _published(inheritedActionDefinition, nameType: nameType),
              if (nestedOwners) _envelopePublished(),
              ...additionalTypes,
            ]
            ..presentations = [
              _descriptor(_elementProvider, inheritedElementDefinition),
              _descriptor(_actionProvider, inheritedActionDefinition),
            ]
            ..presentationMaterials = [source, custom])
          .toFrozen(),
    );
    value = skir.DataValue.createNamed(
      actualType: inheritedActionType,
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "name",
            value: nameValue ?? skir.DataValue.wrapStringValue("Welcome"),
          ),
          skir.FieldValue(
            name: "message",
            value: skir.DataValue.wrapStringValue("Hello player"),
          ),
        ],
      ),
    );
    if (nestedOwners) {
      value = skir.DataValue.createNamed(
        actualType: _envelopeType,
        payload: skir.DataValue.createRecord(
          fields: [
            skir.FieldValue(name: "first", value: value),
            skir.FieldValue(name: "second", value: value),
          ],
        ),
      );
    }
    host = BoundPresentationHost(
      catalog: catalog,
      root: () => useSourceInspector ? inherited : customLayout,
      role: skir.PresentationRole.inspector,
      material: useSourceInspector ? source : custom,
      bindings: [
        BoundPresentationBinding(
          id: inheritedConfiguredValue,
          use: skir.TypeUse.wrapNamed(
            nestedOwners ? _envelopeType : inheritedActionType,
          ),
          read: (path) => value.editorValueAt(path),
          write: (path, replacement) {
            final changed = value.replaceAt(path, replacement);
            if (changed case PortablePathValue<skir.DataValue>(
              value: final next,
            )) {
              value = next;
              writes.add((path, replacement));
              return const PortablePresentationWriteResult.applied();
            }
            return PortablePresentationWriteResult.rejected(const []);
          },
        ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    );
  }

  late final CheckedEditorCatalog catalog;
  late final BoundPresentationHost host;
  late skir.DataValue value;
  final writes = <(skir.ValuePath, skir.DataValue)>[];

  String? get name => value.authoredField("name")?.authoredString;

  void dispose() => host.dispose();
}

final inheritedConfiguredValue = skir.ExpressionBindingId(
  value: "configured_value",
);
final inheritedElementDefinition = _definition("Element");
final inheritedActionDefinition = _definition("Action");
final inheritedActionType = skir.NamedTypeUse(
  definition: inheritedActionDefinition,
  arguments: const [],
);
final _elementProvider = skir.PresentationId(
  namespace: "test",
  name: "element",
);
final _actionProvider = skir.PresentationId(namespace: "test", name: "action");

skir.BoundControl inheritedFieldControl({
  String field = "name",
  String? label,
  String? semanticLabel,
  skir.PresentationNode? prefix,
}) =>
    (skir.BoundControl.mutable()
          ..binding = skir.BindingRef(
            bindingId: inheritedConfiguredValue,
            path: editorRootPath.field(field),
          )
          ..label = label == null ? null : textLiteral(label)
          ..semanticLabel = semanticLabel == null
              ? null
              : textLiteral(semanticLabel)
          ..prefix = prefix)
        .toFrozen();

skir.PresentationNode inheritedFieldRequest({
  skir.BoundControl? control,
  String id = "action.name",
}) => presentationNode(
  id,
  skir.PresentationElement.createDefaultPresentation(
    control: control ?? inheritedFieldControl(),
    presentationId: null,
  ),
);

skir.PresentationNode inheritedFieldTextInput(
  String id, {
  required skir.BoundControl control,
  bool trim = false,
}) {
  final candidate = skir.ExpressionBindingId(value: "completion_candidate");
  return presentationNode(
    id,
    skir.PresentationElement.wrapTextInput(
      (skir.TextControl.mutable()
            ..control = control
            ..mappings = trim
                ? skir.ValueMappings(
                    display: null,
                    completion: skir.ExpressionMapping(
                      inputBinding: candidate,
                      body: portableCall("text.trim_start", [
                        portableCall("text.trim_end", [
                          skir.ExpressionNode.createInput(
                            binding: candidate,
                            path: editorRootPath,
                          ),
                        ]),
                      ]),
                    ),
                  )
                : null)
          .toFrozen(),
    ),
  );
}

skir.PresentationNode inheritedFieldColumn(
  List<skir.PresentationNode> children, {
  String id = "action.layout",
}) => presentationColumn(
  id,
  children,
  layout: skir.AxisChildrenLayout(
    spacing: 8,
    clipOverflow: false,
    mainAxisAlignment: skir.MainAxisAlignment.start,
    crossAxisAlignment: skir.CrossAxisAlignment.stretch,
  ),
);

final inheritedFieldRemaining = presentationNode(
  "action.remaining",
  skir.PresentationElement.wrapRemainingFields(
    skir.RemainingFieldsElement(excluded: const [], excludedParts: const []),
  ),
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test.inherited", name: name),
  revision: 1,
);
skir.TypeTemplate _template(skir.TypeDefinitionId id) =>
    skir.TypeTemplate.createNamed(definition: id, arguments: const []);
skir.PresentationTarget _target(skir.TypeDefinitionId id) =>
    skir.PresentationTarget.createNamed(definition: id, arguments: const []);
skir.PresentationDescriptor _descriptor(
  skir.PresentationId provider,
  skir.TypeDefinitionId type,
) =>
    (skir.PresentationDescriptor.mutable()
          ..id = provider
          ..target = _target(type)
          ..roles = [skir.PresentationRole.inspector])
        .toFrozen();

skir.PublishedType _published(
  skir.TypeDefinitionId id, {
  bool abstract = false,
  skir.TypeTemplate? nameType,
}) {
  final base = skir.NamedTypeTemplate(
    definition: inheritedElementDefinition,
    arguments: const [],
  );
  const names = ["name", "message"];
  final fields = [
    for (final name in names)
      skir.FieldDeclaration(
        owner: skir.FieldOwner(
          definition: inheritedElementDefinition,
          name: name,
        ),
        type: name == "name"
            ? nameType ?? skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)
            : skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        overrides: const [],
        hasConstructorDefault: false,
      ),
  ];
  return (skir.PublishedType.mutable()
        ..definition = skir.TypeDefinition(
          id: id,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: abstract ? fields : const [],
            abstract_: abstract,
          ),
          parents: abstract ? const [] : [base],
        )
        ..status = skir.DeclarationStatus.ready
        ..effectiveFields = [
          for (final field in fields)
            skir.EffectiveFieldTemplate(
              key: field.owner.name,
              owner: field.owner,
              type: field.type,
              rules: const [],
            ),
        ]
        ..ancestorTemplates = abstract ? const [] : [base])
      .toFrozen();
}

final _envelopeDefinition = _definition("Envelope");
final _envelopeType = skir.NamedTypeUse(
  definition: _envelopeDefinition,
  arguments: const [],
);

skir.PublishedType _envelopePublished() {
  final fields = [
    for (final name in ["first", "second"])
      skir.FieldDeclaration(
        owner: skir.FieldOwner(definition: _envelopeDefinition, name: name),
        type: _template(inheritedActionDefinition),
        overrides: const [],
        hasConstructorDefault: false,
      ),
  ];
  return (skir.PublishedType.mutable()
        ..definition = skir.TypeDefinition(
          id: _envelopeDefinition,
          parameters: const [],
          parents: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: fields,
            abstract_: false,
          ),
        )
        ..status = skir.DeclarationStatus.ready
        ..effectiveFields = [
          for (final field in fields)
            skir.EffectiveFieldTemplate(
              key: field.owner.name,
              owner: field.owner,
              type: field.type,
              rules: const [],
            ),
        ])
      .toFrozen();
}
