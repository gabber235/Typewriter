import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
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
      final data = _timelineDataFromElements(_layoutSceneElements());
      final layout = _buildLayout(
        data: data,
        viewport: _viewport(),
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
        final data = _timelineDataFromElements(_layoutSceneElements());
        final preview = const TimelinePreview(
          id: "parent",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 12,
          endFrame: 32,
        );
        final previewData = _timelineDataFromElements(
          _layoutSceneElements(),
          override: const _TimelineOverride(
            cueId: "parent",
            mode: TimelineInteractionMode.move,
            startFrame: 12,
            endFrame: 32,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _childReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "active_child",
            mode: TimelineInteractionMode.move,
            startFrame: 24,
            endFrame: 34,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(_rootReservationSceneElements());
        final preview = const TimelinePreview(
          id: "root_a",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 20,
          startFrame: 24,
          endFrame: 44,
        );
        final previewData = _timelineDataFromElements(
          _rootReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "root_a",
            mode: TimelineInteractionMode.move,
            startFrame: 24,
            endFrame: 44,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
      final data = _timelineDataFromElements(_rootReservationSceneElements());
      final preview = const TimelinePreview(
        id: "root_a",
        mode: TimelineInteractionMode.move,
        originalStartFrame: 0,
        originalEndFrame: 20,
        startFrame: 24,
        endFrame: 44,
      );
      final previewData = _timelineDataFromElements(
        _rootReservationSceneElements(),
        override: const _TimelineOverride(
          cueId: "root_a",
          mode: TimelineInteractionMode.move,
          startFrame: 24,
          endFrame: 44,
        ),
      );

      final baseLayout = _buildLayout(
        data: data,
        viewport: _viewport(),
        preview: null,
      );
      final previewLayout = _buildLayout(
        data: data,
        viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _childSegmentVsKeyframeReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "active_child",
            mode: TimelineInteractionMode.move,
            startFrame: 24,
            endFrame: 34,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _childKeyframeVsSegmentReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "active_keyframe",
            mode: TimelineInteractionMode.move,
            startFrame: 24,
            endFrame: 24,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _rootSegmentVsKeyframeReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "root_a",
            mode: TimelineInteractionMode.move,
            startFrame: 24,
            endFrame: 44,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _trailingKeyframesReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "active_child",
            mode: TimelineInteractionMode.move,
            startFrame: 18,
            endFrame: 28,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _resizeStartChildReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "active_child",
            mode: TimelineInteractionMode.resizeStart,
            startFrame: 9,
            endFrame: 20,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _resizeEndRootReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "root_a",
            mode: TimelineInteractionMode.resizeEnd,
            startFrame: 0,
            endFrame: 24,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _inclusiveBoundaryCollisionSceneElements(),
          override: const _TimelineOverride(
            cueId: "active",
            mode: TimelineInteractionMode.move,
            startFrame: 1,
            endFrame: 5,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
          _multiTrackIsolationSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "track_a_active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 0,
          originalEndFrame: 10,
          startFrame: 10,
          endFrame: 20,
        );
        final previewData = _timelineDataFromElements(
          _multiTrackIsolationSceneElements(),
          override: const _TimelineOverride(
            cueId: "track_a_active_child",
            mode: TimelineInteractionMode.move,
            startFrame: 10,
            endFrame: 20,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _rootKeyframeCompetitionSceneElements(),
          override: const _TimelineOverride(
            cueId: "root_a",
            mode: TimelineInteractionMode.move,
            startFrame: 14,
            endFrame: 34,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
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
        final data = _timelineDataFromElements(
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
        final previewData = _timelineDataFromElements(
          _denseDeterministicReservationSceneElements(),
          override: const _TimelineOverride(
            cueId: "root_a",
            mode: TimelineInteractionMode.move,
            startFrame: 12,
            endFrame: 32,
          ),
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );

        _expectLaneIndices(baseLayout, {
          "root_a": 0,
          "root_a_child_one": 1,
          "root_a_child_two": 1,
          "root_b": 2,
          "root_b_child": 3,
          "root_c_keyframe": 5,
          "root_d": 4,
          "root_e_keyframe": 6,
          "root_f": 0,
        });
        _expectLaneIndices(previewLayout, {
          "root_a": 0,
          "root_a_child_one": 1,
          "root_a_child_two": 1,
          "root_b": 2,
          "root_b_child": 3,
          "root_c_keyframe": 5,
          "root_d": 4,
          "root_e_keyframe": 6,
          "root_f": 2,
        });
      },
    );

    testWidgets("applies overscan visibility and minimum segment width", (
      tester,
    ) async {
      final data = _timelineDataFromElements(_viewportSceneElements());
      final layout = _buildLayout(
        data: data,
        viewport: const TimelineViewport(
          headerWidth: 200,
          planeWidth: 800,
          planeHeight: 400,
          horizontalOffset: 200,
          verticalOffset: 0,
          pixelsPerFrame: 10,
          overscanFrames: 3,
        ),
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
      final data = _timelineDataFromElements(_layoutSceneElements());
      final preview = const TimelinePreview(
        id: "parent",
        mode: TimelineInteractionMode.move,
        originalStartFrame: 0,
        originalEndFrame: 20,
        startFrame: 240,
        endFrame: 260,
      );
      final previewData = _timelineDataFromElements(
        _layoutSceneElements(),
        override: const _TimelineOverride(
          cueId: "parent",
          mode: TimelineInteractionMode.move,
          startFrame: 240,
          endFrame: 260,
        ),
      );

      final layout = _buildLayout(
        data: data,
        viewport: _viewport(),
        preview: preview,
      );

      expect(layout.contentWidth, greaterThan(2400));
    });

    testWidgets(
      "keeps containment when move preview tries to go past parent end",
      (tester) async {
        final data = _timelineDataFromElements(
          _containmentStressSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 55,
          endFrame: 65,
        );

        final layout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );

        _expectContainmentInLayout(layout, data);
      },
    );

    testWidgets(
      "keeps containment when move preview tries to go before parent start",
      (tester) async {
        final data = _timelineDataFromElements(
          _containmentStressSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 15,
          endFrame: 25,
        );

        final layout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );

        _expectContainmentInLayout(layout, data);
      },
    );

    testWidgets(
      "keeps containment when resizeStart preview tries to go before parent start",
      (tester) async {
        final data = _timelineDataFromElements(
          _containmentStressSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.resizeStart,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 15,
          endFrame: 40,
        );

        final layout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );

        _expectContainmentInLayout(layout, data);
      },
    );

    testWidgets(
      "keeps containment when resizeEnd preview tries to go past parent end",
      (tester) async {
        final data = _timelineDataFromElements(
          _containmentStressSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.resizeEnd,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 30,
          endFrame: 70,
        );

        final layout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );

        _expectContainmentInLayout(layout, data);
      },
    );

    testWidgets("keeps containment for in-bounds previews in all modes", (
      tester,
    ) async {
      final data = _timelineDataFromElements(_containmentStressSceneElements());
      final previews = [
        const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 35,
          endFrame: 45,
        ),
        const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.resizeStart,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 25,
          endFrame: 40,
        ),
        const TimelinePreview(
          id: "active_child",
          mode: TimelineInteractionMode.resizeEnd,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 30,
          endFrame: 45,
        ),
      ];

      for (final preview in previews) {
        final layout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );
        _expectContainmentInLayout(layout, data);
      }
    });

    testWidgets(
      "keeps containment for nested descendants under aggressive preview",
      (tester) async {
        final data = _timelineDataFromElements(
          _nestedContainmentStressSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "nested_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 25,
          originalEndFrame: 45,
          startFrame: 55,
          endFrame: 75,
        );

        final layout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );

        _expectContainmentInLayout(layout, data);
      },
    );

    testWidgets(
      "keeps containment local to active track under aggressive preview",
      (tester) async {
        final data = _timelineDataFromElements(
          _multiTrackContainmentStressSceneElements(),
        );
        final preview = const TimelinePreview(
          id: "track_a_active_child",
          mode: TimelineInteractionMode.move,
          originalStartFrame: 30,
          originalEndFrame: 40,
          startFrame: 55,
          endFrame: 65,
        );

        final baseLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: null,
        );
        final previewLayout = _buildLayout(
          data: data,
          viewport: _viewport(),
          preview: preview,
        );

        _expectContainmentInLayout(previewLayout, data);

        expect(
          _placed(previewLayout, "track_b_root").laneIndex,
          _placed(baseLayout, "track_b_root").laneIndex,
        );
        expect(
          _placed(previewLayout, "track_b_child").laneIndex,
          _placed(baseLayout, "track_b_child").laneIndex,
        );
      },
    );
  });
}

