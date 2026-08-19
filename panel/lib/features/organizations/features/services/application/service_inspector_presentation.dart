part of "services.dart";

const _serviceInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "service.inspector",
);
const _serviceRoleRepresentationBindingId = BindingId(57);

final _engineRoleColor = engineServiceRoleColor.asColorLiteral;
final _realmRoleColor = realmServiceRoleColor.asColorLiteral;
final _customRoleColor = customServiceRoleColor.asColorLiteral;

PresentationDefinition serviceInspectorPresentation(Service service) =>
    PresentationDefinition(
      id: _serviceInspectorPresentationId,
      target: NamedType(serviceInspectorTypeRef),
      root: PresentationNode(
        id: "service.inspector",
        element: ColumnElement(
          spacing: 16,
          crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
          children: [
            PresentationNode(
              id: "service.name",
              element: TextInputElement(
                control: BoundControl(
                  binding: serviceInspectorField("name"),
                  label: "Name".asStringLiteral,
                ),
                multiline: false,
                inputFormatters: identifierInputFormats,
              ),
            ),
            _serviceRoleListRow(),
          ],
        ),
      ),
    );

PresentationNode _serviceRoleListRow() => PresentationNode(
  id: "service.roles",
  properties: const PresentationProperties(readOnly: true),
  header: PresentationHeader(title: "Roles".asStringLiteral.asHeaderTitle),
  element: RepeatedElement(
    source: serviceInspectorExpression(
      "roles",
      ListType(element: NamedType(serviceRoleTypeRef)),
    ),
    itemBindingId: const BindingId(55),
    presentation: SequencePresentation(
      layout: PresentationSequenceLayout.children(
        PresentationChildrenLayout.column(spacing: 8),
      ),
      item: PresentationNode(
        id: "service.roles.value",
        element: PolymorphicMatchElement(
          binding: const BindingReference(bindingId: BindingId(55)),
          scopeBindingId: _serviceRoleRepresentationBindingId,
          cases: [
            PolymorphicMatchCase(
              type: engineRoleTypeRef,
              child: _serviceRoleSection(
                id: "service.roles.engine",
                title: "Engine",
                color: _engineRoleColor,
                fields: const ["version"],
              ),
            ),
            PolymorphicMatchCase(
              type: realmRoleTypeRef,
              child: _serviceRoleSection(
                id: "service.roles.realm",
                title: "Realm",
                color: _realmRoleColor,
                fields: const ["version"],
              ),
            ),
            PolymorphicMatchCase(
              type: customRoleTypeRef,
              child: _serviceRoleSection(
                id: "service.roles.custom",
                title: "Custom",
                color: _customRoleColor,
                fields: const ["name", "version"],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

PresentationNode _serviceRoleSection({
  required String id,
  required String title,
  required TypedExpression color,
  required List<String> fields,
}) => PresentationNode(
  id: id,
  properties: const PresentationProperties(readOnly: true),
  element: ContainerElement(
    backgroundColor: color.withAlpha(28),
    radius: PresentationRadius.medium(),
    child: PresentationNode(
      id: "$id.fields",
      header: PresentationHeader(
        title: PresentationHeaderNodeTitle(
          PresentationNode(
            id: "$id.title",
            element: TextElement(
              title.asStringLiteral,
              color: color,
              fontWeight: 700.asIntegerLiteral,
            ),
          ),
        ),
        headerPadding: .only(left: 12, top: 12, right: 12),
      ),
      element: ColumnElement(
        spacing: 8,
        crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
        children: [
          for (final field in fields)
            PresentationNode(
              id: "$id.$field",
              header: PresentationHeader(
                title: field.asStringLiteral.titleCase().asHeaderTitle,
              ),
              element: DefaultPresentationElement(
                binding: BindingReference(
                  bindingId: _serviceRoleRepresentationBindingId,
                  path: DataPath.root.field(field),
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);

BindingReference serviceInspectorField(String name) => BindingReference(
  bindingId: const BindingId(0),
  path: DataPath.root.field(name),
);

TypedExpression serviceInspectorExpression(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(serviceInspectorField(name)),
    );
