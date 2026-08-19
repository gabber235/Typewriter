part of "tags.dart";

const _tagChildrenBindingId = BindingId(45);
const _tagChildBindingId = BindingId(46);

PresentationNode effectiveTagGraph({
  required String id,
  required String title,
  required BindingReference roots,
}) => PresentationNode(
  id: "$id.visibility",
  element: ConditionalElement(
    condition: _bindingExpression(
      roots.bindingId,
      ListType(element: tagReferenceType),
      path: roots.path,
    ).length().greaterThanOrEqual(1),
    whenTrue: PresentationNode(
      id: "$id.section",
      header: PresentationHeader(
        title: title.asStringLiteral.asHeaderTitle,
        initiallyExpanded: true,
      ),
      element: SectionElement(
        child: PresentationNode(
          id: "$id.graph",
          element: CollectionGraphElement(
            sourceId: tagCollectionSourceId,
            roots: roots,
            rootSequence: SequencePresentation(
              item: PresentationNode(
                id: "$id.root",
                element: PresentationSlotElement(slotId: "$id.root.content"),
              ),
              layout: const PresentationSequenceLayout.children(
                PresentationChildrenLayout.column(spacing: 12),
              ),
            ),
            relation: tagInheritsRelationId,
            direction: CollectionGraphDirection.forward,
            node: _tagInheritanceNode(id),
            childrenBindingId: _tagChildrenBindingId,
            childBindingId: _tagChildBindingId,
            children: SequencePresentation(
              layout: PresentationSequenceLayout.hierarchy(
                _tagHierarchyLayout(),
              ),
              item: _tagChildrenSlot("$id.child", "$id.children"),
            ),
          ),
        ),
      ),
    ),
  ),
);

HierarchySequenceLayout _tagHierarchyLayout() {
  final currentColor = _tagRowField("color", NamedType(standardTypeRefs.color));
  final childColor = _tagChildField("color", NamedType(standardTypeRefs.color));
  return HierarchySequenceLayout(
    unaryConnector: _tagConnectorStyle(
      color: childColor,
      startMarker: ConnectorEndpointMarker.arrow(size: 8.asFloatLiteral),
    ),
    trunkConnector: _tagConnectorStyle(
      color: currentColor,
      cornerRadius: 8,
      startMarker: ConnectorEndpointMarker.arrow(size: 10.asFloatLiteral),
    ),
    branchConnector: _tagConnectorStyle(
      color: childColor,
      cornerRadius: 8,
      startMarker: ConnectorEndpointMarker.circle(diameter: 6.asFloatLiteral),
    ),
    itemSpacing: 24.asFloatLiteral,
    indentation: 16.asFloatLiteral,
    leadingSpacing: 16.asFloatLiteral,
    itemAnchor: const ConnectorAnchor.center(),
    flattenSingleItem: true.asBooleanLiteral,
    crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
  );
}

ConnectorStyle _tagConnectorStyle({
  required TypedExpression color,
  double cornerRadius = 0,
  ConnectorEndpointMarker? startMarker,
}) => ConnectorStyle(
  stroke: ConnectorStroke(color: color, width: 2.asFloatLiteral),
  cornerRadius: cornerRadius.asFloatLiteral,
  startMarker: startMarker,
);

PresentationNode _tagInheritanceNode(String id) {
  final children = _bindingExpression(
    _tagChildrenBindingId,
    ListType(element: tagCollectionRowType),
  );
  final slotId = "$id.children";
  final hasOneChild = children.length().compare(
    ComparisonOperator.equal,
    1.asIntegerLiteral,
  );
  final hasSeveralChildren = children.length().greaterThanOrEqual(2);
  return PresentationNode(
    id: "$id.node",
    element: ConditionalElement(
      condition: hasSeveralChildren,
      whenTrue: _tagBranch(id, slotId),
      whenFalse: PresentationNode(
        id: "$id.flattened",
        element: ConditionalElement(
          condition: hasOneChild,
          whenTrue: _tagUnaryNode(id, slotId),
          whenFalse: _tagLeafNode(id),
        ),
      ),
    ),
  );
}

PresentationNode _tagLeafNode(String id) =>
    _tagInheritanceContainer("$id.leaf.container");

PresentationNode _tagUnaryNode(String id, String slotId) => PresentationNode(
  id: "$id.unary",
  element: ColumnElement(
    crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
    children: [
      _tagInheritanceContainer("$id.unary.container"),
      _tagChildrenSlot("$id.unary.children", slotId),
    ],
  ),
);

PresentationNode _tagBranch(String id, String slotId) => PresentationNode(
  id: "$id.branch",
  header: PresentationHeader(
    title: PresentationHeaderTitle.presentation(
      _tagInheritanceContainer("$id.branch.container"),
    ),
    initiallyExpanded: false,
  ),
  element: SectionElement(
    border: PresentationBorder.sides(
      start: PresentationBorderSide(
        color: _tagRowField("color", NamedType(standardTypeRefs.color)),
        width: 4,
      ),
    ),
    child: _tagChildrenSlot("$id.branch.children", slotId),
  ),
);

PresentationNode _tagInheritanceContainer(String id) {
  final color = _tagRowField("color", NamedType(standardTypeRefs.color));
  return PresentationNode(
    id: id,
    element: ContainerElement(
      border: PresentationBorder.all(PresentationBorderSide(color: color)),
      backgroundColor: color.withAlpha(46),
      radius: const PresentationRadius.small(),
      child: PresentationNode(
        id: "$id.padding",
        element: PaddingElement(
          top: 8,
          start: 12,
          end: 12,
          bottom: 8,
          child: PresentationNode(
            id: "$id.label",
            element: TextElement(
              _tagRowField("name", const StringType()),
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}

TypedExpression _tagChildField(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(
          bindingId: _tagChildBindingId,
          path: DataPath.root.field(name),
        ),
      ),
    );

PresentationNode _tagChildrenSlot(String id, String slotId) => PresentationNode(
  id: id,
  element: PresentationSlotElement(slotId: slotId),
);
