import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// How the story renders its rows.
enum RowFocusLayout {
  /// An [AnimatedTable] under [RowFocusKeys]: one stop per row.
  table("Table"),

  /// A card list: each card is one stop.
  cards("Cards"),

  /// Editor style rows: each row holds controls and focus lands on its
  /// [RowLanding].
  editor("Editor");

  const RowFocusLayout(this.label);

  final String label;
}

/// One list whose focus [RowFocus] owns: the page opens on the first row,
/// a removed focused row hands focus to the next survivor, and an announced
/// create takes focus when its row arrives. The buttons never take focus,
/// so they act on the focused row.
@widgetbook.UseCase(name: "Row focus", type: RowFocus)
Widget rowFocusUseCase(BuildContext context) {
  final layout = context.knobs.object.segmented(
    label: "Layout",
    options: RowFocusLayout.values,
    initialOption: RowFocusLayout.table,
    labelBuilder: (layout) => layout.label,
  );
  return Story(
    context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
    at: PanelLocation.component(RowFocusStory(layout: layout)),
  );
}

class RowFocusStory extends HookWidget {
  const RowFocusStory({this.layout = RowFocusLayout.table, super.key});

  final RowFocusLayout layout;

  @override
  Widget build(BuildContext context) {
    final items = useState(const ["Alpha", "Beta", "Gamma"]);
    final created = useRef(1);
    final focus = useRowFocus(debugLabel: "Row focus story");
    final rows = useAnimatedRows<String>(
      items: items.value,
      identity: (item) => item,
      focus: focus,
    );

    void remove(Object? id) => items.value = [
      for (final item in items.value)
        if (item != id) item,
    ];
    String nextName() => "Row ${created.value++}";

    final controls = ExcludeFocus(
      child: Wrap(
        spacing: 8,
        children: [
          Button(
            label: "Remove focused",
            onPressed: () => remove(focus.focusedId),
          ),
          Button(
            label: "Add from elsewhere",
            onPressed: () => items.value = [...items.value, nextName()],
          ),
          Button(
            label: "Announce a create",
            onPressed: () {
              final name = nextName();
              focus.expect(name);
              items.value = [...items.value, name];
            },
          ),
          Button(
            label: "Send focused",
            onPressed: () async {
              final id = focus.focusedId;
              if (id == null) return;
              await rows.sending([id], () async {
                await Future<void>.delayed(const Duration(seconds: 1));
                remove(id);
              });
            },
          ),
        ],
      ),
    );

    return Pane(
      id: "row-focus",
      primary: true,
      openFocus: PaneOpenFocus.firstItem,
      child: SizedBox(
        width: 480,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            controls,
            const SizedBox(height: 16),
            Expanded(
              child: switch (layout) {
                RowFocusLayout.table => _table(rows),
                RowFocusLayout.cards => _list(rows, _card),
                RowFocusLayout.editor => _list(
                  rows,
                  (entry) => _editorRow(entry, remove),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(AnimatedRows<String> rows) => SingleChildScrollView(
    child: AnimatedTable(
      rows: rows,
      rowBuilder: (context, entry) => TableRow(
        children: [
          RowStop(
            bounds: RingBounds.tableRow,
            label: entry.item,
            child: _cell(entry.item),
          ),
          RowStop(
            role: RowRole.part,
            bounds: RingBounds.tableRow,
            child: _cell("Member"),
          ),
        ],
      ),
    ),
  );

  Widget _list(
    AnimatedRows<String> rows,
    Widget Function(RowEntry<String> entry) row,
  ) => CustomScrollView(
    slivers: [
      SliverAnimatedRows(
        rows: rows,
        itemBuilder: (context, entry) => row(entry),
      ),
    ],
  );

  Widget _cell(String text) =>
      Padding(padding: const EdgeInsets.all(12), child: Text(text));

  Widget _card(RowEntry<String> entry) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RowStop(
      label: entry.item,
      borderRadius: BorderRadius.circular(8),
      child: Builder(
        builder: (context) => DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _cell(entry.item),
        ),
      ),
    ),
  );

  Widget _editorRow(RowEntry<String> entry, void Function(Object? id) remove) =>
      RowStop(
        role: RowRole.holder,
        child: Row(
          children: [
            Expanded(
              child: RowLanding(
                child: Button(label: entry.item, onPressed: () {}),
              ),
            ),
            Button(label: "Remove", onPressed: () => remove(entry.id)),
          ],
        ),
      );
}

/// Card rows that are one [RowStop] each: Tab enters the list on the
/// focused card, the arrow keys move between cards, and Remove focused
/// hands focus to the next card.
@widgetbook.UseCase(name: "Card stops", type: RowStop)
Widget rowStopUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: const PanelLocation.component(
      RowFocusStory(layout: RowFocusLayout.cards),
    ),
  );
}

/// Editor rows that hold controls: focus lands on each row's
/// [RowLanding], its name button, never on Remove.
@widgetbook.UseCase(name: "Editor rows", type: RowLanding)
Widget rowLandingUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: const PanelLocation.component(
      RowFocusStory(layout: RowFocusLayout.editor),
    ),
  );
}
