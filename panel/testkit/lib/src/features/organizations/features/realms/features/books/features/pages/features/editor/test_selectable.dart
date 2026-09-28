import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

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
    final initial = NamedType(rootDefinition.id)
        .createInitialValue(registry: TypeRegistry(typeCatalog))
        .valueOrNull;
    final data =
        ref.watch(testDataProvider(id)) ??
        (initial is RecordValue ? initial : RecordValue(const {}))
            .withField("name", id.formatted.asValue)
            .withField("color", color.asValue);

    final snapshot = DocumentEditorSnapshot(
      EditorDocument(
        rootType: NamedType(rootDefinition.id),
        typeCatalog: typeCatalog,
        confirmedValue: data,
        revision: 1,
      ),
    );
    final commands = ref.read(testSelectableDataProvider.notifier);
    final resource = FakeEditableResource(
      key: EditorResourceKey(scope: null, identity: resourceId),
      current: snapshot,
      commit: (commit) async {
        final next = commit.rootValue;
        if (next is! RecordValue) {
          return TypedMutationResult.invalid([
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: "The selectable root must remain a record",
            ),
          ]);
        }
        commands.set(id, next);
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: next,
        );
      },
    );
    return AsyncValue.data(
      TestSelectable(
        resource: resource,
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

class TestSelectable extends EditableSelectable<TestSelectableIdentifier> {
  TestSelectable({
    required this.resource,
    required this.id,
    required this.rootDefinition,
    required this.typeCatalog,
    required this.data,
    required this.color,
    required this.onDelete,
  });

  @override
  final EditableResource resource;

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
  int get hashCode => Object.hash(id, rootType, data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSelectable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rootType == other.rootType &&
          data == other.data;

  @override
  String get name {
    final value = data.fields["name"];
    final name = value?.asStringOrNull;
    return (name?.nullIfEmpty ?? id.id).formatted;
  }

  @override
  Widget? buildInspectorHeader(EditOwner owner) => ManagedInspectorHeader(
    id: id.id,
    owner: owner,
    fallbackName: name,
    fallbackColor: color,
  );

  @override
  EditorSnapshot get snapshot => DocumentEditorSnapshot(document);

  @override
  String toString() {
    return "TestSelectable(id: $id, name: $name)";
  }
}
