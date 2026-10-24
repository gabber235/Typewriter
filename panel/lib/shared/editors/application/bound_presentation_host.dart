import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef PortableBindingReader = skir.DataValue? Function(skir.ValuePath path);
typedef PortableBindingWriter =
    FutureOr<PortablePresentationWriteResult> Function(
      skir.ValuePath path,
      skir.DataValue value,
    );

/// Explicitly maps one backend owned editor value into a portable binding.
///
/// The reader and writer are supplied by the feature that owns the backend
/// data transfer object. This adapter never converts a legacy type catalog or
/// infers a nominal schema from runtime values.
final class BoundPresentationBinding {
  const BoundPresentationBinding({
    required this.id,
    required this.use,
    required this.read,
    this.write,
    this.owner,
    this.control,
  });

  final skir.ExpressionBindingId id;
  final skir.TypeUse use;
  final PortableBindingReader read;
  final PortableBindingWriter? write;

  /// The backend editor source whose changes invalidate this binding.
  final Listenable? owner;
  final EditControl? control;

  bool get editable => write != null;

  PortablePresentationBinding snapshot() => PortablePresentationBinding(
    schema: PortablePresentationBindingSchema.complete(use),
    value: read(skir.ValuePath(segments: const [])) ?? skir.DataValue.unfilled,
    editable: editable,
  );
}

