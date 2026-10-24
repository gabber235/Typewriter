import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The deepest nesting a portable value or expression may reach before
/// evaluation fails with the depth limit failure.
const portableValueDepthLimit = 512;

const _maximumDepth = portableValueDepthLimit;

Never _fail(skir.FailureId failure, [String? message]) =>
    throw skir.PortableOperationFailure(failure, message);

/// Whether [value] holds unfilled entries anywhere inside, as
/// [unfilledPaths] finds them.
bool containsUnfilled(skir.DataValue value) => unfilledPaths(value).isNotEmpty;

/// The paths below [value] that hold unfilled entries, through named
/// payloads, record fields, collection items and map row keys and values.
/// The value itself being unfilled yields the empty path.
List<List<skir.PathSegment>> unfilledPaths(skir.DataValue value) {
  final paths = <List<skir.PathSegment>>[];
  void visit(skir.DataValue current, List<skir.PathSegment> path) {
    if (path.length > _maximumDepth) {
      _fail(skir.PortableFailures.expressionDepthLimit);
    }
    if (current == skir.DataValue.unfilled) {
      paths.add(path);
      return;
    }
    switch (current) {
      case skir.DataValue_namedWrapper(:final value):
        visit(value.payload, path);
      case skir.DataValue_recordWrapper(:final value):
        for (final field in value.fields) {
          visit(field.value, [
            ...path,
            skir.PathSegment.createField(name: field.name),
          ]);
        }
      case skir.DataValue_listValueWrapper(:final value) ||
          skir.DataValue_setValueWrapper(:final value):
        for (final item in value.items) {
          visit(item.value, [
            ...path,
            skir.PathSegment.createItem(id: item.id),
          ]);
        }
      case skir.DataValue_mapValueWrapper(:final value):
        for (final row in value.rows) {
          final rowPath = [...path, skir.PathSegment.createItem(id: row.id)];
          visit(row.key, [...rowPath, skir.PathSegment.mapKey]);
          visit(row.value, [...rowPath, skir.PathSegment.mapValue]);
        }
      default:
        break;
    }
  }

  visit(value, const []);
  return paths;
}

/// The canonical form of a value entering evaluation from outside the
/// runtime (a literal or decoded JSON), as Kotlin's `requirePortable` admits
/// it: integers in canonical notation and record fields in name order. A
/// value that is already canonical is returned as is. A value that is not
/// portable fails [failure].
skir.DataValue admitPortableValue(
  skir.DataValue value,
  skir.FailureId failure,
) => _admitPortable(value, failure, 0);

