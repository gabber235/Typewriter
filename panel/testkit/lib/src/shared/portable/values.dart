import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Collection items holding the texts [values], each identified by its own
/// text.
List<skir.ListItem> textItems(List<String> values) => [
  for (final value in values)
    skir.ListItem(
      id: skir.ItemId(value: value),
      value: skir.DataValue.wrapStringValue(value),
    ),
];

/// A list of the texts [values], in order, as [textItems].
skir.DataValue textList(List<String> values) =>
    skir.DataValue.createListValue(items: textItems(values));

/// A set of the texts [values] as [textItems].
skir.DataValue textSet(List<String> values) =>
    skir.DataValue.createSetValue(items: textItems(values));

/// The record value [record] with each field named in [fields] holding its
/// new value; other fields keep their place and value.
skir.DataValue recordWithFields(
  skir.DataValue record,
  Map<String, skir.DataValue> fields,
) => skir.DataValue.createRecord(
  fields: [
    for (final field in (record as skir.DataValue_recordWrapper).value.fields)
      skir.FieldValue(
        name: field.name,
        value: fields[field.name] ?? field.value,
      ),
  ],
);

/// A record value of the named type [type] holding [fields], none by default.
skir.DataValue namedRecord(
  skir.NamedTypeUse type, [
  List<skir.FieldValue> fields = const [],
]) => skir.DataValue.createNamed(
  actualType: type,
  payload: skir.DataValue.createRecord(fields: fields),
);

/// A record value of the named type [type] whose fields are [fields], in
/// order.
skir.DataValue namedRecordOf(
  skir.NamedTypeUse type,
  Map<String, skir.DataValue> fields,
) => namedRecord(type, [
  for (final MapEntry(:key, :value) in fields.entries)
    skir.FieldValue(name: key, value: value),
]);
