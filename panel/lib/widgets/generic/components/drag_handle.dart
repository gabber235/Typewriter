import "dart:math" show min;

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/widgets/generic/components/cursor_controller.dart";

typedef SizeGetter = double Function();
typedef SizeChanged = void Function(double size);
typedef SizeResolver = double Function(double startSize, double delta);

/// A reusable drag handle for resizing layouts horizontally or vertically.
///
/// - Supports both [Axis.horizontal] and [Axis.vertical].
/// - Reports size changes via [onSizeChange], with optional [minSize]/[maxSize] clamping.
/// - Reads the current size via [getSize] so the handle can compute deltas reliably.
/// - Customizable hit area thickness ([hitThickness]) and visible handle thickness ([handleThickness]).
/// - Shows the handle bar on hover or while dragging. Set [showOnHover] to false to always show the bar.
/// - Use [sizeResolver] to customize how drag delta maps to size changes (e.g., invert direction).
class DragHandle extends HookConsumerWidget {
  const DragHandle({
    required this.axis,
    required this.getSize,
    required this.onSizeChange,
    super.key,
    this.minSize,
    this.maxSize,
    this.sizeResolver,
    this.enabled = true,
    this.hitThickness = 16,
    this.handleThickness = 3,
    this.handleRadius = 4,
    this.handleExtentFactor = 0.9,
    this.maxHandleExtent = 100,
    this.showOnHover = true,
    this.color,
    this.cursor,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
    this.onDragStart,
    this.onDragEnd,
  });

  /// The drag direction.
  final Axis axis;

  /// Returns the current size of the resizable area.
  final SizeGetter getSize;

  /// Called with the clamped new size when the user drags the handle.
  final SizeChanged onSizeChange;

  /// Optional minimum size when dragging.
  final double? minSize;

  /// Optional maximum size when dragging.
  final double? maxSize;

  /// Maps the starting size and drag delta (in logical pixels along [axis]) to a new size.
  ///
  /// Defaults to `(start, delta) => start + delta`.
  /// Provide a custom resolver to invert behavior or implement non-linear scaling.
  final SizeResolver? sizeResolver;

  /// Whether the handle is interactive and visible.
  final bool enabled;

  /// The interactive hit area thickness perpendicular to [axis].
  final double hitThickness;

  /// The visible bar thickness perpendicular to [axis].
  final double handleThickness;

  /// The corner radius of the visible bar.
  final double handleRadius;

  /// The fraction of available space used for the visible bar's length along [axis].
  final double handleExtentFactor;

  /// The maximum length of the visible bar along [axis].
  final double maxHandleExtent;

  /// If true, the visible bar appears only on hover or while dragging.
  final bool showOnHover;

  /// The visible bar color. Defaults to `Theme.of(context).colorScheme.onSurface` with opacity.
  final Color? color;

  /// The mouse cursor when hovering over the handle. Defaults based on [axis].
  final MouseCursor? cursor;

  /// Animation duration for show/hide of the visible bar.
  final Duration animationDuration;

  /// Animation curve for show/hide of the visible bar.
  final Curve animationCurve;

  /// Optional callback when a drag starts.
  final VoidCallback? onDragStart;

  /// Optional callback when a drag stops.
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return const SizedBox.shrink();

    final hovering = useState(false);
    final startSize = useState(0.0);
    final startPosition = useState(Offset.zero);
    final isDragging = useState(false);

    final showHandle =
        (showOnHover && (hovering.value || isDragging.value)) || !showOnHover;

    final defaultCursor = axis == Axis.horizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;

    void onStart(DragStartDetails details) {
      startSize.value = getSize();
      startPosition.value = details.globalPosition;
      isDragging.value = true;
      onDragStart?.call();
      ref
          .read(cursorControllerProvider.notifier)
          .cursor(cursor ?? defaultCursor);
    }

    void onUpdate(DragUpdateDetails details) {
      final position = details.globalPosition;
      final delta = axis == Axis.horizontal
          ? position.dx - startPosition.value.dx
          : position.dy - startPosition.value.dy;

      final resolve = sizeResolver ?? (double s, double d) => s + d;
      var next = resolve(startSize.value, delta);

      if (minSize != null && next < minSize!) {
        next = minSize!;
      }
      if (maxSize != null && next > maxSize!) {
        next = maxSize!;
      }

      onSizeChange(next);
    }

    void onEnd() {
      startSize.value = 0.0;
      startPosition.value = Offset.zero;
      isDragging.value = false;
      onDragEnd?.call();
      ref.read(cursorControllerProvider.notifier).reset();
    }

    final barColor =
        color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);

    Widget buildBar(BoxConstraints constraints) {
      final extentMax = axis == Axis.horizontal
          ? constraints.maxHeight
          : constraints.maxWidth;
      final extent = min(extentMax * handleExtentFactor, maxHandleExtent);

      final width = axis == Axis.horizontal ? handleThickness : extent;
      final height = axis == Axis.horizontal ? extent : handleThickness;

      return AnimatedContainer(
        duration: animationDuration,
        curve: animationCurve,
        width: showHandle ? width : 0,
        height: showHandle ? height : 0,
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(handleRadius),
        ),
      );
    }

    final sizedBox = SizedBox(
      width: axis == Axis.horizontal ? hitThickness : null,
      height: axis == Axis.vertical ? hitThickness : null,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) => buildBar(constraints),
        ),
      ),
    );

    return MouseRegion(
      cursor: cursor ?? defaultCursor,
      onEnter: (_) => hovering.value = true,
      onExit: (_) => hovering.value = false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: axis == Axis.horizontal ? onStart : null,
        onHorizontalDragUpdate: axis == Axis.horizontal ? onUpdate : null,
        onHorizontalDragEnd: axis == Axis.horizontal ? (_) => onEnd() : null,
        onVerticalDragStart: axis == Axis.vertical ? onStart : null,
        onVerticalDragUpdate: axis == Axis.vertical ? onUpdate : null,
        onVerticalDragEnd: axis == Axis.vertical ? (_) => onEnd() : null,
        child: sizedBox,
      ),
    );
  }
}
