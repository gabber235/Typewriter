part of "page_elements.dart";

enum RelationshipDirection { incoming, outgoing }

/// One exact reference occurrence shown in a grouped relationship list.
@freezed
abstract class RelationshipUsage with _$RelationshipUsage {
  const factory RelationshipUsage({
    required String sourceId,
    required String targetId,
    required String slot,
    required DataPath? sourcePath,
  }) = _RelationshipUsage;

  const RelationshipUsage._();

  String get id => "$sourceId:$slot";
}

/// Occurrences grouped by the related resource without losing slot identity.
@freezed
abstract class RelationshipGroup with _$RelationshipGroup {
  const factory RelationshipGroup({
    required String resourceId,
    required String name,
    required String? pageId,
    required List<RelationshipUsage> usages,
  }) = _RelationshipGroup;
}

/// Incoming and outgoing occurrence groups for one local entry.
@freezed
abstract class EntryRelationships with _$EntryRelationships {
  const factory EntryRelationships({
    required List<RelationshipGroup> incoming,
    required List<RelationshipGroup> outgoing,
  }) = _EntryRelationships;
}

extension PageElementRelationshipProjection on List<PageElement> {
  EntryRelationships relationshipsFor(String entryId) {
    final entries = <String, PageEntry>{
      for (final element in this)
        if (element case PageElementEntry(:final entry)) entry.id: entry,
    };
    final entry = entries[entryId];
    if (entry == null) {
      return const EntryRelationships(incoming: [], outgoing: []);
    }
    final (inward, outward) = entry.links;

    ({String name, String? pageId}) relatedResource(String relatedId) {
      final related = entries[relatedId];
      return (
        name: switch (related) {
          DefinitionPageEntry(:final definition) => definition.name,
          ReferencePageEntry(:final name) => name,
          UnavailableReferencePageEntry(:final name) => name,
          MissingElementDefinitionPageEntry(:final name) => name,
          _ => relatedId,
        },
        pageId: switch (related) {
          ReferencePageEntry(:final pageId) => pageId,
          _ => null,
        },
      );
    }

    final incomingBySource = <String, List<ElementLink>>{};
    for (final link in inward) {
      incomingBySource.putIfAbsent(link.otherId, () => []).add(link);
    }
    final outgoingByTarget = <String, List<ElementLink>>{};
    for (final link in outward) {
      outgoingByTarget.putIfAbsent(link.otherId, () => []).add(link);
    }

    final incomingKeys = incomingBySource.keys.toList()..sort();
    final outgoingKeys = outgoingByTarget.keys.toList()..sort();
    return EntryRelationships(
      incoming: [
        for (final key in incomingKeys)
          RelationshipGroup(
            resourceId: key,
            name: relatedResource(key).name,
            pageId: relatedResource(key).pageId,
            usages: [
              for (final link in incomingBySource[key]!..sort(_compareLinks))
                RelationshipUsage(
                  sourceId: link.otherId,
                  targetId: entryId,
                  slot: link.path,
                  sourcePath: link.sourcePath,
                ),
            ],
          ),
      ],
      outgoing: [
        for (final key in outgoingKeys)
          RelationshipGroup(
            resourceId: key,
            name: relatedResource(key).name,
            pageId: relatedResource(key).pageId,
            usages: [
              for (final link in outgoingByTarget[key]!..sort(_compareLinks))
                RelationshipUsage(
                  sourceId: entryId,
                  targetId: link.otherId,
                  slot: link.path,
                  sourcePath: link.sourcePath,
                ),
            ],
          ),
      ],
    );
  }
}

int _compareLinks(ElementLink left, ElementLink right) =>
    left.path.compareTo(right.path);

/// Owns foreign node geometry for one mounted page graph.
///
/// Logical side and position survive relationship refreshes. Local entry
/// rectangles remain fixed obstacles. Direction changes retain the logical
/// side and revalidate its physical region.
final class RemoteGraphPlacementSession {
  RemoteGraphPlacementSession({
    this.placeholderWidth = 4,
    this.placeholderHeight = 1,
  });

  final int placeholderWidth;
  final int placeholderHeight;
  final GraphIncrementalPlacer _placer = const GraphIncrementalPlacer();
  final Map<String, _RemotePlacement> _placements = {};

