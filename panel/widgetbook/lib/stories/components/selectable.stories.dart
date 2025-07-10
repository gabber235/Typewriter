import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

part "selectable.stories.g.dart";

@riverpod
class TestSelectableData extends _$TestSelectableData {
    @override
    Map<String, DynamicData> build() {
        return {};
    }

    void set(String id, DynamicData data) {
        state = {...state, id: data};
    }
}

@riverpod
DynamicData? testData(Ref ref, String id) {
    return ref.watch(testSelectableDataProvider)[id];
}

// Custom selectable identifier for testing
class TestSelectableIdentifier extends SelectableIdentifier {
  TestSelectableIdentifier({
    required this.id,
    required this.dataBlueprint,
  });

  @override
  final String id;
  final ObjectBlueprint dataBlueprint;

  @override
  Future<Selectable> create(Ref ref) async {
    return TestSelectable(
      ref: ref,
      id: this,
      objectBlueprint: dataBlueprint,
      data: ref.watch(testDataProvider(id)) ?? DynamicData(dataBlueprint.defaultValue()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectableIdentifier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Custom selectable implementation for testing
class TestSelectable extends Selectable<TestSelectableIdentifier> {
  TestSelectable({
    required this.ref,
    required this.id,
    required this.objectBlueprint,
    required this.data,
  });

  final Ref ref;

  @override
  final TestSelectableIdentifier id;

  @override
  final ObjectBlueprint objectBlueprint;

  @override
  String get name => data.get("name") ?? id.id.formatted;

  final DynamicData data;

  @override
  dynamic fieldValue(String path) {
    final value = data.get(path);
    return value;
  }

  @override
  void setFieldValue(String path, dynamic value) {
    ref.read(testSelectableDataProvider.notifier).set(id.id, data.copyWith(path, value));
  }
}

// Selectable box widget
class SelectableBox extends HookConsumerWidget {
  const SelectableBox({
    required this.selectable,
    required this.color,
    super.key,
  });

  final TestSelectableIdentifier selectable;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Selector(
      selectableId: selectable,
      builder: (isSelected) {
        return AnimatedOpacity(
          opacity: isSelected ? 1 : 0.3,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isSelected ? 0.8 : 0.3),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectable.id.formatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Main demo widget
class SelectableDemo extends HookConsumerWidget {
  const SelectableDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final blueprint = ObjectBlueprint(fields: {
          "name": DataBlueprint.string(),
          });
    // Create test selectable identifiers
    final selectables = useMemoized(
      () => [
        TestSelectableIdentifier(
          id: "box1",
          dataBlueprint: blueprint,
        ),
        TestSelectableIdentifier(
          id: "box2",
          dataBlueprint: blueprint,
        ),
        TestSelectableIdentifier(
          id: "box3",
          dataBlueprint: blueprint,
        ),
      ],
    );

    final colors = [Colors.red, Colors.green, Colors.orange];
    final selectedItems = ref.watch(selectionProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: List.generate(
                    3,
                    (index) => SelectableBox(
                      selectable: selectables[index],
                      color: colors[index],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          selectedItems.isNotEmpty
              ? FloatingActionButton(
                onPressed: ref.read(selectionProvider.notifier).clear,
                child: const Icon(Icons.clear),
              )
              : null,
    );
  }
}

@widgetbook.UseCase(name: "Selectable Boxes", type: SelectableBox)
Widget selectableUseCase(BuildContext context) {
  return const ProviderScope(child: SelectableDemo());
}
