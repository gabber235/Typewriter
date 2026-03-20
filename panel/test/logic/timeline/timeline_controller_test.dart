import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";

void main() {
  group("TimelineController", () {
    test("keeps the zoom anchor stable under the pointer", () {
      final controller = TimelineController()
        ..panBy(dx: 120)
        ..zoomAt(
          localDx: 80,
          scaleDelta: 2,
          minPixelsPerFrame: 6,
          maxPixelsPerFrame: 48,
        );

      expect(controller.pixelsPerFrame, 24);
      expect(controller.horizontalOffset, 320);
    });

    test("clamps move previews while preserving duration", () {
      final controller = TimelineController()
        ..startMove(id: "cue", startFrame: 5, endFrame: 15)
        ..updateInteraction(-120);

      expect(controller.preview?.startFrame, 0);
      expect(controller.preview?.endFrame, 10);
    });

    test("rounds interaction deltas near half frame thresholds", () {
      final controller = TimelineController()
        ..startMove(id: "cue", startFrame: 10, endFrame: 20)
        ..updateInteraction(5.9);

      expect(controller.preview?.startFrame, 10);
      expect(controller.preview?.endFrame, 20);

      controller
        ..updateInteraction(6.1)
        ..updateInteraction(5.9)
        ..updateInteraction(-5.9)
        ..updateInteraction(-6.1);

      expect(controller.preview?.startFrame, 9);
      expect(controller.preview?.endFrame, 19);
    });

    test("clamps resize previews and clears preview on finish", () {
      final controller = TimelineController()
        ..startResizeStart(id: "cue", startFrame: 8, endFrame: 18)
        ..updateInteraction(180);

      expect(controller.preview?.startFrame, 18);
      expect(controller.preview?.endFrame, 18);

      controller
        ..startResizeEnd(id: "cue", startFrame: 8, endFrame: 18)
        ..updateInteraction(-180);

      expect(controller.preview?.startFrame, 8);
      expect(controller.preview?.endFrame, 8);

      final finished = controller.finishInteraction();
      expect(finished?.mode, TimelineInteractionMode.resizeEnd);
      expect(finished?.startFrame, 8);
      expect(finished?.endFrame, 8);
      expect(controller.preview, isNull);
    });

    test("keeps resize start unchanged when clamped at boundaries", () {
      final controller = TimelineController()
        ..startResizeStart(id: "cue", startFrame: 0, endFrame: 12)
        ..updateInteraction(-240);

      expect(controller.preview?.startFrame, 0);
      expect(controller.preview?.endFrame, 12);

      controller
        ..startResizeStart(id: "cue", startFrame: 7, endFrame: 7)
        ..updateInteraction(240);

      expect(controller.preview?.startFrame, 7);
      expect(controller.preview?.endFrame, 7);
    });

    test("keeps resize end unchanged when clamped at start", () {
      final controller = TimelineController()
        ..startResizeEnd(id: "cue", startFrame: 9, endFrame: 9)
        ..updateInteraction(-240);

      expect(controller.preview?.startFrame, 9);
      expect(controller.preview?.endFrame, 9);
    });

    test("returns final preview from finishInteraction and clears state", () {
      final controller = TimelineController()
        ..startMove(id: "cue", startFrame: 3, endFrame: 9)
        ..updateInteraction(26);
      final finalPreview = controller.preview;

      final finished = controller.finishInteraction();

      expect(finished, same(finalPreview));
      expect(finished?.mode, TimelineInteractionMode.move);
      expect(finished?.startFrame, 5);
      expect(finished?.endFrame, 11);
      expect(controller.preview, isNull);
    });

    test("keeps pan and zoom viewport offsets nonnegative", () {
      final controller = TimelineController()
        ..panBy(dx: 180, dy: 40)
        ..panBy(dx: -500, dy: -200)
        ..zoomAt(
          localDx: 500,
          scaleDelta: 0.5,
          minPixelsPerFrame: 6,
          maxPixelsPerFrame: 48,
        )
        ..panBy(dx: 10, dy: 25)
        ..zoomAt(
          localDx: 0,
          scaleDelta: 2,
          minPixelsPerFrame: 6,
          maxPixelsPerFrame: 48,
        );

      expect(controller.horizontalOffset, 20);
      expect(controller.verticalOffset, 25);
      expect(controller.horizontalOffset, greaterThanOrEqualTo(0));
      expect(controller.verticalOffset, greaterThanOrEqualTo(0));
    });

    test("cancelInteraction clears preview without returning a value", () {
      final controller = TimelineController()
        ..startMove(id: "cue", startFrame: 4, endFrame: 9)
        ..cancelInteraction();

      expect(controller.preview, isNull);
      expect(controller.finishInteraction(), isNull);
    });
  });
}
