import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";

/// The binding a presentation reads its configured value through.
final configuredValueBinding = skir.ExpressionBindingId(
  value: "configured_value",
);

/// The complete selection of [definition] without type arguments.
skir.TypeSelection completeSelection(skir.TypeDefinitionId definition) =>
    selectionOfUse(
      skir.NamedTypeUse(definition: definition, arguments: const []),
    );

/// A reference to the field [field] of [binding].
skir.BindingRef fieldReference(
  skir.ExpressionBindingId binding,
  String field,
) => skir.BindingRef(
  bindingId: binding,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: field)]),
);

/// A control with default properties over the field [field] of [binding],
/// the configured value when absent.
skir.BoundControl fieldControl(
  String field, {
  skir.ExpressionBindingId? binding,
}) =>
    (skir.BoundControl.defaultInstance.toMutable()
          ..binding = fieldReference(binding ?? configuredValueBinding, field))
        .toFrozen();

/// A node showing [element], identified by the name of its element kind.
skir.PresentationNode elementNode(skir.PresentationElement element) =>
    presentationNode(element.kind.name, element);

/// A column of [children] with the default layout, identified by its
/// element kind.
skir.PresentationNode elementColumn(List<skir.PresentationNode> children) =>
    elementNode(
      skir.PresentationElement.wrapChildren(
        skir.ChildrenElement.wrapColumn(
          (skir.AxisChildrenElement.defaultInstance.toMutable()
                ..children = children.map(skir.AxisChild.wrapFixed))
              .toFrozen(),
        ),
      ),
    );

/// A text input node [id] editing [fieldControl] of [field].
skir.PresentationNode textFieldNode(
  String id, {
  String field = "name",
  skir.ExpressionBindingId? binding,
}) => presentationNode(
  id,
  skir.PresentationElement.wrapTextInput(
    (skir.TextControl.defaultInstance.toMutable()
          ..control = fieldControl(field, binding: binding))
        .toFrozen(),
  ),
);

/// A numeric input node editing the field [field] of [binding], identified
/// by its element kind.
skir.PresentationNode numericFieldNode(
  String field,
  skir.ExpressionBindingId binding,
) => elementNode(
  skir.PresentationElement.wrapNumericInput(
    (skir.NumericControl.defaultInstance.toMutable()
          ..control = fieldControl(field, binding: binding))
        .toFrozen(),
  ),
);

/// The part [key] as node [id], showing [body] when given.
skir.PresentationNode presentationPart(
  String id,
  skir.PresentationPartId key, [
  skir.PresentationNode? body,
]) => presentationNode(
  id,
  skir.PresentationElement.createPart(key: key, body: body),
);

/// Declares [id] without a type, for code that tracks authored addresses
/// and never reads binding types.
skir.BindingDeclaration untypedBinding(skir.ExpressionBindingId id) =>
    declareBinding(id, skir.TypeTemplate.unknown);

/// The inspector presentation [name] in [namespace] for the type [owner],
/// ranked by [priority].
skir.PresentationDescriptor inspectorDescriptor(
  String name,
  skir.TypeDefinitionId owner, {
  String namespace = "test",
  int priority = 0,
}) => skir.PresentationDescriptor(
  id: skir.PresentationId(namespace: namespace, name: name),
  owner: skir.DeclarationOwner.defaultInstance,
  target: skir.PresentationTarget.createNamed(
    definition: owner,
    arguments: const [],
  ),
  roles: [skir.PresentationRole.inspector],
  priority: priority,
);

/// The material of inspector [descriptor]: a column `root` of [nodes] whose
/// nodes [references] (else every node) subtypes may inherit.
skir.PresentationMaterial inspectorMaterial(
  skir.PresentationDescriptor descriptor,
  List<skir.PresentationNode> nodes, {
  List<String>? references,
}) => skir.PresentationMaterial(
  provider: descriptor.id,
  target: descriptor.target,
  role: skir.PresentationRole.inspector,
  subject: skir.TypeTemplate.wrapNamed(
    (descriptor.target as skir.PresentationTarget_namedWrapper).value,
  ),
  layout: presentationColumn("root", nodes),
  dependencies: skir.PresentationDependencies.defaultInstance,
  inheritableNodes: references ?? [for (final node in nodes) node.nodeId],
);

/// What a catalog's inspector shows for the complete selection of a type.
extension InspectorPresentations on CheckedEditorCatalog {
  /// The inspector presentation of the direct [field] of [owner].
  EditorFieldPresentationSelection inspectorField(
    skir.TypeDefinitionId owner,
    String field,
  ) => fieldPresentation(
    completeSelection(owner),
    field,
    skir.PresentationRole.inspector,
  );
}

/// The [role] material of presentation [provider] for the type [definition]
/// without type arguments, laying out [layout] with no inheritable nodes.
skir.PresentationMaterial typeMaterial(
  skir.PresentationId provider,
  skir.TypeDefinitionId definition,
  skir.PresentationRole role,
  skir.PresentationNode layout,
) => skir.PresentationMaterial(
  inheritableNodes: const [],
  provider: provider,
  target: skir.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  ),
  role: role,
  layout: layout,
  dependencies: skir.PresentationDependencies.defaultInstance,
  subject: skir.TypeTemplate.createNamed(
    definition: definition,
    arguments: const [],
  ),
);

/// Presentation [id] for the type [definition] without type arguments,
/// serving [roles] at the lowest priority.
skir.PresentationDescriptor typePresentation(
  skir.PresentationId id,
  skir.TypeDefinitionId definition,
  List<skir.PresentationRole> roles,
) => skir.PresentationDescriptor(
  id: id,
  owner: skir.DeclarationOwner.defaultInstance,
  target: skir.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  ),
  roles: roles,
  priority: 0,
);
