import "package:faker/faker.dart" hide Color;
import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/inspector.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations/delete_operation.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/app_required.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

part "selectable.stories.g.dart";

@widgetbook.UseCase(name: "Selectable Boxes", type: SelectableBox)
Widget selectableUseCase(BuildContext context) {
  return ProviderScope(
    retry: (_, _) => null,
    child: AppRequiredWidgets(child: SelectableDemo()),
  );
}

// Selectable box widget
class SelectableBox extends HookConsumerWidget {
  const SelectableBox({required this.selectable, super.key});

  final TestSelectableIdentifier selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    return Selector(
      selectableId: selectable,
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        return AnimatedOpacity(
          opacity:
              isHovered || isFocused
                  ? 0.7
                  : isSelected
                  ? 1
                  : 0.3,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: selectable.color.withValues(alpha: isSelected ? 0.8 : 0.3),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  isFocused
                      ? [
                        BoxShadow(
                          color: selectable.color.withValues(alpha: 0.5),
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
                    textAlign: TextAlign.center,
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

class TestSelectableHeader extends HookConsumerWidget {
  const TestSelectableHeader({required this.selectable, super.key});

  final TestSelectable selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: selectable.name, color: selectable.color),
        const SizedBox(height: 8),
        Identifier(id: selectable.id.id),
      ],
    );
  }
}

// Main demo widget
class SelectableDemo extends HookConsumerWidget {
  const SelectableDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectables = useState(<TestSelectableIdentifier>[]);

    TestSelectableIdentifier generate() {
      final id = faker.person.name().snakeCase();
      final blueprint = ObjectBlueprint(
        fields: {
          "name": DataBlueprint.string(modifiers: [const Modifier.snakeCase()]),
          "count": DataBlueprint.integer(),
        },
      );
      return TestSelectableIdentifier(
        id: id,
        dataBlueprint: blueprint,
        color: safeColors.randomOrNull()!,
        onDelete: () {
          selectables.value =
              selectables.value.where((s) => s.id != id).toList();
        },
      );
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectables.value = List.generate(3, (index) => generate());
      });
      return null;
    }, []);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Inspector(
              margin: EdgeInsets.only(top: 8, right: 8),
              child: Pane(
                id: "boxes",
                borderRadius: BorderRadius.circular(12),
                margin: EdgeInsets.only(top: 8, left: 8),
                child: Section(
                  margin: EdgeInsets.zero,
                  child: Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: List.generate(
                        selectables.value.length,
                        (index) =>
                            SelectableBox(selectable: selectables.value[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ActionRow(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          selectables.value = [...selectables.value, generate()];
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Custom selectable implementation for testing
class TestSelectable extends Selectable<TestSelectableIdentifier> {
  TestSelectable({
    required this.ref,
    required this.id,
    required this.objectBlueprint,
    required this.data,
    required this.color,
    required this.onDelete,
  });

  final Ref ref;

  @override
  final TestSelectableIdentifier id;

  @override
  final ObjectBlueprint objectBlueprint;

  final DynamicData data;

  final Color color;

  final VoidCallback? onDelete;

  @override
  List<SelectableOperation> get operations => [
    if (onDelete != null) DeleteSelectableOperation(onDelete: onDelete!),
  ];

  @override
  int get hashCode => Object.hash(id, objectBlueprint, data, color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          objectBlueprint == other.objectBlueprint &&
          data == other.data &&
          color == other.color;

  @override
  String get name {
    final name = data.get("name") as String?;
    return (name?.nullIfEmpty ?? id.id).formatted;
  }

  @override
  dynamic fieldValue(String path) {
    final value = data.get(path);
    return value;
  }

  @override
  Widget? header() => TestSelectableHeader(selectable: this);

  @override
  void setFieldValue(String path, dynamic value) {
    ref
        .read(testSelectableDataProvider.notifier)
        .set(id.id, data.copyWith(path, value));
  }

  @override
  String toString() {
    return "TestSelectable(id: $id, name: $name)";
  }
}

@Riverpod(keepAlive: true)
class TestSelectableData extends _$TestSelectableData {
  @override
  Map<String, DynamicData> build() {
    return {};
  }

  void set(String id, DynamicData data) {
    print("Setting data for $id: $data");
    state = {...state, id: data};
  }

  @override
  bool updateShouldNotify(
    Map<String, DynamicData> previous,
    Map<String, DynamicData> next,
  ) {
    return !mapEquals(previous, next);
  }
}

@riverpod
DynamicData? testData(Ref ref, String id) {
  final data = ref.watch(testSelectableDataProvider)[id];
  print("Reading data for $id: $data");
  return data;
}

// Custom selectable identifier for testing
class TestSelectableIdentifier extends SelectableIdentifier {
  TestSelectableIdentifier({
    required this.id,
    required this.dataBlueprint,
    this.color = Colors.redAccent,
    this.onDelete,
  });

  @override
  final String id;
  final ObjectBlueprint dataBlueprint;
  final Color color;
  final VoidCallback? onDelete;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectableIdentifier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final data =
        ref.watch(testDataProvider(id)) ??
        DynamicData({...dataBlueprint.defaultValue(), "name": id.formatted});

    return AsyncValue.data(
      TestSelectable(
        ref: ref,
        id: this,
        objectBlueprint: dataBlueprint,
        data: data,
        color: color,
        onDelete: onDelete,
      ),
    );
  }

  @override
  String toString() {
    return "TestSelectableIdentifier(id: $id)";
  }
}
