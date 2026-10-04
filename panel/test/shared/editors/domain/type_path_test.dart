import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("DataPath transparent wrappers", () {
    test("reads and replaces through a polymorphic wrapper", () {
      final concreteType = _typeRef("Record");
      final root = PolymorphicValue(
        concreteType: concreteType,
        value: RecordValue({"name": const StringValue("before")}),
      );
      final path = DataPath.root.field("name");

      expect(path.read(root).valueOrNull, const StringValue("before"));

      final updated = path
          .replace(root, const StringValue("after"))
          .valueOrNull;
      expect(updated, isA<PolymorphicValue>());
      expect((updated! as PolymorphicValue).concreteType, concreteType);
      expect(path.read(updated).valueOrNull, const StringValue("after"));
    });

    test("inserts a terminal absent record field", () {
      final root = RecordValue(const {});
      final path = DataPath.root.field("optional");

      expect(path.read(root).valueOrNull, isNull);

      final updated = path.replace(root, const StringValue("created"));
      expect(
        path.read(updated.valueOrNull!).valueOrNull,
        const StringValue("created"),
      );
    });
  });
}

ResolvedTypeRef _typeRef(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "example", name: name),
  revision: 1,
);
