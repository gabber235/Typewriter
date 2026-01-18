import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";

import "../test_utils.dart";

class MockSelectableIdentifier extends SelectableIdentifier {
  MockSelectableIdentifier(this.id, [this._fieldValues = const {}]);

  @override
  final String id;
  final Map<String, dynamic> _fieldValues;

  @override
  AsyncValue<Selectable<MockSelectableIdentifier>> create(Ref ref) {
    return AsyncData(MockSelectable(this, _fieldValues));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MockSelectableIdentifier && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => "MockSelectableIdentifier($id)";
}

class LoadingSelectableIdentifier extends SelectableIdentifier {
  LoadingSelectableIdentifier(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable<LoadingSelectableIdentifier>> create(Ref ref) {
    return const AsyncLoading();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoadingSelectableIdentifier && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class MockSelectable extends Selectable<MockSelectableIdentifier> {
  MockSelectable(this.id, this._fieldValues);

  @override
  final MockSelectableIdentifier id;
  final Map<String, dynamic> _fieldValues;

  String? lastSetPath;
  dynamic lastSetValue;

  @override
  String get name => "Mock ${id.id}";

  @override
  ObjectBlueprint get objectBlueprint => ObjectBlueprint(
    fields: _fieldValues.map((k, v) => MapEntry(k, DataBlueprint.string())),
  );

  @override
  List<SelectableOperation> get operations => [];

  @override
  Widget? header() => null;

  @override
  dynamic fieldValue(String path) => _fieldValues[path];

  @override
  void setFieldValue(String path, dynamic value) {
    lastSetPath = path;
    lastSetValue = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MockSelectable && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group("Selection state machine", () {
    test("single select on empty selection adds item", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(selectionProvider), [idA]);
    });

    test("single select replaces existing selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container
          .read(selectionProvider.notifier)
          .select(idB, isMultiSelect: false);

      expect(container.read(selectionProvider), [idB]);
    });

    test("single select on already selected sole item clears selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(selectionProvider), isEmpty);
    });

    test(
      "single select on already selected item with multiple keeps only that item",
      () {
        final container = ProviderContainer.test();
        addTearDown(container.dispose);

        final idA = MockSelectableIdentifier("A");
        final idB = MockSelectableIdentifier("B");

        container.read(selectionProvider.notifier).selectAll([idA, idB]);
        container
            .read(selectionProvider.notifier)
            .select(idA, isMultiSelect: false);

        expect(container.read(selectionProvider), [idA]);
      },
    );

    test("multi-select adds to existing selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container
          .read(selectionProvider.notifier)
          .select(idB, isMultiSelect: true);

      expect(container.read(selectionProvider), [idA, idB]);
    });

    test("multi-select on already selected item removes it", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: true);

      expect(container.read(selectionProvider), [idB]);
    });

