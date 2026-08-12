import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "selection_test_support.dart";

void main() {
  group("typed selection value", () {
    test("returns loading when selected is loading", () {
      final container = ProviderContainer.test();
      final loadingId = LoadingSelectableIdentifier("loading");
      container
          .read(selectionProvider.notifier)
          .select(loadingId, isMultiSelect: false);

      final value = container
          .read(selectionEditorSourceProvider)
          .value(DataPath.root.field("field"));

      expect(value, isA<LoadingEditorValue>());
    });

    test("returns none when selection is empty", () {
      final container = ProviderContainer.test();

      final value = container
          .read(selectionEditorSourceProvider)
          .value(DataPath.root.field("field"));

      expect(value, isA<InvalidEditorValue>());
    });

    test("returns value for single selection", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({"field": const StringValue("hello")}),
      );
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      final value = container
          .read(selectionEditorSourceProvider)
          .value(DataPath.root.field("field"));

      expect(value, isA<ReadyEditorValue>());
      expect((value as ReadyEditorValue).value, const StringValue("hello"));
    });

    test("returns value when all items have same value", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({"field": const StringValue("same")}),
      );
      final idB = MockSelectableIdentifier(
        "B",
        RecordValue({"field": const StringValue("same")}),
      );
      final idC = MockSelectableIdentifier(
        "C",
        RecordValue({"field": const StringValue("same")}),
      );

      container.read(selectionProvider.notifier).selectAll([idA, idB, idC]);

      final value = container
          .read(selectionEditorSourceProvider)
          .value(DataPath.root.field("field"));

      expect(value, isA<ReadyEditorValue>());
      expect((value as ReadyEditorValue).value, const StringValue("same"));
    });

    test("returns conflict when items have different values", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({"field": const StringValue("valueA")}),
      );
      final idB = MockSelectableIdentifier(
        "B",
        RecordValue({"field": const StringValue("valueB")}),
      );

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final value = container
          .read(selectionEditorSourceProvider)
          .value(DataPath.root.field("field"));

      expect(value, isA<ConflictEditorValue>());
    });

    test("returns invalid when the field is omitted", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier("A");
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      final value = container
          .read(selectionEditorSourceProvider)
          .value(DataPath.root.field("field"));

      expect(value, isA<InvalidEditorValue>());
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
