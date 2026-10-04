import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Static choices", type: PortableSearchInput)
Widget authoredSearchInputUseCase(BuildContext context) => const FakeApp(
  child: Scaffold(
    body: Center(child: SizedBox(width: 420, child: _SearchInputStory())),
  ),
);

final class _SearchInputStory extends StatefulWidget {
  const _SearchInputStory();

  @override
  State<_SearchInputStory> createState() => _SearchInputStoryState();
}

final class _SearchInputStoryState extends State<_SearchInputStory> {
  static final _target = skir.ExpressionBindingId(value: "target");
  static final _row = skir.ExpressionBindingId(value: "row");
  static final _rowRead = skir.ExpressionNode.createRead(
    binding: _row,
    path: skir.ValuePath(segments: const []),
  );
  static final _control = skir.SearchControl(
    control: skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: _target,
        path: skir.ValuePath(segments: const []),
      ),
      label: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Reward"),
      ),
      description: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue(
          "Search with the keyboard or select a result",
        ),
      ),
      prefix: null,
      semanticLabel: null,
    ),
    selectionMode: skir.SearchSelectionMode.single,
    queryBindingId: skir.ExpressionBindingId(value: "query"),
    summaryBindingId: skir.ExpressionBindingId(value: "summary"),
    maximumExtent: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapInteger("280"),
    ),
    provider: skir.SearchProvider.createStaticValues(
      values: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.createListValue(
          items: [
            skir.ListItem(
              id: skir.ItemId(value: "coin"),
              value: skir.DataValue.wrapStringValue("Coin reward"),
            ),
            skir.ListItem(
              id: skir.ItemId(value: "experience"),
              value: skir.DataValue.wrapStringValue("Experience reward"),
            ),
          ],
        ),
      ),
      result: skir.SearchResultMapping(
        bindingId: _row,
        key: _rowRead,
        selectedValue: _rowRead,
        presentation: skir.PresentationNode(
          nodeId: "reward.result",
          properties: skir.PresentationProperties.defaultInstance,
          element: skir.PresentationElement.createText(
            value: _rowRead,
            color: null,
            fontSize: null,
            fontWeight: null,
            fontItalic: null,
            fontOpticalSize: null,
            fontSlant: null,
            fontWidth: null,
            textAlignment: null,
            lineHeight: null,
            letterSpacing: null,
            decoration: null,
            semanticLabel: null,
            paragraph: skir.TextParagraph.defaultInstance,
          ),
          header: null,
        ),
        label: _rowRead,
      ),
      selectors: const [],
    ),
    summary: null,
    placeholder: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue("Find a reward"),
    ),
    customValue: null,
    initialQuery: null,
  );

  skir.DataValue _value = skir.DataValue.unfilled;

  @override
  Widget build(BuildContext context) => PortableSearchInput(
    control: _control,
    scope: PortablePresentationScope(
      bindings: {_target: PortableExpressionBinding(value: _value)},
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      setBinding: (_, value) => setState(() => _value = value),
    ),
  );
}
