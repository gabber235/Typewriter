import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Interactive content", type: AnchoredPopup)
Widget anchoredPopupUseCase(BuildContext context) {
  final right = context.knobs.boolean(label: "Align right", initialValue: true);
  return AnchoredPopupStory(right: right);
}

class AnchoredPopupStory extends StatelessWidget {
  const AnchoredPopupStory({this.right = true, super.key});
  final bool right;

  @override
  Widget build(BuildContext context) => FakeApp(
    child: Align(
      alignment: right ? Alignment.topRight : Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnchoredPopup(
          targetAnchor: right ? Alignment.bottomRight : Alignment.bottomLeft,
          popupAnchor: right ? Alignment.topRight : Alignment.topLeft,
          offset: const Offset(0, 8),
          builder: (context, show) =>
              TextButton(onPressed: show, child: const Text("Open activity")),
          popupBuilder: (context, close) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text("Activity")),
                    IconButton(
                      tooltip: "Close",
                      onPressed: close,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const TextField(
                  autofocus: true,
                  decoration: InputDecoration(labelText: "Filter activity"),
                ),
                const Text(
                  "Hover Close, or press Escape to return to the trigger.",
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
