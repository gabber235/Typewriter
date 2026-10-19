import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../shared/editors/presentation_builders.dart";

import "inherited_field_presentation_fixture.dart";

enum InheritedInspectorLayoutVariant {
  childOrder,
  excludedHeading,
  replacedDetails,
}

/// Three declared inspector layers with mutable authored data and real writes.
final class InheritedInspectorLayoutScenario {
  InheritedInspectorLayoutScenario({
    InheritedInspectorLayoutVariant variant =
        InheritedInspectorLayoutVariant.childOrder,
    skir.PresentationNode? childLayout,
    skir.PresentationNode? familyLayout,
    skir.PresentationNode? sourceLayout,
    List<String>? childInheritableNodes,
    List<String>? familyInheritableNodes,
    List<String>? sourceInheritableNodes,
    skir.PresentationDependencies? childDependencies,
    skir.PresentationDependencies? familyDependencies,
    skir.PresentationDependencies? sourceDependencies,
  }) {
    final replacingDetails =
        variant == InheritedInspectorLayoutVariant.replacedDetails;
    final source =
        sourceLayout ??
        inheritedFieldColumn([
          inheritedFieldTextInput(
            "element.name",
            control: inheritedFieldControl(label: "Name"),
            trim: true,
          ),
          inspectorLayoutPart(
            "element.heading",
            inspectorHeadingPart,
            body: presentationText(
              "element.heading.body",
              textLiteral("Entry heading"),
            ),
          ),
          inspectorLayoutRemainder("element.remaining"),
        ], id: "element.layout");
    final family =
        familyLayout ??
        inheritedFieldColumn([
          if (replacingDetails)
            inspectorLayoutPart(
              "family.details",
              inspectorDetailsPart,
              body: inheritedFieldColumn([
                inheritedFieldRequest(
                  control: inheritedFieldControl(field: "name"),
                  id: "family.details.name",
                ),
                inheritedFieldRequest(
                  control: inheritedFieldControl(field: "placement"),
                  id: "family.details.placement",
                ),
              ], id: "family.details.body"),
            )
          else
            inheritedFieldRequest(
              control: inheritedFieldControl(field: "name"),
              id: "family.name",
            ),
          inspectorLayoutPart("family.heading", inspectorHeadingPart),
          inspectorLayoutRemainder("family.remaining"),
          if (!replacingDetails)
            inheritedFieldTextInput(
              "family.placement",
              control: inheritedFieldControl(
                field: "placement",
                label: "Placement",
              ),
            ),
        ], id: "family.layout");
    final child =
        childLayout ??
        inheritedFieldColumn([
          inheritedFieldRequest(
            control: inheritedFieldControl(field: "name"),
            id: "message.name",
          ),
          if (replacingDetails)
            inspectorLayoutPart(
              "message.details",
              inspectorDetailsPart,
              body: presentationText(
                "message.details.body",
                textLiteral("Details replaced"),
              ),
            )
          else if (variant != InheritedInspectorLayoutVariant.excludedHeading)
            inspectorLayoutPart("message.heading", inspectorHeadingPart),
          inheritedFieldTextInput(
            "message.message",
            control: inheritedFieldControl(field: "message", label: "Message"),
          ),
          inspectorLayoutRemainder(
            "message.remaining",
            excludedParts:
                variant == InheritedInspectorLayoutVariant.excludedHeading
                ? [inspectorHeadingPart]
                : const [],
          ),
        ], id: "message.layout");
    final sourceMaterial = _material(
      _elementProvider,
      inspectorElementDefinition,
      source,
      sourceInheritableNodes ??
          (sourceLayout == null
              ? [
                  "element.layout",
                  "element.name",
                  "element.heading",
                  "element.remaining",
                ]
              : const []),
      sourceDependencies,
    );
    final familyMaterial = _material(
      _familyProvider,
      inspectorFamilyDefinition,
      family,
      familyInheritableNodes ??
          (familyLayout == null
              ? [
                  "family.layout",
                  replacingDetails ? "family.details" : "family.name",
                  "family.heading",
                  "family.remaining",
                  if (!replacingDetails) "family.placement",
                ]
              : const []),
      familyDependencies,
    );
    final childMaterial = _material(
      _messageProvider,
      inspectorMessageDefinition,
      child,
      childInheritableNodes ??
          (childLayout == null
              ? [
                  "message.layout",
                  "message.name",
                  if (replacingDetails)
                    "message.details"
                  else if (variant !=
                      InheritedInspectorLayoutVariant.excludedHeading)
                    "message.heading",
                  "message.message",
                  "message.remaining",
                ]
              : const []),
      childDependencies,
    );
    final name = _field(inspectorElementDefinition, "name");
    final placement = _field(inspectorFamilyDefinition, "placement");
    final message = _field(inspectorMessageDefinition, "message");
    final other = _field(inspectorMessageDefinition, "other");
    catalog = CheckedEditorCatalog(
      (skir.EditorCatalogWireSnapshot.mutable()
            ..generation = skir.CatalogGeneration(value: "inherited inspector")
            ..types = [
              _published(inspectorElementDefinition, [name], [name], const []),
              _published(
                inspectorFamilyDefinition,
                [placement],
                [name, placement],
                [inspectorElementDefinition],
              ),
              _published(
                inspectorMessageDefinition,
                [message, other],
                [name, placement, message, other],
                [inspectorFamilyDefinition, inspectorElementDefinition],
              ),
            ]
            ..presentations = [
              _descriptor(_elementProvider, inspectorElementDefinition),
              _descriptor(_familyProvider, inspectorFamilyDefinition),
              _descriptor(_messageProvider, inspectorMessageDefinition),
            ]
            ..presentationMaterials = [
              sourceMaterial,
              familyMaterial,
              childMaterial,
            ])
          .toFrozen(),
    );
    value = skir.DataValue.createNamed(
      actualType: inspectorMessageType,
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "name",
            value: skir.DataValue.wrapStringValue("Welcome"),
          ),
          skir.FieldValue(
            name: "placement",
            value: skir.DataValue.wrapStringValue("10, 20"),
          ),
          skir.FieldValue(
            name: "message",
            value: skir.DataValue.wrapStringValue("Hello player"),
          ),
          skir.FieldValue(
            name: "other",
            value: skir.DataValue.wrapStringValue("Cooldown"),
          ),
        ],
      ),
    );
    host = BoundPresentationHost(
      catalog: catalog,
      root: () => child,
      role: skir.PresentationRole.inspector,
      material: childMaterial,
      bindings: [
        BoundPresentationBinding(
          id: inheritedConfiguredValue,
          use: skir.TypeUse.wrapNamed(inspectorMessageType),
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
      budget: skir.EvaluationBudget(maxSteps: 2000, maxCollectionItems: 1000),
    );
  }

  late final CheckedEditorCatalog catalog;
  late final BoundPresentationHost host;
  late skir.DataValue value;
  final writes = <(skir.ValuePath, skir.DataValue)>[];

  String? get name => value.authoredField("name")?.authoredString;

  void dispose() => host.dispose();
}

