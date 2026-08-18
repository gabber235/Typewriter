import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/search_input/search_input_fixed_source.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/search_input/search_input_story.dart";

const _queryBindingId = BindingId(10);
const _summaryBindingId = BindingId(11);
const _resultBindingId = BindingId(20);
const _resultBinding = BindingReference(bindingId: _resultBindingId);
const _stringType = StringType();

final _resultExpression = TypedExpression(
  resultType: _stringType,
  expression: const BindingExpression(_resultBinding),
);

SearchInputElement searchStoryElement({
  required SearchProvider provider,
  SearchSelectionMode mode = SearchSelectionMode.single,
  double maximumExtent = 280,
  String label = "Minecraft effect",
}) => SearchInputElement(
  control: BoundControl(
    binding: searchStoryRootBinding,
    label: label.asStringLiteral,
    description:
        "Search and select using the keyboard or pointer.".asStringLiteral,
  ),
  selectionMode: mode,
  queryBindingId: _queryBindingId,
  summaryBindingId: _summaryBindingId,
  maximumExtent: FloatValue(
    maximumExtent,
  ).asLiteral(const FloatType(width: FloatWidth.float64)),
  provider: provider,
  placeholder: "Search effects".asStringLiteral,
);

SearchProvider staticEffectsProvider({
  List<String> values = effectNames,
  String sectionId = "effects",
  String sectionLabel = "Effects",
  List<SearchSelectorDefinition> selectors = const [],
}) =>
    SearchProvider.staticValues(
          values: ListValue(
            values.map(StringValue.new).toList(),
          ).asLiteral(const ListType(element: _stringType)),
          selectors: selectors,
          result: SearchResultMapping(
            bindingId: _resultBindingId,
            key: _resultExpression,
            selectedValue: _resultExpression,
            presentation: PresentationNode(
              id: "$sectionId.result",
              element: TextElement(_resultExpression),
            ),
          ),
        )
        .ranked([
          SearchRankingField(expression: _resultExpression, weight: 100),
        ])
        .inSection(id: sectionId, label: sectionLabel.asStringLiteral);

SearchProvider selectorRichEffectsProvider() => staticEffectsProvider(
  selectors: [
    SearchSelectorDefinition.keyValue(
      id: "category",
      key: "category:",
      valueBindingId: BindingId(30),
      values: SearchSelectorValues.enumeration([
        "beneficial",
        "harmful",
        "neutral",
      ]),
      colorValue: 0xFF7C4DFF,
    ),
    SearchSelectorDefinition.keyValue(
      id: "source",
      key: "source:",
      valueBindingId: BindingId(31),
      values: SearchSelectorValues.freeText(),
      multiplicity: SearchSelectorMultiplicity.multiple,
      colorValue: 0xFF00A896,
    ),
  ],
);

SearchProvider globallyLimitedComposition() => SearchProvider.merge(
  children: [
    staticEffectsProvider(
      values: effectNames.take(5).toList(),
      sectionId: "suggested",
      sectionLabel: "Suggested",
    ),
    staticEffectsProvider(
      values: effectNames.skip(3).toList(),
      sectionId: "catalog",
      sectionLabel: "Catalog",
    ).cached(capacity: 12),
  ],
).distinct().limited(6.asSigned64Literal);

SearchProvider locallyLimitedComposition() => SearchProvider.merge(
  children: [
    staticEffectsProvider(
      values: effectNames.take(6).toList(),
      sectionId: "beneficial",
      sectionLabel: "Beneficial",
    ).limited(3.asSigned64Literal),
    staticEffectsProvider(
      values: effectNames.skip(4).toList(),
      sectionId: "other",
      sectionLabel: "Other",
    ).limited(3.asSigned64Literal),
  ],
).distinct();

SearchProvider historyEffectsProvider() => staticEffectsProvider().withHistory(
  key: "widgetbook.effects",
  label: "Recent effects".asStringLiteral,
  capacity: 5,
);

PresentationSearchSourceBuilder fixedSource(SearchSourceSnapshot snapshot) =>
    (_, _) => FixedStorySearchSource(snapshot: snapshot);

SearchSourceSnapshot readyStorySnapshot({
  List<SearchErrorSummary> errors = const [],
}) => SearchSourceSnapshot.ready(
  nodes: effectNames.take(8).map(storyResultNode).toList(),
  errorSummaries: errors,
);

SearchNode storyResultNode(String value) => SearchNode.result(
  result: SearchResult(
    id: "story:$value",
    type: presentationSearchResultType,
    title: value,
    subtitle: "Minecraft effect",
    payload: PresentationSearchResultPayload(
      selectedValue: StringValue(value),
      presentation: PresentationNode(
        id: "story.$value",
        element: TextElement(value.asStringLiteral),
      ),
      expressions: const ExpressionContext(bindings: BindingEnvironment({})),
      providerKey: "widgetbook",
    ),
  ),
);

const effectNames = [
  "Speed",
  "Slowness",
  "Haste",
  "Mining Fatigue",
  "Strength",
  "Instant Health",
  "Instant Damage",
  "Jump Boost",
  "Regeneration",
  "Resistance",
  "Fire Resistance",
  "Water Breathing",
];
