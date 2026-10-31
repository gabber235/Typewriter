import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("TimelineLayoutEngine", () {
    test("keeps overlapping sibling subtrees in separate branch lanes", () {
      final data = timeline()
          .track(
            elements: [
              .segment("parent", 0, 20, [.segment("child", 5, 10)]),
              .segment("sibling", 0, 8, [.keyframe("sibling_keyframe", 2)]),
            ],
          )
          .build();

      final placement = data.layout().placement();

      expect(placement.element("parent").laneIndex, 0);
      expect(placement.element("child").laneIndex, 1);
      expect(placement.element("sibling").laneIndex, 2);
      expect(placement.element("sibling_keyframe").laneIndex, 3);
    });

    test("has lane height 1 when no segments and keyframes overlap", () {
      final data = timeline()
          .track(
            elements: [
              .keyframe("keyframe", 0),
              .segment("segment_1", 5, 10),
              .segment("segment_2", 15, 20),
              .keyframe("keyframe_2", 25),
              .segment("segment_3", 35, 40),
            ],
          )
          .build();

      final layout = data.layout();
      expect(layout.tracks.length, 1);
      expect(layout.tracks.first.laneCount, 1);
    });

    test("keeps subtree lanes stable during preview and marks descendants as related", () {
      final data = timeline()
          .track(
            elements: [
              .segment("parent", 0, 20, [.segment("child", 5, 10)]),
              .segment("sibling", 0, 8, [.keyframe("sibling_keyframe", 2)]),
            ],
          )
          .build();

      final basePlacement = data.layout().placement();

      final parentPreview = data.move("parent", 12);

      final previewPlacement = data
          .layout(previews: [parentPreview])
          .placement();

      final baseParent = basePlacement.element("parent");
      final baseChild = basePlacement.element("child");
      final previewParent = previewPlacement.element("parent");
      final previewChild = previewPlacement.element("child");

      expect(previewParent.laneIndex, baseParent.laneIndex);
      expect(previewChild.laneIndex, baseChild.laneIndex);
      expect(previewParent.rect.left, greaterThan(baseParent.rect.left));
      expect(previewChild.rect.left, greaterThan(baseChild.rect.left));
      expect(previewParent.previewState, TimelinePreviewState.active);
      expect(previewChild.previewState, TimelinePreviewState.related);
    });

    test("keeps a moved child subtree in its stream and evicts siblings", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root", 0, 40, [
                .segment("active_child", 0, 10),
                .segment("sibling_child", 24, 30),
              ]),
            ],
          )
          .build();
      final preview = data.move("active_child", 24);

      final baseLayout = data.layout().placement();
      final previewLayout = data.layout(previews: [preview]).placement();

      final baseActiveChild = baseLayout.element("active_child");
      final baseSiblingChild = baseLayout.element("sibling_child");
      final previewActiveChild = previewLayout.element("active_child");
      final previewSiblingChild = previewLayout.element("sibling_child");

      expect(previewActiveChild.laneIndex, baseActiveChild.laneIndex);
      expect(
        previewSiblingChild.laneIndex,
        greaterThan(baseSiblingChild.laneIndex),
      );
      expect(previewActiveChild.previewState, TimelinePreviewState.active);
      expect(previewSiblingChild.previewState, TimelinePreviewState.none);
    });

    test("keeps a moved root subtree in its stream and evicts other roots", () {
      final (baseLayout, previewLayout) = twoRootsWithRootAMoved();

      final baseRootA = baseLayout.element("root_a");
      final baseRootAChild = baseLayout.element("root_a_child");
      final baseRootB = baseLayout.element("root_b");
      final previewRootA = previewLayout.element("root_a");
      final previewRootAChild = previewLayout.element("root_a_child");
      final previewRootB = previewLayout.element("root_b");

      expect(previewRootA.laneIndex, baseRootA.laneIndex);
      expect(previewRootAChild.laneIndex, baseRootAChild.laneIndex);
      expect(previewRootB.laneIndex, greaterThan(baseRootB.laneIndex));
      expect(previewRootA.previewState, TimelinePreviewState.active);
      expect(previewRootAChild.previewState, TimelinePreviewState.related);
    });

    test("moves a competing root subtree as a preserved block", () {
      final (baseLayout, previewLayout) = twoRootsWithRootAMoved();

      final baseRootB = baseLayout.element("root_b");
      final baseRootBChild = baseLayout.element("root_b_child");
      final previewRootB = previewLayout.element("root_b");
      final previewRootBChild = previewLayout.element("root_b_child");

      expect(previewRootB.laneIndex, greaterThan(baseRootB.laneIndex));
      expect(
        previewRootBChild.laneIndex - previewRootB.laneIndex,
        baseRootBChild.laneIndex - baseRootB.laneIndex,
      );
    });

    test("keeps multi root preview lane reservation deterministic", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root_a", 0, 20, [.segment("root_a_child", 5, 10)]),
              .segment("root_b", 24, 30, [.segment("root_b_child", 2, 5)]),
            ],
          )
          .build();

      final previewLayoutA = data
          .layout(previews: [data.move("root_b", 20), data.move("root_a", 24)])
          .placement();
      final previewLayoutB = data
          .layout(previews: [data.move("root_a", 24), data.move("root_b", 20)])
          .placement();

      for (final id in ["root_a", "root_a_child", "root_b", "root_b_child"]) {
        expect(
          previewLayoutA.element(id).laneIndex,
          previewLayoutB.element(id).laneIndex,
          reason: id,
        );
      }
      expect(
        previewLayoutA.element("root_a").previewState,
        TimelinePreviewState.active,
      );
      expect(
        previewLayoutA.element("root_b").previewState,
        TimelinePreviewState.active,
      );
    });

    test(
      "keeps a moved child segment stream when a sibling keyframe overlaps",
      () {
        final data = timeline()
            .track(
              elements: [
                .segment("root", 0, 40, [
                  .segment("active_child", 0, 10),
                  .keyframe("sibling_keyframe", 24),
                ]),
              ],
            )
            .build();
        final preview = data.move("active_child", 24);

        final baseLayout = data.layout().placement();
        final previewLayout = data.layout(previews: [preview]).placement();

        final baseActiveChild = baseLayout.element("active_child");
        final baseSiblingKeyframe = baseLayout.element("sibling_keyframe");
        final previewActiveChild = previewLayout.element("active_child");
        final previewSiblingKeyframe = previewLayout.element(
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

    test("keeps a moved child keyframe stream and moves a sibling segment subtree as a block", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root", 0, 40, [
                .keyframe("active_keyframe", 0),
                .segment("sibling_segment", 24, 30, [
                  .segment("sibling_child", 2, 5),
                ]),
              ]),
            ],
          )
          .build();
      final preview = data.move("active_keyframe", 24);

      final baseLayout = data.layout().placement();
      final previewLayout = data.layout(previews: [preview]).placement();

      final baseActiveKeyframe = baseLayout.element("active_keyframe");
      final baseSiblingSegment = baseLayout.element("sibling_segment");
      final baseSiblingChild = baseLayout.element("sibling_child");
      final previewActiveKeyframe = previewLayout.element("active_keyframe");
      final previewSiblingSegment = previewLayout.element("sibling_segment");
      final previewSiblingChild = previewLayout.element("sibling_child");

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
    });

    for (final (frame, outcome) in [
      (
        24,
        "keeps a moved root segment subtree stream when a sibling root keyframe overlaps",
      ),
      (
        14,
        "evicts root keyframe when moved root subtree lands on keyframe frame",
      ),
    ]) {
      test(outcome, () {
        final (baseLayout, previewLayout) = rootAMovedBesideKeyframe(to: frame);

        final baseRootA = baseLayout.element("root_a");
        final baseRootAChild = baseLayout.element("root_a_child");
        final baseRootKeyframe = baseLayout.element("root_keyframe");
        final previewRootA = previewLayout.element("root_a");
        final previewRootAChild = previewLayout.element("root_a_child");
        final previewRootKeyframe = previewLayout.element("root_keyframe");

        expect(previewRootA.laneIndex, baseRootA.laneIndex);
        expect(previewRootAChild.laneIndex, baseRootAChild.laneIndex);
        expect(
          previewRootKeyframe.laneIndex,
          greaterThan(baseRootKeyframe.laneIndex),
        );
        expect(previewRootA.previewState, TimelinePreviewState.active);
        expect(previewRootAChild.previewState, TimelinePreviewState.related);
      });
    }

    test(
      "keeps lanes stable before overlap and reflows only when overlap starts",
      () {
        final data = timeline()
            .track(
              elements: [
                .segment("root", 0, 40, [
                  .segment("active_child", 10, 20),
                  .keyframe("overlapping_keyframe", 15),
                  .keyframe("far_keyframe", 35),
                ]),
              ],
            )
            .build();
        final preOverlapPreview = data.move("active_child", 11);
        final overlapPreview = data.move("active_child", 30);

        final baseLayout = data.layout().placement();
        final preOverlapLayout = data
            .layout(previews: [preOverlapPreview])
            .placement();
        final overlapLayout = data
            .layout(previews: [overlapPreview])
            .placement();

        final baseActiveChild = baseLayout.element("active_child");
        final baseOverlapingKeyframe = baseLayout.element(
          "overlapping_keyframe",
        );
        final baseFarKeyframe = baseLayout.element("far_keyframe");
        final preOverlapActiveChild = preOverlapLayout.element("active_child");
        final preOverlapOverlappingKeyframe = preOverlapLayout.element(
          "overlapping_keyframe",
        );
        final preOverlapFarKeyframe = preOverlapLayout.element("far_keyframe");

        final overlapActiveChild = overlapLayout.element("active_child");
        final overlapOverlappingKeyframe = overlapLayout.element(
          "overlapping_keyframe",
        );
        final overlapFarKeyframe = overlapLayout.element("far_keyframe");

        expect(preOverlapActiveChild.laneIndex, baseActiveChild.laneIndex);
        expect(overlapActiveChild.laneIndex, baseActiveChild.laneIndex);

        expect(
          preOverlapOverlappingKeyframe.laneIndex,
          baseOverlapingKeyframe.laneIndex,
        );
        expect(
          overlapOverlappingKeyframe.laneIndex,
          lessThan(baseOverlapingKeyframe.laneIndex),
        );

        expect(preOverlapFarKeyframe.laneIndex, baseFarKeyframe.laneIndex);
        expect(
          overlapFarKeyframe.laneIndex,
          greaterThan(baseFarKeyframe.laneIndex),
        );
      },
    );

    test(
      "reserves child stream during resize start and evicts touching sibling",
      () {
        final data = timeline()
            .track(
              elements: [
                .segment("root", 0, 40, [
                  .segment("active_child", 10, 20),
                  .segment("touching_sibling_child", 0, 9),
                ]),
              ],
            )
            .build();
        final preview = data.resizeStart("active_child", 9);

        final baseLayout = data.layout().placement();
        final previewLayout = data.layout(previews: [preview]).placement();

        final baseActiveChild = baseLayout.element("active_child");
        final baseSiblingChild = baseLayout.element("touching_sibling_child");
        final previewActiveChild = previewLayout.element("active_child");
        final previewSiblingChild = previewLayout.element(
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

    test(
      "reserves root stream during resize end and evicts overlapping roots",
      () {
        final data = timeline()
            .track(
              elements: [
                .segment("root_a", 0, 20, [.segment("root_a_child", 5, 10)]),
                .segment("root_b", 21, 31, [.segment("root_b_child", 2, 10)]),
              ],
            )
            .build();
        final preview = data.resizeEnd("root_a", 24);

        final baseLayout = data.layout().placement();
        final previewLayout = data.layout(previews: [preview]).placement();

        final baseRootA = baseLayout.element("root_a");
        final baseRootAChild = baseLayout.element("root_a_child");
        final baseRootB = baseLayout.element("root_b");
        final baseRootBChild = baseLayout.element("root_b_child");
        final previewRootA = previewLayout.element("root_a");
        final previewRootAChild = previewLayout.element("root_a_child");

        final previewRootB = previewLayout.element("root_b");
        final previewRootBChild = previewLayout.element("root_b_child");

        expect(previewRootA.laneIndex, baseRootA.laneIndex);
        expect(previewRootAChild.laneIndex, baseRootAChild.laneIndex);
        expect(previewRootB.laneIndex, greaterThan(baseRootB.laneIndex));
        expect(
          previewRootBChild.laneIndex - previewRootB.laneIndex,
          baseRootBChild.laneIndex - baseRootB.laneIndex,
        );
      },
    );

    test("treats touching segment boundaries as inclusive overlap during move preview", () {
      final data = timeline()
          .track(
            elements: [.segment("active", 0, 4), .segment("touching", 5, 9)],
          )
          .build();
      final preview = data.move("active", 1);

      final baseLayout = data.layout().placement();
      final previewLayout = data.layout(previews: [preview]).placement();

      final baseActive = baseLayout.element("active");
      final baseTouching = baseLayout.element("touching");
      final previewActive = previewLayout.element("active");
      final previewTouching = previewLayout.element("touching");

      expect(previewActive.laneIndex, baseActive.laneIndex);
      expect(previewTouching.laneIndex, greaterThan(baseTouching.laneIndex));
    });

    test("keeps unaffected track lane assignment stable during preview reservation", () {
      final data = timeline()
          .track(
            id: "entry_a",
            elements: [
              .segment("track_a_root", 0, 20, [
                .segment("track_a_active_child", 0, 10),
                .segment("track_a_competing_child", 11, 20),
              ]),
            ],
          )
          .track(
            id: "entry_b",
            elements: [
              .segment("track_b_root", 0, 40, [
                .segment("track_b_left", 5, 10),
                .segment("track_b_right", 15, 20),
                .keyframe("track_b_keyframe", 25),
              ]),
            ],
          )
          .build();
      final preview = data.move("track_a_active_child", 10);

      final baseLayout = data.layout().placement();
      final previewLayout = data.layout(previews: [preview]).placement();

      final baseTrackACompeting = baseLayout.element("track_a_competing_child");
      final previewTrackACompeting = previewLayout.element(
        "track_a_competing_child",
      );
      expect(
        previewTrackACompeting.laneIndex,
        greaterThan(baseTrackACompeting.laneIndex),
      );

      expect(
        previewLayout.element("track_b_root").laneIndex,
        baseLayout.element("track_b_root").laneIndex,
      );
      expect(
        previewLayout.element("track_b_left").laneIndex,
        baseLayout.element("track_b_left").laneIndex,
      );
      expect(
        previewLayout.element("track_b_right").laneIndex,
        baseLayout.element("track_b_right").laneIndex,
      );
      expect(
        previewLayout.element("track_b_keyframe").laneIndex,
        baseLayout.element("track_b_keyframe").laneIndex,
      );
    });

    test("keeps dense layout lane allocation deterministic during reservation preview", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root_a", 0, 20, [
                .segment("root_a_child_one", 11, 20),
                .segment("root_a_child_two", 0, 10),
              ]),
              .segment("root_b", 0, 20, [.segment("root_b_child", 0, 10)]),
              .keyframe("root_c_keyframe", 10),
              .segment("root_d", 10, 20),
              .keyframe("root_e_keyframe", 10),
              .segment("root_f", 30, 50),
            ],
          )
          .build();
      final preview = data.move("root_a", 12);

      final previewLayout = data.layout(previews: [preview]).placement();
      final replayLayout = data.layout(previews: [preview]).placement();

      for (final id in [
        "root_a",
        "root_a_child_one",
        "root_a_child_two",
        "root_b",
        "root_b_child",
        "root_c_keyframe",
        "root_d",
        "root_e_keyframe",
        "root_f",
      ]) {
        expect(
          previewLayout.element(id).laneIndex,
          replayLayout.element(id).laneIndex,
          reason: id,
        );
      }
    });

    test("shows inside and intersecting elements and hides fully out of bounds elements", () {
      final data = timeline()
          .track(
            elements: [
              .segment("outside", 0, 2),
              .segment("intersecting", 17, 22),
              .segment("inside", 25, 30),
            ],
          )
          .build();
      final layout = data.layout().placement(
        viewport: const TimelineViewport(
          headerWidth: 200,
          planeWidth: 800,
          planeHeight: 400,
          horizontalOffset: 200,
          verticalOffset: 0,
          pixelsPerFrame: 10,
          overscanFrames: 0,
        ),
      );

      final visibleIds = layout.visibleElements
          .map((element) => element.element.id.id)
          .toSet();

      expect(visibleIds.contains("outside"), isFalse);
      expect(visibleIds.contains("inside"), isTrue);
      expect(visibleIds.contains("intersecting"), isTrue);
    });

    test("keeps elements inside horizontal viewport overscan", () {
      final data = timeline()
          .track(elements: [.segment("overscan", 15, 17)])
          .build();
      final layout = data.layout().placement(
        viewport: const TimelineViewport(
          headerWidth: 200,
          planeWidth: 100,
          planeHeight: 400,
          horizontalOffset: 200,
          verticalOffset: 0,
          pixelsPerFrame: 10,
          overscanFrames: 10,
        ),
      );

      expect(
        layout.visibleElements.map((element) => element.element.id.id),
        contains("overscan"),
      );
    });

    test("expands culling bounds beyond the physical viewport", () {
      const viewport = TimelineViewport(
        headerWidth: 200,
        planeWidth: 100,
        planeHeight: 100,
        horizontalOffset: 200,
        verticalOffset: 200,
        pixelsPerFrame: 10,
        overscanFrames: 10,
        overscanExtent: 50,
      );

      expect(viewport.visibleBounds, const Rect.fromLTRB(100, 150, 400, 350));
    });

    test("expands content width for far preview geometry", () {
      final data = timeline()
          .track(
            elements: [
              .segment("parent", 0, 20, [.segment("child", 5, 10)]),
              .segment("sibling", 0, 8, [.keyframe("sibling_keyframe", 2)]),
            ],
          )
          .build();
      final preview = data.move("parent", 240);

      final layout = data.layout(previews: [preview]).placement();

      expect(layout.contentWidth, greaterThan(2400));
    });

    test("keeps containment when move preview tries to go past parent end", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root", 20, 60, [.segment("active_child", 10, 20)]),
            ],
          )
          .build();
      final preview = data.move("active_child", 55);

      final layout = data.layout(previews: [preview]).placement();

      expectContainmentInLayout(layout, data);
    });

    test(
      "keeps containment when move preview tries to go before parent start",
      () {
        final data = timeline()
            .track(
              elements: [
                .segment("root", 20, 60, [.segment("active_child", 10, 20)]),
              ],
            )
            .build();
        final preview = data.move("active_child", 15);

        final layout = data.layout(previews: [preview]).placement();

        expectContainmentInLayout(layout, data);
      },
    );

    test("keeps containment when resizeStart preview tries to go before parent start", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root", 20, 60, [.segment("active_child", 10, 20)]),
            ],
          )
          .build();
      final preview = data.resizeStart("active_child", 15);

      final layout = data.layout(previews: [preview]).placement();

      expectContainmentInLayout(layout, data);
    });

    test(
      "keeps containment when resizeEnd preview tries to go past parent end",
      () {
        final data = timeline()
            .track(
              elements: [
                .segment("root", 20, 60, [.segment("active_child", 10, 20)]),
              ],
            )
            .build();
        final preview = data.resizeEnd("active_child", 70);

        final layout = data.layout(previews: [preview]).placement();

        expectContainmentInLayout(layout, data);
      },
    );

    test("keeps containment for in-bounds previews in all modes", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root", 20, 60, [.segment("active_child", 10, 20)]),
            ],
          )
          .build();
      final previews = [
        data.move("active_child", 35),
        data.resizeStart("active_child", 25),
        data.resizeEnd("active_child", 45),
      ];

      for (final preview in previews) {
        final layout = data.layout(previews: [preview]).placement();
        expectContainmentInLayout(layout, data);
      }
    });

    test(
      "keeps containment for nested descendants under aggressive preview",
      () {
        final data = timeline()
            .track(
              elements: [
                .segment("root", 20, 80, [
                  .segment("nested_child", 5, 25, [
                    .segment("grandchild", 10, 15),
                  ]),
                ]),
              ],
            )
            .build();
        final preview = data.move("nested_child", 55);

        final layout = data.layout(previews: [preview]).placement();

        expectContainmentInLayout(layout, data);
      },
    );

    test(
      "keeps containment local to active track under aggressive preview",
      () {
        final data = timeline()
            .track(
              id: "entry_a",
              elements: [
                .segment("track_a_root", 20, 60, [
                  .segment("track_a_active_child", 10, 20),
                ]),
              ],
            )
            .track(
              id: "entry_b",
              elements: [
                .segment("track_b_root", 0, 40, [
                  .segment("track_b_child", 5, 15),
                ]),
              ],
            )
            .build();
        final preview = data.move("track_a_active_child", 55);

        final baseLayout = data.layout().placement();
        final previewLayout = data.layout(previews: [preview]).placement();

        expectContainmentInLayout(previewLayout, data);

        expect(
          previewLayout.element("track_b_root").laneIndex,
          baseLayout.element("track_b_root").laneIndex,
        );
        expect(
          previewLayout.element("track_b_child").laneIndex,
          baseLayout.element("track_b_child").laneIndex,
        );
      },
    );

    test("keeps containment when root resizeStart request exceeds descendant limits", () {
      final data = timeline()
          .track(
            elements: [
              .segment("root", 20, 60, [
                .segment("child", 30, 40, [.keyframe("child_keyframe", 9)]),
              ]),
            ],
          )
          .build();
      final preview = data.resizeStart("root", 55);

      final layout = data.layout(previews: [preview]).placement();

      expectContainmentInLayout(layout, data);
    });
  });
}
