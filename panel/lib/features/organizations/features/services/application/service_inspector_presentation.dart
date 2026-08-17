part of "services.dart";

const _serviceInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "service.inspector",
);
const _serviceSearchQueryBindingId = BindingId(51);
const _serviceSearchSummaryBindingId = BindingId(52);
const _serviceSearchResultBindingId = BindingId(53);

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
            if (service.isEngine || service.isCustom)
              _serviceRunsInSearch
            else
              _serviceTextRow(
                "service.runsIn.notApplicable",
                "Runs in",
                "Not applicable".asStringLiteral,
              ),
            _serviceTextRow(
              "service.status",
              "Status",
              serviceInspectorExpression("status", const StringType()),
            ),
            _serviceListRow("service.roles", "Roles", "roles"),
            _serviceListRow("service.versions", "Versions", "versions"),
            _serviceTextRow(
              "service.lastSeen",
              "Last seen",
              service.lastSeenLabel.asStringLiteral,
            ),
            _serviceTextRow(
              "service.createdAt",
              "Created",
              service.createdAt.toIso8601String().asStringLiteral,
            ),
          ],
        ),
      ),
    );

final _serviceRunsInSearch = PresentationNode(
  id: "service.runsIn",
  element: SearchInputElement(
    control: BoundControl(
      binding: serviceInspectorField("runsIn"),
      label: "Runs in".asStringLiteral,
    ),
    selectionMode: SearchSelectionMode.single,
    queryBindingId: _serviceSearchQueryBindingId,
    summaryBindingId: _serviceSearchSummaryBindingId,
    maximumExtent: 280.asFloatLiteral,
    placeholder: "Search Realm services".asStringLiteral,
    summary: _serviceRunsInSummary,
    provider: SearchProvider.collection(
      sourceId: serviceCollectionSourceId,
      result: SearchResultMapping(
        bindingId: _serviceSearchResultBindingId,
        key: _serviceResultField("key", serviceReferenceType),
        selectedValue: _serviceResultField(
          "selection",
          serviceOptionReferenceType,
        ),
        label: _serviceResultField("name", const StringType()),
        presentation: _serviceResultRow,
      ),
      where: _serviceResultField("selectable", const BooleanType()),
    ),
  ),
);

final _serviceRunsInSummary = PresentationNode(
  id: "service.runsIn.summary",
  element: PolymorphicInputElement(
    control: const BoundControl(
      binding: BindingReference(bindingId: _serviceSearchSummaryBindingId),
    ),
    concreteTypes: [
      ConcreteTypePresentation(
        type: standardTypeRefs.noneOf(serviceReferenceType),
        label: "Standalone".asStringLiteral,
        presentation: PresentationNode(
          id: "service.runsIn.summary.none",
          element: TextElement("Standalone".asStringLiteral),
        ),
      ),
      ConcreteTypePresentation(
        type: standardTypeRefs.someOf(serviceReferenceType),
        label: "Realm".asStringLiteral,
        presentation: PresentationNode(
          id: "service.runsIn.summary.some",
          element: CollectionLookupElement(
            sourceId: serviceCollectionSourceId,
            key: BindingReference(
              bindingId: _serviceSearchSummaryBindingId,
              path: DataPath.root.field("value"),
            ),
            found: PresentationNode(
              id: "service.runsIn.summary.name",
              element: TextElement(
                _serviceRowField("name", const StringType()),
              ),
            ),
            missing: PresentationNode(
              id: "service.runsIn.summary.missing",
              element: TextElement("Service unavailable".asStringLiteral),
            ),
          ),
        ),
      ),
    ],
  ),
);

final _serviceResultRow = PresentationNode(
  id: "service.runsIn.result",
  element: ColumnElement(
    spacing: 2,
    crossAxisAlignment: PresentationCrossAxisAlignment.start,
    children: [
      PresentationNode(
        id: "service.runsIn.result.name",
        element: TextElement(_serviceResultField("name", const StringType())),
      ),
      PresentationNode(
        id: "service.runsIn.result.roles",
        element: RepeatedElement(
          source: _serviceResultField(
            "roles",
            ListType(element: const StringType()),
          ),
          itemBindingId: const BindingId(54),
          presentation: SequencePresentation(
            item: PresentationNode(
              id: "service.runsIn.result.role",
              element: TextElement(
                _serviceBindingExpression(
                  const BindingId(54),
                  const StringType(),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);

PresentationNode _serviceListRow(String id, String label, String field) =>
    PresentationNode(
      id: id,
      properties: const PresentationProperties(readOnly: true),
      header: PresentationHeader(title: label.asStringLiteral.asHeaderTitle),
      element: SectionElement(
        child: PresentationNode(
          id: "$id.values",
          element: RepeatedElement(
            source: serviceInspectorExpression(
              field,
              ListType(element: const StringType()),
            ),
            itemBindingId: const BindingId(55),
            presentation: SequencePresentation(
              item: PresentationNode(
                id: "$id.value",
                element: TextElement(
                  _serviceBindingExpression(
                    const BindingId(55),
                    const StringType(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

PresentationNode _serviceTextRow(
  String id,
  String label,
  TypedExpression value,
) => PresentationNode(
  id: id,
  properties: const PresentationProperties(readOnly: true),
  header: PresentationHeader(title: label.asStringLiteral.asHeaderTitle),
  element: SectionElement(
    child: PresentationNode(id: "$id.value", element: TextElement(value)),
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

TypedExpression _serviceResultField(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(
          bindingId: _serviceSearchResultBindingId,
          path: DataPath.root.field(name),
        ),
      ),
    );

TypedExpression _serviceBindingExpression(BindingId id, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(BindingReference(bindingId: id)),
    );
