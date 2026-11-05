import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Inline choices", type: PortableSearchInput)
Widget authoredSearchInputUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Search width",
    initialValue: 360,
    min: 240,
    max: 700,
  );
  final choices = context.knobs.object.segmented(
    label: "Choices",
    options: const ["Rewards", "None"],
    initialOption: "Rewards",
  );
  final readOnly = context.knobs.boolean(label: "Read only");
  final customValue = context.knobs.boolean(label: "Allow custom choices");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: _SearchInputStory(
          key: ValueKey((readOnly, customValue, choices)),
          readOnly: readOnly,
          customValue: customValue,
          rewards: choices == "Rewards",
        ),
      ),
    ),
  );
}

/// A reward field that searches a fixed list of rewards and keeps the one
/// the user chooses.
final class _SearchInputStory extends HookWidget {
  const _SearchInputStory({
    required this.readOnly,
    required this.customValue,
    required this.rewards,
    super.key,
  });

  final bool readOnly;
  final bool customValue;
  final bool rewards;

  static final _target = skir.ExpressionBindingId(value: "target");
  static final _row = skir.ExpressionBindingId(value: "row");
  static final _rowRead = skir.ExpressionNode.createInput(
    binding: _row,
    path: skir.ValuePath(segments: const []),
  );
  static skir.SearchControl _control({required bool rewards}) =>
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
        queryBinding: declareNamedBinding("query", textTemplate),
        summaryBinding: declareNamedBinding("summary", textTemplate),
        maximumExtent: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapInteger("280"),
        ),
        provider: skir.SearchProvider.createStaticValues(
          values: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.createListValue(
              items: [
                if (rewards) ...[
                  skir.ListItem(
                    id: skir.ItemId(value: "coin"),
                    value: skir.DataValue.wrapStringValue("Coin reward"),
                  ),
                  skir.ListItem(
                    id: skir.ItemId(value: "experience"),
                    value: skir.DataValue.wrapStringValue("Experience reward"),
                  ),
                ],
              ],
            ),
          ),
          result: skir.SearchResultMapping(
            binding: declareBinding(_row, textTemplate),
            key: _rowRead,
            selectedValue: _rowRead,
            presentation: presentationText("reward.result", _rowRead),
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

  @override
  Widget build(BuildContext context) {
    final value = useRef(skir.DataValue.wrapStringValue("Coin reward"));
    final control = _control(rewards: rewards);
    final host = useMemoized(
      () => BoundPresentationHost(
        readOnly: readOnly,
        catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
        root: () => skir.PresentationNode(
          nodeId: "reward.search",
          properties: skir.PresentationProperties.defaultInstance,
          element: skir.PresentationElement.wrapSearchInput(
            (control.toMutable()
                  ..customValue = customValue
                      ? skir.ExpressionNode.createInput(
                          binding: control.queryBinding.id,
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
            read: (_) => value.value,
            write: (_, next) async {
              value.value = next;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      ),
    );
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}
