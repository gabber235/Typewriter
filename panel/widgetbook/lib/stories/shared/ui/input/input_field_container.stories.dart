import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Navigation and editing focus",
  type: InputFieldContainer,
)
Widget inputFieldContainerUseCase(BuildContext context) =>
    InputFieldContainerStory(
      width: context.knobs.double.slider(
        label: "Field width",
        initialValue: 360,
        min: 220,
        max: 600,
      ),
      squareCorners: context.knobs.boolean(
        label: "Square highlight",
        initialValue: false,
      ),
    );

/// Wraps a plain text input so its surrounding and editing focus can be
/// compared with the global interaction mode.
class InputFieldContainerStory extends HookWidget {
  const InputFieldContainerStory({
    this.width = 360,
    this.squareCorners = false,
    super.key,
  });

  final double width;
  final bool squareCorners;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(
      () => InputFieldController(inputDebugLabel: "Quest title input"),
    );
    useEffect(() => controller.dispose, [controller]);
    final text = useTextEditingController(text: "The lost lantern");
    final dismissals = useState(0);
    return FakeApp(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Align(child: ModeDisplayWidget()),
            const Text("Quest title"),
            InputFieldContainer(
              controller: controller,
              borderRadius: squareCorners ? BorderRadius.zero : null,
              onDismiss: () => dismissals.value++,
              child: TextField(
                controller: text,
                focusNode: controller.inputFocusNode,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            Text("Left editing ${dismissals.value} times"),
            const Text(
              "Tab focuses the container. Enter starts editing the input. "
              "Escape leaves editing and keeps the typed text.",
            ),
          ],
        ),
      ),
    );
  }
}
