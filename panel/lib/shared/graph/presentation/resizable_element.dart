import "package:typewriter_panel/typewriter_panel.dart";

/// Adds a corner resize handle and transient outline to a graph element.
///
/// Pointer dimensions are rounded to [cellSize] and clamped to one cell. The
/// callbacks receive preview values during the gesture and the final value on
/// completion. The parent owns persistence and may omit callbacks to disable
/// resizing.
class ResizableElement extends HookConsumerWidget {
  const ResizableElement({
    required this.element,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.child,
    required this.cellSize,
    this.handleSize = 25,
    this.onResizeCancel,
    super.key,
  });

  final GraphElement element;
  final GraphResizeCallback? onResizeStart;
  final GraphResizeCallback? onResizeUpdate;
  final GraphResizeCallback? onResizeEnd;
  final VoidCallback? onResizeCancel;
  final Widget child;
  final double cellSize;
  final double handleSize;

  /// What assistive technology reads for the corner resize handle.
  static const resizeHandleLabel = "Resize";

  (int, int) _calculateNewSize(
    double deltaWidth,
    double deltaHeight,
    int originalWidth,
    int originalHeight,
  ) {
    final deltaCellWidth = (deltaWidth / cellSize).round();
    final deltaCellHeight = (deltaHeight / cellSize).round();
    return (
      max(originalWidth + deltaCellWidth, 1),
      max(originalHeight + deltaCellHeight, 1),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovering = useState(false);
    final startData = useState<(Offset, int, int)?>(null);
    // The handle shows while hovered and through a resize.
    final shown = isHovering.value || startData.value != null;
    final animation = useMotion(
      shown ? MotionToken.hoverIn : MotionToken.hoverOut,
      shown ? 1.0 : 0.0,
    ).value;

    /// The size the element takes with the handle at [position], or null
    /// when no resize is in progress.
    (int, int)? sizeAt(Offset position) {
      final start = startData.value;
      if (start == null) return null;
      final delta = position - start.$1;
      return _calculateNewSize(delta.dx, delta.dy, start.$2, start.$3);
    }

    void resetInteraction() {
      startData.value = null;
      ref.read(cursorControllerProvider.notifier).reset();
    }

    return ResizableElementSurface(
      handleSize: handleSize,
      animationProgress: animation,
      outlineColor: Theme.of(context).colorScheme.onSurface,
      gestureDetector: MouseRegion(
        onEnter: (_) {
          isHovering.value = true;
        },
        onExit: (_) {
          isHovering.value = false;
        },
        cursor: startData.value != null
            ? SystemMouseCursors.grabbing
            : !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS
            ? SystemMouseCursors.grab
            : SystemMouseCursors.resizeUpLeftDownRight,
        // A cancelled pointer ends the pan like a release, so the cancel is
        // caught before the pan recognizer sees it and the resize is dropped
        // instead of committed.
        child: Listener(
          onPointerCancel: (_) {
            if (startData.value == null) return;
            onResizeCancel?.call();
            resetInteraction();
          },
          child: GestureDetector(
            onPanStart: onResizeStart == null
                ? null
                : (details) {
                    ref
                        .read(cursorControllerProvider.notifier)
                        .cursor(SystemMouseCursors.grabbing);
                    startData.value = (
                      details.localPosition,
                      element.width,
                      element.height,
                    );
                    onResizeStart!(element.id, element.width, element.height);
                  },
            onPanUpdate: onResizeUpdate == null
                ? null
                : (details) {
                    final size = sizeAt(details.localPosition);
                    if (size == null) return;
                    onResizeUpdate!(element.id, size.$1, size.$2);
                  },
            onPanEnd: onResizeEnd == null
                ? null
                : (details) {
                    final size = sizeAt(details.localPosition);
                    if (size == null) return;
                    onResizeEnd!(element.id, size.$1, size.$2);
                    resetInteraction();
                  },
            child: Semantics(
              container: true,
              label: resizeHandleLabel,
              child: ColoredBox(
                color: Colors.transparent,
                child: SizedBox(width: handleSize, height: handleSize),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
