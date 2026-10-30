import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [DragHandle] between page content and a side panel it resizes, along
/// either axis.
@widgetbook.UseCase(name: "Default", type: DragHandle)
Widget dragHandleUseCase(BuildContext context) {
  final axis = context.knobs.object.segmented(
    label: "Axis",
    options: Axis.values,
    labelBuilder: (axis) => axis.name,
    initialOption: Axis.horizontal,
  );
  final enabled = context.knobs.boolean(label: "Enabled");
  return Story(
    const [],
    at: PanelLocation.component(_ResizablePanel(axis: axis, enabled: enabled)),
  );
}

class _ResizablePanel extends HookWidget {
  const _ResizablePanel({required this.axis, required this.enabled});

  final Axis axis;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final size = useState<double>(280);
    final colors = Theme.of(context).colorScheme;
    final horizontal = axis == Axis.horizontal;
    return SizedBox(
      width: 900,
      height: 560,
      child: Flex(
        direction: axis,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: Center(child: Text("Page"))),
          DragHandle(
            semanticLabel: "Inspector size",
            axis: axis,
            enabled: enabled,
            minSize: 160,
            maxSize: 480,
            getSize: () => size.value,
            onSizeChange: (value) => size.value = value,
            sizeResolver: (size, delta) => size - delta,
          ),
          ColoredBox(
            color: colors.surfaceContainer,
            child: SizedBox(
              width: horizontal ? size.value : null,
              height: horizontal ? null : size.value,
              child: const Center(child: Text("Inspector")),
            ),
          ),
        ],
      ),
    );
  }
}