final inspectorElementDefinition = _definition("Element");
final inspectorFamilyDefinition = _definition("Family");
final inspectorMessageDefinition = _definition("Message");
final inspectorMessageType = skir.NamedTypeUse(
  definition: inspectorMessageDefinition,
  arguments: const [],
);
final inspectorHeadingPart = skir.PresentationPartId(
  owner: inspectorElementDefinition,
  name: "heading",
);
final inspectorDetailsPart = skir.PresentationPartId(
  owner: inspectorFamilyDefinition,
  name: "details",
);
final _elementProvider = skir.PresentationId(
  namespace: "test.layout",
  name: "element",
);
final _familyProvider = skir.PresentationId(
  namespace: "test.layout",
  name: "family",
);
final _messageProvider = skir.PresentationId(
  namespace: "test.layout",
  name: "message",
);

skir.PresentationNode inspectorLayoutPart(
  String id,
  skir.PresentationPartId key, {
  skir.PresentationNode? body,
}) => presentationNode(
  id,
  skir.PresentationElement.createPart(key: key, body: body),
);

skir.PresentationNode inspectorLayoutRemainder(
  String id, {
  List<String> excludedFields = const [],
  List<skir.PresentationPartId> excludedParts = const [],
}) => presentationNode(
  id,
  skir.PresentationElement.wrapRemainingFields(
    skir.RemainingFieldsElement(
      excluded: [
        for (final field in excludedFields)
          skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: field)],
          ),
      ],
      excludedParts: excludedParts,
    ),
  ),
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test.inspector", name: name),
  revision: 1,
);

skir.NamedTypeTemplate _named(skir.TypeDefinitionId id) =>
    skir.NamedTypeTemplate(definition: id, arguments: const []);

skir.PresentationTarget _target(skir.TypeDefinitionId id) =>
    skir.PresentationTarget.wrapNamed(_named(id));

skir.FieldDeclaration _field(skir.TypeDefinitionId owner, String name) =>
    skir.FieldDeclaration(
      owner: skir.FieldOwner(definition: owner, name: name),
      type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      overrides: const [],
      hasConstructorDefault: false,
    );

skir.PublishedType _published(
  skir.TypeDefinitionId id,
  List<skir.FieldDeclaration> own,
  List<skir.FieldDeclaration> effective,
  List<skir.TypeDefinitionId> ancestors,
) =>
    (skir.PublishedType.mutable()
          ..definition = skir.TypeDefinition(
            id: id,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: own,
              abstract_: id != inspectorMessageDefinition,
            ),
            parents: ancestors.isEmpty ? const [] : [_named(ancestors.first)],
          )
          ..status = skir.DeclarationStatus.ready
          ..effectiveFields = [
            for (final field in effective)
              skir.EffectiveFieldTemplate(
                key: field.owner.name,
                owner: field.owner,
                type: field.type,
                rules: const [],
              ),
          ]
          ..ancestorTemplates = ancestors.map(_named).toList())
        .toFrozen();

skir.PresentationDescriptor _descriptor(
  skir.PresentationId provider,
  skir.TypeDefinitionId owner,
) =>
    (skir.PresentationDescriptor.mutable()
          ..id = provider
          ..target = _target(owner)
          ..roles = [skir.PresentationRole.inspector])
        .toFrozen();

skir.PresentationMaterial _material(
  skir.PresentationId provider,
  skir.TypeDefinitionId owner,
  skir.PresentationNode layout,
  List<String> membership,
  skir.PresentationDependencies? dependencies,
) =>
    (skir.PresentationMaterial.mutable()
          ..provider = provider
          ..target = _target(owner)
          ..subject = skir.TypeTemplate.wrapNamed(_named(owner))
          ..role = skir.PresentationRole.inspector
          ..layout = layout
          ..inheritableNodes = membership
          ..dependencies =
              dependencies ?? skir.PresentationDependencies.defaultInstance)
        .toFrozen();
