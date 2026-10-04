import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as portable_action;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as portable_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as portable_catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as portable_expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as portable_presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as portable_types;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

EditOwner? selectionOwner(ProviderContainer container) {
  final hosts = container.read(inspectionSessionProvider).hosts;
  if (hosts.length != 1) return null;
  return (hosts.single as _MockOwnerHost).owner;
}

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

class MockSelectable extends InspectableSelectable<MockSelectableIdentifier>
    implements EditorTarget {
  MockSelectable(this.id, this.data);

  @override
  final MockSelectableIdentifier id;
  final RecordValue data;

  EditorCommit? latestCommit;

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
  late final EditorDocument document = EditorDocument(
    rootType: NamedType(rootDefinition.id),
    typeCatalog: TypeCatalog([rootDefinition]),
    confirmedValue: data,
    revision: 1,
  );

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  SelectableIdentifier get targetId => id;

  @override
  String get label => name;

  @override
  EditorCommitPolicy get commitPolicy => EditorCommitPolicy.autosaveChanges;

  @override
  List<TypeDiagnostic> validateDraft(DataValue value) =>
      snapshot.validateDraft(value);

  @override
  EditorValue value(DataPath path) =>
      document.confirmedValue.readEditorValue(path);

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    final representation = rootDefinition.representation as RecordType;
    final expected = switch (path.segments) {
      [] => representation,
      [FieldPathSegment(:final name)] => representation.fields[name]?.type,
      _ => null,
    };
    if (expected == null) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "The test selection path is unavailable",
          path: path,
        ),
      ]);
    }
    final diagnostics = value.validateAgainst(expected, path: path);
    return diagnostics.isEmpty
        ? EditorMutationResult.applied(value)
        : EditorMutationResult.invalid(diagnostics);
  }

  @override
  List<PortableMultiInspectionSurface> get portableMultiInspectionSurfaces => [
    _MockPortableSurface(this, rootDefinition.representation),
  ];

  @override
  InspectionContent buildInspection(EditorOwnerScope owners) =>
      InspectionContent(host: _MockOwnerHost(owners.editor(this)));

  @override
  EditorSnapshot get snapshot =>
      FakeEditorSnapshot(document, validation: validate);

  @override
  late final EditableResource resource = FakeEditableResource(
    key: EditorResourceKey(scope: null, identity: id.resourceId),
    current: snapshot,
    commit: commit,
    load: () async => snapshot,
  );

  Future<TypedMutationResult> commit(EditorCommit commit) async {
    latestCommit = commit;
    final value = commit.rootValue;
    if (value is! RecordValue) {
      return TypedMutationResult.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "The selectable root must remain a record",
        ),
      ]);
    }
    return TypedMutationResult.success(
      revision: commit.expectedRevision + 1,
      value: value,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MockSelectable && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

final class _MockPortableSurface implements PortableMultiInspectionSurface {
  const _MockPortableSurface(this.target, this.rootType);

  @override
  Object get id => _MockPortableSurface;

  @override
  final EditorTarget target;

  @override
  final TypeExpression rootType;

  @override
  TypeCatalog get typeCatalog => target.document.typeCatalog;

  @override
  bool isCompatibleWith(PortableMultiInspectionSurface other) =>
      other is _MockPortableSurface;

  @override
  PortablePresentationHost buildHost(
    List<PortableMultiInspectionSurface> members,
    EditOwner combinedOwner,
    Future<void> Function() commit,
  ) => _MockOwnerHost(combinedOwner);
}

final class _MockOwnerHost extends ChangeNotifier
    implements PortablePresentationHost {
  _MockOwnerHost(this.owner)
    : _document = PortablePresentationDocument(
        catalog: CheckedEditorCatalog(
          portable_catalog.EditorCatalogWireSnapshot.defaultInstance,
        ),
        root: portable_presentation.PresentationNode.defaultInstance,
        bindings: const {},
        budget: portable_expression.EvaluationBudget.defaultInstance,
      );

  final EditOwner owner;
  final PortablePresentationDocument _document;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  PortablePresentationDocument get document => _document;

  @override
  bool get enabled => true;

  @override
  bool get readOnly => owner.readOnly;

  @override
  Future<PortablePresentationWriteResult> execute(
    portable_action.EditorAction editorAction,
  ) async => const PortablePresentationWriteResult.rejected(
    "This test host has no actions",
  );

  @override
  portable_types.TypeUse? expectedType(portable_binding.BindingRef reference) =>
      null;

  @override
  portable_types.ValueLocation? location(
    portable_binding.BindingRef reference,
  ) => null;

  @override
  portable_types.DataValue? read(portable_binding.BindingRef reference) => null;

  @override
  Future<PortablePresentationWriteResult> write(
    portable_binding.BindingRef reference,
    portable_types.DataValue value,
  ) async => const PortablePresentationWriteResult.rejected(
    "This test host has no bindings",
  );
}

extension TestDataValueTypeExpression on DataValue {
  TypeExpression get typeExpression => switch (this) {
    StringValue() => const StringType(),
    IntegerValue() => const IntegerType(width: IntegerWidth.signed64),
    BooleanValue() => const BooleanType(),
    _ => const AnyType(),
  };
}
