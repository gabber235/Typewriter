import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A quest title field inside an [InputFieldContainer]: keyboard focus first
/// lands on the container, Enter starts editing, Escape leaves it.
@widgetbook.UseCase(name: "Default", type: InputFieldContainer)
Widget inputFieldContainerUseCase(BuildContext context) {
  final square = context.knobs.boolean(label: "Square highlight");
  return Story(
    const [],
    at: PanelLocation.component(
      InputFieldContainerStory(squareCorners: square),
    ),
  );
}

/// A quest title field inside an [InputFieldContainer].
class InputFieldContainerStory extends HookWidget {
  const InputFieldContainerStory({this.squareCorners = false, super.key});

  final bool squareCorners;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(
      () => InputFieldController(inputDebugLabel: "Quest title input"),
    );
    useEffect(() => controller.dispose, [controller]);
    return SizedBox(
      width: 360,
      child: InputFieldContainer(
        controller: controller,
        borderRadius: squareCorners ? BorderRadius.zero : null,
        child: EditorTextField(
          text: "The lost lantern",
          focusNode: controller.inputFocusNode,
          hintText: "Quest title",
        ),
      ),
    );
  }
}
