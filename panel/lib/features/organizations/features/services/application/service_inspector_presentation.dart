part of "services.dart";

const _serviceInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "service.inspector",
);

PresentationDefinition serviceInspectorPresentation(Service service) =>
    PresentationDefinition(
      id: _serviceInspectorPresentationId,
      target: NamedType(serviceInspectorTypeRef),
      root: PresentationNode(
        id: "service.inspector",
        header: PresentationHeader(
          title: "Service Details".asStringLiteral.asHeaderTitle,
        ),
        element: ColumnElement(
          spacing: 12,
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
            for (final field in const [
              ("version", "Version"),
              ("state", "State"),
              ("lastSeen", "Last seen"),
            ])
              PresentationNode(
                id: "service.${field.$1}",
                properties: const PresentationProperties(readOnly: true),
                header: PresentationHeader(
                  title: field.$2.asStringLiteral.asHeaderTitle,
                ),
                element: TextElement(
                  serviceInspectorExpression(field.$1, const StringType()),
                ),
              ),
          ],
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
