import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as skir;

sealed class PortablePathResult<T> {
  const PortablePathResult();
}

final class PortablePathValue<T> extends PortablePathResult<T> {
  const PortablePathValue(this.value);

  final T value;
}

final class PortablePathUnavailable<T> extends PortablePathResult<T> {
  const PortablePathUnavailable(this.message);

  final String message;
}

extension PortableValueTree on skir.DataValue {
  skir.DataValue get authoredPayload {
    var current = this;
    while (current is skir.DataValue_namedWrapper) {
      current = current.value.payload;
    }
    return current;
  }

  skir.NamedTypeUse? get authoredActualType => switch (this) {
    skir.DataValue_namedWrapper(:final value) => value.actualType,
    _ => null,
  };

  skir.DataValue withAuthoredPayload(skir.DataValue payload) {
    if (this case skir.DataValue_namedWrapper(:final value)) {
      return skir.DataValue.createNamed(
        actualType: value.actualType,
        payload: value.payload.withAuthoredPayload(payload),
      );
    }
    return payload;
  }

  String? get authoredString => switch (authoredPayload) {
    skir.DataValue_stringValueWrapper(:final value) => value,
    _ => null,
  };

  BigInt? get authoredInteger => switch (authoredPayload) {
    skir.DataValue_integerWrapper(:final value) => BigInt.tryParse(value),
    _ => null,
  };

  skir.RecordPayload? get authoredRecord => switch (authoredPayload) {
    skir.DataValue_recordWrapper(:final value) => value,
    _ => null,
  };

  Iterable<skir.ListItem>? get authoredItems => switch (authoredPayload) {
    skir.DataValue_listValueWrapper(:final value) => value.items,
    skir.DataValue_setValueWrapper(:final value) => value.items,
    _ => null,
  };

  skir.LinkValue? get authoredLink => switch (authoredPayload) {
    skir.DataValue_linkWrapper(:final value) => value,
    _ => null,
  };

  skir.DataValue? authoredField(String name) {
    final record = authoredRecord;
    if (record == null) return null;
    return record.fields
        .where((field) => field.name == name)
        .firstOrNull
        ?.value;
  }

  PortablePathResult<skir.DataValue> readAt(skir.ValuePath path) {
    Object current = this;
    for (final segment in path.segments) {
      final unwrapped = _unwrapForPath(current);
      if (unwrapped case PortablePathUnavailable<Object>()) {
        return PortablePathUnavailable(unwrapped.message);
      }
      current = (unwrapped as PortablePathValue<Object>).value;
      final next = _readSegment(current, segment);
      if (next case PortablePathUnavailable<Object>()) {
        return PortablePathUnavailable(next.message);
      }
      current = (next as PortablePathValue<Object>).value;
    }
    if (current is skir.DataValue) return PortablePathValue(current);
    return const PortablePathUnavailable("The path ends at a map row");
  }

  PortablePathResult<skir.DataValue> replaceAt(
    skir.ValuePath path,
    skir.DataValue replacement,
  ) => _replaceValue(this, path.segments.toList(), 0, replacement);
}

extension PortableRecordTree on skir.AuthoringRecord {
  skir.DataValue? authoredField(String name) =>
      fields.where((field) => field.name == name).firstOrNull?.value;

  PortablePathResult<skir.DataValue> readAt(skir.ValuePath path) {
    final segments = path.segments.toList(growable: false);
    if (segments.isEmpty) {
      return const PortablePathUnavailable("A record path requires a field");
    }
    final first = segments.first;
    final fieldName = switch (first) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (fieldName == null) {
      return const PortablePathUnavailable(
        "A record path must begin with a field",
      );
    }
    final field = fields.where((field) => field.name == fieldName).firstOrNull;
    if (field == null) {
      return PortablePathUnavailable("The record field $fieldName is absent");
    }
    if (segments.length == 1) return PortablePathValue(field.value);
    return field.value.readAt(skir.ValuePath(segments: segments.skip(1)));
  }

