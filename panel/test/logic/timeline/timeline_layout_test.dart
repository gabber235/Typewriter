import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_builder.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_data.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_item.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_layout.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";

void main() {
  group("TimelineLayoutEngine", () {
    testWidgets("keeps overlapping sibling subtrees in separate branch lanes", (
      tester,
    ) async {
      final baseData = buildSceneTimelineData(_layoutSceneElements());
      final layout = buildSceneTimelineLayout(
        data: _timelineData(baseData),
        baseData: baseData,
        previewData: baseData,
        viewport: _viewport(),
        style: TimelineStyle.fallback(ThemeData()),
        preview: null,
      );

      final parent = _placed(layout, "parent");
      final child = _placed(layout, "child");
      final sibling = _placed(layout, "sibling");
      final siblingKeyframe = _placed(layout, "sibling_keyframe");

      expect(parent.laneIndex, 0);
      expect(child.laneIndex, 1);
      expect(sibling.laneIndex, 2);
      expect(siblingKeyframe.laneIndex, 3);
    });

    testWidgets(
      "keeps subtree lanes stable during preview and marks descendants as related",
      (tester) async {
        final baseData = buildSceneTimelineData(_layoutSceneElements());
        final preview = const TimelinePreview(
          id: "parent",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 12,
          endFrame: 32,
        );
        final previewData = buildSceneTimelineData(
          _layoutSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "parent",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 12,
            endFrame: 32,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseParent = _placed(baseLayout, "parent");
        final baseChild = _placed(baseLayout, "child");
        final previewParent = _placed(previewLayout, "parent");
        final previewChild = _placed(previewLayout, "child");

        expect(previewParent.laneIndex, baseParent.laneIndex);
        expect(previewChild.laneIndex, baseChild.laneIndex);
        expect(previewParent.rect.left, greaterThan(baseParent.rect.left));
        expect(previewChild.rect.left, greaterThan(baseChild.rect.left));
        expect(previewParent.previewState, TimelinePreviewState.active);
        expect(previewChild.previewState, TimelinePreviewState.related);
      },
    );

    testWidgets(
      "keeps a moved child subtree in its stream and evicts siblings",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _childReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 10,
          startFrame: 24,
          endFrame: 34,
        );
        final previewData = buildSceneTimelineData(
          _childReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "active_child",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 24,
            endFrame: 34,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseActiveChild = _placed(baseLayout, "active_child");
        final baseSiblingChild = _placed(baseLayout, "sibling_child");
        final previewActiveChild = _placed(previewLayout, "active_child");
        final previewSiblingChild = _placed(previewLayout, "sibling_child");

        expect(previewActiveChild.laneIndex, baseActiveChild.laneIndex);
        expect(
          previewSiblingChild.laneIndex,
          greaterThan(baseSiblingChild.laneIndex),
        );
        expect(previewActiveChild.previewState, TimelinePreviewState.active);
        expect(previewSiblingChild.previewState, TimelinePreviewState.none);
      },
    );

    testWidgets(
      "keeps a moved root subtree in its stream and evicts other roots",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _rootReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "root_a",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 24,
          endFrame: 44,
        );
        final previewData = buildSceneTimelineData(
          _rootReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "root_a",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 24,
            endFrame: 44,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseRootA = _placed(baseLayout, "root_a");
        final baseRootAChild = _placed(baseLayout, "root_a_child");
        final baseRootB = _placed(baseLayout, "root_b");
        final previewRootA = _placed(previewLayout, "root_a");
        final previewRootAChild = _placed(previewLayout, "root_a_child");
        final previewRootB = _placed(previewLayout, "root_b");

        expect(previewRootA.laneIndex, baseRootA.laneIndex);
        expect(previewRootAChild.laneIndex, baseRootAChild.laneIndex);
        expect(previewRootB.laneIndex, greaterThan(baseRootB.laneIndex));
        expect(previewRootA.previewState, TimelinePreviewState.active);
        expect(previewRootAChild.previewState, TimelinePreviewState.related);
      },
    );

    testWidgets("moves a competing root subtree as a preserved block", (
      tester,
    ) async {
      final baseData = buildSceneTimelineData(_rootReservationSceneElements());
      final preview = const TimelinePreview(
        id: "root_a",
        mode: TimelineInteractionMode.move,
        originalStartFrame: 0,
        originalEndFrame: 20,
        startFrame: 24,
        endFrame: 44,
      );
      final previewData = buildSceneTimelineData(
        _rootReservationSceneElements(),
        override: const SceneTimelineOverride(
          cueId: "root_a",
          mode: SceneTimelineOverrideMode.move,
          startFrame: 24,
          endFrame: 44,
        ),
      );

      final baseLayout = buildSceneTimelineLayout(
        data: _timelineData(baseData),
        baseData: baseData,
        previewData: baseData,
        viewport: _viewport(),
        style: TimelineStyle.fallback(ThemeData()),
        preview: null,
      );
      final previewLayout = buildSceneTimelineLayout(
        data: _timelineData(baseData),
        baseData: baseData,
        previewData: previewData,
        viewport: _viewport(),
        style: TimelineStyle.fallback(ThemeData()),
        preview: preview,
      );

      final baseRootB = _placed(baseLayout, "root_b");
      final baseRootBChild = _placed(baseLayout, "root_b_child");
      final previewRootB = _placed(previewLayout, "root_b");
      final previewRootBChild = _placed(previewLayout, "root_b_child");

      expect(previewRootB.laneIndex, greaterThan(baseRootB.laneIndex));
      expect(
        previewRootBChild.laneIndex - previewRootB.laneIndex,
        baseRootBChild.laneIndex - baseRootB.laneIndex,
      );
    });

    testWidgets(
      "keeps a moved child segment stream when a sibling keyframe overlaps",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _childSegmentVsKeyframeReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 10,
          startFrame: 24,
          endFrame: 34,
        );
        final previewData = buildSceneTimelineData(
          _childSegmentVsKeyframeReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "active_child",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 24,
            endFrame: 34,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseActiveChild = _placed(baseLayout, "active_child");
        final baseSiblingKeyframe = _placed(baseLayout, "sibling_keyframe");
        final previewActiveChild = _placed(previewLayout, "active_child");
        final previewSiblingKeyframe = _placed(
          previewLayout,
          "sibling_keyframe",
        );

        expect(previewActiveChild.laneIndex, baseActiveChild.laneIndex);
        expect(
          previewSiblingKeyframe.laneIndex,
          greaterThan(baseSiblingKeyframe.laneIndex),
        );
        expect(previewActiveChild.previewState, TimelinePreviewState.active);
        expect(previewSiblingKeyframe.previewState, TimelinePreviewState.none);
      },
    );

    testWidgets(
      "keeps a moved child keyframe stream and moves a sibling segment subtree as a block",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _childKeyframeVsSegmentReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_keyframe",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 0,
          startFrame: 24,
          endFrame: 24,
        );
        final previewData = buildSceneTimelineData(
          _childKeyframeVsSegmentReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "active_keyframe",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 24,
            endFrame: 24,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseActiveKeyframe = _placed(baseLayout, "active_keyframe");
        final baseSiblingSegment = _placed(baseLayout, "sibling_segment");
        final baseSiblingChild = _placed(baseLayout, "sibling_child");
        final previewActiveKeyframe = _placed(previewLayout, "active_keyframe");
        final previewSiblingSegment = _placed(previewLayout, "sibling_segment");
        final previewSiblingChild = _placed(previewLayout, "sibling_child");

        expect(previewActiveKeyframe.laneIndex, baseActiveKeyframe.laneIndex);
        expect(
          previewSiblingSegment.laneIndex,
          greaterThan(baseSiblingSegment.laneIndex),
        );
        expect(
          previewSiblingChild.laneIndex - previewSiblingSegment.laneIndex,
          baseSiblingChild.laneIndex - baseSiblingSegment.laneIndex,
        );
        expect(previewActiveKeyframe.previewState, TimelinePreviewState.active);
      },
    );

    testWidgets(
      "keeps a moved root segment subtree stream when a sibling root keyframe overlaps",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _rootSegmentVsKeyframeReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "root_a",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 24,
          endFrame: 44,
        );
        final previewData = buildSceneTimelineData(
          _rootSegmentVsKeyframeReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "root_a",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 24,
            endFrame: 44,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseRootA = _placed(baseLayout, "root_a");
        final baseRootAChild = _placed(baseLayout, "root_a_child");
        final baseRootKeyframe = _placed(baseLayout, "root_keyframe");
        final previewRootA = _placed(previewLayout, "root_a");
        final previewRootAChild = _placed(previewLayout, "root_a_child");
        final previewRootKeyframe = _placed(previewLayout, "root_keyframe");

        expect(previewRootA.laneIndex, baseRootA.laneIndex);
        expect(previewRootAChild.laneIndex, baseRootAChild.laneIndex);
        expect(
          previewRootKeyframe.laneIndex,
          greaterThan(baseRootKeyframe.laneIndex),
        );
        expect(previewRootA.previewState, TimelinePreviewState.active);
        expect(previewRootAChild.previewState, TimelinePreviewState.related);
      },
    );

    testWidgets(
      "clears full active stream so trailing sibling keyframes cannot block continued drag",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _trailingKeyframesReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 10,
          originalEndFrame: 20,
          startFrame: 18,
          endFrame: 28,
        );
        final previewData = buildSceneTimelineData(
          _trailingKeyframesReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "active_child",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 18,
            endFrame: 28,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseActiveChild = _placed(baseLayout, "active_child");
        final previewActiveChild = _placed(previewLayout, "active_child");
        final previewNearKeyframe = _placed(previewLayout, "near_keyframe");
        final previewFarKeyframe = _placed(previewLayout, "far_keyframe");

        expect(previewActiveChild.laneIndex, baseActiveChild.laneIndex);
        expect(
          previewNearKeyframe.laneIndex,
          greaterThan(baseActiveChild.laneIndex),
        );
        expect(
          previewFarKeyframe.laneIndex,
          greaterThan(baseActiveChild.laneIndex),
        );
      },
    );

    testWidgets(
      "reserves child stream during resize start and evicts touching sibling",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _resizeStartChildReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.resizeStart,
          originalStartFrame: 10,
          originalEndFrame: 20,
          startFrame: 9,
          endFrame: 20,
        );
        final previewData = buildSceneTimelineData(
          _resizeStartChildReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "active_child",
            mode: SceneTimelineOverrideMode.resizeStart,
            startFrame: 9,
            endFrame: 20,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseActiveChild = _placed(baseLayout, "active_child");
        final baseSiblingChild = _placed(baseLayout, "touching_sibling_child");
        final previewActiveChild = _placed(previewLayout, "active_child");
        final previewSiblingChild = _placed(
          previewLayout,
          "touching_sibling_child",
        );

        expect(previewActiveChild.laneIndex, baseActiveChild.laneIndex);
        expect(
          previewSiblingChild.laneIndex,
          greaterThan(baseSiblingChild.laneIndex),
        );
        expect(previewActiveChild.previewState, TimelinePreviewState.active);
        expect(previewSiblingChild.previewState, TimelinePreviewState.none);
      },
    );

    testWidgets(
      "reserves root stream during resize end and evicts overlapping roots",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _resizeEndRootReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "root_a",
          mode: TimelineInteractionMode.resizeEnd,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 0,
          endFrame: 24,
        );
        final previewData = buildSceneTimelineData(
          _resizeEndRootReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "root_a",
            mode: SceneTimelineOverrideMode.resizeEnd,
            startFrame: 0,
            endFrame: 24,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseRootA = _placed(baseLayout, "root_a");
        final baseRootAChild = _placed(baseLayout, "root_a_child");
        final baseRootB = _placed(baseLayout, "root_b");
        final baseRootBChild = _placed(baseLayout, "root_b_child");
        final previewRootA = _placed(previewLayout, "root_a");
        final previewRootAChild = _placed(previewLayout, "root_a_child");
        final previewRootB = _placed(previewLayout, "root_b");
        final previewRootBChild = _placed(previewLayout, "root_b_child");

        expect(previewRootA.laneIndex, baseRootA.laneIndex);
        expect(previewRootAChild.laneIndex, baseRootAChild.laneIndex);
        expect(previewRootB.laneIndex, greaterThan(baseRootB.laneIndex));
        expect(
          previewRootBChild.laneIndex - previewRootB.laneIndex,
          baseRootBChild.laneIndex - baseRootB.laneIndex,
        );
      },
    );

    testWidgets(
      "treats touching segment boundaries as inclusive overlap during move preview",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _inclusiveBoundaryCollisionSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 4,
          startFrame: 1,
          endFrame: 5,
        );
        final previewData = buildSceneTimelineData(
          _inclusiveBoundaryCollisionSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "active",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 1,
            endFrame: 5,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseActive = _placed(baseLayout, "active");
        final baseTouching = _placed(baseLayout, "touching");
        final previewActive = _placed(previewLayout, "active");
        final previewTouching = _placed(previewLayout, "touching");

        expect(previewActive.laneIndex, baseActive.laneIndex);
        expect(previewTouching.laneIndex, greaterThan(baseTouching.laneIndex));
      },
    );

    testWidgets(
      "keeps unaffected track lane assignment stable during preview reservation",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _multiTrackIsolationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "track_a_active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 10,
          startFrame: 16,
          endFrame: 26,
        );
        final previewData = buildSceneTimelineData(
          _multiTrackIsolationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "track_a_active_child",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 16,
            endFrame: 26,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseTrackACompeting = _placed(
          baseLayout,
          "track_a_competing_child",
        );
        final previewTrackACompeting = _placed(
          previewLayout,
          "track_a_competing_child",
        );
        expect(
          previewTrackACompeting.laneIndex,
          greaterThan(baseTrackACompeting.laneIndex),
        );

        expect(
          _placed(previewLayout, "track_b_root").laneIndex,
          _placed(baseLayout, "track_b_root").laneIndex,
        );
        expect(
          _placed(previewLayout, "track_b_left").laneIndex,
          _placed(baseLayout, "track_b_left").laneIndex,
        );
        expect(
          _placed(previewLayout, "track_b_right").laneIndex,
          _placed(baseLayout, "track_b_right").laneIndex,
        );
        expect(
          _placed(previewLayout, "track_b_keyframe").laneIndex,
          _placed(baseLayout, "track_b_keyframe").laneIndex,
        );
      },
    );

    testWidgets(
      "evicts root keyframe when moved root subtree lands on keyframe frame",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _rootKeyframeCompetitionSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "root_a",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 14,
          endFrame: 34,
        );
        final previewData = buildSceneTimelineData(
          _rootKeyframeCompetitionSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "root_a",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 14,
            endFrame: 34,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        final baseRootA = _placed(baseLayout, "root_a");
        final baseRootAChild = _placed(baseLayout, "root_a_child");
        final baseRootKeyframe = _placed(baseLayout, "root_keyframe");
        final previewRootA = _placed(previewLayout, "root_a");
        final previewRootAChild = _placed(previewLayout, "root_a_child");
        final previewRootKeyframe = _placed(previewLayout, "root_keyframe");

        expect(previewRootA.laneIndex, baseRootA.laneIndex);
        expect(previewRootAChild.laneIndex, baseRootAChild.laneIndex);
        expect(
          previewRootKeyframe.laneIndex,
          greaterThan(baseRootKeyframe.laneIndex),
        );
      },
    );

    testWidgets(
      "keeps dense layout lane allocation deterministic during reservation preview",
      (tester) async {
        final baseData = buildSceneTimelineData(
          _denseDeterministicReservationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "root_a",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 12,
          endFrame: 32,
        );
        final previewData = buildSceneTimelineData(
          _denseDeterministicReservationSceneElements(),
          override: const SceneTimelineOverride(
            cueId: "root_a",
            mode: SceneTimelineOverrideMode.move,
            startFrame: 12,
            endFrame: 32,
          ),
        );

        final baseLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: baseData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: null,
        );
        final previewLayout = buildSceneTimelineLayout(
          data: _timelineData(baseData),
          baseData: baseData,
          previewData: previewData,
          viewport: _viewport(),
          style: TimelineStyle.fallback(ThemeData()),
          preview: preview,
        );

        _expectLaneIndices(baseLayout, {
          "root_a": 0,
          "root_a_child_one": 1,
          "root_a_child_two": 1,
          "root_b": 2,
          "root_b_child": 3,
          "root_c_keyframe": 4,
          "root_d": 4,
          "root_e_keyframe": 4,
          "root_f": 0,
        });
        _expectLaneIndices(previewLayout, {
          "root_a": 0,
          "root_a_child_one": 1,
          "root_a_child_two": 1,
          "root_b": 2,
          "root_b_child": 3,
          "root_c_keyframe": 4,
          "root_d": 4,
          "root_e_keyframe": 4,
          "root_f": 2,
        });
      },
    );

    testWidgets("applies overscan visibility and minimum segment width", (
      tester,
    ) async {
      final baseData = buildSceneTimelineData(_viewportSceneElements());
      final layout = buildSceneTimelineLayout(
        data: _timelineData(baseData),
        baseData: baseData,
        previewData: baseData,
        viewport: const TimelineViewport(
          headerWidth: 200,
          planeWidth: 800,
          planeHeight: 400,
          horizontalOffset: 200,
          verticalOffset: 0,
          pixelsPerFrame: 10,
          overscanFrames: 3,
        ),
        style: TimelineStyle.fallback(ThemeData()),
        preview: null,
      );

      expect(
        layout.visibleElements.map((element) => element.element.id.id).toList(),
        ["near_edge", "inside"],
      );
      expect(_placed(layout, "near_edge").rect.width, greaterThanOrEqualTo(16));
    });

    testWidgets("expands content width for far preview geometry", (
      tester,
    ) async {
      final baseData = buildSceneTimelineData(_layoutSceneElements());
      final preview = const TimelinePreview(
        id: "parent",
        mode: TimelineInteractionMode.move,
        originalStartFrame: 0,
        originalEndFrame: 20,
        startFrame: 240,
        endFrame: 260,
      );
      final previewData = buildSceneTimelineData(
        _layoutSceneElements(),
        override: const SceneTimelineOverride(
          cueId: "parent",
          mode: SceneTimelineOverrideMode.move,
          startFrame: 240,
          endFrame: 260,
        ),
      );

      final layout = buildSceneTimelineLayout(
        data: _timelineData(baseData),
        baseData: baseData,
        previewData: previewData,
        viewport: _viewport(),
        style: TimelineStyle.fallback(ThemeData()),
        preview: preview,
      );

      expect(layout.contentWidth, greaterThan(2400));
    });
  });
}

