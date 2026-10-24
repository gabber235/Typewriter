import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Ordinary content", type: AppBarControlContent)
Widget appBarControlContentUseCase(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Search");
  final width = context.knobs.double.slider(
    label: "Allocated width",
    initialValue: 220,
    min: 48,
    max: 360,
  );
  final shortcut = context.knobs.boolean(
    label: "Show shortcut",
    initialValue: true,
  );
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: width,
        height: 48,
        child: AppBarControl.filled(
          contentBuilder: (context, compact) => AppBarControlContent(
            compact: compact,
            icon: const Icon(Icons.search, size: 18),
            label: label,
            shortcut: shortcut ? const Text("⌘ K") : null,
          ),
          tooltip: label,
          semanticLabel: label,
          onPressed: () {},
        ),
      ),
    ),
  );
}
