part of "services.dart";

const _serviceInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "service.inspector",
);

PresentationDefinition serviceInspectorPresentation(Service service) =>
    PresentationDefinition(
      id: _serviceInspectorPresentationId,
      inputs: [
        PresentationInputParameter(
          id: const BindingId(0),
          name: "runtime",
          type: NamedType(serviceInspectorTypeRef),
        ),
        PresentationInputParameter(
          id: const BindingId(1),
          name: "identity",
          type: _serviceIdentityType,
          access: PresentationInputAccess.edit,
        ),
      ],
      root: PresentationNode(
        id: "service.inspector",
        element: ColumnElement(
          spacing: _dashboardSectionSpacing,
          crossAxisAlignment: PresentationCrossAxisAlignment.start,
          children: [
            _dashboardSection(
              id: "service.details",
              title: "Service",
              color: service.color,
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
                _dashboardCard(
                  id: "service.connection",
                  label: "CONNECTION",
                  color: service.color,
                  children: [
                    _statusElement(
                      id: "service.state",
                      value: serviceInspectorExpression(
                        "state",
                        const StringType(),
                      ),
                      tones: const {
                        "Connected": StatusTone.online,
                        "Offline": StatusTone.offline,
                      },
                    ),
                    _dashboardGrid(
                      id: "service.facts",
                      children: [
                        _serviceReadOnlyField("version", "Version"),
                        _readOnlyField(
                          id: "service.lastSeen",
                          label: "Last seen",
                          content: _optionalRelativeTimeContent(
                            binding: serviceInspectorField("lastSeen"),
                            scopeBindingId: const BindingId(73),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ].map(PresentationAxisChild.fixed).toList(),
        ),
      ),
    );

PresentationNode _serviceReadOnlyField(String field, String label) =>
    _readOnlyField(
      id: "service.$field",
      label: label,
      value: serviceInspectorExpression(field, const StringType()),
    );

BindingReference serviceInspectorField(String name) => BindingReference(
  bindingId: BindingId(name == "name" ? 1 : 0),
  path: DataPath.root.field(name),
);

TypedExpression serviceInspectorExpression(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(serviceInspectorField(name)),
    );
