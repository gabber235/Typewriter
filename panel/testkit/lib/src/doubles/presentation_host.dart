import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A presentation host with no store behind it: it reads values from the
/// invocation's bindings, keeps every write and action it receives, and
/// answers as configured.
///
/// Reads give [value] when set; otherwise the binding the invocation carries,
/// or the one [document] declares, at the reference's path.
final class FakePresentationHost extends ChangeNotifier
    implements PortablePresentationHost {
  FakePresentationHost({
    PortablePresentationDocument? document,
    this.value,
    this.expected,
    this.types = const {},
    this.rejectWrites = false,
    this.updatesDocument = false,
    this.locates = false,
    this.writeGate,
    this.actionResult = const PortablePresentationWriteApplied(),
    this.onWrite,
    this.onWriteContext,
    this.onExecute,
  }) : _document = document ?? emptyDocument();

  /// A document over an empty catalog with no root and no bindings.
  static PortablePresentationDocument emptyDocument({
    CheckedEditorCatalog? catalog,
    Map<skir.ExpressionBindingId, PortablePresentationBinding> bindings =
        const {},
    skir.PresentationNode? root,
    skir.PresentationRole? role,
    List<PortablePresentationDiagnostic> diagnostics = const [],
  }) => PortablePresentationDocument(
    catalog:
        catalog ?? CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
    root: root ?? skir.PresentationNode.defaultInstance,
    bindings: bindings,
    budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    role: role,
    diagnostics: diagnostics,
  );

  PortablePresentationDocument _document;

  /// The one value every read gives, replaced by every applied write; null
  /// reads the invocation's bindings instead.
  skir.DataValue? value;

  /// The type every binding expects unless [types] names its reference.
  final skir.TypeUse? expected;

  /// The type expected at each reference that differs from [expected].
  final Map<skir.BindingRef, skir.TypeUse> types;

  /// Whether every write is refused with a `rejected_write` diagnostic.
  final bool rejectWrites;

  /// Whether an applied write replaces the value of the document binding it
  /// targets, so later renders see it.
  final bool updatesDocument;

  /// Whether locations extend the location of the invocation's binding by
  /// the reference's path; otherwise no value has a location.
  final bool locates;

  /// Holds every write until it completes; a rejection it completes with is
  /// the write's answer.
  final Completer<PortablePresentationWriteResult>? writeGate;

  /// What every action answers.
  final PortablePresentationWriteResult actionResult;

  /// Called with every write once it is applied.
  final void Function(skir.BindingRef reference, skir.DataValue value)? onWrite;

  /// Called with every write and its invocation context once it is applied.
  final void Function(
    skir.BindingRef reference,
    skir.DataValue value,
    PortableInvocationContext context,
  )?
  onWriteContext;

  /// Called with every action as it arrives.
  final void Function(skir.EditorAction action)? onExecute;

  /// Every write received, applied or not, in order.
  final writes = <(skir.BindingRef, skir.DataValue)>[];

  /// The invocation context of every write, in order.
  final writeContexts = <PortableInvocationContext>[];

  /// Every action received, in order.
  final actions = <skir.EditorAction>[];

  @override
  PortablePresentationDocument get document => _document;

  /// Replaces the document and tells listeners.
  set document(PortablePresentationDocument next) {
    _document = next;
    notifyListeners();
  }

  @override
  bool get enabled => true;

  @override
  bool get readOnly => false;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => types[reference] ?? expected;

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (!locates) return null;
    final base = context.bindings[reference.bindingId]?.location;
    if (base == null) return null;
    return skir.ValueLocation(
      resource: base.resource,
      path: skir.ValuePath(
        segments: [...base.path.segments, ...reference.path.segments],
      ),
    );
  }

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (value case final held?) return held;
    final root =
        context.bindings[reference.bindingId]?.value ??
        _document.bindings[reference.bindingId]?.value;
    if (root == null || reference.path.segments.isEmpty) return root;
    return switch (root.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    writes.add((reference, value));
    writeContexts.add(context);
    if (rejectWrites) {
      return PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "rejected_write",
          message: "The document rejected this write",
          severity: skir.DiagnosticSeverity.error,
        ),
      ]);
    }
    if (writeGate case final gate?) {
      final result = await gate.future;
      if (result is PortablePresentationWriteRejected) return result;
    }
    if (this.value != null) this.value = value;
    onWrite?.call(reference, value);
    onWriteContext?.call(reference, value, context);
    final current = _document.bindings[reference.bindingId];
    if (updatesDocument && current != null) {
      _document = PortablePresentationDocument(
        catalog: _document.catalog,
        root: _document.root,
        bindings: {
          ..._document.bindings,
          reference.bindingId: current.copyWith(value: value),
        },
        budget: _document.budget,
        role: _document.role,
        material: _document.material,
        diagnostics: _document.diagnostics,
        activePresentations: _document.activePresentations,
        slots: _document.slots,
      );
    }
    notifyListeners();
    return const PortablePresentationWriteApplied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction action, {
    required PortableInvocationContext context,
  }) async {
    actions.add(action);
    onExecute?.call(action);
    return actionResult;
  }
}

/// A host that shows [root] over [bindings], expects writes of [expected]
/// and applies each write to its document, refusing every one when
/// [rejectWrites].
FakePresentationHost documentHost(
  skir.PresentationNode root, {
  required Map<skir.ExpressionBindingId, PortablePresentationBinding> bindings,
  skir.TypeUse? expected,
  bool rejectWrites = false,
}) => FakePresentationHost(
  document: FakePresentationHost.emptyDocument(root: root, bindings: bindings),
  expected: expected,
  updatesDocument: true,
  rejectWrites: rejectWrites,
);