  PortablePathResult<skir.AuthoringRecord> replaceAt(
    skir.ValuePath path,
    skir.DataValue replacement,
  ) {
    final segments = path.segments.toList(growable: false);
    if (segments.isEmpty) {
      return const PortablePathUnavailable("A record path requires a field");
    }
    final first = segments.first;
    final fieldName = switch (first) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (fieldName == null) {
      return const PortablePathUnavailable(
        "A record path must begin with a field",
      );
    }
    final current = fields.toList(growable: false);
    final index = current.indexWhere((field) => field.name == fieldName);
    if (segments.length == 1) {
      final updated = skir.FieldValue(name: fieldName, value: replacement);
      return PortablePathValue(
        skir.AuthoringRecord(
          configuration: configuration,
          fields: index < 0
              ? [...current, updated]
              : List.generate(
                  current.length,
                  (fieldIndex) =>
                      fieldIndex == index ? updated : current[fieldIndex],
                ),
        ),
      );
    }
    if (index < 0) {
      return PortablePathUnavailable(
        "The parent field $fieldName needs initialization",
      );
    }
    final nested = current[index].value.replaceAt(
      skir.ValuePath(segments: segments.skip(1)),
      replacement,
    );
    return switch (nested) {
      PortablePathValue(:final value) => PortablePathValue(
        skir.AuthoringRecord(
          configuration: configuration,
          fields: List.generate(
            current.length,
            (fieldIndex) => fieldIndex == index
                ? skir.FieldValue(name: current[fieldIndex].name, value: value)
                : current[fieldIndex],
          ),
        ),
      ),
      PortablePathUnavailable(:final message) => PortablePathUnavailable(
        message,
      ),
    };
  }

  PortablePathResult<List<skir.ValuePath>> duplicateCollectionRows() {
    final duplicates = <skir.ValuePath>[];
    for (final field in fields) {
      final result = field.value.duplicateCollectionRows(
        skir.ValuePath(
          segments: [skir.PathSegment.createField(name: field.name)],
        ),
      );
      switch (result) {
        case PortablePathValue(:final value):
          duplicates.addAll(value);
        case PortablePathUnavailable(:final message):
          return PortablePathUnavailable(message);
      }
    }
    return PortablePathValue(duplicates);
  }
}

Iterable<skir.ValuePath> expandAuthoredPattern(
  skir.AuthoringRecord record,
  skir.RelativeFieldPattern pattern,
) sync* {
  final segments = pattern.segments.toList(growable: false);

  Iterable<skir.ValuePath> expand(skir.ValuePath path, int index) sync* {
    if (index == segments.length) {
      yield path;
      return;
    }
    final segment = segments[index];
    switch (segment) {
      case skir.FieldPatternSegment_fieldWrapper(:final value):
        final next = skir.ValuePath(
          segments: [
            ...path.segments,
            skir.PathSegment.createField(name: value.name),
          ],
        );
        if (record.readAt(next) is PortablePathValue<skir.DataValue>) {
          yield* expand(next, index + 1);
        }
      case final value when value == skir.FieldPatternSegment.items:
        final collection = switch (record.readAt(path)) {
          PortablePathValue(value: final value) => value.authoredItems,
          PortablePathUnavailable() => null,
        };
        for (final item in collection ?? const <skir.ListItem>[]) {
          yield* expand(
            skir.ValuePath(
              segments: [
                ...path.segments,
                skir.PathSegment.createItem(id: item.id),
              ],
            ),
            index + 1,
          );
        }
      case final branch
          when branch == skir.FieldPatternSegment.keys ||
              branch == skir.FieldPatternSegment.values:
        final payload = switch (record.readAt(path)) {
          PortablePathValue(value: final value) => value.authoredPayload,
          PortablePathUnavailable() => null,
        };
        if (payload case skir.DataValue_mapValueWrapper(:final value)) {
          for (final row in value.rows) {
            yield* expand(
              skir.ValuePath(
                segments: [
                  ...path.segments,
                  skir.PathSegment.createItem(id: row.id),
                  if (branch == skir.FieldPatternSegment.keys)
                    skir.PathSegment.mapKey,
                  if (branch == skir.FieldPatternSegment.values)
                    skir.PathSegment.mapValue,
                ],
              ),
              index + 1,
            );
          }
        }
      default:
    }
  }

  yield* expand(skir.ValuePath(segments: const []), 0);
}

