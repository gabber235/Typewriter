import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/features/organizations.dart";

void main() {
  test("timeline fixture dimensions are deterministic and linked", () {
    final first = generateTimelinePageElements(
      trackCount: 2,
      segmentsPerTrack: 3,
      keyframesPerSegment: 2,
      nestingDepth: 1,
    );
    final second = generateTimelinePageElements(
      trackCount: 2,
      segmentsPerTrack: 3,
      keyframesPerSegment: 2,
      nestingDepth: 1,
    );

    expect(first, second);
    expect(first, hasLength(38));
    final ids = first.map((element) => element.id).toSet();
    final entries = first.whereType<PageElementEntry>().toList();
    expect(entries, hasLength(2));
    for (final entry in entries) {
      final definition = (entry.entry as DefinitionPageEntry).definition;
      expect(definition.placement.kind, EntryPlacementKind.timelineEntry);
      expect(
        entry.entry.links.$2.every((link) => ids.contains(link.otherId)),
        isTrue,
      );
    }
    for (final segment
        in first
            .whereType<PageElementCue>()
            .map((element) => element.cue)
            .whereType<Segment>()) {
      expect(
        segment.outwardLinks.every((link) => ids.contains(link.otherId)),
        isTrue,
      );
    }
  });
}
