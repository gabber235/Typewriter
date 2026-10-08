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
final class EditorSourcePresentationBinding {
  const EditorSourcePresentationBinding({
    required this.id,
    required this.use,
    required this.read,
    this.write,
    this.owner,
  });

  final skir.ExpressionBindingId id;
  final skir.TypeUse use;
  final PortableBindingReader read;
  final PortableBindingWriter? write;

  /// The backend editor source whose changes invalidate this binding.
  final Listenable? owner;

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
final class EditorSourcePresentationHost extends ChangeNotifier
    implements PortablePresentationHost {
  EditorSourcePresentationHost({
    required this.catalog,
    required this.root,
    required Iterable<EditorSourcePresentationBinding> bindings,
    required this.budget,
    this._enabled = true,
    this.readOnly = false,
    this.capabilities = const PortablePresentationCapabilities(),
    this.role,
    this.material,
    this.activePresentations = const {},
    this.slots = const {},
    this.executeAction,
  }) : _bindings = _indexBindings(bindings) {
    _document = _snapshot();
    for (final owner in _owners) {
      owner.addListener(_changed);
    }
  }

  final CheckedEditorCatalog catalog;
  final skir.PresentationNode Function() root;
  final Map<skir.ExpressionBindingId, EditorSourcePresentationBinding>
  _bindings;
  final FutureOr<PortablePresentationWriteResult> Function(
    skir.EditorAction action,
  )?
  executeAction;
  final skir.EvaluationBudget budget;
  final skir.PresentationRole? role;
  final skir.PresentationMaterial? material;
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

  @override
  skir.DataValue? read(skir.BindingRef reference) {
    final exposed = _document.bindings[reference.bindingId];
    if (exposed == null) return null;
    if (reference.path.segments.isEmpty) return exposed.value;
    return switch (exposed.value.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  @override
  skir.ValueLocation? location(skir.BindingRef reference) => null;

  @override
  skir.TypeUse? expectedType(skir.BindingRef reference) {
    final source = _bindings[reference.bindingId];
    final exposed = _document.bindings[reference.bindingId];
    if (source == null || exposed == null) return null;
    if (reference.path.segments.isEmpty) return source.use;
    final selection = switch (source.use) {
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
    skir.DataValue value,
  ) async {
    if (!enabled || readOnly) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final writer = _bindings[reference.bindingId]?.write;
    if (writer == null) {
      return const PortablePresentationWriteRejected(
        "This presentation binding is read only",
      );
    }
    final expected = expectedType(reference);
    if (expected == null || !catalog.admitsPortableValue(expected, value)) {
      return const PortablePresentationWriteRejected(
        "The value does not match the binding type",
      );
    }
    final result = await writer(reference.path, value);
    if (result is PortablePresentationWriteApplied && !_disposed) _changed();
    return result;
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction,
  ) async {
    if (!enabled || readOnly) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final executor = executeAction;
    if (executor == null) {
      if (editorAction case skir.EditorAction_localWrapper(
        value: skir.LocalEditorAction_setValueWrapper(:final value),
      )) {
        final evaluated = PortableExpressionEvaluator({
          for (final entry in document.bindings.entries)
            entry.key: entry.value.value,
        }, budget: budget).evaluate(value.value);
        return switch (evaluated) {
          PortableExpressionAvailable(value: final replacement) => write(
            value.target,
            replacement,
          ),
          PortableExpressionFailed(:final message) =>
            PortablePresentationWriteRejected(message),
          PortableExpressionUnavailable() =>
            const PortablePresentationWriteRejected(
              "The action value is unavailable",
            ),
        };
      }
      return const PortablePresentationWriteRejected(
        "This presentation action is unavailable",
      );
    }
    final result = await executor(editorAction);
    if (result is PortablePresentationWriteApplied && !_disposed) _changed();
    return result;
  }

  PortablePresentationDocument _snapshot() => PortablePresentationDocument(
    catalog: catalog,
    root: root(),
    bindings: {
      for (final entry in _bindings.entries) entry.key: entry.value.snapshot(),
    },
    budget: budget,
    role: role,
    material: material,
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
    for (final owner in _owners) {
      owner.removeListener(_changed);
    }
    super.dispose();
  }
}

Map<skir.ExpressionBindingId, EditorSourcePresentationBinding> _indexBindings(
  Iterable<EditorSourcePresentationBinding> values,
) {
  final indexed = <skir.ExpressionBindingId, EditorSourcePresentationBinding>{};
  for (final value in values) {
    if (indexed.containsKey(value.id)) {
      throw ArgumentError.value(value.id, "bindings", "Duplicate binding id");
    }
    indexed[value.id] = value;
  }
  return Map.unmodifiable(indexed);
}