bool authoredPathStartsWith(skir.ValuePath path, skir.ValuePath prefix) {
  final value = path.segments.toList(growable: false);
  final expected = prefix.segments.toList(growable: false);
  if (expected.length > value.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (value[index] != expected[index]) return false;
  }
  return true;
}

PortablePathResult<Object> _unwrapForPath(Object value) {
  var current = value;
  var depth = 0;
  while (current is skir.DataValue_namedWrapper) {
    depth++;
    if (depth > _maximumAuthoredValueDepth) {
      return const PortablePathUnavailable(
        "The authored value exceeded its depth limit",
      );
    }
    current = current.value.payload;
  }
  return PortablePathValue(current);
}

PortablePathResult<Object> _readSegment(
  Object current,
  skir.PathSegment segment,
) => switch (segment) {
  skir.PathSegment_fieldWrapper(:final value) => _readField(
    current,
    value.name,
  ),
  skir.PathSegment_itemWrapper(:final value) => _readItem(current, value.id),
  _ when segment == skir.PathSegment.mapKey =>
    current is skir.MapRow
        ? PortablePathValue(current.key)
        : const PortablePathUnavailable("A map key requires a map row"),
  _ when segment == skir.PathSegment.mapValue =>
    current is skir.MapRow
        ? PortablePathValue(current.value)
        : const PortablePathUnavailable("A map value requires a map row"),
  _ => const PortablePathUnavailable("The path contains an unknown segment"),
};

PortablePathResult<Object> _readField(Object current, String name) {
  if (current case skir.DataValue_recordWrapper(:final value)) {
    for (final field in value.fields) {
      if (field.name == name) return PortablePathValue(field.value);
    }
    return PortablePathUnavailable("The record field $name is absent");
  }
  return const PortablePathUnavailable("A field requires a record value");
}

PortablePathResult<Object> _readItem(Object current, skir.ItemId id) {
  final items = switch (current) {
    skir.DataValue_listValueWrapper(:final value) => value.items,
    skir.DataValue_setValueWrapper(:final value) => value.items,
    _ => null,
  };
  if (items != null) {
    for (final item in items) {
      if (item.id == id) return PortablePathValue(item.value);
    }
    return PortablePathUnavailable("The collection item ${id.value} is absent");
  }
  if (current case skir.DataValue_mapValueWrapper(:final value)) {
    for (final row in value.rows) {
      if (row.id == id) return PortablePathValue(row);
    }
    return PortablePathUnavailable("The map row ${id.value} is absent");
  }
  return const PortablePathUnavailable("An item requires a collection value");
}

PortablePathResult<skir.DataValue> _replaceValue(
  skir.DataValue current,
  List<skir.PathSegment> segments,
  int offset,
  skir.DataValue replacement,
) {
  if (offset > _maximumAuthoredValueDepth) {
    return const PortablePathUnavailable(
      "The authored value exceeded its depth limit",
    );
  }
  if (offset == segments.length) return PortablePathValue(replacement);
  if (current is skir.DataValue_namedWrapper) {
    final wrappers = <skir.NamedTypeUse>[];
    skir.DataValue payload = current;
    while (payload is skir.DataValue_namedWrapper) {
      if (wrappers.length >= _maximumAuthoredValueDepth) {
        return const PortablePathUnavailable(
          "The authored value exceeded its depth limit",
        );
      }
      wrappers.add(payload.value.actualType);
      payload = payload.value.payload;
    }
    final nested = _replaceValue(payload, segments, offset, replacement);
    if (nested case PortablePathUnavailable(:final message)) {
      return PortablePathUnavailable(message);
    }
    var rebuilt = (nested as PortablePathValue<skir.DataValue>).value;
    for (final actualType in wrappers.reversed) {
      rebuilt = skir.DataValue.createNamed(
        actualType: actualType,
        payload: rebuilt,
      );
    }
    return PortablePathValue(rebuilt);
  }
  final segment = segments[offset];
  return switch (segment) {
    skir.PathSegment_fieldWrapper(:final value) => _replaceField(
      current,
      value.name,
      segments,
      offset,
      replacement,
    ),
    skir.PathSegment_itemWrapper(:final value) => _replaceItem(
      current,
      value.id,
      segments,
      offset,
      replacement,
    ),
    _ => const PortablePathUnavailable(
      "A map key or value must follow a map row item",
    ),
  };
}