class _TimelineOverride {
  const _TimelineOverride({
    required this.cueId,
    required this.mode,
    required this.startFrame,
    required this.endFrame,
  });

  final String cueId;
  final TimelineInteractionMode mode;
  final int startFrame;
  final int endFrame;
}

TimelineLayoutResult _buildLayout({
  required TimelineData data,
  required TimelineViewport viewport,
  required TimelinePreview? preview,
}) {
  return TimelineLayoutEngine(
    style: TimelineStyle.fallback(ThemeData()),
  ).build(data: data, viewport: viewport, preview: preview);
}

TimelineData _timelineDataFromElements(
  List<PageElement> elements, {
  _TimelineOverride? override,
}) {
  final entries = <PageEntry>[];
  final entriesById = <String, PageEntry>{};
  final cuesById = <String, Cue>{};
  final childrenByCueId = <String, List<String>>{};

  for (final element in elements) {
    switch (element) {
      case PageElementEntry(entry: final entry):
        entries.add(entry);
        entriesById[entry.id] = entry;
      case PageElementCue(cue: final cue):
        cuesById[cue.id] = cue;

        if (cue case Segment(outwardLinks: final outwardLinks)) {
          childrenByCueId[cue.id] = _childIds(outwardLinks);
        }
      case PageElementGroup():
    }
  }

  final rootCueIdsByEntryId = <String, List<String>>{};
  for (final element in elements) {
    if (element case PageElementEntry(entry: final entry)) {
      rootCueIdsByEntryId[entry.id] = _childIds(_entryOutwardLinks(entry));
    }
  }

  final tracks = <TimelineTrack>[];
  for (final entry in entries) {
    final rootCueIds = rootCueIdsByEntryId[entry.id] ?? const <String>[];
    final trackElements = <TimelineElement>[];

    for (final rootCueId in rootCueIds) {
      final element = _buildTimelineElement(
        cueId: rootCueId,
        cuesById: cuesById,
        childrenByCueId: childrenByCueId,
        override: override,
        parentAbsoluteStartFrame: 0,
        parentLocalStartFrame: 0,
        parentDuration: null,
      );
      if (element != null) {
        trackElements.add(element);
      }
    }

    trackElements.sort(_compareTimelineElements);

    tracks.add(
      TimelineTrack(
        id: TimelineIdentifier(entry.id),
        header: (_) => const SizedBox.shrink(),
        elements: trackElements,
      ),
    );
  }

  return TimelineData(tracks: tracks);
}