/// Presents backend owned service drafts through the portable renderer.
///
/// Persistence, conflicts, remote refreshes, reservations, and save policy
/// remain on the original editor sources. This host only exposes their current
/// values through explicit feature owned codecs and forwards accepted writes.
/// Writes compare their captured invocation value with the current binding
/// before calling the writer. Disposal releases binding controls and observer
/// subscriptions; the feature retains ownership of the underlying draft.
final class BoundPresentationHost extends ChangeNotifier
    implements PortablePresentationHost {
  BoundPresentationHost({
    required this.catalog,
    required this.root,
    required Iterable<BoundPresentationBinding> bindings,
    required this.budget,
    this._enabled = true,
    this.readOnly = false,
    this.capabilities = const PortablePresentationCapabilities(),
    this.role,
    this.material,
    this.contextInputs,
    this.activePresentations = const {},
    this.slots = const {},
  }) : _bindings = _indexBindings(bindings) {
    _document = _snapshot();
    for (final owner in _owners) {
      owner.addListener(_changed);
    }
  }

  final CheckedEditorCatalog catalog;
  final skir.PresentationNode Function() root;
  final Map<skir.ExpressionBindingId, BoundPresentationBinding> _bindings;
  final skir.EvaluationBudget budget;
  final skir.PresentationRole? role;
  final skir.PresentationMaterial? material;

  /// Context inputs of a presentation built without material.
  final List<skir.PresentationContextInput>? contextInputs;
  final Set<skir.PresentationId> activePresentations;
  final Map<String, skir.PresentationNode> slots;
  late PortablePresentationDocument _document;
  bool _disposed = false;

  final bool _enabled;

  @override
  bool get enabled => _enabled && !_disposed;

  @override
  final bool readOnly;

  @override
  final PortablePresentationCapabilities capabilities;

  Set<Listenable> get _owners => _bindings.values
      .map((candidate) => candidate.owner)
      .whereType<Listenable>()
      .toSet();

  @override
  PortablePresentationDocument get document => _document;

  /// Returns the existing backend source lifetime behind a binding.
  Listenable? bindingOwner(skir.ExpressionBindingId id) => _bindings[id]?.owner;

  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (!enabled ||
        readOnly ||
        context.catalogGeneration != catalog.snapshot.generation ||
        context.bindings[reference.bindingId] == null) {
      return null;
    }
    return _bindings[reference.bindingId]?.control;
  }

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    return context.read(reference, catalog.snapshot.generation);
  }

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != catalog.snapshot.generation) return null;
    final exposed = context.bindings[reference.bindingId];
    if (exposed == null) return null;
    final root = switch (exposed.schema) {
      CompletePortablePresentationBinding(:final use) => use,
      _ => null,
    };
    if (root == null) return null;
    if (reference.path.segments.isEmpty) return root;
    final selection = switch (root) {
      skir.TypeUse_namedWrapper(:final value) =>
        skir.TypeSelection.wrapComplete(value),
      _ => null,
    };
    return selection == null
        ? null
        : catalog.valueTypeAt(selection, reference.path, value: exposed.value);
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    if (!enabled || readOnly) {
      return _reject("This presentation is read only", target: reference);
    }
    final writer = _bindings[reference.bindingId]?.write;
    if (writer == null) {
      return _reject(
        "This presentation binding is read only",
        target: reference,
      );
    }
    if (!context.isCurrent(
      reference,
      catalog.snapshot.generation,
      _bindings[reference.bindingId]
          ?.read(editorRootPath)
          ?.editorValueAt(reference.path),
    )) {
      return _reject(
        "The presentation value changed before this write",
        target: reference,
      );
    }
    final expected = expectedType(reference, context: context);
    if (expected == null || !catalog.admitsPortableValue(expected, value)) {
      return _reject(
        "The value does not match the binding type",
        target: reference,
      );
    }
    final result = await writer(reference.path, value);
    if (result is PortablePresentationWriteApplied && !_disposed) _changed();
    return result;
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async {
    if (editorAction is skir.EditorAction_navigateWrapper ||
        editorAction is skir.EditorAction_authoringWrapper) {
      final invoke = capabilities.resourceAction;
      if (!enabled ||
          invoke == null ||
          editorAction is skir.EditorAction_authoringWrapper && readOnly) {
        return _reject("This resource action is unavailable");
      }
      return invoke(editorAction, context);
    }
    if (!enabled || readOnly) {
      return _reject("This presentation is read only");
    }
    if (editorAction case skir.EditorAction_localWrapper(
      value: skir.LocalEditorAction_setValueWrapper(:final value),
    )) {
      final evaluated = (context.queries?.catalog ?? catalog)
          .evaluateExpression(
            value.value,
            bindings: context.bindings,
            budget: budget,
            queries: context.queries,
          );
      return switch (evaluated) {
        PortableExpressionAvailable(value: final replacement) => write(
          value.target,
          replacement,
          context: context,
        ),
        PortableExpressionFailed(:final message) => _reject(
          message,
          target: value.target,
        ),
        PortableExpressionUnavailable() => _reject(
          "The action value is unavailable",
          target: value.target,
        ),
      };
    }
    return _reject("This presentation action is unavailable");
  }

  PortablePresentationWriteResult _reject(
    String message, {
    skir.BindingRef? target,
  }) => PortablePresentationWriteResult.rejected([
    PortablePresentationDiagnostic(
      code: "binding_rejected",
      message: message,
      severity: skir.DiagnosticSeverity.error,
      targets: target == null
          ? const []
          : [PortableDiagnosticTarget.binding(target)],
    ),
  ]);

  PortablePresentationDocument _snapshot() => PortablePresentationDocument(
    catalog: catalog,
    queries: PortableExpressionQueries(catalog: catalog),
    root: root(),
    bindings: {
      for (final entry in _bindings.entries) entry.key: entry.value.snapshot(),
    },
    budget: budget,
    role: role,
    material: material,
    contextInputs: contextInputs,
    activePresentations: activePresentations,
    slots: slots,
  );

  void _changed() {
    if (_disposed) return;
    _document = _snapshot();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final control
        in _bindings.values
            .map((binding) => binding.control)
            .whereType<EditControl>()
            .toSet()) {
      control.dispose();
    }
    for (final owner in _owners) {
      owner.removeListener(_changed);
    }
    super.dispose();
  }
}

Map<skir.ExpressionBindingId, BoundPresentationBinding> _indexBindings(
  Iterable<BoundPresentationBinding> values,
) {
  final indexed = <skir.ExpressionBindingId, BoundPresentationBinding>{};
  for (final value in values) {
    if (indexed.containsKey(value.id)) {
      throw ArgumentError.value(value.id, "bindings", "Duplicate binding id");
    }
    indexed[value.id] = value;
  }
  return Map.unmodifiable(indexed);
}
