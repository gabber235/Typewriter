import "package:typewriter_panel/typewriter_panel.dart";

/// A child of a [SearchRoot] that reads the search the way real children do,
/// one line each: `<label> selected: <count>`, the snapshot as
/// `Status: <status>, nodes: <count>`, and its own taps as `Taps: 0` or,
/// once tapped, `Taps: <taps>, selected: <count>`, so a test sees whether
/// the probe kept its state.
final class SearchProbe extends HookConsumerWidget {
  const SearchProbe({this.label = "Results", super.key});

  /// What the selection line names the results.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taps = useState(0);
    final controller = ref.watch(searchProvider)!;
    final selected = controller.selectedCount;
    final snapshot = controller.snapshot;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label selected: $selected"),
        Text(
          "Status: ${snapshot.status.name}, nodes: ${snapshot.nodes.length}",
        ),
        GestureDetector(
          onTap: () => taps.value++,
          child: Text(
            taps.value == 0
                ? "Taps: 0"
                : "Taps: ${taps.value}, selected: $selected",
          ),
        ),
      ],
    );
  }
}
