part of "tags.dart";

const _tagSearchQueryBindingId = BindingId(41);
const _tagSearchSummaryBindingId = BindingId(42);
const _tagSearchResultBindingId = BindingId(43);
const _tagSummaryItemBindingId = BindingId(44);
const _tagChildrenBindingId = BindingId(45);

PresentationNode tagReferenceSearch({
  required String id,
  required String label,
  required BindingReference binding,
}) {
  final key = _tagResultField("key", tagReferenceType);
  final name = _tagResultField("name", const StringType());
  final selectable = _tagResultField("selectable", const BooleanType());
  return PresentationNode(
    id: "$id.search",
    element: SearchInputElement(
      control: BoundControl(binding: binding, label: label.asStringLiteral),
      selectionMode: SearchSelectionMode.multiple,
      queryBindingId: _tagSearchQueryBindingId,
      summaryBindingId: _tagSearchSummaryBindingId,
      maximumExtent: 320.asFloatLiteral,
      placeholder: "Search Tags".asStringLiteral,
      summary: _directTagSummary(id),
      provider: SearchProvider.collection(
        sourceId: tagCollectionSourceId,
        result: SearchResultMapping(
          bindingId: _tagSearchResultBindingId,
          key: key,
          selectedValue: key,
          label: name,
          presentation: _tagChip("$id.result"),
        ),
        where: selectable,
      ),
    ),
  );
}

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
            relation: tagInheritsRelationId,
            direction: CollectionGraphDirection.forward,
            node: _tagInheritanceNode(id),
            childrenBindingId: _tagChildrenBindingId,
          ),
        ),
      ),
    ),
  ),
);

PresentationNode _directTagSummary(String id) => PresentationNode(
  id: "$id.summary",
  element: RepeatedElement(
    source: _bindingExpression(
      _tagSearchSummaryBindingId,
      ListType(element: tagReferenceType),
    ),
    itemBindingId: _tagSummaryItemBindingId,
    presentation: SequencePresentation(
      layout: const PresentationChildrenLayout.wrap(spacing: 8, runSpacing: 8),
      item: PresentationNode(
        id: "$id.summary.lookup",
        element: CollectionLookupElement(
          sourceId: tagCollectionSourceId,
          key: const BindingReference(bindingId: _tagSummaryItemBindingId),
          found: _tagChip("$id.summary.found"),
          missing: _missingTag("$id.summary.missing"),
        ),
      ),
      empty: PresentationNode(
        id: "$id.summary.empty",
        element: TextElement("None selected".asStringLiteral),
      ),
    ),
  ),
);

PresentationNode _tagInheritanceNode(String id) {
  final children = _bindingExpression(
    _tagChildrenBindingId,
    ListType(element: tagCollectionRowType),
  );
  final slotId = "$id.children";
  return PresentationNode(
    id: "$id.node",
    element: ConditionalElement(
      condition: children.length().greaterThanOrEqual(2),
      whenTrue: _tagBranch(id, slotId),
      whenFalse: PresentationNode(
        id: "$id.flattened",
        element: ConditionalElement(
          condition: children.length().greaterThanOrEqual(1),
          whenTrue: _tagUnaryNode(id, slotId),
          whenFalse: _tagLeafNode(id),
        ),
      ),
    ),
  );
}

PresentationNode _tagLeafNode(String id) => PresentationNode(
  id: "$id.leaf",
  element: PaddingElement(bottom: 8, child: _tagChip("$id.leaf.chip")),
);

PresentationNode _tagUnaryNode(String id, String slotId) => PresentationNode(
  id: "$id.unary",
  element: PaddingElement(
    bottom: 8,
    child: PresentationNode(
      id: "$id.unary.content",
      element: ColumnElement(
        spacing: 8,
        children: [
          _tagChip("$id.unary.chip"),
          PresentationNode(
            id: "$id.unary.children.padding",
            element: PaddingElement(
              start: 16,
              child: _tagChildrenSlot("$id.unary.children", slotId),
            ),
          ),
        ],
      ),
    ),
  ),
);

PresentationNode _tagBranch(String id, String slotId) => PresentationNode(
  id: "$id.branch.spacing",
  element: PaddingElement(
    bottom: 8,
    child: PresentationNode(
      id: "$id.branch",
      header: PresentationHeader(
        title: PresentationHeaderTitle.presentation(
          _tagChip("$id.branch.chip"),
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
        child: PresentationNode(
          id: "$id.branch.children.padding",
          element: PaddingElement(
            start: 8,
            child: _tagChildrenSlot("$id.branch.children", slotId),
          ),
        ),
      ),
    ),
  ),
);

PresentationNode _tagChildrenSlot(String id, String slotId) => PresentationNode(
  id: id,
  element: PresentationSlotElement(slotId: slotId),
);

PresentationNode _tagChip(String id) => PresentationNode(
  id: id,
  element: ChipElement(
    label: _tagRowField("name", const StringType()),
    color: _tagRowField("color", NamedType(standardTypeRefs.color)),
  ),
);

PresentationNode _missingTag(String id) => PresentationNode(
  id: id,
  element: TextElement("Tag unavailable".asStringLiteral),
);

TypedExpression _tagResultField(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(
          bindingId: _tagSearchResultBindingId,
          path: DataPath.root.field(name),
        ),
      ),
    );

TypedExpression _bindingExpression(
  BindingId id,
  TypeExpression type, {
  DataPath path = DataPath.root,
}) => TypedExpression(
  resultType: type,
  expression: BindingExpression(BindingReference(bindingId: id, path: path)),
);
