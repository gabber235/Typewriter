import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_controller.dart";

import "support/timeline_test_dsl.dart";

void main() {
  group("TimelineController", () {
    test("keeps the zoom anchor stable under the pointer", () {
      final controller = _controller()
        ..panBy(dx: 120, animate: false)
        ..zoomAt(
          localDx: 80,
          scaleDelta: 2,
          minPixelsPerFrame: 6,
          maxPixelsPerFrame: 48,
          animate: false,
        );

      expect(controller.pixelsPerFrame, 24);
      expect(controller.horizontalOffset, 320);
    });

    test("clamps move previews while preserving duration", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [previewCue("cue").move(startFrame: 5, endFrame: 15)],
        )
        ..updateInteraction(-120);

      expect(_preview(controller)?.startFrame, 0);
      expect(_preview(controller)?.endFrame, 10);
    });

    test("updates all move previews in one interaction session", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [
            previewCue("cue_a").move(startFrame: 10, endFrame: 20),
            previewCue("cue_b").move(startFrame: 2, endFrame: 6),
          ],
        )
        ..updateInteraction(24);

      final session = controller.finishInteractionSession();
      final byId = {for (final preview in session) preview.id.id: preview};

      expect(byId["cue_a"]?.startFrame, 12);
      expect(byId["cue_a"]?.endFrame, 22);
      expect(byId["cue_b"]?.startFrame, 4);
      expect(byId["cue_b"]?.endFrame, 8);
      expect(_preview(controller), isNull);
      expect(controller.previews, isEmpty);
    });

    test("rounds interaction deltas near half frame thresholds", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [previewCue("cue").move(startFrame: 10, endFrame: 20)],
        )
        ..updateInteraction(5.9);

      expect(_preview(controller)?.startFrame, 10);
      expect(_preview(controller)?.endFrame, 20);

      controller
        ..updateInteraction(6.1)
        ..updateInteraction(5.9)
        ..updateInteraction(-5.9)
        ..updateInteraction(-6.1);

      expect(_preview(controller)?.startFrame, 9);
      expect(_preview(controller)?.endFrame, 19);
    });

    test("clamps resize previews and clears preview on finish", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [
            previewCue("cue").resizeStart(startFrame: 8, endFrame: 18),
          ],
        )
        ..updateInteraction(180);

      expect(_preview(controller)?.startFrame, 18);
      expect(_preview(controller)?.endFrame, 18);

      controller
        ..startInteractionSession(
          previews: [previewCue("cue").resizeEnd(startFrame: 8, endFrame: 18)],
        )
        ..updateInteraction(-180);

      expect(_preview(controller)?.startFrame, 8);
      expect(_preview(controller)?.endFrame, 8);

      final finished = controller.finishInteractionSession();
      expect(finished, hasLength(1));
      expect(finished.first.mode, TimelineInteractionMode.resizeEnd);
      expect(finished.first.startFrame, 8);
      expect(finished.first.endFrame, 8);
      expect(_preview(controller), isNull);
    });

    test("keeps resize start unchanged when clamped at boundaries", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [
            previewCue("cue").resizeStart(startFrame: 0, endFrame: 12),
          ],
        )
        ..updateInteraction(-240);

      expect(_preview(controller)?.startFrame, 0);
      expect(_preview(controller)?.endFrame, 12);

      controller
        ..startInteractionSession(
          previews: [previewCue("cue").resizeStart(startFrame: 7, endFrame: 7)],
        )
        ..updateInteraction(240);

      expect(_preview(controller)?.startFrame, 7);
      expect(_preview(controller)?.endFrame, 7);
    });

    test("keeps resize end unchanged when clamped at start", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [previewCue("cue").resizeEnd(startFrame: 9, endFrame: 9)],
        )
        ..updateInteraction(-240);

      expect(_preview(controller)?.startFrame, 9);
      expect(_preview(controller)?.endFrame, 9);
    });

    test("updates paired resize previews in one session", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [
            previewCue("root_left").resizeEnd(startFrame: 10, endFrame: 30),
            previewCue("root_right").resizeStart(startFrame: 31, endFrame: 50),
          ],
        )
        ..updateInteraction(36);

      final session = controller.finishInteractionSession();
      final byId = {for (final preview in session) preview.id.id: preview};

      expect(byId["root_left"]?.startFrame, 10);
      expect(byId["root_left"]?.endFrame, 33);
      expect(byId["root_right"]?.startFrame, 34);
      expect(byId["root_right"]?.endFrame, 50);
    });

    test("clamps each mode independently in paired resize session", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [
            previewCue("root_left").resizeEnd(startFrame: 10, endFrame: 10),
            previewCue("root_right").resizeStart(startFrame: 11, endFrame: 11),
          ],
        )
        ..updateInteraction(-240);

      final session = controller.finishInteractionSession();
      final byId = {for (final preview in session) preview.id.id: preview};

      expect(byId["root_left"]?.startFrame, 10);
      expect(byId["root_left"]?.endFrame, 10);
      expect(byId["root_right"]?.startFrame, 0);
      expect(byId["root_right"]?.endFrame, 11);
    });

    test(
      "returns final previews from finishInteractionSession and clears state",
      () {
        final controller = _controller()
          ..startInteractionSession(
            previews: [previewCue("cue").move(startFrame: 3, endFrame: 9)],
          )
          ..updateInteraction(26);
        final finalPreview = _preview(controller);

        final finished = controller.finishInteractionSession();

        expect(finished, hasLength(1));
        expect(finished.first.id, finalPreview?.id);
        expect(finished.first.mode, TimelineInteractionMode.move);
        expect(finished.first.startFrame, 5);
        expect(finished.first.endFrame, 11);
        expect(_preview(controller), isNull);
      },
    );

    test("keeps pan and zoom viewport offsets nonnegative", () {
      final controller = _controller()
        ..panBy(dx: 180, dy: 40, animate: false)
        ..panBy(dx: -500, dy: -200, animate: false)
        ..zoomAt(
          localDx: 500,
          scaleDelta: 0.5,
          minPixelsPerFrame: 6,
          maxPixelsPerFrame: 48,
          animate: false,
        )
        ..panBy(dx: 10, dy: 25, animate: false)
        ..zoomAt(
          localDx: 0,
          scaleDelta: 2,
          minPixelsPerFrame: 6,
          maxPixelsPerFrame: 48,
          animate: false,
        );

      expect(controller.horizontalOffset, 20);
      expect(controller.verticalOffset, 25);
      expect(controller.horizontalOffset, greaterThanOrEqualTo(0));
      expect(controller.verticalOffset, greaterThanOrEqualTo(0));
    });

    test("cancelInteraction clears previews without returning values", () {
      final controller = _controller()
        ..startInteractionSession(
          previews: [previewCue("cue").move(startFrame: 4, endFrame: 9)],
        )
        ..cancelInteraction();

      expect(_preview(controller), isNull);
      expect(controller.finishInteractionSession(), isEmpty);
    });
  });
}

TimelineController _controller({double pixelsPerFrame = 12}) {
  return TimelineController(
    tickerProvider: const TestVSync(),
    pixelsPerFrame: pixelsPerFrame,
  );
}

TimelinePreview? _preview(TimelineController controller) {
  if (controller.previews.isEmpty) return null;
  return controller.previews.first;
}
