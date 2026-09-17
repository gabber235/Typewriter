import "dart:math" as math;

import "package:typewriter_panel/typewriter_panel.dart";

const _entriesPerLayer = 4;
const _mainAxisSpacing = 2;
const _crossAxisSpacing = 1;

/// Positions graph fixture entries in deterministic layers and links each
/// layer to the next one.
List<EntryDefinition> layoutGraphEntries(
  List<EntryDefinition> entries, {
  required GraphDirection direction,
}) {
  if (entries.isEmpty) return const [];

  final layers = <List<EntryDefinition>>[
    for (var index = 0; index < entries.length; index += _entriesPerLayer)
      entries.sublist(
        index,
        math.min(index + _entriesPerLayer, entries.length),
      ),
  ];
  final positionedLayers = <List<EntryDefinition>>[];
  final layerMainSize = entries
      .map(
        (entry) => direction.main(
          math.max(1, entry.placement.width),
          math.max(1, entry.placement.height),
        ),
      )
      .reduce(math.max);

  for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
    final layer = layers[layerIndex];
    final mainIndex = switch (direction) {
      GraphDirection.leftToRight || GraphDirection.topToBottom => layerIndex,
      GraphDirection.rightToLeft ||
      GraphDirection.bottomToTop => layers.length - layerIndex - 1,
    };
    final main = mainIndex * (layerMainSize + _mainAxisSpacing);
    var cross = 0;
    final positioned = <EntryDefinition>[];

    for (final entry in layer) {
      final width = math.max(1, entry.placement.width);
      final height = math.max(1, entry.placement.height);
      positioned.add(
        entry.copyWith(
          placement: EntryPlacement(
            x: direction.main(main, cross),
            y: direction.cross(main, cross),
            width: width,
            height: height,
          ),
        ),
      );
      cross += direction.cross(width, height) + _crossAxisSpacing;
    }
    positionedLayers.add(positioned);
  }

  final outward = <String, List<ElementLink>>{};
  final inward = <String, List<ElementLink>>{};
  for (
    var layerIndex = 0;
    layerIndex < positionedLayers.length - 1;
    layerIndex++
  ) {
    final sources = positionedLayers[layerIndex];
    final targets = positionedLayers[layerIndex + 1];
    for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
      final source = sources[sourceIndex];
      final target = targets[math.min(sourceIndex, targets.length - 1)];
      final linkId = "${source.id}->${target.id}";
      outward
          .putIfAbsent(source.id, () => [])
          .add(
            ElementLink(
              linkId: linkId,
              otherId: target.id,
              path: "connections",
            ),
          );
      inward
          .putIfAbsent(target.id, () => [])
          .add(
            ElementLink(
              linkId: linkId,
              otherId: source.id,
              path: "connections",
            ),
          );
    }
  }

  return [
    for (final entry in positionedLayers.expand((layer) => layer))
      entry.copyWith(
        outwardEdges: outward[entry.id] ?? const [],
        inwardEdges: inward[entry.id] ?? const [],
      ),
  ];
}

List<EntryDefinition> generateDynamicGraphLayout(
  List<EntryDefinition> entries,
  GraphDirection? direction,
) => layoutGraphEntries(
  entries,
  direction: direction ?? GraphDirection.leftToRight,
);