TimelineElement? _buildTimelineElement({
  required String cueId,
  required Map<String, Cue> cuesById,
  required Map<String, List<String>> childrenByCueId,
  required _TimelineOverride? override,
  required int parentAbsoluteStartFrame,
  required int parentLocalStartFrame,
  required int? parentDuration,
}) {
  final cue = cuesById[cueId];
  if (cue == null) return null;

  final localFrames = _resolveLocalFrames(
    cueId: cueId,
    cue: cue,
    cuesById: cuesById,
    childrenByCueId: childrenByCueId,
    override: override,
    parentLocalStartFrame: parentLocalStartFrame,
    parentDuration: parentDuration,
  );

  final absoluteStartFrame = parentAbsoluteStartFrame + localFrames.startFrame;

  switch (cue) {
    case Keyframe():
      return TimelineKeyframe(
        id: TimelineIdentifier(cueId),
        frame: absoluteStartFrame,
        builder: (_, __) => const SizedBox.shrink(),
        color: Colors.orange,
      );
    case Segment():
      final absoluteEndFrame = parentAbsoluteStartFrame + localFrames.endFrame;
      final segmentDuration = localFrames.endFrame - localFrames.startFrame;
      final childElements = <TimelineElement>[];
      final childIds = childrenByCueId[cueId] ?? const <String>[];
      for (final childId in childIds) {
        final childElement = _buildTimelineElement(
          cueId: childId,
          cuesById: cuesById,
          childrenByCueId: childrenByCueId,
          override: override,
          parentAbsoluteStartFrame: absoluteStartFrame,
          parentLocalStartFrame: cue.startFrame,
          parentDuration: segmentDuration,
        );
        if (childElement != null) {
          childElements.add(childElement);
        }
      }
      childElements.sort(_compareTimelineElements);

      return TimelineSegment(
        id: TimelineIdentifier(cueId),
        startFrame: absoluteStartFrame,
        endFrame: absoluteEndFrame,
        builder: (_, __) => const SizedBox.shrink(),
        children: childElements,
        color: Colors.blue,
      );
    case _:
      return null;
  }
}

