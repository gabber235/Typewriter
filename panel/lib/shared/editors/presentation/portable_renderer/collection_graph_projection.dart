part of "../portable_presentation_renderer.dart";

@freezed
abstract class _CollectionGraphOccurrence with _$CollectionGraphOccurrence {
  const factory _CollectionGraphOccurrence({
    required String canonicalKey,
    required List<String> path,
    required List<_CollectionGraphOccurrence> children,
  }) = __CollectionGraphOccurrence;
}

@freezed
abstract class _CollectionGraphProjection with _$CollectionGraphProjection {
  const factory _CollectionGraphProjection({
    required List<_CollectionGraphOccurrence> roots,
    required bool truncated,
  }) = __CollectionGraphProjection;
}

@freezed
abstract class _CollectionGraphOccurrenceKey
    with _$CollectionGraphOccurrenceKey {
  const factory _CollectionGraphOccurrenceKey({
    required Object graph,
    required Map<skir.ExpressionBindingId, Object> invocation,
    required List<String> path,
  }) = __CollectionGraphOccurrenceKey;
}

/// Projects view occurrences independently of widget construction and disclosure.
/// Canonical keys identify resources; paths identify their separate appearances.
_CollectionGraphProjection _projectCollectionGraph({
  required Iterable<String> roots,
  required Map<String, List<String>> adjacency,
  required Set<String> availableKeys,
  required int maximumDepth,
  required int maximumOccurrences,
}) {
  var remaining = max(0, maximumOccurrences);
  var truncated = false;

  _CollectionGraphOccurrence? project(String root) {
    if (!availableKeys.contains(root)) return null;
    if (remaining == 0) {
      truncated = true;
      return null;
    }
    remaining--;
    final stack = [
      _CollectionGraphProjectionFrame(root, [root], {root}, 0),
    ];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      final targets = frame.targets ??=
          (frame.depth < maximumDepth
                  ? (adjacency[frame.key] ?? const <String>[]).toSet()
                  : const <String>{})
              .iterator;
      if (!truncated && targets.moveNext()) {
        final key = targets.current;
        if (!availableKeys.contains(key) || frame.ancestors.contains(key)) {
          continue;
        }
        if (remaining == 0) {
          truncated = true;
          continue;
        }
        remaining--;
        stack.add(
          _CollectionGraphProjectionFrame(
            key,
            [...frame.path, key],
            {...frame.ancestors, key},
            frame.depth + 1,
          ),
        );
        continue;
      }
      final occurrence = _CollectionGraphOccurrence(
        canonicalKey: frame.key,
        path: frame.path,
        children: List.unmodifiable(frame.children),
      );
      stack.removeLast();
      if (stack.isEmpty) return occurrence;
      stack.last.children.add(occurrence);
    }
    return null;
  }

  final occurrences = <_CollectionGraphOccurrence>[];
  for (final root in roots.toSet()) {
    final occurrence = project(root);
    if (occurrence != null) occurrences.add(occurrence);
    if (truncated) break;
  }
  return _CollectionGraphProjection(roots: occurrences, truncated: truncated);
}

/// Mutable work belongs to one projection call and never reaches widget builders.
final class _CollectionGraphProjectionFrame {
  _CollectionGraphProjectionFrame(
    this.key,
    this.path,
    this.ancestors,
    this.depth,
  );

  final String key;
  final List<String> path;
  final Set<String> ancestors;
  final int depth;
  final children = <_CollectionGraphOccurrence>[];
  Iterator<String>? targets;
}
