import "package:typewriter_panel/typewriter_panel.dart";

// Sheets whose own settle is running; the scroll end it causes is ignored.
final _settling = Expando<bool>("sheet settling");

/// Sheet moves with the surface tokens.
extension SheetMotion on DraggableScrollableController {
  /// Moves the sheet to [target]: up with surfaceIn, down with panelOut.
  /// Completes when the sheet lands, or at once when it is already there.
  Future<void> settleTo(BuildContext context, double target) async {
    if (!isAttached || (size - target).abs() < 0.001) return;
    final timeline = motionTimeline(
      context,
      target > size ? MotionToken.surfaceIn : MotionToken.panelOut,
    );
    _settling[this] = true;
    try {
      if (timeline.isInstant) {
        jumpTo(target);
      } else {
        await animateTo(
          target,
          duration: timeline.duration,
          curve: timeline.curve,
        );
      }
    } finally {
      _settling[this] = null;
    }
  }

  /// After a released drag, settles on the nearest of [stops]. A scroll end
  /// caused by a settle of this sheet is ignored.
  Future<void> settleNearest(BuildContext context, List<double> stops) async {
    if (!isAttached || _settling[this] == true) return;
    await settleTo(
      context,
      stops.reduce((a, b) => (a - size).abs() <= (b - size).abs() ? a : b),
    );
  }
}
