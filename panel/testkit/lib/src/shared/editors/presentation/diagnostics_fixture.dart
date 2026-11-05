import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";

/// An error diagnostic of code `invalid_value` on [targets].
PortablePresentationDiagnostic invalidValueDiagnostic(
  List<PortableDiagnosticTarget> targets, {
  String message = "The value is invalid",
}) => PortablePresentationDiagnostic(
  code: "invalid_value",
  message: message,
  severity: skir.DiagnosticSeverity.error,
  targets: targets,
);

/// A control in the diagnostic placement tree that observes the value
/// "current" at [target], below [parent].
PortableDiagnosticNode diagnosticControl(
  PortableDiagnosticTarget target, {
  Object? parent,
}) => PortableDiagnosticNode(
  kind: PortableDiagnosticNodeKind.control,
  parent: parent,
  observations: [
    PortableDiagnosticObservation(
      target: target,
      value: skir.DataValue.wrapStringValue("current"),
    ),
  ],
);

/// A header in the diagnostic placement tree that observes [target], below
/// [parent].
PortableDiagnosticNode diagnosticHeader(
  PortableDiagnosticTarget target, {
  Object? parent,
}) => diagnosticControl(
  target,
  parent: parent,
).copyWith(kind: PortableDiagnosticNodeKind.header);

/// A presentation host over one text field bound to [binding], holding
/// "Original value", whose writes answer [response] or a rejection that
/// marks the field invalid.
///
/// The document carries [diagnostics] placed by [diagnosticFallback];
/// [replaceGeneration] swaps in a catalog of another generation.
final class DiagnosedTextHost extends ChangeNotifier
    implements PortablePresentationHost {
  DiagnosedTextHost({
    String binding = "title",
    this.response,
    this.diagnostics = const [],
    this.diagnosticFallback = PortableDiagnosticFallback.presentation,
  }) : binding = skir.ExpressionBindingId(value: binding) {
    _delegate = _createDelegate("initial");
    _delegate.addListener(notifyListeners);
  }

  /// The binding the text field edits.
  final skir.ExpressionBindingId binding;

  /// What every write answers; null rejects it.
  final Future<PortablePresentationWriteResult>? response;
  final List<PortablePresentationDiagnostic> diagnostics;
  final PortableDiagnosticFallback diagnosticFallback;
  final source = ValueNotifier(
    skir.DataValue.wrapStringValue("Original value"),
  );
  late BoundPresentationHost _delegate;

  /// How many writes reached the host.
  int requests = 0;

  BoundPresentationHost _createDelegate(String generation) {
    final snapshot =
        (skir.EditorCatalog.defaultInstance.toMutable()
              ..generation = skir.CatalogGeneration(value: generation))
            .toFrozen();
    return BoundPresentationHost(
      catalog: CheckedEditorCatalog(snapshot),
      root: () => skir.PresentationNode(
        nodeId: "diagnostic.text",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: textInputElement(
          skir.BindingRef(bindingId: binding, path: editorRootPath),
        ),
      ),
      bindings: [
        BoundPresentationBinding(
          id: binding,
          use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          owner: source,
          read: (_) => source.value,
          write: (_, value) {
            requests++;
            return response ??
                PortablePresentationWriteResult.rejected([
                  invalidValueDiagnostic([
                    PortableDiagnosticTarget.binding(
                      skir.BindingRef(bindingId: binding, path: editorRootPath),
                    ),
                  ]),
                ]);
          },
        ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      role: skir.PresentationRole.inspector,
    );
  }

  /// Replaces the catalog with one of [generation], as a republish does.
  void replaceGeneration(String generation) {
    _delegate
      ..removeListener(notifyListeners)
      ..dispose();
    _delegate = _createDelegate(generation);
    _delegate.addListener(notifyListeners);
    notifyListeners();
  }

  @override
  PortablePresentationDocument get document {
    final source = _delegate.document;
    return PortablePresentationDocument(
      catalog: source.catalog,
      root: source.root,
      bindings: source.bindings,
      budget: source.budget,
      role: source.role,
      diagnostics: diagnostics,
      diagnosticFallback: diagnosticFallback,
    );
  }

  @override
  PortablePresentationCapabilities get capabilities => _delegate.capabilities;
  @override
  bool get enabled => _delegate.enabled;
  @override
  bool get readOnly => _delegate.readOnly;
  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _delegate.commitControl(reference, context: context);
  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _delegate.read(reference, context: context);
  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _delegate.location(reference, context: context);
  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _delegate.expectedType(reference, context: context);
  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) => _delegate.write(reference, value, context: context);
  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction action, {
    required PortableInvocationContext context,
  }) => _delegate.execute(action, context: context);
  @override
  void dispose() {
    _delegate
      ..removeListener(notifyListeners)
      ..dispose();
    source.dispose();
    super.dispose();
  }
}
