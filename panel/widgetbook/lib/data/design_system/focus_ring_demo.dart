import "package:typewriter_panel/typewriter_panel.dart";

/// Everything the focus ring layer rings, for Tab and the arrow keys: two
/// panes of rows, a button, a field and a table row, and a search field
/// whose result cursor carries the ring while the field keeps focus.
class FocusRingDemo extends StatelessWidget {
  const FocusRingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.space2);
    Widget row(String label) => Padding(
      padding: EdgeInsets.only(bottom: context.spacing.space1),
      child: RingTarget(
        borderRadius: context.shapes.mediumBorderRadius,
        child: Focus(child: _Row(label)),
      ),
    );
    return SizedBox(
      width: 760,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (var index = 1; index <= 3; index++)
                              row("Left $index"),
                          ],
                        ),
                      ),
                      SizedBox(width: context.spacing.space4),
                      Expanded(
                        child: Column(
                          children: [
                            for (var index = 1; index <= 3; index++)
                              row("Right $index"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  gap,
                  TextButton(onPressed: () {}, child: const Text("Invite")),
                  gap,
                  const TextField(
                    decoration: InputDecoration(hintText: "Display name"),
                  ),
                  gap,
                  Table(
                    children: [
                      for (final member in ["Ada", "Ben"])
                        TableRow(
                          children: [
                            RingTarget(
                              bounds: RingBounds.tableRow,
                              child: Focus(child: _Row(member)),
                            ),
                            _Row("$member role"),
                            _Row("${member.toLowerCase()}@typewriter.test"),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: context.spacing.space6),
            const Expanded(child: _CursorList()),
          ],
        ),
      ),
    );
  }
}

/// A query field whose arrow keys move a [RingCursor] over its results.
class _CursorList extends HookWidget {
  const _CursorList();

  static const _results = ["Ada", "Ben", "Cleo", "Dara"];

  @override
  Widget build(BuildContext context) {
    final cursor = useState(0);
    void move(int by) =>
        cursor.value = (cursor.value + by).clamp(0, _results.length - 1);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => move(-1),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextField(decoration: InputDecoration(hintText: "Search")),
          SizedBox(height: context.spacing.space2),
          for (final (index, result) in _results.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing.space1),
              child: RingCursor(
                active: index == cursor.value,
                borderRadius: context.shapes.mediumBorderRadius,
                child: _Row(result),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space3),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: context.shapes.mediumBorderRadius,
      ),
      child: Text(label, style: context.theme.textTheme.bodyMedium),
    );
  }
}
