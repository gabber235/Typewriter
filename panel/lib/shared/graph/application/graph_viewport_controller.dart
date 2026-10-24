import "package:typewriter_panel/typewriter_panel.dart";

/// Owns the graph viewport transform and its cancellable animations.
///
/// The controller owns both animation and transformation resources. Call
/// [dispose] when the graph leaves the tree. Scale limits are enforced by
/// [zoomAt]; direct transform changes remain the responsibility of the viewer.
class GraphViewportController {
  GraphViewportController({
    required TickerProvider tickerProvider,
    required Matrix4 initialTransform,
    this.minScale = 0.6,
    this.maxScale = 2.5,
  }) : transformation = TransformationController(initialTransform),
       _animation = AnimationController(
         vsync: tickerProvider,
         duration: const Duration(milliseconds: 250),
       );

  final double minScale;
  final double maxScale;
  final TransformationController transformation;
  final AnimationController _animation;
  VoidCallback? _valueListener;
  AnimationStatusListener? _statusListener;

  /// Animates the viewport to [target], replacing any active animation.
  void animateTo(Matrix4 target) {
    _removeAnimationListeners();
    final tween = Matrix4Tween(
      begin: Matrix4.copy(transformation.value),
      end: target,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));

    void valueListener() {
      transformation.value = tween.value;
    }

    void statusListener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      transformation.value = target;
      _removeAnimationListeners();
    }

    _valueListener = valueListener;
    _statusListener = statusListener;
    _animation
      ..stop()
      ..reset()
      ..addListener(valueListener)
      ..addStatusListener(statusListener)
      ..forward();
  }

  /// Zooms around a viewport point while respecting the configured scale range.
  void zoomAt(Offset focalPoint, double scaleFactor) {
    final scenePoint = transformation.toScene(focalPoint);
    final currentScale = transformation.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * scaleFactor).clamp(minScale, maxScale);
    final appliedScale = targetScale / currentScale;
    final target = Matrix4.copy(transformation.value)
      ..translateByDouble(scenePoint.dx, scenePoint.dy, 0, 1)
      ..scaleByDouble(appliedScale, appliedScale, 1, 1)
      ..translateByDouble(-scenePoint.dx, -scenePoint.dy, 0, 1);
    animateTo(target);
  }

  /// Resets the transform to unit scale with its origin at [centerOffset].
  void reset(Offset centerOffset) {
    animateTo(
      Matrix4.identity()
        ..translateByDouble(centerOffset.dx, centerOffset.dy, 0, 1),
    );
  }

  /// Moves the scene so [point] appears at [viewportCenter].
  void centerViewportPoint({
    required Offset point,
    required Offset viewportCenter,
  }) {
    final scenePoint = transformation.toScene(point);
    final sceneCenter = transformation.toScene(viewportCenter);
    final delta = sceneCenter - scenePoint;
    animateTo(
      Matrix4.copy(transformation.value)
        ..translateByDouble(delta.dx, delta.dy, 0, 1),
    );
  }

  void _removeAnimationListeners() {
    final valueListener = _valueListener;
    final statusListener = _statusListener;
    if (valueListener != null) _animation.removeListener(valueListener);
    if (statusListener != null) {
      _animation.removeStatusListener(statusListener);
    }
    _valueListener = null;
    _statusListener = null;
  }

  void dispose() {
    _removeAnimationListeners();
    _animation.dispose();
    transformation.dispose();
  }
}

/// Creates and disposes a viewport controller for the current hook.
GraphViewportController useGraphViewportController({
  required TickerProvider tickerProvider,
  required Matrix4 initialTransform,
}) {
  final controller = useMemoized(
    () => GraphViewportController(
      tickerProvider: tickerProvider,
      initialTransform: initialTransform,
    ),
  );
  useEffect(() => controller.dispose, [controller]);
  return controller;
}
