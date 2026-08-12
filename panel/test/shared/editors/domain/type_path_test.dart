import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("expandTypeQueryPath", () {
    test("preserves a field name containing dots", () {
      final root = RecordValue({"literal.name": const StringValue("value")});

      final paths = root.expandTypeQueryPath(const [
        TypeFieldQuerySegment("literal.name"),
      ]);

      expect(paths, [DataPath.root.field("literal.name")]);
      expect(paths.single.read(root).valueOrNull, const StringValue("value"));
    });

    test("returns the list insertion index for a terminal element query", () {
      final root = ListValue([
        const StringValue("first"),
        const StringValue("second"),
      ]);

      final paths = root.expandTypeQueryPath(const [
        TypeListElementQuerySegment(),
      ]);

      expect(paths, [DataPath.root.index(2)]);
    });

    test("expands nested fields through every existing list value", () {
      final root = RecordValue({
        "items": ListValue([
          RecordValue({"name": const StringValue("first")}),
          RecordValue({"name": const StringValue("second")}),
        ]),
      });

      final paths = root.expandTypeQueryPath(const [
        TypeFieldQuerySegment("items"),
        TypeListElementQuerySegment(),
        TypeFieldQuerySegment("name"),
      ]);

      expect(paths, [
        DataPath.root.field("items").index(0).field("name"),
        DataPath.root.field("items").index(1).field("name"),
      ]);
    });

    test("retains typed map keys", () {
      final firstKey = IntegerValue(BigInt.one);
      final secondKey = IntegerValue(BigInt.two);
      final root = MapValue([
        DataMapEntry(key: firstKey, value: const StringValue("first")),
        DataMapEntry(key: secondKey, value: const StringValue("second")),
      ]);

      final paths = root.expandTypeQueryPath(const [
        TypeMapValueQuerySegment(),
      ]);

      expect(paths, [
        DataPath.root.mapKey(firstKey),
        DataPath.root.mapKey(secondKey),
      ]);
    });

    test("unwraps a polymorphic value without changing the data path", () {
      final root = PolymorphicValue(
        concreteType: _typeRef("Record"),
        value: RecordValue({"name": const StringValue("tagged")}),
      );

      final paths = root.expandTypeQueryPath(const [
        TypeFieldQuerySegment("name"),
      ]);

      expect(paths, [DataPath.root.field("name")]);
    });
  });

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

  group("queryReferences", () {
    test("finds exact nominal references with structured paths", () {
      final entry = NamedType(_typeRef("Entry"));
      final root = RecordType(
        fields: {
          "target": TypeField(
            name: "target",
            type: NamedType(standardTypeRefs.refTo(entry)),
          ),
        },
      );

      final references = root.queryReferences(relation: "entry");

      expect(references, hasLength(1));
      expect(references.single.path, const [TypeFieldQuerySegment("target")]);
      expect(typeExpressionsEqual(references.single.target, entry), isTrue);
    });
  });
}

ResolvedTypeRef _typeRef(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "example", name: name),
  revision: 1,
);
