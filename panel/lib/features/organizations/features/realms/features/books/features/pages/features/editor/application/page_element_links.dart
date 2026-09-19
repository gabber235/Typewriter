part of "page_elements.dart";

/// Rebuilds display links from the values currently projected for this page.
///
/// Reference slots belong to persisted storage. Display links instead use the
/// concrete value path, so a local draft and its later canonical refresh
/// produce the same topology without a second optimistic state owner.
extension PageElementLinkProjection on List<PageElement> {
  List<PageElement> projectLinks() {
    final references = [
      for (final element in this) ...element._referenceOccurrences,
    ];
    final inward = <String, List<ElementLink>>{};
    final outward = <String, List<ElementLink>>{};

    for (final reference in references) {
      final path = reference.path.segments.join();
      final link = ElementLink(
        linkId: "${reference.sourceId}:$path",
        otherId: reference.targetId,
        path: path,
      );
      outward.putIfAbsent(reference.sourceId, () => []).add(link);
      inward
          .putIfAbsent(reference.targetId, () => [])
          .add(link.copyWith(otherId: reference.sourceId));
    }

    return [
      for (final element in this)
        element._withProjectedLinks(
          inward[element.id] ?? const [],
          outward[element.id] ?? const [],
        ),
    ];
  }
}

extension on PageElement {
  Iterable<_PageReferenceOccurrence> get _referenceOccurrences sync* {
    final source = switch (this) {
      PageElementEntry(entry: DefinitionPageEntry(:final definition)) => (
        definition.id,
        definition.data,
      ),
      PageElementCue(cue: Segment(:final id, :final data)) => (id, data),
      _ => null,
    };
    if (source == null) return;

    for (final reference in source.$2._referenceOccurrences(DataPath.root)) {
      yield _PageReferenceOccurrence(
        sourceId: source.$1,
        targetId: reference.targetId,
        path: reference.path,
      );
    }
  }

  PageElement _withProjectedLinks(
    List<ElementLink> inward,
    List<ElementLink> outward,
  ) => switch (this) {
    PageElementEntry(:final entry) => PageElement.entry(
      entry: switch (entry) {
        DefinitionPageEntry(:final definition) => PageEntry.definition(
          definition: definition.copyWith(
            inwardEdges: [...definition.inwardEdges.structural, ...inward],
            outwardEdges: [...definition.outwardEdges.structural, ...outward],
          ),
        ),
        MissingElementDefinitionPageEntry() => entry.copyWith(
          inwardLinks: [...entry.inwardLinks.structural, ...inward],
        ),
        _ => entry,
      },
    ),
    PageElementCue(:final cue) => PageElement.cue(
      cue: switch (cue) {
        Segment() => cue.copyWith(
          inwardLinks: [...cue.inwardLinks.structural, ...inward],
          outwardLinks: [...cue.outwardLinks.structural, ...outward],
        ),
        Keyframe() => cue.copyWith(
          inwardLinks: [...cue.inwardLinks.structural, ...inward],
        ),
        _ => cue,
      },
    ),
    _ => this,
  };
}

extension on List<ElementLink> {
  /// Persisted structural links use named slots such as `children` and
  /// `parent`. Projected value references use canonical record paths, which
  /// always start with a field segment because page element values are records.
  Iterable<ElementLink> get structural =>
      where((link) => !link.path.startsWith("."));
}

extension on DataValue {
  Iterable<({DataPath path, String targetId})> _referenceOccurrences(
    DataPath path,
  ) sync* {
    switch (this) {
      case ReferenceValue(:final id):
        yield (path: path, targetId: id.id);
      case RecordValue(:final fields):
        for (final field in fields.entries) {
          yield* field.value._referenceOccurrences(path.field(field.key));
        }
      case ListValue(:final values):
        for (final entry in values.indexed) {
          yield* entry.$2._referenceOccurrences(path.index(entry.$1));
        }
      case MapValue(:final entries):
        for (final entry in entries) {
          yield* entry.value._referenceOccurrences(path.mapKey(entry.key));
        }
      case PolymorphicValue(:final value):
        yield* value._referenceOccurrences(path);
      default:
        return;
    }
  }
}

final class _PageReferenceOccurrence {
  const _PageReferenceOccurrence({
    required this.sourceId,
    required this.targetId,
    required this.path,
  });

  final String sourceId;
  final String targetId;
  final DataPath path;
}
