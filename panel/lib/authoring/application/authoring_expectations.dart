part of "realm_edit_model.dart";

// Edit expectations: how each staged fact is keyed, observed and compared.
skir.EditExpectation _value({required skir.ValueLocation at}) =>
    skir.EditExpectation.createValue(at: at, expected: null);
skir.EditExpectation _configuration({required skir.ValueLocation at}) =>
    skir.EditExpectation.createConfiguration(at: at, expected: null);
skir.EditExpectation _exists({required skir.ResourceId resource}) =>
    skir.EditExpectation.createResourceExists(id: resource, expected: false);
Object _factKey(skir.EditExpectation expected) => switch (expected) {
  skir.EditExpectation_valueWrapper(:final value) => ("value", value.at),
  skir.EditExpectation_resourceWrapper(:final value) => ("resource", value.id),
  skir.EditExpectation_resourceExistsWrapper(:final value) => (
    "exists",
    value.id,
  ),
  skir.EditExpectation_configurationWrapper(:final value) => (
    "configuration",
    value.at,
  ),
  skir.EditExpectation_resourceIdsWrapper() => "resources",
  skir.EditExpectation_linksWrapper(:final value) => (
    "links",
    value.resource,
    value.contract,
    value.direction,
  ),
  _ => throw StateError("Unknown edit expectation"),
};
bool _sameExpectation(skir.EditExpectation first, skir.EditExpectation second) {
  if (first is skir.EditExpectation_linksWrapper &&
      second is skir.EditExpectation_linksWrapper) {
    return _factKey(first) == _factKey(second) &&
        first.value.expected.toSet().length ==
            second.value.expected.toSet().length &&
        first.value.expected.toSet().containsAll(second.value.expected);
  }
  if (first is skir.EditExpectation_resourceIdsWrapper &&
      second is skir.EditExpectation_resourceIdsWrapper) {
    return first.value.toSet().length == second.value.toSet().length &&
        first.value.toSet().containsAll(second.value);
  }
  if (_factKey(first) != _factKey(second)) return false;
  if (first is skir.EditExpectation_valueWrapper &&
      second is skir.EditExpectation_valueWrapper) {
    return _sameExpectedValue(first.value.expected, second.value.expected);
  }
  if (first is skir.EditExpectation_resourceWrapper &&
      second is skir.EditExpectation_resourceWrapper) {
    final left = first.value.expected;
    final right = second.value.expected;
    if (left == null || right == null) return left == right;
    return left.configuration == right.configuration &&
        _sameExpectedFields(left.fields, right.fields);
  }
  return first == second;
}

bool _sameExpectedFields(
  Iterable<skir.FieldValue> first,
  Iterable<skir.FieldValue> second,
) {
  final left = {for (final field in first) field.name: field.value};
  final right = {for (final field in second) field.name: field.value};
  return left.length == right.length &&
      left.entries.every(
        (entry) =>
            right.containsKey(entry.key) &&
            _sameExpectedValue(entry.value, right[entry.key]),
      );
}

bool _sameExpectedValue(skir.DataValue? first, skir.DataValue? second) {
  if (first == null || second == null) return first == second;
  return switch ((first, second)) {
    (
      skir.DataValue_recordWrapper(value: final left),
      skir.DataValue_recordWrapper(value: final right),
    ) =>
      _sameExpectedFields(left.fields, right.fields),
    (
      skir.DataValue_namedWrapper(value: final left),
      skir.DataValue_namedWrapper(value: final right),
    ) =>
      left.actualType == right.actualType &&
          _sameExpectedValue(left.payload, right.payload),
    (
      skir.DataValue_listValueWrapper(value: final left),
      skir.DataValue_listValueWrapper(value: final right),
    ) =>
      _sameExpectedItems(left.items, right.items),
    (
      skir.DataValue_setValueWrapper(value: final left),
      skir.DataValue_setValueWrapper(value: final right),
    ) =>
      _sameExpectedItems(left.items, right.items),
    (
      skir.DataValue_mapValueWrapper(value: final left),
      skir.DataValue_mapValueWrapper(value: final right),
    ) =>
      left.rows.length == right.rows.length &&
          Iterable<int>.generate(left.rows.length).every(
            (index) =>
                left.rows.elementAt(index).id ==
                    right.rows.elementAt(index).id &&
                _sameExpectedValue(
                  left.rows.elementAt(index).key,
                  right.rows.elementAt(index).key,
                ) &&
                _sameExpectedValue(
                  left.rows.elementAt(index).value,
                  right.rows.elementAt(index).value,
                ),
          ),
    (
      skir.DataValue_floatWrapper(value: final left),
      skir.DataValue_floatWrapper(value: final right),
    ) =>
      left == right && left.isNegative == right.isNegative ||
          left.isNaN && right.isNaN,
    _ => first == second,
  };
}

bool _sameExpectedItems(
  Iterable<skir.ListItem> first,
  Iterable<skir.ListItem> second,
) =>
    first.length == second.length &&
    Iterable<int>.generate(first.length).every(
      (index) =>
          first.elementAt(index).id == second.elementAt(index).id &&
          _sameExpectedValue(
            first.elementAt(index).value,
            second.elementAt(index).value,
          ),
    );

skir.ValueLocation _root(skir.ResourceId resource) => skir.ValueLocation(
  resource: resource,
  path: skir.ValuePath(segments: const []),
);

skir.NamedTypeUse? _concreteNamed(skir.TypeUse? type) => switch (type) {
  skir.TypeUse_namedWrapper(:final value) => value,
  skir.TypeUse_nullableWrapper(:final value) => _concreteNamed(value.value),
  _ => null,
};
