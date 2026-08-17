part of "tags.dart";

const _tagSearchQueryBindingId = BindingId(41);
const _tagSearchSummaryBindingId = BindingId(42);
const _tagSearchResultBindingId = BindingId(43);
const _tagSummaryItemBindingId = BindingId(44);

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

PresentationNode _directTagSummary(String id) => PresentationNode(
  id: "$id.summary",
  element: RepeatedElement(
    source: _bindingExpression(
      _tagSearchSummaryBindingId,
      ListType(element: tagReferenceType),
    ),
    itemBindingId: _tagSummaryItemBindingId,
    presentation: SequencePresentation(
      layout: const PresentationSequenceLayout.children(
        PresentationChildrenLayout.wrap(spacing: 8, runSpacing: 8),
      ),
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
