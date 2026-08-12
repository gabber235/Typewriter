import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("Common editable projection", () {
    test("keeps only shared fields with equivalent types", () {
      final first = RecordType(
        fields: {
          "shared": const TypeField(
            name: "shared",
            type: StringType(),
            initialValue: StringValue("same"),
          ),
          "first": const TypeField(name: "first", type: BooleanType()),
        },
      );
      final second = RecordType(
        fields: {
          "shared": const TypeField(
            name: "shared",
            type: StringType(),
            initialValue: StringValue("same"),
          ),
          "second": const TypeField(name: "second", type: BooleanType()),
        },
      );

      final result = [first, second].commonEditableProjection();
      final record = result.valueOrNull! as RecordType;

      expect(record.fields.keys, ["shared"]);
      expect(record.fields["shared"]!.initialValue, const StringValue("same"));
    });

    test("drops an initializer when selections disagree", () {
      final first = _recordField(
        "value",
        const StringType(),
        initialValue: const StringValue("first"),
      );
      final second = _recordField(
        "value",
        const StringType(),
        initialValue: const StringValue("second"),
      );

      final record =
          [first, second].commonEditableProjection().valueOrNull! as RecordType;

      expect(record.fields["value"]!.initialValue, isNull);
    });

    test("reports failure when no editable fields are shared", () {
      final result = [
        _recordField("left", const StringType()),
        _recordField("right", const StringType()),
      ].commonEditableProjection();

      expect(
        result.diagnostics.single.code,
        TypeDiagnosticCode.invalidConstraint,
      );
    });

    test("equivalent nonrecord types project unchanged", () {
      const type = ListType(element: BooleanType(), unique: true);

      final result = [type, type].commonEditableProjection();

      expect(result.valueOrNull, same(type));
    });
  });
}

RecordType _recordField(
  String name,
  TypeExpression type, {
  DataValue? initialValue,
}) => RecordType(
  fields: {name: TypeField(name: name, type: type, initialValue: initialValue)},
);
