import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A Book a fixture document starts with. Seeds describe fixture content; the
/// panel reads it back through the working document like any resource.
final class Book {
  const Book({
    required this.bookId,
    required this.title,
    required this.icon,
    required this.color,
    this.tagIds = const [],
  });

  final skir.ResourceId bookId;
  final String title;
  final String icon;
  final Color color;
  final List<skir.ResourceId> tagIds;

  Book copyWith({
    skir.ResourceId? bookId,
    String? title,
    String? icon,
    Color? color,
    List<skir.ResourceId>? tagIds,
  }) => Book(
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    tagIds: tagIds ?? this.tagIds,
  );
}

/// A Tag a fixture document starts with, placed on the tag graph.
final class Tag {
  const Tag({
    required this.tagId,
    required this.name,
    required this.color,
    this.parentIds = const [],
    this.placement = const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
  });

  final skir.ResourceId tagId;
  final String name;
  final Color color;
  final List<skir.ResourceId> parentIds;
  final GraphPlacement placement;

  Tag copyWith({
    skir.ResourceId? tagId,
    String? name,
    Color? color,
    List<skir.ResourceId>? parentIds,
    GraphPlacement? placement,
  }) => Tag(
    tagId: tagId ?? this.tagId,
    name: name ?? this.name,
    color: color ?? this.color,
    parentIds: parentIds ?? this.parentIds,
    placement: placement ?? this.placement,
  );
}

/// A page a fixture document starts with, owned by [bookId] when present.
final class Page {
  const Page({
    required this.pageId,
    required this.name,
    this.bookId,
    this.chapter = "",
    this.priority = 0,
  });

  final skir.ResourceId pageId;
  final skir.ResourceId? bookId;
  final String name;
  final String chapter;
  final int priority;

  Page copyWith({
    skir.ResourceId? pageId,
    skir.ResourceId? bookId,
    String? name,
    String? chapter,
    int? priority,
  }) => Page(
    pageId: pageId ?? this.pageId,
    bookId: bookId ?? this.bookId,
    name: name ?? this.name,
    chapter: chapter ?? this.chapter,
    priority: priority ?? this.priority,
  );
}

/// A scene a fixture document starts with: a section of the realm whose
/// workspace lays its [tracks] out on a timeline.
final class Scene {
  const Scene({
    required this.sceneId,
    required this.name,
    this.tracks = const [],
  });

  final skir.ResourceId sceneId;
  final String name;
  final List<Track> tracks;
}

/// One track of a [Scene], owning the [cues] the timeline shows on its row.
final class Track {
  const Track({
    required this.trackId,
    required this.name,
    this.cues = const [],
  });

  final skir.ResourceId trackId;
  final String name;
  final List<Cue> cues;
}

/// A cue placed on a [Track] from [startFrame] to [endFrame].
final class Cue {
  const Cue({
    required this.cueId,
    required this.name,
    required this.startFrame,
    required this.endFrame,
  });

  final skir.ResourceId cueId;
  final String name;
  final int startFrame;
  final int endFrame;
}
