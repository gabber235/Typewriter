import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "test_selectable.g.dart";

@Riverpod(keepAlive: true)
class TestSelectableData extends _$TestSelectableData {
  @override
  Map<String, RecordValue> build() {
    return {};
  }

  void set(String id, RecordValue data) {
    state = {...state, id: data};
  }

  @override
  bool updateShouldNotify(
    Map<String, RecordValue> previous,
    Map<String, RecordValue> next,
  ) {
    return !mapEquals(previous, next);
  }
}

@riverpod
RecordValue? testData(Ref ref, String id) {
  final data = ref.watch(testSelectableDataProvider)[id];
  return data;
}

class TestSelectableIdentifier extends SelectableIdentifier {
  TestSelectableIdentifier({
    required this.id,
    RecordType? rootType,
    this.color = Colors.redAccent,
    this.onDelete,
  }) : representation =
           rootType ??
           RecordType(
             fields: const {
               "name": TypeField(name: "name", type: StringType()),
             },
           );

  @override
  final String id;
  final RecordType representation;
  final Color color;
  final VoidCallback? onDelete;

  late final TypeDefinition rootDefinition = TypeDefinition(
    id: ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "testkit", name: id),
      revision: 1,
    ),
    kind: NominalTypeKind.concrete,
    representation: representation,
  );

  late final TypeCatalog typeCatalog = TypeCatalog([rootDefinition]);

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
    final initial = NamedType(
      rootDefinition.id,
    ).createInitialValue(registry: TypeRegistry(typeCatalog)).valueOrNull;
    final data =
        ref.watch(testDataProvider(id)) ??
        (initial is RecordValue ? initial : RecordValue(const {})).withField(
          "name",
          StringValue(id.formatted),
        );

    return AsyncValue.data(
      TestSelectable(
        ref: ref,
        id: this,
        rootDefinition: rootDefinition,
        typeCatalog: typeCatalog,
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

class TestSelectable extends InspectableSelectable<TestSelectableIdentifier> {
  TestSelectable({
    required this.ref,
    required this.id,
    required this.rootDefinition,
    required this.typeCatalog,
    required this.data,
    required this.color,
    required this.onDelete,
  });

  final Ref ref;

  @override
  final TestSelectableIdentifier id;

  final TypeDefinition rootDefinition;

  @override
  final TypeCatalog typeCatalog;

  final RecordValue data;

  final Color color;

  final VoidCallback? onDelete;

  @override
  late final EditorDocument document = EditorDocument(
    rootType: NamedType(rootDefinition.id),
    typeCatalog: typeCatalog,
    confirmedValue: data,
    revision: 1,
  );

  @override
  List<SelectionCapability> get capabilities => [
    if (onDelete != null) DeleteSelectionCapability(onDelete: onDelete!),
  ];

  @override
  int get hashCode => Object.hash(id, rootType, data, color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rootType == other.rootType &&
          data == other.data &&
          color == other.color;

  @override
  String get name {
    final value = data.fields["name"];
    final name = value is StringValue ? value.value : null;
    return (name?.nullIfEmpty ?? id.id).formatted;
  }

  @override
  Widget? buildInspectorHeader() => TestSelectableHeader(selectable: this);

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) async {
    final next = commit.rootValue;
    if (next is! RecordValue) {
      return TypedMutationResult.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "The selectable root must remain a record",
        ),
      ]);
    }
    ref.read(testSelectableDataProvider.notifier).set(id.id, next);
    return TypedMutationResult.success(
      revision: commit.expectedRevision + 1,
      value: next,
    );
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
