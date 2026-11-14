import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A row that grows open with surfaceIn and shrinks with panelOut; Escape in
/// the open body closes it and returns focus to its header.
class _Card extends HookWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(ExpansibleController.new);
    useEffect(() => controller.dispose, [controller]);
    return SizedBox(
      width: 360,
      child: GrowingCard(
        controller: controller,
        header: (context, animation) => Button(
          face: ButtonFace.bare,
          label: "Spring join code",
          onPressed: () => controller.isExpanded
              ? controller.collapse()
              : controller.expand(),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.space3),
            child: Row(
              children: [
                const Expanded(child: Text("Spring join code")),
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.5).animate(animation),
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
        body: (context) => Padding(
          padding: EdgeInsets.all(context.spacing.space3),
          child: const Text("Single use, expires in seven days."),
        ),
      ),
    );
  }
}

@widgetbook.UseCase(name: "Default", type: GrowingCard)
Widget growingCardUseCase(BuildContext context) =>
    Story(const [], at: const PanelLocation.component(_Card()));