const _maximumAuthoredValueDepth = 512;

PortablePathResult<skir.DataValue> _replaceField(
  skir.DataValue current,
  String name,
  List<skir.PathSegment> segments,
  int offset,
  skir.DataValue replacement,
) {
  if (current case skir.DataValue_recordWrapper(:final value)) {
    final fields = value.fields.toList();
    final index = fields.indexWhere((field) => field.name == name);
    if (index < 0) {
      return PortablePathUnavailable("The record field $name is absent");
    }
    final nested = _replaceValue(
      fields[index].value,
      segments,
      offset + 1,
      replacement,
    );
    return switch (nested) {
      PortablePathValue(:final value) => PortablePathValue(
        skir.DataValue.createRecord(
          fields: List.generate(
            fields.length,
            (fieldIndex) => fieldIndex == index
                ? skir.FieldValue(name: name, value: value)
                : fields[fieldIndex],
          ),
        ),
      ),
      PortablePathUnavailable(:final message) => PortablePathUnavailable(
        message,
      ),
    };
  } else {
    return const PortablePathUnavailable("A field requires a record value");
  }
}

PortablePathResult<skir.DataValue> _replaceItem(
  skir.DataValue current,
  skir.ItemId id,
  List<skir.PathSegment> segments,
  int offset,
  skir.DataValue replacement,
) {
  if (current case skir.DataValue_listValueWrapper(:final value)) {
    return _replaceListItem(
      value,
      id,
      segments,
      offset,
      replacement,
      skir.DataValue.createListValue,
    );
  }
  if (current case skir.DataValue_setValueWrapper(:final value)) {
    return _replaceListItem(
      value,
      id,
      segments,
      offset,
      replacement,
      skir.DataValue.createSetValue,
    );
  }
  if (current case skir.DataValue_mapValueWrapper(:final value)) {
    final rows = value.rows.toList();
    final index = rows.indexWhere((row) => row.id == id);
    if (index < 0) {
      return PortablePathUnavailable("The map row ${id.value} is absent");
    }
    if (offset + 1 >= segments.length) {
      return const PortablePathUnavailable("A map row is not a value");
    }
    final branch = segments[offset + 1];
    final row = rows[index];
    final source = branch == skir.PathSegment.mapKey
        ? row.key
        : branch == skir.PathSegment.mapValue
        ? row.value
        : null;
    if (source == null) {
      return const PortablePathUnavailable(
        "A map row item requires a key or value segment",
      );
    }
    final nested = _replaceValue(source, segments, offset + 2, replacement);
    if (nested case PortablePathUnavailable(:final message)) {
      return PortablePathUnavailable(message);
    }
    final next = (nested as PortablePathValue<skir.DataValue>).value;
    rows[index] = skir.MapRow(
      id: row.id,
      key: branch == skir.PathSegment.mapKey ? next : row.key,
      value: branch == skir.PathSegment.mapValue ? next : row.value,
    );
    return PortablePathValue(skir.DataValue.createMapValue(rows: rows));
  }
  return const PortablePathUnavailable("An item requires a collection value");
}

