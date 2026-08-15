import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "selection_test_support.dart";

void main() {
  group("typed selection value", () {
    test("selection changes flow into the editor source", () {
      final container = ProviderContainer.test();
      final path = DataPath.root.field("field");

      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({"field": const StringValue("hello")}),
      );

      expect(
        container.read(selectionEditorSourceProvider).value(path),
        isA<InvalidEditorValue>(),
      );

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      final value = container.read(selectionEditorSourceProvider).value(path);

      expect(value, isA<ReadyEditorValue>());
      expect((value as ReadyEditorValue).value, const StringValue("hello"));
    });
  });

  group("inspected root type provider", () {
    test("returns null when no selection", () {
      final container = ProviderContainer.test();

      final rootType = container.read(inspectedRootTypeProvider);

      expect(rootType, isNull);
    });

    test("returns a nominal type for single selection", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({
          "name": const StringValue("test"),
          "count": IntegerValue(BigInt.from(42)),
        }),
      );
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      final rootType = container.read(inspectedRootTypeProvider);

      expect(rootType, isA<NamedType>());
      expect(
        (rootType! as NamedType).reference,
        ResolvedTypeRef(
          id: const QualifiedTypeId(namespace: "selection_test", name: "A"),
          revision: 1,
        ),
      );
    });

    test("returns overlapping elementDefinition for multiple selections", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({
          "shared": const StringValue("a"),
          "uniqueA": IntegerValue(BigInt.one),
        }),
      );
      final idB = MockSelectableIdentifier(
        "B",
        RecordValue({
          "shared": const StringValue("b"),
          "uniqueB": IntegerValue(BigInt.two),
        }),
      );

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final rootType = container.read(inspectedRootTypeProvider) as RecordType?;

      expect(rootType, isNotNull);
      expect(rootType!.fields.containsKey("shared"), isTrue);
      expect(rootType.fields.containsKey("uniqueA"), isFalse);
      expect(rootType.fields.containsKey("uniqueB"), isFalse);
    });
  });
}