skir.DataValue _admitPortable(
  skir.DataValue value,
  skir.FailureId failure,
  int depth,
) {
  Never invalid(String message) => _fail(failure, message);
  if (depth > _maximumDepth) invalid("The value is nested too deeply.");
  if (value == skir.DataValue.unfilled ||
      value == skir.DataValue.null_ ||
      value == skir.DataValue.unit) {
    return value;
  }
  skir.ItemId item(skir.ItemId id) =>
      id.value.trim().isEmpty ? invalid("Item ids must not be blank.") : id;
  Iterable<skir.ListItem> items(Iterable<skir.ListItem> source) {
    var changed = false;
    final checked = [
      for (final entry in source)
        () {
          final admitted = _admitPortable(entry.value, failure, depth + 1);
          item(entry.id);
          if (identical(admitted, entry.value)) return entry;
          changed = true;
          return skir.ListItem(id: item(entry.id), value: admitted);
        }(),
    ];
    return changed ? checked : source;
  }

  return switch (value) {
    skir.DataValue_booleanWrapper() ||
    skir.DataValue_stringValueWrapper() ||
    skir.DataValue_bytesWrapper() ||
    skir.DataValue_timestampWrapper() ||
    skir.DataValue_enumCaseWrapper() => value,
    // Kotlin's BigInteger syntax: an optional sign and decimal digits.
    skir.DataValue_integerWrapper(value: final text) =>
      _integerSyntax.hasMatch(text)
          ? switch (BigInt.parse(text)) {
              final parsed when parsed.toString() == text => value,
              final parsed => skir.integerValue(parsed),
            }
          : invalid("The integer payload is invalid."),
    skir.DataValue_floatWrapper(value: final number) =>
      number.isFinite ? value : invalid("Float payloads must be finite."),
    skir.DataValue_decimalWrapper(value: final text) =>
      _canonicalDecimalSyntax.hasMatch(text)
          ? value
          : invalid("The decimal payload is not canonical decimal syntax."),
    skir.DataValue_durationWrapper(value: final duration) =>
      BigInt.from(duration.value.milliseconds).abs() <= portableDurationLimit
          ? value
          : invalid("The duration exceeds the portable range."),
    skir.DataValue_recordWrapper(value: final record) => () {
      var changed = false;
      final fields = [
        for (final field in record.fields)
          () {
            final admitted = _admitPortable(field.value, failure, depth + 1);
            if (identical(admitted, field.value)) return field;
            changed = true;
            return skir.FieldValue(name: field.name, value: admitted);
          }(),
      ];
      final sorted = [...fields]
        ..sort((left, right) => left.name.compareTo(right.name));
      for (var index = 1; index < sorted.length; index++) {
        if (sorted[index - 1].name == sorted[index].name) {
          invalid("Record field ${sorted[index].name} is duplicated.");
        }
      }
      final ordered = [
        for (var index = 0; index < fields.length; index++)
          identical(fields[index], sorted[index]),
      ].every((same) => same);
      return !changed && ordered
          ? value
          : skir.DataValue.createRecord(fields: sorted);
    }(),
    skir.DataValue_namedWrapper(value: final named) => () {
      final payload = _admitPortable(named.payload, failure, depth + 1);
      return identical(payload, named.payload)
          ? value
          : skir.DataValue.createNamed(
              actualType: named.actualType,
              payload: payload,
            );
    }(),
    skir.DataValue_listValueWrapper(value: final list) => () {
      final checked = items(list.items);
      return identical(checked, list.items)
          ? value
          : skir.DataValue.createListValue(items: checked);
    }(),
    skir.DataValue_setValueWrapper(value: final set) => () {
      final checked = items(set.items);
      return identical(checked, set.items)
          ? value
          : skir.DataValue.createSetValue(items: checked);
    }(),
    skir.DataValue_mapValueWrapper(value: final map) => () {
      var changed = false;
      final rows = [
        for (final row in map.rows)
          () {
            item(row.id);
            final key = _admitPortable(row.key, failure, depth + 1);
            final rowValue = _admitPortable(row.value, failure, depth + 1);
            if (identical(key, row.key) && identical(rowValue, row.value)) {
              return row;
            }
            changed = true;
            return skir.MapRow(id: row.id, key: key, value: rowValue);
          }(),
      ];
      return changed ? skir.DataValue.createMapValue(rows: rows) : value;
    }(),
    skir.DataValue_linkWrapper(value: final link) =>
      link.endpoint.value.trim().isEmpty ||
              link.target.resource.value.trim().isEmpty
          ? invalid("Links need an endpoint and a target resource.")
          : value,
    _ => invalid("Unknown value variant."),
  };
}

final _canonicalDecimalSyntax = RegExp(r"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$");

final _integerSyntax = RegExp(r"^[+-]?[0-9]+$");

/// Formats a value for presentation labels.
///
/// Named values use their payload, and empty values have no display text.
String portableExpressionDisplayText(skir.DataValue value) {
  final unwrapped = value.authoredPayload;
  if (unwrapped == skir.DataValue.unfilled ||
      unwrapped == skir.DataValue.null_ ||
      unwrapped == skir.DataValue.unit) {
    return "";
  }
  return switch (unwrapped) {
    skir.DataValue_booleanWrapper(:final value) => value.toString(),
    skir.DataValue_integerWrapper(:final value) => value,
    skir.DataValue_floatWrapper(:final value) => value.toString(),
    skir.DataValue_decimalWrapper(:final value) => value,
    skir.DataValue_stringValueWrapper(:final value) => value,
    skir.DataValue_bytesWrapper(:final value) => "${value.length} bytes",
    skir.DataValue_timestampWrapper(:final value) => value.toIso8601String(),
    skir.DataValue_durationWrapper(:final value) => value.toString(),
    skir.DataValue_enumCaseWrapper(:final value) => value,
    skir.DataValue_listValueWrapper(:final value) =>
      "${value.items.length} items",
    skir.DataValue_setValueWrapper(:final value) =>
      "${value.items.length} items",
    skir.DataValue_mapValueWrapper(:final value) =>
      "${value.rows.length} entries",
    skir.DataValue_recordWrapper() => "record",
    skir.DataValue_linkWrapper(:final value) => value.target.resource.value,
    _ => "",
  };
}

/// The semantic key of portable equality and collection identity: named
/// type identity stays significant, record fields and set and map entries are
/// order independent, list order matters, and item identities are ignored.
/// Equal keys mean equal values exactly when Kotlin's `canonicalValueKey`
/// agrees.
String canonicalAuthoredValue(skir.DataValue value) => _canonical(value, 0);