PortablePathResult<skir.DataValue> _replaceListItem(
  skir.ListPayload payload,
  skir.ItemId id,
  List<skir.PathSegment> segments,
  int offset,
  skir.DataValue replacement,
  skir.DataValue Function({required Iterable<skir.ListItem_orMutable> items})
  rebuild,
) {
  final items = payload.items.toList();
  final index = items.indexWhere((item) => item.id == id);
  if (index < 0) {
    return PortablePathUnavailable("The collection item ${id.value} is absent");
  }
  final nested = _replaceValue(
    items[index].value,
    segments,
    offset + 1,
    replacement,
  );
  if (nested case PortablePathUnavailable(:final message)) {
    return PortablePathUnavailable(message);
  }
  items[index] = skir.ListItem(
    id: id,
    value: (nested as PortablePathValue<skir.DataValue>).value,
  );
  return PortablePathValue(rebuild(items: items));
}

extension PortableCollectionDiagnostics on skir.DataValue {
  PortablePathResult<List<skir.ValuePath>> duplicateCollectionRows([
    skir.ValuePath? location,
  ]) {
    final path = location ?? skir.ValuePath(segments: const []);
    final duplicates = <skir.ValuePath>[];
    final pending = <_ValueVisit>[_ValueVisit(this, path, 0)];
    while (pending.isNotEmpty) {
      final visit = pending.removeLast();
      if (visit.depth > _maximumAuthoredValueDepth) {
        return const PortablePathUnavailable(
          "The authored value exceeded its depth limit",
        );
      }
      _collectDuplicateRows(visit, duplicates, pending);
    }
    return PortablePathValue(duplicates);
  }
}

void _collectDuplicateRows(
  _ValueVisit visit,
  List<skir.ValuePath> duplicates,
  List<_ValueVisit> pending,
) {
  final value = visit.value;
  final path = visit.path;
  final nextDepth = visit.depth + 1;
  switch (value) {
    case skir.DataValue_namedWrapper(:final value):
      pending.add(_ValueVisit(value.payload, path, nextDepth));
    case skir.DataValue_recordWrapper(:final value):
      for (final field in value.fields.toList().reversed) {
        pending.add(
          _ValueVisit(
            field.value,
            _append(path, skir.PathSegment.createField(name: field.name)),
            nextDepth,
          ),
        );
      }
    case skir.DataValue_listValueWrapper(:final value):
      for (final item in value.items.toList().reversed) {
        pending.add(
          _ValueVisit(
            item.value,
            _append(path, skir.PathSegment.createItem(id: item.id)),
            nextDepth,
          ),
        );
      }
    case skir.DataValue_setValueWrapper(:final value):
      final seen = <skir.DataValue>{};
      for (final item in value.items) {
        final itemPath = _append(
          path,
          skir.PathSegment.createItem(id: item.id),
        );
        if (!seen.add(item.value)) duplicates.add(itemPath);
        pending.add(_ValueVisit(item.value, itemPath, nextDepth));
      }
    case skir.DataValue_mapValueWrapper(:final value):
      final seen = <skir.DataValue>{};
      for (final row in value.rows) {
        final rowPath = _append(path, skir.PathSegment.createItem(id: row.id));
        if (!seen.add(row.key)) {
          duplicates.add(_append(rowPath, skir.PathSegment.mapKey));
        }
        pending
          ..add(
            _ValueVisit(
              row.value,
              _append(rowPath, skir.PathSegment.mapValue),
              nextDepth,
            ),
          )
          ..add(
            _ValueVisit(
              row.key,
              _append(rowPath, skir.PathSegment.mapKey),
              nextDepth,
            ),
          );
      }
    default:
      break;
  }
}

final class _ValueVisit {
  const _ValueVisit(this.value, this.path, this.depth);

  final skir.DataValue value;
  final skir.ValuePath path;
  final int depth;
}

skir.ValuePath _append(skir.ValuePath path, skir.PathSegment segment) =>
    skir.ValuePath(segments: [...path.segments, segment]);
