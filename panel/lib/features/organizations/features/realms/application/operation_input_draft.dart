import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns transient operation input independently of resource drafts.
/// Changes invalidate submitted input and never publish a resource edit.
final class OperationInputDraft extends ChangeNotifier {
  OperationInputDraft({
    required this.catalog,
    required this.type,
    required this._value,
  });

  final CheckedEditorCatalog catalog;
  final skir.TypeUse type;
  skir.DataValue _value;
  int _revision = 0;
  bool _disposed = false;

  skir.DataValue get value => _value;
  int get revision => _revision;
  bool get disposed => _disposed;

  skir.DataValue? read(skir.ValuePath path) => switch (_value.readAt(path)) {
    PortablePathValue(:final value) => value,
    PortablePathUnavailable() => null,
  };

  PortablePresentationWriteResult write(
    skir.ValuePath path,
    skir.DataValue next,
  ) {
    if (_disposed) return _reject("The operation input is closed");
    final replaced = _value.replaceAt(path, next);
    if (replaced case PortablePathUnavailable(:final message)) {
      return _reject(message);
    }
    final value = (replaced as PortablePathValue<skir.DataValue>).value;
    if (!catalog.admitsPortableValue(type, value)) {
      return _reject("The operation input does not match its declared type");
    }
    if (value != _value) {
      _value = value;
      _revision++;
      notifyListeners();
    }
    return const PortablePresentationWriteApplied();
  }

  /// Accepts normalization only for the input that produced this response.
  bool normalize(skir.DataValue value, {required int submittedRevision}) {
    if (_disposed || submittedRevision != _revision) return false;
    if (!catalog.admitsPortableValue(type, value)) {
      throw StateError("The normalized operation input has an invalid type");
    }
    if (_value != value) {
      _value = value;
      _revision++;
      notifyListeners();
    }
    return true;
  }

  /// The dialog disposes the returned host before disposing this draft.
  BoundPresentationHost createHost({
    skir.PresentationId? presentation,
    PortablePresentationCapabilities capabilities =
        const PortablePresentationCapabilities(),
  }) => BoundPresentationHost(
    catalog: catalog,
    capabilities: capabilities,
    root: () => skir.PresentationNode(
      nodeId: "operation.input",
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.createDefaultPresentation(
        control: skir.BoundControl(
          label: null,
          description: null,
          prefix: null,
          semanticLabel: null,
          binding: skir.BindingRef(
            bindingId: configuredValueBindingId,
            path: editorRootPath,
          ),
        ),
        presentationId: presentation,
      ),
    ),
    bindings: [
      BoundPresentationBinding(
        id: configuredValueBindingId,
        use: type,
        read: read,
        write: write,
        owner: this,
      ),
    ],
    budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
  );

  PortablePresentationWriteResult _reject(String message) =>
      PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "operation_input_rejected",
          message: message,
          severity: skir.DiagnosticSeverity.error,
        ),
      ]);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
