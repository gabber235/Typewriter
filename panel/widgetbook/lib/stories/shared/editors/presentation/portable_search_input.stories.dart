import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Inline choices", type: PortableSearchInput)
Widget authoredSearchInputUseCase(BuildContext context) =>
    portableSearchInputStory(
      width: context.knobs.double.slider(
        label: "Search width",
        initialValue: 360,
        min: 240,
        max: 700,
      ),
      readOnly: context.knobs.boolean(
        label: "Search read only",
        initialValue: false,
      ),
      customValue: context.knobs.boolean(
        label: "Allow custom choices",
        initialValue: false,
      ),
    );

@widgetbook.UseCase(name: "Rich portable result", type: PortableSearchInput)
Widget richPortableSearchInputUseCase(BuildContext context) =>
    portableSearchInputStory(richRows: true);

Widget portableSearchInputStory({
  double width = 360,
  bool readOnly = false,
  bool customValue = false,
  bool richRows = false,
}) => FakeApp(
  child: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchInputStory(
                key: ValueKey((readOnly, customValue, richRows)),
                readOnly: readOnly,
                customValue: customValue,
                richRows: richRows,
              ),
              const SizedBox(height: 20),
              const Text("Description"),
              const TextField(
                decoration: InputDecoration(hintText: "Describe this reward"),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

final class _SearchInputStory extends StatefulWidget {
  const _SearchInputStory({
    required this.readOnly,
    required this.customValue,
    required this.richRows,
    super.key,
  });
  final bool readOnly;
  final bool customValue;
  final bool richRows;

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
  static skir.SearchControl _control({bool richRows = false}) =>
      skir.SearchControl(
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
                sizing: null,
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
            resultAppearance: richRows
                ? skir.ResultAppearance(
                    accent: null,

                    style: skir.ResultStyle.card,
                    kindLabel: skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapStringValue("reward"),
                    ),
                    leading: skir.PresentationNode(
                      nodeId: "reward.result.leading",
                      header: null,
                      properties: skir.PresentationProperties.defaultInstance,
                      element: skir.PresentationElement.wrapIcon(
                        (skir.IconContent.mutable()
                              ..name = skir.ExpressionNode.wrapLiteral(
                                skir.DataValue.wrapStringValue(
                                  "material-symbols:stars",
                                ),
                              ))
                            .toFrozen(),
                      ),
                    ),
                  )
                : null,
          ),
          selectors: const [],
        ),
        summary: null,
        placeholder: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Find a reward"),
        ),
        customValue: null,
        initialQuery: null,
        appearance:
            (skir.InputAppearance.mutable()
                  ..density = skir.ControlDensity.compact
                  ..valueStyle = (skir.InputTextStyle.mutable()..weight = 500)
                      .toFrozen())
                .toFrozen(),
        content:
            (skir.InputContent.mutable()
                  ..placeholder = skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapStringValue("Find a reward"),
                  )
                  ..leading = skir.InputAdornment.none)
                .toFrozen(),
        popup:
            (skir.PopupAppearance.mutable()
                  ..maximumWidth = skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapFloat(480),
                  )
                  ..maximumExtent = skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapFloat(320),
                  )
                  ..padding = skir.PresentationInsets.wrapAll(8))
                .toFrozen(),
        popupSide: skir.PopupSide.below,
        emptyText: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("No matching rewards"),
        ),
        loadingText: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Finding rewards"),
        ),
        empty: null,
        loading: null,
      );

  skir.DataValue _value = skir.DataValue.wrapStringValue("Coin reward");

  late final _host = BoundPresentationHost(
    readOnly: widget.readOnly,
    catalog: skir.EditorCatalogWireSnapshot.defaultInstance
        .asTrustedLocalCatalog(),
    root: () => skir.PresentationNode(
      nodeId: "reward.search",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.wrapSearchInput(
        (_control(richRows: widget.richRows).toMutable()
              ..customValue = widget.customValue
                  ? skir.ExpressionNode.createRead(
                      binding: _control().queryBindingId,
                      path: editorRootPath,
                    )
                  : null)
            .toFrozen(),
      ),
      header: null,
    ),
    bindings: [
      BoundPresentationBinding(
        id: _target,
        use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        read: (_) => _value,
        write: (_, value) async {
          setState(() => _value = value);
          return const PortablePresentationWriteApplied();
        },
      ),
    ],
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
  );

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PortablePresentationRenderer(host: _host);
  }
}