({int startFrame, int endFrame}) _resolveLocalFrames({
  required String cueId,
  required Cue cue,
  required Map<String, Cue> cuesById,
  required Map<String, List<String>> childrenByCueId,
  required _TimelineOverride? override,
  required int parentLocalStartFrame,
  required int? parentDuration,
}) {
  final baseFrames = switch (cue) {
    Segment(startFrame: final startFrame, endFrame: final endFrame) => (
      startFrame: startFrame,
      endFrame: endFrame,
    ),
    Keyframe(frame: final frame) => (startFrame: frame, endFrame: frame),
    _ => (startFrame: 0, endFrame: 0),
  };

  if (override == null || override.cueId != cueId) {
    return _normalizeBaseFrames(baseFrames, parentDuration);
  }

  final duration = baseFrames.endFrame - baseFrames.startFrame;
  final requiredDuration = _requiredDurationForChildren(
    cueId: cueId,
    cuesById: cuesById,
    childrenByCueId: childrenByCueId,
  );
  final desiredLocalStart = override.startFrame - parentLocalStartFrame;

  switch (override.mode) {
    case TimelineInteractionMode.move:
      if (parentDuration == null) {
        return (
          startFrame: override.startFrame,
          endFrame: override.startFrame + duration,
        );
      }

      final maxStartFrame = parentDuration - duration;
      final clampedStartFrame = _clampInt(desiredLocalStart, 0, maxStartFrame);
      return (
        startFrame: clampedStartFrame,
        endFrame: clampedStartFrame + duration,
      );
    case TimelineInteractionMode.resizeStart:
      if (cue is! Segment) return baseFrames;

      final baseLocalStart = cue.startFrame;
      final baseLocalEnd = cue.endFrame;

      if (parentDuration == null) {
        final newDuration = override.endFrame - override.startFrame;
        final newLocalStart = baseLocalEnd - newDuration;
        final clampedLocalStart = _clampInt(newLocalStart, 0, baseLocalEnd);
        return (startFrame: clampedLocalStart, endFrame: baseLocalEnd);
      }

      final maxStart = baseLocalEnd - requiredDuration;
      final newLocalStart = override.startFrame - parentLocalStartFrame;
      final clampedLocalStart = _clampInt(newLocalStart, 0, max(0, maxStart));
      return (startFrame: clampedLocalStart, endFrame: baseLocalEnd);
    case TimelineInteractionMode.resizeEnd:
      if (cue is! Segment) return baseFrames;

      final baseLocalStart = cue.startFrame;

      if (parentDuration == null) {
        return (startFrame: baseLocalStart, endFrame: override.endFrame);
      }

      final desiredLocalEnd = override.endFrame - parentLocalStartFrame;
      final minLocalEnd = baseLocalStart + requiredDuration;
      final clampedLocalEnd = _clampInt(
        desiredLocalEnd,
        minLocalEnd,
        parentDuration,
      );
      return (startFrame: baseLocalStart, endFrame: clampedLocalEnd);
  }
}

