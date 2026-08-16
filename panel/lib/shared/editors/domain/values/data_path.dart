import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "data_path.freezed.dart";

@freezed
abstract class DataPath with _$DataPath {
  const factory DataPath(List<DataPathSegment> segments) = _DataPath;

  const DataPath._();

  static const root = DataPath([]);

  DataPath field(String name) =>
      DataPath([...segments, FieldPathSegment(name)]);

  DataPath index(int index) => DataPath([...segments, IndexPathSegment(index)]);

  DataPath mapKey(DataValue key) =>
      DataPath([...segments, MapKeyPathSegment(key)]);

  DataPath followedBy(DataPath suffix) =>
      DataPath([...segments, ...suffix.segments]);

  /// Whether this path equals [ancestor] or points inside it.
  bool isAtOrBelow(DataPath ancestor) {
    if (segments.length < ancestor.segments.length) return false;
    for (var index = 0; index < ancestor.segments.length; index++) {
      if (segments[index] != ancestor.segments[index]) return false;
    }
    return true;
  }

  TypeResult<DataValue> read(DataValue root) {
    var current = root;
    for (final segment in segments) {
      final result = _readSegment(current, segment);
      switch (result) {
        case TypeSuccess(:final value):
          current = value;
        case TypeFailure(:final diagnostics):
          return TypeResult.failure(diagnostics);
      }
    }
    return TypeResult.success(current);
  }

  TypeResult<DataValue> replace(DataValue root, DataValue replacement) =>
      _replace(root, 0, replacement);

  TypeResult<DataValue> _replace(
    DataValue current,
    int offset,
    DataValue replacement,
  ) {
    if (offset == segments.length) return TypeResult.success(replacement);
    if (current case PolymorphicValue(:final concreteType, :final value)) {
      return _replace(value, offset, replacement).map(
        (next) => PolymorphicValue(concreteType: concreteType, value: next),
      );
    }
    final segment = segments[offset];
    if (offset == segments.length - 1) {
      return segment.replace(current, replacement);
    }
    final child = segment.read(current);
    if (child case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final updated = _replace(
      (child as TypeSuccess<DataValue>).value,
      offset + 1,
      replacement,
    );
    if (updated case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return segment.replace(current, (updated as TypeSuccess<DataValue>).value);
  }

  TypeResult<DataValue> _readSegment(
    DataValue current,
    DataPathSegment segment,
  ) => switch (current) {
    PolymorphicValue(:final value) => _readSegment(value, segment),
    _ => segment.read(current),
  };

  @override
  String toString() => segments.isEmpty ? r"$" : r"$" + segments.join();
}

extension _DataPathResultMap on TypeResult<DataValue> {
  TypeResult<DataValue> map(DataValue Function(DataValue value) transform) =>
      switch (this) {
        TypeSuccess(:final value) => TypeResult.success(transform(value)),
        TypeFailure(:final diagnostics) => TypeResult.failure(diagnostics),
      };
}

@Freezed(toStringOverride: false)
sealed class DataPathSegment with _$DataPathSegment {
  const DataPathSegment._();

  @Assert("name != \"\"", "Field name must not be empty.")
  const factory DataPathSegment.field(String name) = FieldPathSegment;

  @Assert("index >= 0", "List index must not be negative.")
  const factory DataPathSegment.index(int index) = IndexPathSegment;

  const factory DataPathSegment.mapKey(DataValue key) = MapKeyPathSegment;

  TypeResult<DataValue> read(DataValue parent) => switch (this) {
    FieldPathSegment(:final name) => parent._readField(name),
    IndexPathSegment(:final index) => parent._readIndex(index),
    MapKeyPathSegment(:final key) => parent._readMapKey(key),
  };

  TypeResult<DataValue> replace(DataValue parent, DataValue value) =>
      switch (this) {
        FieldPathSegment(:final name) => parent._replaceField(name, value),
        IndexPathSegment(:final index) => parent._replaceIndex(index, value),
        MapKeyPathSegment(:final key) => parent._replaceMapKey(key, value),
      };

  TypeResult<DataValue> invalid(String message) => TypeResult.failure([
    TypeDiagnostic(code: TypeDiagnosticCode.invalidPath, message: message),
  ]);

  @override
  String toString() => switch (this) {
    FieldPathSegment(:final name) => ".$name",
    IndexPathSegment(:final index) => "[$index]",
    MapKeyPathSegment(:final key) => "{$key}",
  };
}

extension on DataValue {
  TypeResult<DataValue> _readField(String name) {
    if (this is! RecordValue) return _invalidSegment("Expected a record");
    final value = (this as RecordValue).fields[name];
    if (value == null) return _invalidSegment("Record field '$name' is absent");
    return TypeResult.success(value);
  }

  TypeResult<DataValue> _replaceField(String name, DataValue value) {
    if (this is! RecordValue) return _invalidSegment("Expected a record");
    return TypeResult.success((this as RecordValue).withField(name, value));
  }

  TypeResult<DataValue> _readIndex(int index) {
    if (this is! ListValue) return _invalidSegment("Expected a list");
    final list = this as ListValue;
    if (index >= list.values.length) {
      return _invalidSegment("List index $index is absent");
    }
    return TypeResult.success(list.values[index]);
  }

  TypeResult<DataValue> _replaceIndex(int index, DataValue value) {
    if (this is! ListValue) return _invalidSegment("Expected a list");
    final list = this as ListValue;
    if (index >= list.values.length) {
      return _invalidSegment("List index $index is absent");
    }
    final values = List<DataValue>.of(list.values)..[index] = value;
    return TypeResult.success(ListValue(values));
  }

  TypeResult<DataValue> _readMapKey(DataValue key) {
    if (this is! MapValue) return _invalidSegment("Expected a map");
    final entry = (this as MapValue).entries.firstWhereOrNull(
      (entry) => entry.key == key,
    );
    if (entry == null) return _invalidSegment("Map key is absent");
    return TypeResult.success(entry.value);
  }

  TypeResult<DataValue> _replaceMapKey(DataValue key, DataValue value) {
    if (this is! MapValue) return _invalidSegment("Expected a map");
    final map = this as MapValue;
    final index = map.entries.indexWhere((entry) => entry.key == key);
    if (index < 0) return _invalidSegment("Map key is absent");
    final entries = List<DataMapEntry>.of(map.entries)
      ..[index] = DataMapEntry(key: key, value: value);
    return TypeResult.success(MapValue(entries));
  }
}

TypeFailure<DataValue> _invalidSegment(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidPath, message: message),
]);
