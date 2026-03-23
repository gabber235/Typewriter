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

    test("updates all move previews in one interaction session", () {
      final controller = TimelineController()
        ..startMove(
          id: "cue_a",
          startFrame: 10,
          endFrame: 20,
          additionalPreviews: const [(id: "cue_b", startFrame: 2, endFrame: 6)],
        )
        ..updateInteraction(24);

      final session = controller.finishInteractionSession();
      final byId = {for (final preview in session) preview.id: preview};

      expect(byId["cue_a"]?.startFrame, 12);
      expect(byId["cue_a"]?.endFrame, 22);
      expect(byId["cue_b"]?.startFrame, 4);
      expect(byId["cue_b"]?.endFrame, 8);
      expect(controller.preview, isNull);
      expect(controller.previews, isEmpty);
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
        ..startInteractionSession(
          activeId: "cue",
          seeds: const [
            (
              id: "cue",
              mode: TimelineInteractionMode.resizeStart,
              startFrame: 8,
              endFrame: 18,
            ),
          ],
        )
        ..updateInteraction(180);

      expect(controller.preview?.startFrame, 18);
      expect(controller.preview?.endFrame, 18);

      controller
        ..startInteractionSession(
          activeId: "cue",
          seeds: const [
            (
              id: "cue",
              mode: TimelineInteractionMode.resizeEnd,
              startFrame: 8,
              endFrame: 18,
            ),
          ],
        )
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
        ..startInteractionSession(
          activeId: "cue",
          seeds: const [
            (
              id: "cue",
              mode: TimelineInteractionMode.resizeStart,
              startFrame: 0,
              endFrame: 12,
            ),
          ],
        )
        ..updateInteraction(-240);

      expect(controller.preview?.startFrame, 0);
      expect(controller.preview?.endFrame, 12);

      controller
        ..startInteractionSession(
          activeId: "cue",
          seeds: const [
            (
              id: "cue",
              mode: TimelineInteractionMode.resizeStart,
              startFrame: 7,
              endFrame: 7,
            ),
          ],
        )
        ..updateInteraction(240);

      expect(controller.preview?.startFrame, 7);
      expect(controller.preview?.endFrame, 7);
    });

    test("keeps resize end unchanged when clamped at start", () {
      final controller = TimelineController()
        ..startInteractionSession(
          activeId: "cue",
          seeds: const [
            (
              id: "cue",
              mode: TimelineInteractionMode.resizeEnd,
              startFrame: 9,
              endFrame: 9,
            ),
          ],
        )
        ..updateInteraction(-240);

      expect(controller.preview?.startFrame, 9);
      expect(controller.preview?.endFrame, 9);
    });

    test("updates paired resize previews in one session", () {
      final controller = TimelineController()
        ..startInteractionSession(
          activeId: "root_left",
          seeds: const [
            (
              id: "root_left",
              mode: TimelineInteractionMode.resizeEnd,
              startFrame: 10,
              endFrame: 30,
            ),
            (
              id: "root_right",
              mode: TimelineInteractionMode.resizeStart,
              startFrame: 31,
              endFrame: 50,
            ),
          ],
        )
        ..updateInteraction(36);

      final session = controller.finishInteractionSession();
      final byId = {for (final preview in session) preview.id: preview};

      expect(byId["root_left"]?.startFrame, 10);
      expect(byId["root_left"]?.endFrame, 33);
      expect(byId["root_right"]?.startFrame, 34);
      expect(byId["root_right"]?.endFrame, 50);
    });

    test("clamps each mode independently in paired resize session", () {
      final controller = TimelineController()
        ..startInteractionSession(
          activeId: "root_left",
          seeds: const [
            (
              id: "root_left",
              mode: TimelineInteractionMode.resizeEnd,
              startFrame: 10,
              endFrame: 10,
            ),
            (
              id: "root_right",
              mode: TimelineInteractionMode.resizeStart,
              startFrame: 11,
              endFrame: 11,
            ),
          ],
        )
        ..updateInteraction(-240);

      final session = controller.finishInteractionSession();
      final byId = {for (final preview in session) preview.id: preview};

      expect(byId["root_left"]?.startFrame, 10);
      expect(byId["root_left"]?.endFrame, 10);
      expect(byId["root_right"]?.startFrame, 0);
      expect(byId["root_right"]?.endFrame, 11);
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
