part of "services.dart";

const _serviceInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "service.inspector",
);
const _serviceSearchQueryBindingId = BindingId(51);
const _serviceSearchSummaryBindingId = BindingId(52);
const _serviceSearchResultBindingId = BindingId(53);
const _serviceSearchRoleBindingId = BindingId(54);
const _serviceSearchSummaryValueBindingId = BindingId(58);
const _serviceRoleBindingId = BindingId(56);
const _serviceRoleRepresentationBindingId = BindingId(57);

final _serviceColorType = NamedType(standardTypeRefs.color);
final _serviceCollectionRolesType = ListType(
  element: serviceCollectionRoleType,
);
final _standaloneColor = standaloneServiceColor.asColorLiteral;
final _engineRoleColor = engineServiceRoleColor.asColorLiteral;
final _realmRoleColor = realmServiceRoleColor.asColorLiteral;
final _customRoleColor = customServiceRoleColor.asColorLiteral;

final _serviceRoles = serviceInspectorExpression(
  "roles",
  ListType(element: NamedType(serviceRoleTypeRef)),
);

final _serviceRole = _serviceBindingExpression(
  _serviceRoleBindingId,
  NamedType(serviceRoleTypeRef),
);

final _isConfigurableRole = TypedExpression(
  resultType: const BooleanType(),
  expression: BooleanExpression(
    operator: BooleanOperator.or,
    operands: [
      _serviceRole.isType(NamedType(engineRoleTypeRef)),
      _serviceRole.isType(NamedType(customRoleTypeRef)),
    ],
  ),
);

final _canConfigureRunsIn = _serviceRoles.any(
  itemBindingId: _serviceRoleBindingId,
  predicate: _isConfigurableRole,
);

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
            PresentationNode(
              id: "service.runsIn.conditional",
              element: ConditionalElement(
                condition: _canConfigureRunsIn,
                whenTrue: _serviceRunsInSearch,
              ),
            ),
            _serviceRoleListRow(),
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
    initialQuery: "".asStringLiteral,
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
  element: PolymorphicMatchElement(
    binding: const BindingReference(bindingId: _serviceSearchSummaryBindingId),
    scopeBindingId: _serviceSearchSummaryValueBindingId,
    cases: [
      PolymorphicMatchCase(
        type: standardTypeRefs.noneOf(serviceReferenceType),
        child: _standaloneServiceOption("service.runsIn.summary.none"),
      ),
      PolymorphicMatchCase(
        type: standardTypeRefs.someOf(serviceReferenceType),
        child: PresentationNode(
          id: "service.runsIn.summary.some",
          element: CollectionLookupElement(
            sourceId: serviceCollectionSourceId,
            key: BindingReference(
              bindingId: _serviceSearchSummaryValueBindingId,
              path: DataPath.root.field("value"),
            ),
            found: _serviceOptionCard(
              id: "service.runsIn.summary.service",
              name: _serviceRowField("name", const StringType()),
              color: _serviceRowField("color", _serviceColorType),
              roles: _serviceRowField("roles", _serviceCollectionRolesType),
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
  element: ConditionalElement(
    condition: _serviceResultField("standalone", const BooleanType()),
    whenTrue: _standaloneServiceOption("service.runsIn.result.standalone"),
    whenFalse: _serviceOptionCard(
      id: "service.runsIn.result.service",
      name: _serviceResultField("name", const StringType()),
      color: _serviceResultField("color", _serviceColorType),
      roles: _serviceResultField("roles", _serviceCollectionRolesType),
    ),
  ),
);

PresentationNode _standaloneServiceOption(String id) => _serviceOptionCard(
  id: id,
  name: "Standalone".asStringLiteral,
  color: _standaloneColor,
  roles: null,
);

PresentationNode _serviceOptionCard({
  required String id,
  required TypedExpression name,
  required TypedExpression color,
  required TypedExpression? roles,
}) => PresentationNode(
  id: id,
  element: ColumnElement(
    crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
    children: [
      PresentationNode(
        id: "$id.card",
        element: ContainerElement(
          backgroundColor: color.withAlpha(32),
          radius: PresentationRadius.custom(8.asFloatLiteral),
          child: PresentationNode(
            id: "$id.padding",
            element: PaddingElement(
              top: 8,
              start: 12,
              end: 12,
              bottom: 8,
              child: PresentationNode(
                id: "$id.content",
                element: WrapElement(
                  spacing: 12,
                  runSpacing: 8,
                  mainAxisAlignment: PresentationMainAxisAlignment.spaceBetween,
                  crossAxisAlignment: PresentationCrossAxisAlignment.center,
                  children: [
                    PresentationNode(
                      id: "$id.name",
                      element: TextElement(name, color: color),
                    ),
                    if (roles != null)
                      PresentationNode(
                        id: "$id.roles",
                        element: RepeatedElement(
                          source: roles,
                          itemBindingId: _serviceSearchRoleBindingId,
                          presentation: SequencePresentation(
                            layout: const PresentationSequenceLayout.children(
                              PresentationChildrenLayout.wrap(
                                spacing: 6,
                                runSpacing: 6,
                              ),
                            ),
                            item: PresentationNode(
                              id: "$id.role",
                              element: ChipElement(
                                label: _serviceBindingField(
                                  _serviceSearchRoleBindingId,
                                  "label",
                                  const StringType(),
                                ),
                                color: _serviceBindingField(
                                  _serviceSearchRoleBindingId,
                                  "color",
                                  _serviceColorType,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
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

TypedExpression _serviceBindingField(
  BindingId id,
  String name,
  TypeExpression type,
) => TypedExpression(
  resultType: type,
  expression: BindingExpression(
    BindingReference(bindingId: id, path: DataPath.root.field(name)),
  ),
);
