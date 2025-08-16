// Custom selectable implementation for testing
import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:mocktail/mocktail.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations/delete_operation.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";

part "test_selectable.g.dart";

@Riverpod(keepAlive: true)
class TestSelectableData extends _$TestSelectableData {
  @override
  Map<String, DynamicData> build() {
    return {};
  }

  void set(String id, DynamicData data) {
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

class TestSelectableDataMock extends _$TestSelectableData
    with
        // ignore: prefer_mixin
        Mock
    implements
        TestSelectableData {}

@riverpod
DynamicData? testData(Ref ref, String id) {
  final data = ref.watch(testSelectableDataProvider)[id];
  return data;
}

// Custom selectable identifier for testing
class TestSelectableIdentifier extends SelectableIdentifier {
  TestSelectableIdentifier({
    required this.id,
    this.dataBlueprint = const ObjectBlueprint(fields: {}),
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
    final data = ref.watch(testDataProvider(id)) ??
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
