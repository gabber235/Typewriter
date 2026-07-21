import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:skir_client/skir_client.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("Color serialization", () {
    for (final color in [
      Colors.blue,
      const Color(0x00000000),
      const Color(0x7fffffff),
      const Color(0x80000000),
      const Color(0xffffffff),
    ]) {
      test("preserves 0x${color.toARGB32().toRadixString(16)}", () {
        final bytes = skir.Color.serializer.toBytes(color.toSkirColor());
        final decoded = skir.Color.serializer.fromBytes(bytes).toFlutterColor();

        expect(decoded.toARGB32(), color.toARGB32());
      });
    }
  });

  group("RecordIdExtension.id", () {
    test("formats unknown, number, and string keys", () {
      expect(_id(skir.RecordIdKey.unknown), "<unknown>");
      expect(_id(skir.RecordIdKey.wrapNumber(-42)), "-42");
      expect(_id(skir.RecordIdKey.wrapString("quest_42")), "quest_42");
      expect(_id(skir.RecordIdKey.wrapString("")), "``");
      expect(_id(skir.RecordIdKey.wrapString("two words")), "`two words`");
      expect(_id(skir.RecordIdKey.wrapString("42")), "`42`");
      expect(
        _id(skir.RecordIdKey.wrapString("9223372036854775808")),
        "9223372036854775808",
      );
    });

    test("formats UUID keys", () {
      expect(
        _id(skir.RecordIdKey.wrapUuid("123e4567-e89b-12d3-a456-426614174000")),
        "u'123e4567-e89b-12d3-a456-426614174000'",
      );
    });

    test("formats array values recursively", () {
      final key = skir.RecordIdKey.wrapArray([
        skir.RecordIdValue.unknown,
        skir.RecordIdValue.null_,
        skir.RecordIdValue.wrapBoolean(true),
        skir.RecordIdValue.wrapBoolean(false),
        skir.RecordIdValue.wrapNumber(7),
        skir.RecordIdValue.wrapFloat(1.5),
        skir.RecordIdValue.wrapString("it's"),
        skir.RecordIdValue.wrapArray([skir.RecordIdValue.wrapNumber(2)]),
      ]);

      expect(
        _id(key),
        r"[<unknown>, NONE, true, false, 7, 1.5f, 'it\'s', [2]]",
      );
    });

    test("formats object keys and values recursively", () {
      final nested = skir.RecordIdValue.wrapObject(
        KeyedIterable.copy([
          skir.ObjectRecordIdValue(
            key: "nested key",
            value: skir.RecordIdValue.wrapString("value"),
          ),
        ], (item) => item.key),
      );
      final key = skir.RecordIdKey.wrapObject(
        KeyedIterable.copy([
          skir.ObjectRecordIdKey(key: "simple", value: nested),
          skir.ObjectRecordIdKey(key: "123", value: skir.RecordIdValue.null_),
        ], (item) => item.key),
      );

      expect(_id(key), "{simple: {`nested key`: 'value'}, `123`: NONE}");
    });
  });
}

String _id(skir.RecordIdKey key) {
  return skir.RecordId(table: "ignored", key: key).id;
}
