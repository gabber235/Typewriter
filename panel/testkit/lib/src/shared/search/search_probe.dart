import "package:typewriter_panel/typewriter_panel.dart";

/// A child of a [SearchRoot] that reads the search the way real children do,
/// one line each: the collapsed sections as `<label> collapsed: <count>`,
/// the snapshot as `Status: <status>, nodes: <count>`, and its own taps as
/// `Taps: 0` or, once tapped, `Taps: <taps>, collapsed: <count>`, so a test
/// sees whether the probe kept its state.
final class SearchProbe extends HookConsumerWidget {
  const SearchProbe({this.label = "Results", super.key});

  /// What the collapsed line names the sections.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taps = useState(0);
    final controller = ref.watch(searchProvider)!;
    final collapsed = controller.collapsedSectionIds.length;
    final snapshot = controller.snapshot;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label collapsed: $collapsed"),
        Text(
          "Status: ${snapshot.status.name}, nodes: ${snapshot.nodes.length}",
        ),
        GestureDetector(
          onTap: () => taps.value++,
          child: Text(
            taps.value == 0
                ? "Taps: 0"
                : "Taps: ${taps.value}, collapsed: $collapsed",
          ),
        ),
      ],
    );
  }
}