String _canonical(skir.DataValue value, int depth) {
  if (depth > _maximumDepth) _fail(skir.PortableFailures.expressionDepthLimit);
  if (value == skir.DataValue.unfilled) return "unfilled";
  if (value == skir.DataValue.null_) return "null";
  if (value == skir.DataValue.unit) return "unit";
  return switch (value) {
    skir.DataValue_booleanWrapper(:final value) => "boolean:$value",
    skir.DataValue_integerWrapper(:final value) =>
      "integer:${BigInt.parse(value)}",
    skir.DataValue_floatWrapper(:final value) => "float:${_floatBits(value)}",
    skir.DataValue_decimalWrapper(:final value) =>
      "decimal:${skir.PortableDecimal.parse(value)}",
    skir.DataValue_stringValueWrapper(:final value) =>
      "text:${value.length}:$value",
    skir.DataValue_bytesWrapper(:final value) => "bytes:${value.toBase16()}",
    skir.DataValue_timestampWrapper(:final value) =>
      "timestamp:${value.millisecondsSinceEpoch}",
    skir.DataValue_durationWrapper(:final value) =>
      "duration:${value.value.milliseconds}",
    skir.DataValue_enumCaseWrapper(:final value) =>
      "enum:${value.length}:$value",
    skir.DataValue_recordWrapper(:final value) => _framed(
      "record",
      value.fields
          .map(
            (field) => _framed("field", [
              field.name,
              _canonical(field.value, depth + 1),
            ]),
          )
          .toList()
        ..sort(),
    ),
    skir.DataValue_namedWrapper(:final value) => _framed("named", [
      _namedTypeKey(value.actualType, depth + 1),
      _canonical(value.payload, depth + 1),
    ]),
    skir.DataValue_listValueWrapper(:final value) => _framed(
      "list",
      value.items.map((item) => _canonical(item.value, depth + 1)),
    ),
    skir.DataValue_setValueWrapper(:final value) => _framed(
      "set",
      value.items.map((item) => _canonical(item.value, depth + 1)).toList()
        ..sort(),
    ),
    skir.DataValue_mapValueWrapper(:final value) => _framed(
      "map",
      value.rows
          .map(
            (row) => _framed("row", [
              _canonical(row.key, depth + 1),
              _canonical(row.value, depth + 1),
            ]),
          )
          .toList()
        ..sort(),
    ),
    skir.DataValue_linkWrapper(:final value) => _framed("link", [
      value.endpoint.value,
      value.target.resource.value,
      _pathKey(value.target.opposite),
    ]),
    _ => "unknown",
  };
}

String _framed(String kind, Iterable<String> parts) {
  final values = parts.toList(growable: false);
  return "$kind:${values.length}:${values.map((part) => "${part.length}:$part").join()}";
}

String _floatBits(double value) {
  final bytes = ByteData(8)..setFloat64(0, value);
  return "${bytes.getUint32(0).toRadixString(16).padLeft(8, "0")}"
      "${bytes.getUint32(4).toRadixString(16).padLeft(8, "0")}";
}

String _namedTypeKey(skir.NamedTypeUse value, int depth) {
  if (depth > _maximumDepth) _fail(skir.PortableFailures.expressionDepthLimit);
  return _framed("named_type", [
    _framed("definition", [
      _typeIdKey(value.definition.typeId),
      value.definition.revision.toString(),
    ]),
    _framed(
      "arguments",
      value.arguments.map((argument) => _typeUseKey(argument, depth + 1)),
    ),
  ]);
}

String _typeIdKey(skir.TypeId value) => switch (value) {
  skir.TypeId_declaredWrapper(:final value) => _framed("declared", [
    value.value,
  ]),
  skir.TypeId_qualifiedWrapper(:final value) => _framed("qualified", [
    value.namespace,
    value.name,
  ]),
  _ => "unknown_type_id",
};

String _typeUseKey(skir.TypeUse value, int depth) {
  if (depth > _maximumDepth) _fail(skir.PortableFailures.expressionDepthLimit);
  return switch (value) {
    skir.TypeUse_namedWrapper(:final value) => _namedTypeKey(value, depth + 1),
    skir.TypeUse_nullableWrapper(:final value) => _framed("nullable", [
      _typeUseKey(value.value, depth + 1),
    ]),
    skir.TypeUse_scalarWrapper(:final value) => _framed("scalar", [
      _scalarKindKey(value),
    ]),
    _ => "unknown_type_use",
  };
}

String _scalarKindKey(skir.ScalarKind value) => switch (value) {
  skir.ScalarKind_integerWrapper(:final value) =>
    "integer:${value.width.kind.name}",
  skir.ScalarKind_floatWrapper(:final value) =>
    "float:${value.width.kind.name}",
  _ => value.kind.name,
};

String _pathKey(skir.ValuePath? value) {
  if (value == null) return "absent";
  return _framed("path", value.segments.map(_pathSegmentKey));
}

String _pathSegmentKey(skir.PathSegment value) {
  if (value == skir.PathSegment.mapKey) return "map_key";
  if (value == skir.PathSegment.mapValue) return "map_value";
  return switch (value) {
    skir.PathSegment_fieldWrapper(:final value) => _framed("field", [
      value.name,
    ]),
    skir.PathSegment_itemWrapper(:final value) => _framed("item", [
      value.id.value,
    ]),
    _ => "unknown_path_segment",
  };
}