TimelineData _timelineData(SceneTimelineData sceneData) {
  return TimelineData(
    tracks: [
      for (final track in sceneData.tracks)
        TimelineTrack(
          id: TimelineIdentifier(track.id.id),
          header: (_) => const SizedBox.shrink(),
          elements: [
            for (final item in track.rootItems) _timelineElement(item),
          ],
        ),
    ],
  );
}

TimelineLayoutResult buildSceneTimelineLayout({
  required TimelineData data,
  required SceneTimelineData baseData,
  required SceneTimelineData previewData,
  required TimelineViewport viewport,
  required TimelineStyle style,
  required TimelinePreview? preview,
}) {
  assert(baseData.tracks.length == data.tracks.length);
  assert(previewData.tracks.length == data.tracks.length);
  return TimelineLayoutEngine(
    style: style,
  ).build(data: data, viewport: viewport, preview: preview);
}

TimelineElement _timelineElement(SceneTimelineItem item) {
  return switch (item) {
    SceneSegmentItem() => TimelineSegment(
      id: TimelineIdentifier(item.cueId),
      startFrame: item.absoluteStartFrame,
      endFrame: item.absoluteEndFrame,
      builder: (_, data) => const SizedBox.shrink(),
      children: [for (final child in item.children) _timelineElement(child)],
      color: Colors.blue,
    ),
    SceneKeyframeItem() => TimelineKeyframe(
      id: TimelineIdentifier(item.cueId),
      frame: item.absoluteStartFrame,
      builder: (_, data) => const SizedBox.shrink(),
      color: Colors.orange,
    ),
  };
}

