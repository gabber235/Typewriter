import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The rows of an editor collection: Add slides a row in, Remove squashes
/// one shut, and with reordering a handle drags a row or its menu moves it
/// a step. A read only collection keeps its handles disabled.
@widgetbook.UseCase(name: "Add, remove and reorder", type: CollectionSequence)
Widget collectionSequenceUseCase(BuildContext context) => Story(
  context.knobs.traits("Motion", {
    "Full": const [],
    "Reduced": const [reducedMotion],
  }),
  at: PanelLocation.component(
    CollectionSequenceStory(
      count: context.knobs.object.segmented(
        label: "Items",
        options: const [0, 3, 12],
        initialOption: 3,
        labelBuilder: (count) => switch (count) {
          0 => "Empty",
          3 => "Few",
          _ => "Many",
        },
      ),
      allowReorder: context.knobs.boolean(label: "Reorder", initialValue: true),
      readOnly: context.knobs.boolean(label: "Read only"),
      width: context.knobs.width(const {"Inspector": 420, "Narrow": 240}),
    ),
  ),
);

/// Quest steps on a [CollectionSequence] whose moves, additions and
/// removals the story applies at once.
class CollectionSequenceStory extends HookWidget {
  const CollectionSequenceStory({
    required this.count,
    required this.allowReorder,
    required this.readOnly,
    required this.width,
    super.key,
  });

  final int count;
  final bool allowReorder;
  final bool readOnly;
  final double width;

  static final _steps = skir.ExpressionBindingId(value: "steps");
  static final _collection = skir.BindingRef(
    bindingId: _steps,
    path: editorRootPath,
  );

  static skir.ListItem _item(int number) => skir.ListItem(
    id: skir.ItemId(value: "step$number"),
    value: skir.DataValue.wrapStringValue("Talk to villager $number"),
  );

  @override
  Widget build(BuildContext context) {
    final items = useState([for (var n = 1; n <= count; n++) _item(n)]);
    final next = useRef(count + 1);
    final host = useMemoized(
      () => FakePresentationHost(
        onExecute: (action) {
          if (action case skir.EditorAction_localWrapper(
            value: skir.LocalEditorAction_moveListItemWrapper(:final value),
          )) {
            final moved = items.value.firstWhere(
              (item) => item.id == value.item,
            );
            final rest = [...items.value]..remove(moved);
            final at = value.after == null
                ? 0
                : rest.indexWhere((item) => item.id == value.after) + 1;
            items.value = rest..insert(at, moved);
          }
        },
      ),
    );
    useEffect(() => host.dispose, [host]);
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    final scope = PortablePresentationScope(
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      operations: operations,
      host: host,
      readOnly: readOnly,
    );
    late final CollectionSequence sequence;
    sequence = CollectionSequence(
      scope: scope,
      collection: _collection,
      items: items.value,
      allowReorder: allowReorder,
      entryBuilder: (context, item, index) {
        final text = switch (item.value) {
          skir.DataValue_stringValueWrapper(:final value) => value,
          _ => item.id.value,
        };
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
          child: Row(
            spacing: 8,
            children: [
              sequence.handle(context, index, scope),
              Expanded(
                child: RowLanding(
                  child: EditorTextField(
                    text: text,
                    readOnly: readOnly,
                    semanticLabel: "Step ${index + 1}",
                  ),
                ),
              ),
              Button(
                label: "Remove",
                onPressed: readOnly
                    ? null
                    : () => items.value = [
                        for (final other in items.value)
                          if (other.id != item.id) other,
                      ],
              ),
            ],
          ),
        );
      },
    );
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Button(
              label: "Add step",
              onPressed: readOnly
                  ? null
                  : () => items.value = [...items.value, _item(next.value++)],
            ),
          ),
          if (items.value.isEmpty) const Text("No steps yet"),
          sequence,
        ],
      ),
    );
  }
}
