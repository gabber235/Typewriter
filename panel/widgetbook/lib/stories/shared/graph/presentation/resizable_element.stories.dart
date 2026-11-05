import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: ResizableElement)
Widget resizableElementUseCase(BuildContext context) {
  final width = context.knobs.int.slider(
    label: "Width",
    initialValue: 4,
    min: 1,
    max: 8,
  );
  final height = context.knobs.int.slider(
    label: "Height",
    initialValue: 2,
    min: 1,
    max: 6,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      ResizableElementStory(
        key: ValueKey((width, height)),
        width: width,
        height: height,
      ),
    ),
  );
}

/// A graph node on its grid that keeps the size its handle is dragged to and
/// names that size.
class ResizableElementStory extends HookWidget {
  const ResizableElementStory({
    required this.width,
    required this.height,
    super.key,
  });

  final int width;
  final int height;

  static const cellSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final size = useState((width, height));
    void resize(GraphIdentifier _, int width, int height) =>
        size.value = (width, height);
    final (columns, rows) = size.value;
    final element = GraphElement(
      id: const GraphIdentifier("quest"),
      x: 1,
      y: 1,
      width: columns,
      height: rows,
      builder: (_) => const SizedBox(),
    );
    return SizedBox(
      width: cellSize * 12,
      height: cellSize * 9,
      child: Stack(
        children: [
          Positioned(
            left: element.x * cellSize,
            top: element.y * cellSize,
            child: ResizableElement(
              element: element,
              cellSize: cellSize,
              onResizeStart: resize,
              onResizeUpdate: resize,
              onResizeEnd: resize,
              child: Container(
                width: columns * cellSize,
                height: rows * cellSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text("Quest $columns x $rows"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
