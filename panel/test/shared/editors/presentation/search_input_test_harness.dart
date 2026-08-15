import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

PresentationNode searchTestPresentation({
  bool multiple = false,
  double maximumExtent = 260,
  SearchProvider? provider,
}) {
  const queryId = BindingId(10);
  const summaryId = BindingId(11);
  const values = [
    "Alpha",
    "Beta",
    "Gamma",
    "Delta",
    "Epsilon",
    "Zeta",
    "Eta",
    "Theta",
  ];
  final summaryExpression = TypedExpression(
    resultType: multiple
        ? const ListType(element: StringType())
        : const StringType(),
    expression: const BindingExpression(BindingReference(bindingId: summaryId)),
  );
  return PresentationNode(
    id: "search",
    element: SearchInputElement(
      control: const BoundControl(
        binding: BindingReference(bindingId: BindingId(0)),
      ),
      selectionMode: multiple
          ? SearchSelectionMode.multiple
          : SearchSelectionMode.single,
      queryBindingId: queryId,
      summaryBindingId: summaryId,
      maximumExtent: maximumExtent.asFloatLiteral,
      summary: PresentationNode(
        id: "summary",
        element: TextElement(summaryExpression),
      ),
      provider:
          provider ??
          SearchProvider.staticValues(
            values: ListValue(
              values.map(StringValue.new).toList(),
            ).asLiteral(const ListType(element: StringType())),
            result: searchTestResultMapping,
          ),
    ),
  );
}

Widget searchTestRenderer({
  required TypeExpression type,
  required DataValue value,
  required PresentationNode presentation,
  bool readOnly = false,
  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "searchRoot"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    presentation: presentation,
    readOnly: readOnly,
    realmSearchSourceBuilder: realmSearchSourceBuilder,
  );
}

const searchTestResultExpression = TypedExpression(
  resultType: StringType(),
  expression: BindingExpression(BindingReference(bindingId: BindingId(12))),
);

const searchTestResultMapping = SearchResultMapping(
  bindingId: BindingId(12),
  key: searchTestResultExpression,
  selectedValue: searchTestResultExpression,
  presentation: PresentationNode(
    id: "row",
    element: TextElement(searchTestResultExpression),
  ),
);
