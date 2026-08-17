part of "../../data_renderer.dart";

final class _GraphOccurrencePath {
  _GraphOccurrencePath(Iterable<DataValue> values)
    : values = List.unmodifiable(values);

  final List<DataValue> values;

  @override
  bool operator ==(Object other) {
    if (other is! _GraphOccurrencePath ||
        other.values.length != values.length) {
      return false;
    }
    for (var index = 0; index < values.length; index++) {
      if (other.values[index] != values[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(values);
}

final class _GraphOccurrenceIdentity {
  _GraphOccurrenceIdentity({
    required this.sourceId,
    required this.relation,
    required List<DataValue> path,
  }) : path = List.unmodifiable(path);

  final PresentationCollectionSourceId sourceId;
  final PresentationCollectionRelationId relation;
  final List<DataValue> path;

  @override
  bool operator ==(Object other) {
    if (other is! _GraphOccurrenceIdentity ||
        other.sourceId != sourceId ||
        other.relation != relation ||
        other.path.length != path.length) {
      return false;
    }
    for (var index = 0; index < path.length; index++) {
      if (other.path[index] != path[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(sourceId, relation, Object.hashAll(path));
}