    test("selectAll replaces selection by default", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");
      final idC = MockSelectableIdentifier("C");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container.read(selectionProvider.notifier).selectAll([idB, idC]);

      expect(container.read(selectionProvider), [idB, idC]);
    });

    test("selectAll appends when replaceCurrentSelection is false", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container.read(selectionProvider.notifier).selectAll([
        idB,
      ], replaceCurrentSelection: false);

      expect(container.read(selectionProvider), [idA, idB]);
    });

    test("unselect removes specific item", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);
      container.read(selectionProvider.notifier).unselect(idA);

      expect(container.read(selectionProvider), [idB]);
    });

    test("unselect on non-existent item is no-op", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container.read(selectionProvider.notifier).unselect(idB);

      expect(container.read(selectionProvider), [idA]);
    });

    test("unselectAll removes multiple items", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");
      final idC = MockSelectableIdentifier("C");

      container.read(selectionProvider.notifier).selectAll([idA, idB, idC]);
      container.read(selectionProvider.notifier).unselectAll([idA, idC]);

      expect(container.read(selectionProvider), [idB]);
    });

    test("clear empties selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);
      container.read(selectionProvider.notifier).clear();

      expect(container.read(selectionProvider), isEmpty);
    });
  });

  group("Selection with HardwareKeyboard", () {
    testWidgets("select defaults to single-select when shift not pressed", (
      tester,
    ) async {
      late ProviderContainer container;

      await tester.pumpTestApp(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      );

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).select(idA);
      container.read(selectionProvider.notifier).select(idB);

      expect(container.read(selectionProvider), [idB]);
    });

    testWidgets("select defaults to multi-select when shift is pressed", (
      tester,
    ) async {
      late ProviderContainer container;

      await tester.pumpTestApp(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      );

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).select(idA);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      container.read(selectionProvider.notifier).select(idB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(container.read(selectionProvider), [idA, idB]);
    });

    testWidgets("shift released returns to single-select behavior", (
      tester,
    ) async {
      late ProviderContainer container;

      await tester.pumpTestApp(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      );

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");
      final idC = MockSelectableIdentifier("C");

      container.read(selectionProvider.notifier).select(idA);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      container.read(selectionProvider.notifier).select(idB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      container.read(selectionProvider.notifier).select(idC);

      expect(container.read(selectionProvider), [idC]);
    });
  });

  group("hasSelection and isSelected providers", () {
    test("hasSelection returns false when empty", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      expect(container.read(hasSelectionProvider), isFalse);
    });

    test("hasSelection returns true when items selected", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(hasSelectionProvider), isTrue);
    });

    test("isSelected returns true for selected item", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      expect(container.read(isSelectedProvider(idA)), isTrue);
      expect(container.read(isSelectedProvider(idB)), isTrue);
    });

    test("isSelected returns false for non-selected item", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final idC = MockSelectableIdentifier("C");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(isSelectedProvider(idC)), isFalse);
    });
  });

  group("Selected provider", () {
    test("returns empty list when no selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final selected = container.read(selectedProvider);

      expect(selected.hasValue, isTrue);
      expect(selected.requireValue, isEmpty);
    });

    test("returns resolved selectables for valid identifiers", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"field": "valueA"});
      final idB = MockSelectableIdentifier("B", {"field": "valueB"});

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final selected = container.read(selectedProvider);

      expect(selected.hasValue, isTrue);
      expect(selected.requireValue.length, 2);
      expect(selected.requireValue[0].name, "Mock A");
      expect(selected.requireValue[1].name, "Mock B");
    });

    test("returns loading state when identifier returns loading", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A");
      final loadingId = LoadingSelectableIdentifier("loading");

      container.read(selectionProvider.notifier).selectAll([idA, loadingId]);

      final selected = container.read(selectedProvider);

      expect(selected.isLoading, isTrue);
    });

    test("updateFieldValue calls setFieldValue on all selectables", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"field": "oldA"});
      final idB = MockSelectableIdentifier("B", {"field": "oldB"});

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final selectables = container.read(selectedProvider).requireValue;
      final mockA = selectables[0] as MockSelectable;
      final mockB = selectables[1] as MockSelectable;

      container
          .read(selectedProvider.notifier)
          .updateFieldValue("field", "newValue");

      expect(mockA.lastSetPath, "field");
      expect(mockA.lastSetValue, "newValue");
      expect(mockB.lastSetPath, "field");
      expect(mockB.lastSetValue, "newValue");
    });
  });

  group("fieldValue provider", () {
    test("returns loading when selected is loading", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final loadingId = LoadingSelectableIdentifier("loading");
      container
          .read(selectionProvider.notifier)
          .select(loadingId, isMultiSelect: false);

      final value = container.read(fieldValueProvider("field"));

      expect(value, isA<LoadingValue>());
    });

    test("returns none when selection is empty", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final value = container.read(fieldValueProvider("field"));

      expect(value, isA<NoneValue>());
    });

    test("returns value for single selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"field": "hello"});
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      final value = container.read(fieldValueProvider("field"));

      expect(value, isA<Value>());
      expect((value as Value).value, "hello");
    });

    test("returns value when all items have same value", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"field": "same"});
      final idB = MockSelectableIdentifier("B", {"field": "same"});
      final idC = MockSelectableIdentifier("C", {"field": "same"});

      container.read(selectionProvider.notifier).selectAll([idA, idB, idC]);

      final value = container.read(fieldValueProvider("field"));

      expect(value, isA<Value>());
      expect((value as Value).value, "same");
    });

    test("returns conflict when items have different values", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"field": "valueA"});
      final idB = MockSelectableIdentifier("B", {"field": "valueB"});

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final value = container.read(fieldValueProvider("field"));

      expect(value, isA<ConflictValue>());
    });

    test("returns none when field value is null", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"field": null});
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      final value = container.read(fieldValueProvider("field"));

      expect(value, isA<NoneValue>());
    });
  });

  group("selectedDataBlueprint provider", () {
    test("returns null when no selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final blueprint = container.read(selectedDataBlueprintProvider);

      expect(blueprint, isNull);
    });

    test("returns blueprint for single selection", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"name": "test", "count": 42});
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      final blueprint = container.read(selectedDataBlueprintProvider);

      expect(blueprint, isNotNull);
      expect(blueprint!.fields.containsKey("name"), isTrue);
      expect(blueprint.fields.containsKey("count"), isTrue);
    });

    test("returns overlapping blueprint for multiple selections", () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);

      final idA = MockSelectableIdentifier("A", {"shared": "a", "uniqueA": 1});
      final idB = MockSelectableIdentifier("B", {"shared": "b", "uniqueB": 2});

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final blueprint = container.read(selectedDataBlueprintProvider);

      expect(blueprint, isNotNull);
      expect(blueprint!.fields.containsKey("shared"), isTrue);
      expect(blueprint.fields.containsKey("uniqueA"), isFalse);
      expect(blueprint.fields.containsKey("uniqueB"), isFalse);
    });
  });
}
