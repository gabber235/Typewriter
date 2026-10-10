import "package:typewriter_panel/typewriter_panel.dart";

/// Reads the dimension controlled by a [DragHandle].
typedef SizeGetter = double Function();

/// Receives each bounded dimension produced by a drag.
typedef SizeChanged = void Function(double size);

/// Converts the drag start dimension and logical pixel delta into a dimension.
typedef SizeResolver = double Function(double startSize, double delta);

/// Resizes an owner supplied dimension through horizontal or vertical dragging.
///
/// The handle owns only the gesture session and cursor override. The caller
/// remains authoritative for the resized value through [getSize] and
/// [onSizeChange]. Bounds are applied before each size update, and the cursor
/// is reset when the drag ends.
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
    this.keyboardStep = 8,
    this.semanticLabel = "Resize dimension",
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
  /// Provide a custom resolver to invert behavior or implement nonlinear scaling.
  final SizeResolver? sizeResolver;

  /// Whether the handle is interactive and visible.
  final bool enabled;

  final double keyboardStep;

  final String semanticLabel;

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
    final focused = useState(false);
    final focusNode = useFocusNode();
    final startSize = useState(0.0);
    final startPosition = useState(Offset.zero);
    final isDragging = useState(false);

    final resize = DimensionResizeOperation(
      getSize: getSize,
      onSizeChange: onSizeChange,
      minSize: minSize,
      maxSize: maxSize,
      sizeResolver: sizeResolver,
    );
    final showHandle =
        !showOnHover || hovering.value || focused.value || isDragging.value;

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

      resize.from(startSize.value, delta);
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

    return FocusableActionDetector(
      focusNode: focusNode,
      enabled: enabled,
      onShowFocusHighlight: (value) => focused.value = value,
      shortcuts: {
        SingleActivator(
          axis == Axis.horizontal
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowUp,
        ): ResizeDimensionIntent(
          delta: -keyboardStep,
        ),
        SingleActivator(
          axis == Axis.horizontal
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowDown,
        ): ResizeDimensionIntent(
          delta: keyboardStep,
        ),
        if (minSize != null)
          const SingleActivator(LogicalKeyboardKey.home):
              const ResizeDimensionToBoundIntent(DimensionResizeBound.minimum),
        if (maxSize != null)
          const SingleActivator(LogicalKeyboardKey.end):
              const ResizeDimensionToBoundIntent(DimensionResizeBound.maximum),
      },
      actions: {
        ResizeDimensionIntent: CallbackAction<ResizeDimensionIntent>(
          onInvoke: (intent) {
            if (enabled) resize.by(intent.delta);
            return null;
          },
        ),
        ResizeDimensionToBoundIntent:
            CallbackAction<ResizeDimensionToBoundIntent>(
              onInvoke: (intent) {
                if (enabled) resize.toBound(intent.bound);
                return null;
              },
            ),
      },
      child: Semantics(
        label: semanticLabel,
        value: getSize().round().toString(),
        increasedValue: resize
            .resolve(getSize(), keyboardStep)
            .round()
            .toString(),
        decreasedValue: resize
            .resolve(getSize(), -keyboardStep)
            .round()
            .toString(),
        onIncrease: enabled ? () => resize.by(keyboardStep) : null,
        onDecrease: enabled ? () => resize.by(-keyboardStep) : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: focused.value
                  ? context.colors.focusRing
                  : context.colors.focusRing.withValues(alpha: 0),
              width: 2,
            ),
          ),
          child: MouseRegion(
            cursor: cursor ?? defaultCursor,
            onEnter: (_) => hovering.value = true,
            onExit: (_) => hovering.value = false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTap: enabled ? focusNode.requestFocus : null,
              onHorizontalDragStart: enabled && axis == Axis.horizontal
                  ? onStart
                  : null,
              onHorizontalDragUpdate: enabled && axis == Axis.horizontal
                  ? onUpdate
                  : null,
              onHorizontalDragEnd: enabled && axis == Axis.horizontal
                  ? (_) => onEnd()
                  : null,
              onHorizontalDragCancel: enabled && axis == Axis.horizontal
                  ? onEnd
                  : null,
              onVerticalDragStart: enabled && axis == Axis.vertical
                  ? onStart
                  : null,
              onVerticalDragUpdate: enabled && axis == Axis.vertical
                  ? onUpdate
                  : null,
              onVerticalDragEnd: enabled && axis == Axis.vertical
                  ? (_) => onEnd()
                  : null,
              onVerticalDragCancel: enabled && axis == Axis.vertical
                  ? onEnd
                  : null,
              child: sizedBox,
            ),
          ),
        ),
      ),
    );
  }
}
