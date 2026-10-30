import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";

/// Measuring where anchored overlays may go.
extension AnchoredScopeBounds on WidgetTester {
  /// Shows [area] holding a probe and returns the bounds the nearest
  /// [AnchoredOverlayScope] gives overlays around that probe, in the
  /// coordinates of [area] itself; null when no scope bounds them.
  Future<Rect?> anchoredScopeBoundsAround(
    Widget Function(Widget probe) area,
  ) async {
    Rect? resolved;
    final overlay = GlobalKey();
    final probe = Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = overlay.currentContext?.findRenderObject();
          if (box is RenderBox) {
            resolved = AnchoredOverlayScope.maybeScopeBoundsInOverlay(
              context,
              overlayBox: box,
            );
          }
        });
        return const SizedBox.shrink();
      },
    );
    await showComponent(KeyedSubtree(key: overlay, child: area(probe)));
    return resolved;
  }
}