({int startFrame, int endFrame}) _normalizeBaseFrames(
  ({int startFrame, int endFrame}) frames,
  int? parentDuration,
) {
  if (parentDuration == null) {
    return frames;
  }

  final duration = frames.endFrame - frames.startFrame;
  final clampedDuration = _clampInt(duration, 0, parentDuration);
  final maxStartFrame = parentDuration - clampedDuration;
  final clampedStartFrame = _clampInt(frames.startFrame, 0, maxStartFrame);
  return (
    startFrame: clampedStartFrame,
    endFrame: clampedStartFrame + clampedDuration,
  );
}

int _requiredDurationForChildren({
  required String cueId,
  required Map<String, Cue> cuesById,
  required Map<String, List<String>> childrenByCueId,
}) {
  final childIds = childrenByCueId[cueId] ?? const <String>[];
  var requiredDuration = 0;

  for (final childId in childIds) {
    final childCue = cuesById[childId];
    if (childCue == null) continue;

    final childEndFrame = switch (childCue) {
      Segment(endFrame: final endFrame) => endFrame,
      Keyframe(frame: final frame) => frame,
      _ => 0,
    };
    requiredDuration = max(requiredDuration, childEndFrame);
  }

  return requiredDuration;
}

int _clampInt(int value, int minValue, int maxValue) {
  if (maxValue < minValue) {
    return minValue;
  }
  return value.clamp(minValue, maxValue) as int;
}

int _compareTimelineElements(TimelineElement left, TimelineElement right) {
  final startCompare = left.startFrame.compareTo(right.startFrame);
  if (startCompare != 0) return startCompare;

  final endCompare = right.endFrame.compareTo(left.endFrame);
  if (endCompare != 0) return endCompare;

  return left.id.id.compareTo(right.id.id);
}

List<String> _childIds(List<ElementLink> links) {
  final ids = <String>[];
  final seenIds = <String>{};

  for (final link in links) {
    if (link.path != "children") continue;
    if (!seenIds.add(link.otherId)) continue;
    ids.add(link.otherId);
  }

  return ids;
}

List<String> _parentIds(Cue cue) {
  final inwardLinks = switch (cue) {
    Segment(:final inwardLinks) => inwardLinks,
    Keyframe(:final inwardLinks) => inwardLinks,
    _ => const <ElementLink>[],
  };

  final ids = <String>[];
  final seenIds = <String>{};

  for (final link in inwardLinks) {
    if (link.path != "parent") continue;
    if (!seenIds.add(link.otherId)) continue;
    ids.add(link.otherId);
  }

  return ids;
}

