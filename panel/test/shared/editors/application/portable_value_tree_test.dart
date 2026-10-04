import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("replaces a stable list item and preserves its actual type", () {
    final first = skir.ItemId(value: "first");
    final second = skir.ItemId(value: "second");
    final actual = skir.NamedTypeUse(
      definition: _definition("List"),
      arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
    );
    final original = skir.DataValue.createNamed(
      actualType: actual,
      payload: skir.DataValue.createListValue(
        items: [
          skir.ListItem(
            id: first,
            value: skir.DataValue.wrapStringValue("one"),
          ),
          skir.ListItem(
            id: second,
            value: skir.DataValue.wrapStringValue("two"),
          ),
        ],
      ),
    );
    final path = skir.ValuePath(
      segments: [skir.PathSegment.createItem(id: second)],
    );

    final replaced = original.replaceAt(
      path,
      skir.DataValue.wrapStringValue("changed"),
    );

    expect(replaced, isA<PortablePathValue<skir.DataValue>>());
    final result = (replaced as PortablePathValue<skir.DataValue>).value;
    expect(result, isA<skir.DataValue_namedWrapper>());
    final named = result as skir.DataValue_namedWrapper;
    expect(named.value.actualType, actual);
    final list = named.value.payload as skir.DataValue_listValueWrapper;
    expect(list.value.items.map((item) => item.id), [first, second]);
    expect(
      (list.value.items.last.value as skir.DataValue_stringValueWrapper).value,
      "changed",
    );
  });

  test("reads a nested map value by row identity", () {
    final row = skir.ItemId(value: "row");
    final value = skir.DataValue.createMapValue(
      rows: [
        skir.MapRow(
          id: row,
          key: skir.DataValue.wrapStringValue("key"),
          value: skir.DataValue.createRecord(
            fields: [
              skir.FieldValue(
                name: "count",
                value: skir.DataValue.wrapInteger("3"),
              ),
            ],
          ),
        ),
      ],
    );
    final path = skir.ValuePath(
      segments: [
        skir.PathSegment.createItem(id: row),
        skir.PathSegment.mapValue,
        skir.PathSegment.createField(name: "count"),
      ],
    );

    final result = value.readAt(path);

    expect(result, isA<PortablePathValue<skir.DataValue>>());
    expect(
      ((result as PortablePathValue<skir.DataValue>).value
              as skir.DataValue_integerWrapper)
          .value,
      "3",
    );
  });

  test("retains duplicate map rows and reports the later key", () {
    final first = skir.ItemId(value: "first");
    final second = skir.ItemId(value: "second");
    final duplicateKey = skir.DataValue.wrapStringValue("same");
    final value = skir.DataValue.createMapValue(
      rows: [
        skir.MapRow(
          id: first,
          key: duplicateKey,
          value: skir.DataValue.wrapInteger("1"),
        ),
        skir.MapRow(
          id: second,
          key: duplicateKey,
          value: skir.DataValue.wrapInteger("2"),
        ),
      ],
    );

    final result = value.duplicateCollectionRows();

    expect(result, isA<PortablePathValue<List<skir.ValuePath>>>());
    final duplicates =
        (result as PortablePathValue<List<skir.ValuePath>>).value;
    expect(duplicates, hasLength(1));
    expect(duplicates.single.segments, [
      skir.PathSegment.createItem(id: second),
      skir.PathSegment.mapKey,
    ]);
    final map = value as skir.DataValue_mapValueWrapper;
    expect(map.value.rows, hasLength(2));
  });

  test("retains duplicate set items and reports the later item", () {
    final first = skir.ItemId(value: "first");
    final second = skir.ItemId(value: "second");
    final duplicate = skir.DataValue.wrapStringValue("same");
    final value = skir.DataValue.createSetValue(
      items: [
        skir.ListItem(id: first, value: duplicate),
        skir.ListItem(id: second, value: duplicate),
      ],
    );

    final result = value.duplicateCollectionRows();

    expect(result, isA<PortablePathValue<List<skir.ValuePath>>>());
    final duplicates =
        (result as PortablePathValue<List<skir.ValuePath>>).value;
    expect(duplicates, hasLength(1));
    expect(duplicates.single.segments, [
      skir.PathSegment.createItem(id: second),
    ]);
    final set = value as skir.DataValue_setValueWrapper;
    expect(set.value.items, hasLength(2));
  });

  test("sets an absent direct field without creating unrelated fields", () {
    final record = skir.AuthoringRecord(
      configuration: skir.TypeSelection.unknown,
      fields: [
        skir.FieldValue(
          name: "title",
          value: skir.DataValue.wrapStringValue("kept"),
        ),
      ],
    );
    final path = skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "count")],
    );

    final result = record.replaceAt(path, skir.DataValue.wrapInteger("3"));

    expect(result, isA<PortablePathValue<skir.AuthoringRecord>>());
    final updated = (result as PortablePathValue<skir.AuthoringRecord>).value;
    expect(updated.fields.map((field) => field.name), ["title", "count"]);
  });

  test("nested writes require explicit parent initialization", () {
    final record = skir.AuthoringRecord(
      configuration: skir.TypeSelection.unknown,
      fields: const [],
    );
    final path = skir.ValuePath(
      segments: [
        skir.PathSegment.createField(name: "style"),
        skir.PathSegment.createField(name: "bold"),
      ],
    );

    final result = record.replaceAt(path, skir.DataValue.wrapBoolean(true));

    expect(result, isA<PortablePathUnavailable<skir.AuthoringRecord>>());
    expect(
      (result as PortablePathUnavailable<skir.AuthoringRecord>).message,
      contains("needs initialization"),
    );
  });

  test("deep named values return a bounded path failure", () {
    final actualType = skir.NamedTypeUse(
      definition: _definition("Nested"),
      arguments: const [],
    );
    var value = skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(name: "value", value: skir.DataValue.wrapBoolean(true)),
      ],
    );
    for (var depth = 0; depth < 600; depth++) {
      value = skir.DataValue.createNamed(
        actualType: actualType,
        payload: value,
      );
    }

    final result = value.readAt(
      skir.ValuePath(segments: [skir.PathSegment.createField(name: "value")]),
    );

    expect(result, isA<PortablePathUnavailable<skir.DataValue>>());
    expect(
      (result as PortablePathUnavailable<skir.DataValue>).message,
      contains("depth limit"),
    );
  });

  test("deep collection diagnostics return a bounded failure", () {
    final actualType = skir.NamedTypeUse(
      definition: _definition("Nested"),
      arguments: const [],
    );
    var value = skir.DataValue.createSetValue(items: const []);
    for (var depth = 0; depth < 600; depth++) {
      value = skir.DataValue.createNamed(
        actualType: actualType,
        payload: value,
      );
    }

    final result = value.duplicateCollectionRows();

    expect(result, isA<PortablePathUnavailable<List<skir.ValuePath>>>());
    expect(
      (result as PortablePathUnavailable<List<skir.ValuePath>>).message,
      contains("depth limit"),
    );
  });
}

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "typewriter", name: name),
  revision: 1,
);
