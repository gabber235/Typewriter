import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/generic/components/drag_handle.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

Widget _dragHandleUseCase(BuildContext context, Axis axis) {
  final isHorizontal = axis == Axis.horizontal;
  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final enabled = context.knobs.boolean(
          label: "Enabled",
          initialValue: true,
        );
        final showOnHover = context.knobs.boolean(
          label: "Show on hover",
          initialValue: true,
        );
        final invert = context.knobs.boolean(
          label: "Invert delta",
          initialValue: true,
        );
        final hitThickness = context.knobs.double.slider(
          label: "Hit thickness",
          initialValue: 16,
          min: 8,
          max: 36,
        );
        final handleThickness = context.knobs.double.slider(
          label: "Handle thickness",
          initialValue: 3,
          min: 1,
          max: 8,
        );
        final handleExtentFactor = context.knobs.double.slider(
          label: "Handle extent factor",
          initialValue: 0.9,
          min: 0.2,
          max: 1.0,
        );
        final maxHandleExtent = context.knobs.double.slider(
          label: "Max handle extent",
          initialValue: 100,
          min: 20,
          max: 200,
        );
        final minSizeKnob = context.knobs.double.slider(
          label: isHorizontal ? "Min width" : "Min height",
          initialValue: isHorizontal ? 200 : 160,
          min: isHorizontal ? 100 : 80,
          max: isHorizontal ? 600 : 400,
        );
        final maxFactor = context.knobs.double.slider(
          label: isHorizontal
              ? "Max width factor (of available)"
              : "Max height factor (of available)",
          initialValue: isHorizontal ? 0.5 : 0.6,
          min: 0.2,
          max: 0.9,
        );

        final size = useState<double>(isHorizontal ? 320 : 240);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isHorizontal ? 1200 : 1000,
              maxHeight: isHorizontal ? 500 : 600,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableMax = isHorizontal
                    ? constraints.maxWidth
                    : constraints.maxHeight;
                final maxSize = availableMax * maxFactor;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: .circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: .circular(12),
                    child: Flex(
                      direction: isHorizontal ? .horizontal : .vertical,
                      crossAxisAlignment: .stretch,
                      children: [
                        Expanded(
                          child: Container(
                            alignment: .center,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            child: const Text("Content"),
                          ),
                        ),
                        DragHandle(
                          axis: axis,
                          enabled: enabled,
                          showOnHover: showOnHover,
                          hitThickness: hitThickness,
                          handleThickness: handleThickness,
                          handleExtentFactor: handleExtentFactor,
                          maxHandleExtent: maxHandleExtent,
                          minSize: minSizeKnob,
                          maxSize: maxSize,
                          getSize: () => size.value,
                          onSizeChange: (v) => size.value = v,
                          sizeResolver: invert
                              ? (s, d) => s - d
                              : (s, d) => s + d,
                        ),
                        Container(
                          width: isHorizontal
                              ? size.value.clamp(minSizeKnob, maxSize)
                              : null,
                          height: isHorizontal
                              ? null
                              : size.value.clamp(minSizeKnob, maxSize),
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: const Center(child: Text("Resizable panel")),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ),
  );
}

@widgetbook.UseCase(name: "Horizontal", type: DragHandle)
Widget dragHandleHorizontalUseCase(BuildContext context) {
  return _dragHandleUseCase(context, Axis.horizontal);
}

@widgetbook.UseCase(name: "Vertical", type: DragHandle)
Widget dragHandleVerticalUseCase(BuildContext context) {
  return _dragHandleUseCase(context, Axis.vertical);
}
