import "package:typewriter_panel/typewriter_panel.dart";

const _queryBindingId = BindingId(10);
const _summaryBindingId = BindingId(11);
const _resultBindingId = BindingId(20);
const _defaultIconIdentifiers = [
  "mdi:home",
  "mdi:account",
  "mdi:star",
  "mdi:map-marker",
  "game-icons:broad-dagger",
];

PresentationNode iconifySearchPresentation() {
  final query = _binding(_queryBindingId, const StringType());
  final icon = _binding(
    _resultBindingId,
    NamedType(standardTypeRefs.iconifyIcon),
  );
  final name = icon
      .regexCapture(r"^[^:]+:(.+)$", group: 1)
      .replaceLiteral("-", " ")
      .titleCase();
  final collection = icon
      .regexCapture(r"^([^:]+):.+$", group: 1)
      .replaceLiteral("-", " ")
      .titleCase();
  final resultPresentation = _iconResult(icon, name, collection);
  final mapping = SearchResultMapping(
    bindingId: _resultBindingId,
    key: icon,
    selectedValue: icon,
    presentation: resultPresentation,
  );
  final suggested =
      SearchProvider.staticValues(
            values:
                ListValue(
                  _defaultIconIdentifiers
                      .map(StringValue.new)
                      .toList(growable: false),
                ).asLiteral(
                  ListType(element: NamedType(standardTypeRefs.iconifyIcon)),
                ),
            result: mapping,
          )
          .ranked([
            SearchRankingField(expression: name, weight: 100),
            SearchRankingField(expression: icon, weight: 50),
          ])
          .inSection(
            id: "iconify.suggested",
            label: "Suggested".asStringLiteral,
          );
  final remote =
      SearchProvider.httpJson(
            uri: "https://api.iconify.design/search".asStringLiteral,
            parameters: [
              HttpQueryParameter(
                name: "query",
                value: query
                    .regexCapture(r"^(?:[^:]+:)?(.+)$", group: 1)
                    .coalesce(query),
              ),
              HttpQueryParameter(
                name: "prefix",
                value: query
                    .regexCapture(r"^([^:]+):(.+)$", group: 1)
                    .coalesce("".asStringLiteral),
                omitIfEmpty: true,
              ),
              HttpQueryParameter(name: "limit", value: "64".asStringLiteral),
            ],
            resultPath: r"$.icons[*]",
            resultType: NamedType(standardTypeRefs.iconifyIcon),
            result: mapping,
          )
          .gated(
            condition: query.length().greaterThanOrEqual(2),
            guidance: "Enter at least two characters".asStringLiteral,
          )
          .debounced(const Duration(milliseconds: 150))
          .ranked([
            SearchRankingField(expression: name, weight: 100),
            SearchRankingField(expression: collection, weight: 40),
            SearchRankingField(expression: icon, weight: 30),
          ])
          .limited(64.asIntegerLiteral)
          .cached(capacity: 100)
          .withHistory(
            key: "iconify",
            label: "Recent".asStringLiteral,
            capacity: 10,
          )
          .inSection(id: "iconify.remote", label: "Iconify".asStringLiteral);
  return PresentationNode(
    id: "iconify.default",
    element: SearchInputElement(
      control: const BoundControl(
        binding: BindingReference(bindingId: BindingId(0)),
      ),
      selectionMode: SearchSelectionMode.single,
      queryBindingId: _queryBindingId,
      summaryBindingId: _summaryBindingId,
      maximumExtent: 280.asFloatLiteral,
      placeholder: "Search icons".asStringLiteral,
      customValue: query.withResultType(
        NamedType(standardTypeRefs.iconifyIcon),
      ),
      summary: _iconSummary(),
      provider: SearchProvider.merge(children: [remote, suggested]).distinct(),
    ),
  );
}

PresentationNode _iconResult(
  TypedExpression icon,
  TypedExpression name,
  TypedExpression collection,
) => PresentationNode(
  id: "iconify.result",
  element: RowElement(
    spacing: 10,
    children: [
      PresentationNode(
        id: "iconify.result.icon",
        element: IconElement(name: icon),
      ),
      PresentationNode(
        id: "iconify.result.labels",
        element: ColumnElement(
          spacing: 1,
          crossAxisAlignment: PresentationCrossAxisAlignment.start,
          children: [
            PresentationNode(
              id: "iconify.result.name",
              element: TextElement(name),
            ),
            PresentationNode(
              id: "iconify.result.collection",
              element: TextElement(collection),
            ),
          ],
        ),
      ),
    ],
  ),
);

PresentationNode _iconSummary() {
  final icon = _binding(
    _summaryBindingId,
    NamedType(standardTypeRefs.iconifyIcon),
  );
  return PresentationNode(
    id: "iconify.summary",
    element: RowElement(
      spacing: 10,
      children: [
        PresentationNode(
          id: "iconify.summary.icon",
          element: IconElement(name: icon),
        ),
        PresentationNode(
          id: "iconify.summary.value",
          element: TextElement(icon),
        ),
      ],
    ),
  );
}

TypedExpression _binding(BindingId id, TypeExpression type) => TypedExpression(
  resultType: type,
  expression: BindingExpression(BindingReference(bindingId: id)),
);
