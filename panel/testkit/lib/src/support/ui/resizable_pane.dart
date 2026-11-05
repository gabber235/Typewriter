import "package:typewriter_panel/typewriter_panel.dart";

/// A pane labeled "Pane" at the end of [axis] whose size a [DragHandle]
/// before it owns, in an 800 wide area (300 high when horizontal, 800 when
/// vertical).
final class ResizablePane extends StatefulWidget {
  /// A pane of [initialSize] the handle resizes between [minSize] and
  /// [maxSize], through [resolver] when given.
  const ResizablePane({
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
    this.axis = Axis.horizontal,
    this.enabled = true,
    this.resolver,
    super.key,
  });

  /// The direction the handle resizes along.
  final Axis axis;

  /// The pane size before any resize.
  final double initialSize;

  /// The smallest size the handle allows.
  final double minSize;

  /// The largest size the handle allows.
  final double maxSize;

  /// Whether the handle resizes at all.
  final bool enabled;

  /// How a drag changes the size; null uses the handle's default.
  final SizeResolver? resolver;

  @override
  State<ResizablePane> createState() => _ResizablePaneState();
}

class _ResizablePaneState extends State<ResizablePane> {
  late double size = widget.initialSize;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    return SizedBox(
      width: 800,
      height: horizontal ? 300 : 800,
      child: Flex(
        direction: widget.axis,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          DragHandle(
            axis: widget.axis,
            enabled: widget.enabled,
            minSize: widget.minSize,
            maxSize: widget.maxSize,
            getSize: () => size,
            onSizeChange: (value) => setState(() => size = value),
            sizeResolver: widget.resolver,
            animationDuration: const Duration(milliseconds: 100),
          ),
          Semantics(
            container: true,
            label: "Pane",
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              width: horizontal ? size : null,
              height: horizontal ? null : size,
            ),
          ),
        ],
      ),
    );
  }
}