List<ElementLink> _entryOutwardLinks(PageEntry entry) {
  return switch (entry) {
    DefinitionPageEntry(definition: final definition) =>
      definition.outwardEdges,
    NoBlueprintPageEntry(:final outwardLinks) => outwardLinks,
    _ => const <ElementLink>[],
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
  final actual = <String, int>{
    for (final key in expected.keys) key: _placed(layout, key).laneIndex,
  };
  for (final entry in expected.entries) {
    expect(
      actual[entry.key],
      entry.value,
      reason: "${entry.key} actual: $actual",
    );
  }
}

void _expectContainmentInLayout(
  TimelineLayoutResult layout,
  TimelineData data,
) {
  for (final track in data.tracks) {
    for (final root in track.elements) {
      final placedRoot = _placed(layout, root.id.id);
      _expectContainedElement(placedRoot.element);
    }
  }
}

void _expectContainedElement(TimelineElement element) {
  if (element is! TimelineSegment) return;

  for (final child in element.children) {
    expect(
      child.startFrame,
      greaterThanOrEqualTo(element.startFrame),
      reason:
          "${child.id.id} starts before parent ${element.id.id} (${child.startFrame} < ${element.startFrame})",
    );
    expect(
      child.endFrame,
      lessThanOrEqualTo(element.endFrame),
      reason:
          "${child.id.id} ends after parent ${element.id.id} (${child.endFrame} > ${element.endFrame})",
    );
    _expectContainedElement(child);
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
        frame: 20,
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
        frame: 35,
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
            linkId: "root_touching_sibling",
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
            linkId: "root_touching_sibling",
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
        startFrame: 21,
        endFrame: 31,
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
        endFrame: 10,
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
              linkId: "entry_a_root",
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
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_b_root",
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
        endFrame: 20,
        blueprint: _blueprint("track_a_root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_a_root",
            otherId: "entry_a",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "track_a_root_active_child",
            otherId: "track_a_active_child",
            path: "children",
          ),
          const ElementLink(
            linkId: "track_a_root_competing_child",
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
            linkId: "track_a_root_active_child",
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
        startFrame: 11,
        endFrame: 20,
        blueprint: _blueprint("track_a_competing_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_a_root_competing_child",
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
            linkId: "entry_b_root",
            otherId: "entry_b",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "track_b_root_left",
            otherId: "track_b_left",
            path: "children",
          ),
          const ElementLink(
            linkId: "track_b_root_right",
            otherId: "track_b_right",
            path: "children",
          ),
          const ElementLink(
            linkId: "track_b_root_keyframe",
            otherId: "track_b_keyframe",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_b_left",
        startFrame: 5,
        endFrame: 10,
        blueprint: _blueprint("track_b_left_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_b_root_left",
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
        startFrame: 15,
        endFrame: 20,
        blueprint: _blueprint("track_b_right_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_b_root_right",
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
        frame: 25,
        blueprint: _blueprint("track_b_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_b_root_keyframe",
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

List<PageElement> _denseDeterministicReservationSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Dense Deterministic Entry",
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
              linkId: "entry_root_c_keyframe",
              otherId: "root_c_keyframe",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_d",
              otherId: "root_d",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_e_keyframe",
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
            linkId: "root_a_child_one",
            otherId: "root_a_child_one",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_a_child_two",
            otherId: "root_a_child_two",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a_child_one",
        startFrame: 11,
        endFrame: 20,
        blueprint: _blueprint("root_a_child_one_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_one",
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
        startFrame: 0,
        endFrame: 10,
        blueprint: _blueprint("root_a_child_two_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_a_child_two",
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
            linkId: "root_b_child",
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
        endFrame: 10,
        blueprint: _blueprint("root_b_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_b_child",
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
        frame: 10,
        blueprint: _blueprint("root_c_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_c_keyframe",
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
        endFrame: 20,
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
        frame: 10,
        blueprint: _blueprint("root_e_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_e_keyframe",
            otherId: "entry",
            path: "parent",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_f",
        startFrame: 30,
        endFrame: 50,
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

List<PageElement> _containmentStressSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Containment Stress Entry",
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
        startFrame: 20,
        endFrame: 60,
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
  ];
}

List<PageElement> _nestedContainmentStressSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Nested Containment Stress Entry",
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
        startFrame: 20,
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
            linkId: "root_nested_child",
            otherId: "nested_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "nested_child",
        startFrame: 5,
        endFrame: 25,
        blueprint: _blueprint("nested_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_nested_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "nested_child_grandchild",
            otherId: "grandchild",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "grandchild",
        startFrame: 10,
        endFrame: 15,
        blueprint: _blueprint("grandchild_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "nested_child_grandchild",
            otherId: "nested_child",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _multiTrackContainmentStressSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry_a",
          name: "Containment Track A",
          blueprint: _blueprint("entry_a_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_a_root",
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
          name: "Containment Track B",
          blueprint: _blueprint("entry_b_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_b_root",
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
        startFrame: 20,
        endFrame: 60,
        blueprint: _blueprint("track_a_root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_a_root",
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
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_a_active_child",
        startFrame: 10,
        endFrame: 20,
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
        id: "track_b_root",
        startFrame: 0,
        endFrame: 40,
        blueprint: _blueprint("track_b_root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_b_root",
            otherId: "entry_b",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "track_b_child_link",
            otherId: "track_b_child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "track_b_child",
        startFrame: 5,
        endFrame: 15,
        blueprint: _blueprint("track_b_child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "track_b_child_link",
            otherId: "track_b_root",
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
