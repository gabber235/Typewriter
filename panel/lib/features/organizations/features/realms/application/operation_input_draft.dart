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
  ///
  /// Without a declared [presentation], fields named in [candidateSearches]
  /// get a search input backed by that capability, which offers the field's
  /// declared candidates; every other field gets its default control.
  BoundPresentationHost createHost({
    skir.PresentationId? presentation,
    Map<String, skir.CapabilityId> candidateSearches = const {},
    PortablePresentationCapabilities capabilities =
        const PortablePresentationCapabilities(),
  }) => BoundPresentationHost(
    catalog: catalog,
    capabilities: capabilities,
    root: () => presentation == null && candidateSearches.isNotEmpty
        ? _generatedForm(candidateSearches)
        : _node(
            "operation.input",
            skir.PresentationElement.createDefaultPresentation(
              control: _control(editorRootPath),
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

  /// One control per input field, in declaration order.
  skir.PresentationNode _generatedForm(
    Map<String, skir.CapabilityId> candidateSearches,
  ) {
    final named = catalog.namedUse(type);
    final fields = named == null
        ? const <AppliedEditorField>[]
        : catalog.fields(skir.TypeSelection.wrapComplete(named));
    return _node(
      "operation.input",
      skir.PresentationElement.wrapChildren(
        skir.ChildrenElement.createColumn(
          layout: skir.AxisChildrenLayout(
            spacing: 12,
            mainAxisAlignment: skir.MainAxisAlignment.start,
            crossAxisAlignment: skir.CrossAxisAlignment.stretch,
            clipOverflow: false,
          ),
          children: [
            for (final field in fields)
              skir.AxisChild.wrapFixed(switch (candidateSearches[field
                  .template
                  .key]) {
                final capability? => _candidateSearch(
                  field.template.key,
                  capability,
                ),
                null => _node(
                  "operation.input.${field.template.key}",
                  skir.PresentationElement.createDefaultPresentation(
                    control: _control(editorRootPath.field(field.template.key)),
                    presentationId: null,
                  ),
                ),
              }),
          ],
        ),
      ),
    );
  }

  /// A search over the declared candidates of [field]: each result is an
  /// operation resource option whose id fills the field.
  skir.PresentationNode _candidateSearch(
    String field,
    skir.CapabilityId capability,
  ) {
    final row = skir.ExpressionBindingId(value: "operation.input.$field.row");
    final id = skir.ExpressionNode.createInput(
      binding: row,
      path: editorRootPath.field("id"),
    );
    final label = skir.ExpressionNode.createInput(
      binding: row,
      path: editorRootPath.field("label"),
    );
    skir.ExpressionNode text(String value) =>
        skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));
    return _node(
      "operation.input.$field",
      skir.PresentationElement.createSearchInput(
        control: _control(editorRootPath.field(field)),
        selectionMode: skir.SearchSelectionMode.single,
        queryBindingId: skir.ExpressionBindingId(
          value: "operation.input.$field.query",
        ),
        summaryBindingId: skir.ExpressionBindingId(
          value: "operation.input.$field.summary",
        ),
        maximumExtent: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapFloat(320),
        ),
        provider: skir.SearchProvider.createRealmCallback(
          capabilityId: capability,
          payload: text(""),
          result: skir.SearchResultMapping(
            bindingId: row,
            key: id,
            selectedValue: id,
            label: label,
            presentation: _node(
              "operation.input.$field.result",
              skir.PresentationElement.createText(
                value: label,
                color: null,
                sizing: null,
                fontWeight: null,
                fontItalic: null,
                fontOpticalSize: null,
                fontSlant: null,
                fontWidth: null,
                textAlignment: null,
                lineHeight: null,
                letterSpacing: null,
                decoration: null,
                semanticLabel: null,
                paragraph: skir.TextParagraph.defaultInstance,
              ),
            ),
          ),
          selectors: const [],
        ),
        summary: null,
        placeholder: text("Search"),
        customValue: null,
        initialQuery: null,
        appearance: null,
        content: null,
        popup: null,
        popupSide: null,
        emptyText: text("No matching resources"),
        loadingText: text("Finding resources"),
        empty: null,
        loading: null,
      ),
    );
  }

  static skir.BoundControl _control(skir.ValuePath path) => skir.BoundControl(
    label: null,
    description: null,
    prefix: null,
    semanticLabel: null,
    binding: skir.BindingRef(bindingId: configuredValueBindingId, path: path),
  );

  static skir.PresentationNode _node(
    String id,
    skir.PresentationElement element,
  ) => skir.PresentationNode(
    nodeId: id,
    properties: skir.PresentationProperties.defaultInstance,
    header: null,
    element: element,
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