TimelineViewport _viewport() {
  return const TimelineViewport(
    headerWidth: 200,
    planeWidth: 1200,
    planeHeight: 800,
    horizontalOffset: 0,
    verticalOffset: 0,
    pixelsPerFrame: 10,
    overscanFrames: 0,
  );
}

TimelinePlacedElement _placed(TimelineLayoutResult layout, String cueId) {
  return layout.visibleElements.firstWhere(
    (element) => element.element.id.id == cueId,
  );
}

void _expectLaneIndices(
  TimelineLayoutResult layout,
  Map<String, int> expected,
) {
  for (final entry in expected.entries) {
    expect(_placed(layout, entry.key).laneIndex, entry.value);
  }
}

List<PageElement> _layoutSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Scene Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_parent",
              otherId: "parent",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_sibling",
              otherId: "sibling",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "parent",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("parent_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_parent",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "parent_child",
            otherId: "child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "child",
        startFrame: 5,
        endFrame: 10,
        blueprint: _blueprint("child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "parent_child",
            otherId: "parent",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "sibling",
        startFrame: 0,
        endFrame: 8,
        blueprint: _blueprint("sibling_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_sibling",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "sibling_keyframe_link",
            otherId: "sibling_keyframe",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "sibling_keyframe",
        frame: 2,
        blueprint: _blueprint("sibling_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "sibling_keyframe_link",
            otherId: "sibling",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _viewportSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Viewport Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_outside",
              otherId: "outside",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_near_edge",
              otherId: "near_edge",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_inside",
              otherId: "inside",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "outside",
        startFrame: 0,
        endFrame: 2,
        blueprint: _blueprint("outside_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_outside",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "near_edge",
        startFrame: 17,
        endFrame: 17,
        blueprint: _blueprint("near_edge_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_near_edge",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "inside",
        startFrame: 25,
        endFrame: 30,
        blueprint: _blueprint("inside_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_inside",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _childReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Child Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 0,
        endFrame: 40,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "active_child",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_sibling_child",
            otherId: "sibling_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "active_child",
        startFrame: 0,
        endFrame: 10,
        blueprint: _blueprint("active_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "sibling_child",
        startFrame: 24,
        endFrame: 30,
        blueprint: _blueprint("sibling_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_sibling_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _rootReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Root Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root_a",
              otherId: "root_a",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_b",
              otherId: "root_b",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("root_a_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_a",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a_child",
        startFrame: 5,
        endFrame: 10,
        blueprint: _blueprint("root_a_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_b",
        startFrame: 24,
        endFrame: 30,
        blueprint: _blueprint("root_b_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_b",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_b_child_link",
            otherId: "root_b_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_b_child",
        startFrame: 2,
        endFrame: 5,
        blueprint: _blueprint("root_b_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_b_child_link",
            otherId: "root_b",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _childSegmentVsKeyframeReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Child Segment Keyframe Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 0,
        endFrame: 40,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "active_child",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_sibling_keyframe",
            otherId: "sibling_keyframe",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "active_child",
        startFrame: 0,
        endFrame: 10,
        blueprint: _blueprint("active_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "sibling_keyframe",
        frame: 24,
        blueprint: _blueprint("sibling_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_sibling_keyframe",
            otherId: "root",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _childKeyframeVsSegmentReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Child Keyframe Segment Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 0,
        endFrame: 40,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_active_keyframe",
            otherId: "active_keyframe",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_sibling_segment",
            otherId: "sibling_segment",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "active_keyframe",
        frame: 0,
        blueprint: _blueprint("active_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_active_keyframe",
            otherId: "root",
            path: "parent",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "sibling_segment",
        startFrame: 24,
        endFrame: 30,
        blueprint: _blueprint("sibling_segment_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_sibling_segment",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "sibling_segment_child_link",
            otherId: "sibling_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "sibling_child",
        startFrame: 2,
        endFrame: 5,
        blueprint: _blueprint("sibling_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "sibling_segment_child_link",
            otherId: "sibling_segment",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _rootSegmentVsKeyframeReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Root Segment Keyframe Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root_a",
              otherId: "root_a",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_keyframe",
              otherId: "root_keyframe",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("root_a_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_a",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a_child",
        startFrame: 5,
        endFrame: 10,
        blueprint: _blueprint("root_a_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "root_keyframe",
        frame: 24,
        blueprint: _blueprint("root_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_keyframe",
            otherId: "entry",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _trailingKeyframesReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Trailing Keyframes Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 0,
        endFrame: 80,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "active_child",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_near_keyframe",
            otherId: "near_keyframe",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_far_keyframe",
            otherId: "far_keyframe",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "active_child",
        startFrame: 10,
        endFrame: 20,
        blueprint: _blueprint("active_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "near_keyframe",
        frame: 24,
        blueprint: _blueprint("near_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_near_keyframe",
            otherId: "root",
            path: "parent",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "far_keyframe",
        frame: 52,
        blueprint: _blueprint("far_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_far_keyframe",
            otherId: "root",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _resizeStartChildReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Resize Start Child Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 0,
        endFrame: 40,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "active_child",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_touching_sibling_child",
            otherId: "touching_sibling_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "active_child",
        startFrame: 10,
        endFrame: 20,
        blueprint: _blueprint("active_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_active_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "touching_sibling_child",
        startFrame: 0,
        endFrame: 9,
        blueprint: _blueprint("touching_sibling_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_touching_sibling_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _resizeEndRootReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Resize End Root Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root_a",
              otherId: "root_a",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_b",
              otherId: "root_b",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("root_a_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_a",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a_child",
        startFrame: 4,
        endFrame: 10,
        blueprint: _blueprint("root_a_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_b",
        startFrame: 24,
        endFrame: 30,
        blueprint: _blueprint("root_b_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_b",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_b_child_link",
            otherId: "root_b_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_b_child",
        startFrame: 2,
        endFrame: 8,
        blueprint: _blueprint("root_b_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_b_child_link",
            otherId: "root_b",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _inclusiveBoundaryCollisionSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Inclusive Boundary Collision Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_active",
              otherId: "active",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_touching",
              otherId: "touching",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "active",
        startFrame: 0,
        endFrame: 4,
        blueprint: _blueprint("active_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_active",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "touching",
        startFrame: 5,
        endFrame: 9,
        blueprint: _blueprint("touching_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_touching",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _multiTrackIsolationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry_a",
          name: "Track A Entry",
          blueprint: _blueprint("entry_a_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_a_root_link",
              otherId: "track_a_root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry_b",
          name: "Track B Entry",
          blueprint: _blueprint("entry_b_blueprint"),
          placement: const EntryPlacement(x: 0, y: 80, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_b_root_link",
              otherId: "track_b_root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_a_root",
        startFrame: 0,
        endFrame: 40,
        blueprint: _blueprint("track_a_root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_a_root_link",
            otherId: "entry_a",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "track_a_active_child_link",
            otherId: "track_a_active_child",
            path: "children",
          ),
          const ElementLink(
            linkId: "track_a_competing_child_link",
            otherId: "track_a_competing_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_a_active_child",
        startFrame: 0,
        endFrame: 10,
        blueprint: _blueprint("track_a_active_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_a_active_child_link",
            otherId: "track_a_root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_a_competing_child",
        startFrame: 16,
        endFrame: 22,
        blueprint: _blueprint("track_a_competing_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_a_competing_child_link",
            otherId: "track_a_root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_b_root",
        startFrame: 0,
        endFrame: 40,
        blueprint: _blueprint("track_b_root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_b_root_link",
            otherId: "entry_b",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "track_b_left_link",
            otherId: "track_b_left",
            path: "children",
          ),
          const ElementLink(
            linkId: "track_b_right_link",
            otherId: "track_b_right",
            path: "children",
          ),
          const ElementLink(
            linkId: "track_b_keyframe_link",
            otherId: "track_b_keyframe",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_b_left",
        startFrame: 0,
        endFrame: 10,
        blueprint: _blueprint("track_b_left_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_b_left_link",
            otherId: "track_b_root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_b_right",
        startFrame: 12,
        endFrame: 18,
        blueprint: _blueprint("track_b_right_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_b_right_link",
            otherId: "track_b_root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "track_b_keyframe",
        frame: 24,
        blueprint: _blueprint("track_b_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_b_keyframe_link",
            otherId: "track_b_root",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _rootKeyframeCompetitionSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Root Keyframe Competition Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root_a",
              otherId: "root_a",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_keyframe",
              otherId: "root_keyframe",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("root_a_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_a",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a_child",
        startFrame: 4,
        endFrame: 10,
        blueprint: _blueprint("root_a_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_link",
            otherId: "root_a",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "root_keyframe",
        frame: 34,
        blueprint: _blueprint("root_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_keyframe",
            otherId: "entry",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _denseDeterministicReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Dense Deterministic Reservation Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root_a",
              otherId: "root_a",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_b",
              otherId: "root_b",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_c",
              otherId: "root_c_keyframe",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_d",
              otherId: "root_d",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_e",
              otherId: "root_e_keyframe",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_f",
              otherId: "root_f",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("root_a_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_a",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_a_child_one_link",
            otherId: "root_a_child_one",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_a_child_two_link",
            otherId: "root_a_child_two",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a_child_one",
        startFrame: 0,
        endFrame: 6,
        blueprint: _blueprint("root_a_child_one_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_one_link",
            otherId: "root_a",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a_child_two",
        startFrame: 8,
        endFrame: 14,
        blueprint: _blueprint("root_a_child_two_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_two_link",
            otherId: "root_a",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_b",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("root_b_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_b",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_b_child_link",
            otherId: "root_b_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_b_child",
        startFrame: 0,
        endFrame: 6,
        blueprint: _blueprint("root_b_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_b_child_link",
            otherId: "root_b",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "root_c_keyframe",
        frame: 0,
        blueprint: _blueprint("root_c_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_c",
            otherId: "entry",
            path: "parent",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_d",
        startFrame: 10,
        endFrame: 12,
        blueprint: _blueprint("root_d_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_d",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "root_e_keyframe",
        frame: 20,
        blueprint: _blueprint("root_e_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_e",
            otherId: "entry",
            path: "parent",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_f",
        startFrame: 32,
        endFrame: 36,
        blueprint: _blueprint("root_f_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_f",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

ElementBlueprint _blueprint(String id) {
  return ElementBlueprint(
    id: id,
    name: id,
    description: id,
    extension: "test",
    dataBlueprint: ObjectBlueprint(fields: {}),
    color: Colors.blue,
  );
}
