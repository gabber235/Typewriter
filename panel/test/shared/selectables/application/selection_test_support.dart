import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final selectionEditorSourceProvider = Provider<SelectionEditorSource>((ref) {
  final source = SelectionEditorSource(ref);
  ref.onDispose(source.dispose);
  return source;
});

class MockSelectableIdentifier extends SelectableIdentifier {
  MockSelectableIdentifier(this.id, [RecordValue? value])
    : value = value ?? RecordValue(const {});

  @override
  final String id;
  final RecordValue value;

  @override
  AsyncValue<Selectable<MockSelectableIdentifier>> create(Ref ref) {
    return AsyncData(MockSelectable(this, value));
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

class MockSelectable extends InspectableSelectable<MockSelectableIdentifier> {
  MockSelectable(this.id, this.data);

  @override
  final MockSelectableIdentifier id;
  final RecordValue data;

  DataPath? lastSetPath;
  DataValue? lastSetValue;

  @override
  String get name => "Mock ${id.id}";

  late final TypeDefinition rootDefinition = TypeDefinition(
    id: ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "selection_test", name: id.id),
      revision: 1,
    ),
    kind: NominalTypeKind.concrete,
    representation: RecordType(
      fields: data.fields.map(
        (name, value) =>
            MapEntry(name, TypeField(name: name, type: value.typeExpression)),
      ),
    ),
  );

  @override
  ResolvedTypeRef get rootType => rootDefinition.id;

  @override
  late final TypeCatalog typeCatalog = TypeCatalog([rootDefinition]);

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  Widget? buildInspectorHeader() => null;

  @override
  EditorValue value(DataPath path) => data.readEditorValue(path);

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    final result = validateUpdate(path, value);
    if (result is! AppliedEditorMutation) return result;
    lastSetPath = path;
    lastSetValue = value;
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MockSelectable && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

extension TestDataValueTypeExpression on DataValue {
  TypeExpression get typeExpression => switch (this) {
    StringValue() => const StringType(),
    IntegerValue() => const IntegerType(width: IntegerWidth.signed64),
    BooleanValue() => const BooleanType(),
    _ => const AnyType(),
  };
}
