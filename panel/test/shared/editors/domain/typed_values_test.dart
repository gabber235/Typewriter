import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("DataValue", () {
    test("nested values use structural equality", () {
      final first = RecordValue({
        "items": ListValue([
          MapValue([
            DataMapEntry(
              key: const StringValue("key"),
              value: IntegerValue(BigInt.from(42)),
            ),
          ]),
        ]),
      });
      final second = RecordValue({
        "items": ListValue([
          MapValue([
            DataMapEntry(
              key: const StringValue("key"),
              value: IntegerValue(BigInt.from(42)),
            ),
          ]),
        ]),
      });

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test("bytes own an immutable copy of their input", () {
      final input = Uint8List.fromList([1, 2, 3]);
      final value = BytesValue(input);

      input[0] = 9;

      expect(value, BytesValue(Uint8List.fromList([1, 2, 3])));
    });

    test("timestamps normalize equivalent instants to UTC", () {
      final localOffset = TimestampValue(
        DateTime.parse("2026-08-09T12:00:00+02:00"),
      );
      final utc = TimestampValue(DateTime.parse("2026-08-09T10:00:00Z"));

      expect(localOffset, utc);
      expect(localOffset.value.isUtc, isTrue);
    });

    test("record updates preserve the original value", () {
      final original = RecordValue({"name": const StringValue("before")});

      final updated = original.withField("name", const StringValue("after"));
      final removed = updated.withoutField("name");

      expect(original.fields, {"name": const StringValue("before")});
      expect(updated.fields, {"name": const StringValue("after")});
      expect(removed.fields, isEmpty);
    });
  });

  group("DataPath", () {
    test("reads fields, indices, and map keys", () {
      final root = RecordValue({
        "items": ListValue([
          MapValue([
            DataMapEntry(
              key: IntegerValue(BigInt.one),
              value: const StringValue("found"),
            ),
          ]),
        ]),
      });
      final path = DataPath.root
          .field("items")
          .index(0)
          .mapKey(IntegerValue(BigInt.one));

      expect(path.read(root).valueOrNull, const StringValue("found"));
      expect(path.toString(), r"$.items[0]{DataValue.integer(value: 1)}");
    });

    test("field names containing dots remain one segment", () {
      final root = RecordValue({"a.b": const StringValue("value")});
      final path = DataPath.root.field("a.b");

      expect(path.segments, [const FieldPathSegment("a.b")]);
      expect(path.read(root).valueOrNull, const StringValue("value"));
    });

    test("deep replacement rebuilds ancestors without mutating the root", () {
      final root = RecordValue({
        "items": ListValue([
          RecordValue({"name": const StringValue("before")}),
        ]),
      });
      final path = DataPath.root.field("items").index(0).field("name");

      final result = path.replace(root, const StringValue("after"));

      expect(path.read(root).valueOrNull, const StringValue("before"));
      expect(
        path.read(result.valueOrNull!).valueOrNull,
        const StringValue("after"),
      );
    });

    test("invalid segments return an invalid path diagnostic", () {
      final path = DataPath.root.field("items").index(2);

      final result = path.read(
        RecordValue({
          "items": ListValue([const StringValue("only")]),
        }),
      );

      expect(result, isA<TypeFailure<DataValue>>());
      expect(result.diagnostics.single.code, TypeDiagnosticCode.invalidPath);
      expect(result.diagnostics.single.message, contains("index 2"));
    });

    test("a segment rejects an incompatible parent kind", () {
      final result = DataPath.root
          .field("name")
          .read(ListValue([const StringValue("value")]));

      expect(result.diagnostics.single.code, TypeDiagnosticCode.invalidPath);
      expect(result.diagnostics.single.message, contains("record"));
    });
  });
}
