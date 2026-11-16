import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [AnimatedTable] of members under a header row: Add slides a row in,
/// a row's Remove squashes it shut with all its cells, and once the last
/// row has left the empty state shows. Starting empty shows it at once.
@widgetbook.UseCase(name: "Members", type: AnimatedTable)
Widget animatedTableUseCase(BuildContext context) {
  final start = context.knobs.object.segmented(
    label: "Start",
    options: const ["Rows", "Empty"],
    initialOption: "Rows",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      _MembersTable(
        initial: start == "Empty" ? const [] : const ["Ada", "Grace", "Linus"],
      ),
    ),
  );
}

class _MembersTable extends HookWidget {
  const _MembersTable({required this.initial});

  final List<String> initial;

  @override
  Widget build(BuildContext context) {
    final members = useState(initial);
    final next = useRef(1);
    final focus = useRowFocus(debugLabel: "Animated table story");
    final rows = useAnimatedRows<String>(
      items: members.value,
      identity: (member) => member,
      focus: focus,
    );
    Widget cell(Widget child) =>
        Padding(padding: const EdgeInsets.all(12), child: child);
    return SizedBox(
      width: 480,
      height: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Button(
            label: "Add member",
            onPressed: () =>
                members.value = [...members.value, "Member ${next.value++}"],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: AnimatedTable(
                rows: rows,
                headerRows: [
                  TableRow(
                    children: [
                      cell(const Text("Name")),
                      cell(const Text("Role")),
                      cell(const SizedBox.shrink()),
                    ],
                  ),
                ],
                columnWidths: const {2: IntrinsicColumnWidth()},
                emptyBuilder: (context) => const EmptyState(
                  title: "No members",
                  description: "Members who join appear here",
                ),
                rowBuilder: (context, entry) => TableRow(
                  children: [
                    RowStop(
                      bounds: RingBounds.tableRow,
                      label: entry.item,
                      child: cell(Text(entry.item)),
                    ),
                    RowStop(
                      role: RowRole.part,
                      bounds: RingBounds.tableRow,
                      child: cell(const Text("Editor")),
                    ),
                    RowStop(
                      role: RowRole.part,
                      bounds: RingBounds.tableRow,
                      child: Button(
                        face: ButtonFace.icon,
                        icon: const Icon(Icons.close),
                        label: "Remove ${entry.item}",
                        tooltip: "Remove",
                        onPressed: () => members.value = [
                          for (final member in members.value)
                            if (member != entry.id) member,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
