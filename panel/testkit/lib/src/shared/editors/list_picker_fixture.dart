import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/shared/editors/presentation/collection_editor_fixture.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";

/// A search over the static [choices], keyed by item id, that writes the
/// chosen one to [target].
///
/// Results bind as [resultType] (text unless given) and show their value.
/// A [listType] collects several choices into that list type; otherwise one
/// choice replaces the value. The search is labeled [label], shows
/// [placeholder] and [summary] when given, and grows to [maximumExtent].
skir.SearchControl staticSearchControl({
  required skir.BindingRef target,
  required Map<String, skir.DataValue> choices,
  skir.TypeTemplate? resultType,
  skir.TypeDefinitionId? listType,
  String? label,
  String? placeholder,
  skir.PresentationNode? summary,
  double maximumExtent = 220,
}) {
  final row = skir.ExpressionBindingId(value: "row");
  final rowRead = inputExpression(row);
  final control = skir.SearchControl.mutable()
    ..control =
        (skir.BoundControl.mutable()
              ..binding = target
              ..label = label == null ? null : textLiteral(label))
            .toFrozen()
    ..selectionMode = listType == null
        ? skir.SearchSelectionMode.single
        : skir.SearchSelectionMode.multiple
    ..queryBinding = declareNamedBinding("query", textTemplate)
    ..summaryBinding = declareNamedBinding(
      "summary",
      listType == null
          ? textTemplate
          : skir.TypeTemplate.createNamed(
              definition: listType,
              arguments: const [],
            ),
    )
    ..maximumExtent = numberLiteral(maximumExtent)
    ..placeholder = placeholder == null ? null : textLiteral(placeholder)
    ..provider = skir.SearchProvider.createStaticValues(
      values: literalExpression(
        skir.DataValue.createListValue(
          items: [
            for (final choice in choices.entries)
              skir.ListItem(
                id: skir.ItemId(value: choice.key),
                value: choice.value,
              ),
          ],
        ),
      ),
      result: skir.SearchResultMapping(
        binding: declareBinding(row, resultType ?? textTemplate),
        key: rowRead,
        selectedValue: rowRead,
        label: rowRead,
        presentation: presentationText("result", rowRead),
      ),
      selectors: const [],
    );
  if (summary != null) control.summary = summary;
  return control.toFrozen();
}

/// A list picker: a search input over [choices], Book, Map, Star and Wolf
/// unless given, whose checks are the entries of a text list on a real
/// authored draft. The list starts empty, or with [held] it holds Arrival,
/// Discovery and Return.
final class ListPickerScenario {
  ListPickerScenario({this.choices = defaultChoices, bool held = false})
    : collection = CollectionEditorScenario(
        empty: !held,
        transformLayout: (_) => presentationNode(
          "search",
          skir.PresentationElement.wrapSearchInput(
            staticSearchControl(
              target: skir.BindingRef(
                bindingId: configuredValueBindingId,
                path: CollectionEditorScenario.entriesPath,
              ),
              listType: textList,
              label: "Icon identifier",
              placeholder: "Search icons",
              maximumExtent: 400,
              choices: {
                for (final name in choices)
                  name: skir.DataValue.wrapStringValue(name),
              },
            ),
          ),
        ),
      ) {
    var last = entries;
    collection.addListener(() {
      final now = entries;
      if (listEquals(now, last)) return;
      last = now;
      changes++;
    });
  }

  /// The choices the picker offers unless given, in the order it shows them.
  static const defaultChoices = ["Book", "Map", "Star", "Wolf"];

  /// The choices the picker offers, in the order it shows them.
  final List<String> choices;

  /// The text list type the entries are stored as.
  static final textList = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "collection.fixture",
      name: "TextList",
    ),
    revision: 1,
  );

  /// The draft the picker writes to.
  final CollectionEditorScenario collection;

  /// The entries the list holds, in order.
  List<String?> get entries => [
    for (final item in collection.value.authoredItems!)
      item.value.authoredString,
  ];

  /// How many times the list changed, one per write: a range of values
  /// added together counts once.
  var changes = 0;
}
