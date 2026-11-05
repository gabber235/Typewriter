import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("Flutter colors convert to Skir colors and back without loss", () {
    for (final color in [
      Colors.blue,
      const Color(0x00000000),
      const Color(0x7fffffff),
      const Color(0x80000000),
      const Color(0xffffffff),
    ]) {
      expect(
        color.toSkirColor().toFlutterColor().toARGB32(),
        color.toARGB32(),
        reason: "0x${color.toARGB32().toRadixString(16)}",
      );
    }
  });

  group("RecordIdExtension.toSurrealQl", () {
    test("formats unknown, number, and string keys", () {
      expect(skir.RecordIdKey.unknown.surrealQl, "<unknown>");
      expect(skir.RecordIdKey.wrapNumber(-42).surrealQl, "-42");
      expect(skir.RecordIdKey.wrapString("quest_42").surrealQl, "quest_42");
      expect(skir.RecordIdKey.wrapString("").surrealQl, "``");
      expect(skir.RecordIdKey.wrapString("two words").surrealQl, "`two words`");
      expect(skir.RecordIdKey.wrapString("42").surrealQl, "`42`");

      expect(
        skir.RecordIdKey.wrapString("9223372036854775808").surrealQl,
        "9223372036854775808",
      );
    });

    test("formats UUID keys", () {
      expect(
        skir.RecordIdKey.wrapUuid("123e4567-e89b-12d3-a456-426614174000")
            .surrealQl,
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
        key.surrealQl,
        r"[<unknown>, NONE, true, false, 7, 1.5f, 'it\'s', [2]]",
      );
    });

    test("formats object keys and values recursively", () {
      final nested = skir.RecordIdValue.wrapObject(
        skir.KeyedIterable.copy([
          skir.ObjectRecordIdValue(
            key: "nested key",
            value: skir.RecordIdValue.wrapString("value"),
          ),
        ], (item) => item.key),
      );
      final key = skir.RecordIdKey.wrapObject(
        skir.KeyedIterable.copy([
          skir.ObjectRecordIdKey(key: "simple", value: nested),
          skir.ObjectRecordIdKey(key: "123", value: skir.RecordIdValue.null_),
        ], (item) => item.key),
      );

      expect(key.surrealQl, "{simple: {`nested key`: 'value'}, `123`: NONE}");
    });
  });
}