  Map<String, GraphGridRect> place({
    required List<PageElement> elements,
    required GraphDirection direction,
    required Offset emptyGraphAnchor,
  }) {
    final local = <String, GraphGridRect>{};
    final remote = <String, PageEntry>{};
    for (final element in elements) {
      if (element case PageElementEntry(:final entry)) {
        switch (entry) {
          case DefinitionPageEntry(:final definition)
              when definition.placement.kind == EntryPlacementKind.graph:
            local[entry.id] = GraphGridRect(
              x: definition.placement.x,
              y: definition.placement.y,
              width: definition.placement.width,
              height: definition.placement.height,
            );
          case MissingElementDefinitionPageEntry(:final placement)
              when placement.kind == EntryPlacementKind.graph:
            local[entry.id] = GraphGridRect(
              x: placement.x,
              y: placement.y,
              width: placement.width,
              height: placement.height,
            );
          case ReferencePageEntry() ||
              UnavailableReferencePageEntry() ||
              NonexistentPageEntry():
            remote[entry.id] = entry;
          default:
        }
      }
    }
    _placements.removeWhere((id, _) => !remote.containsKey(id));

    final counts = {
      for (final id in remote.keys) id: (incoming: 0, outgoing: 0),
    };
    for (final element in elements) {
      if (element case PageElementEntry(:final entry)) {
        final (inward, outward) = entry.links;
        for (final link in inward) {
          if (remote.containsKey(link.otherId)) {
            final count = counts[link.otherId]!;
            counts[link.otherId] = (
              incoming: count.incoming + 1,
              outgoing: count.outgoing,
            );
          }
        }
        for (final link in outward) {
          if (remote.containsKey(link.otherId)) {
            final count = counts[link.otherId]!;
            counts[link.otherId] = (
              incoming: count.incoming,
              outgoing: count.outgoing + 1,
            );
          }
        }
      }
    }

    final localBounds = local.values.graphBounds;
    final obstacles = [...local.values];
    final pending = remote.keys.toSet();
    for (final item in _placements.entries.toList(growable: false)) {
      final region = _region(
        direction,
        item.value.side,
        localBounds,
        emptyGraphAnchor,
      );
      final remainsValid =
          region.allows(item.value.rect) &&
          obstacles.every(
            (obstacle) => !item.value.rect.overlaps(obstacle, gap: _placer.gap),
          );
      if (!remainsValid) continue;
      obstacles.add(item.value.rect);
      pending.remove(item.key);
    }

    for (final id in pending.toList()..sort()) {
      final previous = _placements[id];
      final count = counts[id]!;
      final side =
          previous?.side ??
          (count.incoming > count.outgoing
              ? RelationshipDirection.incoming
              : RelationshipDirection.outgoing);
      final region = _region(direction, side, localBounds, emptyGraphAnchor);
      final preferredAnchor =
          previous?.rect.center ??
          _preferredAnchor(direction, side, localBounds, emptyGraphAnchor);
      final rect = _placer
          .placeGroup(
            obstacles: obstacles,
            group: [
              GraphGridRect(
                x: 0,
                y: 0,
                width: placeholderWidth,
                height: placeholderHeight,
              ),
            ],
            anchor: preferredAnchor,
            allowedRegion: region,
          )
          .single;
      _placements[id] = _RemotePlacement(side: side, rect: rect);
      obstacles.add(rect);
    }
    return Map.unmodifiable({
      for (final item in _placements.entries) item.key: item.value.rect,
    });
  }
}

final class _RemotePlacement {
  const _RemotePlacement({required this.side, required this.rect});

  final RelationshipDirection side;
  final GraphGridRect rect;
}

GraphPlacementRegion _region(
  GraphDirection direction,
  RelationshipDirection side,
  GraphGridRect? bounds,
  Offset anchor,
) {
  final left = bounds?.x ?? anchor.dx.floor();
  final right = bounds?.right ?? anchor.dx.ceil();
  final top = bounds?.y ?? anchor.dy.floor();
  final bottom = bounds?.bottom ?? anchor.dy.ceil();
  return switch ((direction, side)) {
    (GraphDirection.leftToRight, RelationshipDirection.incoming) =>
      GraphPlacementRegion.leftOf(left),
    (GraphDirection.leftToRight, RelationshipDirection.outgoing) =>
      GraphPlacementRegion.rightOf(right),
    (GraphDirection.rightToLeft, RelationshipDirection.incoming) =>
      GraphPlacementRegion.rightOf(right),
    (GraphDirection.rightToLeft, RelationshipDirection.outgoing) =>
      GraphPlacementRegion.leftOf(left),
    (GraphDirection.topToBottom, RelationshipDirection.incoming) =>
      GraphPlacementRegion.above(top),
    (GraphDirection.topToBottom, RelationshipDirection.outgoing) =>
      GraphPlacementRegion.below(bottom),
    (GraphDirection.bottomToTop, RelationshipDirection.incoming) =>
      GraphPlacementRegion.below(bottom),
    (GraphDirection.bottomToTop, RelationshipDirection.outgoing) =>
      GraphPlacementRegion.above(top),
  };
}

Offset _preferredAnchor(
  GraphDirection direction,
  RelationshipDirection side,
  GraphGridRect? bounds,
  Offset fallback,
) {
  final center = bounds?.center ?? fallback;
  final left = bounds?.x.toDouble() ?? fallback.dx;
  final right = bounds?.right.toDouble() ?? fallback.dx;
  final top = bounds?.y.toDouble() ?? fallback.dy;
  final bottom = bounds?.bottom.toDouble() ?? fallback.dy;
  return switch ((direction, side)) {
    (GraphDirection.leftToRight, RelationshipDirection.incoming) => Offset(
      left - 2,
      center.dy,
    ),
    (GraphDirection.leftToRight, RelationshipDirection.outgoing) => Offset(
      right + 2,
      center.dy,
    ),
    (GraphDirection.rightToLeft, RelationshipDirection.incoming) => Offset(
      right + 2,
      center.dy,
    ),
    (GraphDirection.rightToLeft, RelationshipDirection.outgoing) => Offset(
      left - 2,
      center.dy,
    ),
    (GraphDirection.topToBottom, RelationshipDirection.incoming) => Offset(
      center.dx,
      top - 0.5,
    ),
    (GraphDirection.topToBottom, RelationshipDirection.outgoing) => Offset(
      center.dx,
      bottom + 0.5,
    ),
    (GraphDirection.bottomToTop, RelationshipDirection.incoming) => Offset(
      center.dx,
      bottom + 0.5,
    ),
    (GraphDirection.bottomToTop, RelationshipDirection.outgoing) => Offset(
      center.dx,
      top - 0.5,
    ),
  };
}
