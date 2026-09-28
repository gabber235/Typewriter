import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns a typed value for an editing surface that has no persistence boundary.
///
/// Updates are validated against the current schema and notify listeners only
/// after the local value changes. An interaction captures the value at its
/// start, so cancellation restores that value while commit merely closes the
/// interaction. The creator owns disposal; disposal invalidates open
/// interactions and makes later updates conflicts.
final class LocalEditor extends ChangeNotifier
    implements EditOwner, ConcreteTypeSelectionOwner {
  LocalEditor({
    required this.rootType,
    required this.typeCatalog,
    required this._value,
    this.concreteTypeInitializer,
  });

  @override
  TypeExpression rootType;

  @override
  TypeCatalog typeCatalog;
  final ConcreteTypeInitializer? concreteTypeInitializer;
  DataValue _value;
  bool _disposed = false;
  final Set<_LocalInteraction> _interactions = {};
  final Map<DataPath, int> _selectionRequests = {};
  int _nextSelectionRequest = 0;

  @override
  bool get readOnly => _disposed;

  @override
  EditorValue value(DataPath path) => _value.readEditorValue(path);

  @override
  EditorMutationResult update(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    if (_disposed) return const EditorMutationResult.conflict();
    final result = validate(path, value);
    if (result is! AppliedEditorMutation) return result;
    final replaced = path.replace(_value, value);
    if (replaced case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }

    _value = replaced.valueOrNull!;

    notifyListeners();
    return result;
  }

  @override
  EditorMutationResult validate(DataPath path, DataValue value) => rootType
      .validateEditorMutation(path, value, registry: TypeRegistry(typeCatalog));

  @override
  Future<EditorMutationResult> selectConcreteTypeAsync(
    DataPath path,
    ResolvedTypeRef type,
  ) async {
    final registry = TypeRegistry(typeCatalog);
    final declared = rootType.resolvePath(path, registry: registry).valueOrNull;
    if (declared is! NamedType ||
        !NamedType(type).isStructurallyAssignableTo(declared, registry)) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Concrete type does not refine the declared type",
          path: path,
        ),
      ]);
    }
    final resolved = registry.resolveExact(type).valueOrNull;
    if (resolved == null || !resolved.isConcrete) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Concrete type is unavailable",
          path: path,
        ),
      ]);
    }
    final captured = value(path).valueOrNull;
    final request = ++_nextSelectionRequest;
    _selectionRequests[path] = request;
    if (captured is PolymorphicValue && captured.concreteType == type) {
      return EditorMutationResult.applied(captured);
    }
    final initializer = concreteTypeInitializer;
    final ConcreteTypeInitializationResult initialized;
    try {
      initialized = initializer == null
          ? resolved.representation is UnitType
                ? ConcreteTypeInitialized(
                    TypedValueEnvelope(
                      rootType: type,
                      rootValue: const UnitValue(),
                    ),
                  )
                : const ConcreteTypeInitializationRejected([])
          : await initializer(type: type, supplied: null);
    } on Object catch (error) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Concrete type initialization failed: $error",
          path: path,
        ),
      ]);
    }
    if (_disposed ||
        _selectionRequests[path] != request ||
        value(path).valueOrNull != captured) {
      return const EditorMutationResult.conflict();
    }
    final selectedValue = switch (initialized) {
      ConcreteTypeInitialized(:final value)
          when value.rootType == type &&
              value.rootValue
                  .validateAgainst(resolved.representation, registry: registry)
                  .isEmpty =>
        PolymorphicValue(concreteType: type, value: value.rootValue),
      ConcreteTypeNeedsInput() => null,
      ConcreteTypeInitializationRejected() => null,
      ConcreteTypeInitialized() => null,
    };
    if (selectedValue == null) {
      return switch (initialized) {
        ConcreteTypeInitializationRejected(:final diagnostics) =>
          EditorMutationResult.invalid(diagnostics),
        ConcreteTypeNeedsInput() => EditorMutationResult.invalid([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Concrete type initialization requires editor input",
            path: path,
          ),
        ]),
        ConcreteTypeInitialized() => EditorMutationResult.invalid([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Realm returned a value for the wrong concrete type",
            path: path,
          ),
        ]),
      };
    }
    return update(path, selectedValue);
  }

  void refreshSchema(TypeExpression type, TypeCatalog catalog) {
    if (rootType == type && typeCatalog == catalog) return;
    rootType = type;
    typeCatalog = catalog;
    notifyListeners();
  }

  @override
  EditorInteractionSession beginInteraction(DataPath path) {
    final interaction = _LocalInteraction(this, path, value(path).valueOrNull);
    if (_disposed) {
      interaction.active = false;
    } else {
      _interactions.add(interaction);
    }
    return interaction;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final interaction in _interactions) {
      interaction.active = false;
    }
    _interactions.clear();
    super.dispose();
  }
}

final class _LocalInteraction implements EditorInteractionSession {
  _LocalInteraction(this.owner, this.path, this.origin);

  final LocalEditor owner;
  final DataValue? origin;

  @override
  final DataPath path;

  @override
  bool active = true;
  @override
  Future<void> commit() async {
    _close();
  }

  @override
  void cancel() {
    if (!active) return;
    _close();
    if (origin case final value?) owner.update(path, value);
  }

  void _close() {
    active = false;
    owner._interactions.remove(this);
  }
}
