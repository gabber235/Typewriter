import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Portable document",
  type: PortablePresentationRenderer,
)
Widget portablePresentationRendererUseCase(BuildContext context) {
  return FakeApp(
    child: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: context.knobs.double.slider(
              label: "Editor width",
              initialValue: 640,
              min: 320,
              max: 900,
            ),
            child: const PortablePresentationGallery(),
          ),
        ),
      ),
    ),
  );
}

final class PortablePresentationGallery extends HookWidget {
  const PortablePresentationGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final host = useMemoized(_PortableGalleryHost.new);
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

class _PortableGalleryHost extends ChangeNotifier
    implements PortablePresentationHost {
  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;
  final Map<skir.ExpressionBindingId, skir.DataValue> _values = {
    _title: skir.DataValue.wrapStringValue("Quest objective"),
    _count: skir.DataValue.wrapInteger("3"),
  };

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  PortablePresentationDocument get document => PortablePresentationDocument(
    catalog: CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot.defaultInstance,
    ),
    root: _root,
    bindings: {
      _title: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_textType),
        value: _values[_title]!,
        editable: true,
      ),
      _count: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_integerType),
        value: _values[_count]!,
        editable: true,
      ),
    },
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
  );

  @override
  bool get enabled => true;

  @override
  bool get readOnly => false;

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async => PortablePresentationWriteResult.rejected([
    PortablePresentationDiagnostic(
      code: "gallery_action",
      message: "This gallery action has no persistence owner",
      severity: skir.DiagnosticSeverity.error,
    ),
  ]);

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => switch (reference.bindingId) {
    final value when value == _title => _textType,
    final value when value == _count => _integerType,
    _ => null,
  };

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => reference.path.segments.isEmpty ? _values[reference.bindingId] : null;

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    if (reference.path.segments.isNotEmpty ||
        !_values.containsKey(reference.bindingId)) {
      return PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "gallery_binding",
          message: "The gallery binding is unavailable",
          severity: skir.DiagnosticSeverity.error,
        ),
      ]);
    }
    _values[reference.bindingId] = value;
    notifyListeners();
    return const PortablePresentationWriteResult.applied();
  }
}

final _title = skir.ExpressionBindingId(value: "title");
final _count = skir.ExpressionBindingId(value: "count");
final _textType = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _integerType = skir.TypeUse.wrapScalar(
  skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
);
final _root = skir.PresentationNode(
  nodeId: "portable.gallery",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [
        skir.AxisChild.wrapFixed(
          _node(
            "title",
            skir.PresentationElement.createTextInput(
              control: _control(_title, "Title"),
              content:
                  (skir.InputContent.mutable()
                        ..placeholder = _literal("Quest objective"))
                      .toFrozen(),
              appearance: null,
              entry: null,
              mappings: null,
              options: skir.TextEditingOptions.defaultInstance,
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "count",
            skir.PresentationElement.wrapNumericInput(
              (skir.NumericControl.mutable()
                    ..control = _control(_count, "Count"))
                  .toFrozen(),
            ),
          ),
        ),
      ],
      layout: skir.AxisChildrenLayout(
        clipOverflow: false,

        spacing: 16,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.stretch,
      ),
    ),
  ),
  header: skir.PresentationHeader(
    binding: skir.BindingRef(
      bindingId: _title,
      path: skir.ValuePath(segments: const []),
    ),
    title: skir.PresentationHeaderTitle.wrapText(
      _literal("Portable presentation host"),
    ),
    description: _literal("Bindings keep persistence outside the renderer"),
    initiallyExpanded: true,
    items: const [],
    headerPadding: null,
    contentPadding: null,
  ),
);

skir.PresentationNode _node(String id, skir.PresentationElement element) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      element: element,
      header: null,
    );

skir.BoundControl _control(skir.ExpressionBindingId binding, String label) =>
    skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: binding,
        path: skir.ValuePath(segments: const []),
      ),
      label: _literal(label),
      description: null,
      prefix: null,
      semanticLabel: null,
    );

skir.ExpressionNode _literal(String value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));
// Add alongside the existing portable renderer stories.
@widgetbook.UseCase(name: "Field validation", type: PortableDiagnosticFrame)
Widget portableFieldValidationUseCase(BuildContext context) =>
    context.diagnosticStory();

@widgetbook.UseCase(
  name: "Descendant summary",
  type: PortableDiagnosticHeaderMarker,
)
Widget portableHeaderDiagnosticsUseCase(BuildContext context) =>
    context.diagnosticStory();

@widgetbook.UseCase(name: "Inline messages", type: PortableDiagnosticMessages)
Widget portableDiagnosticMessagesUseCase(BuildContext context) =>
    context.diagnosticStory();

@widgetbook.UseCase(name: "General feedback", type: PortablePresentationChrome)
Widget portableGeneralDiagnosticsUseCase(BuildContext context) =>
    context.diagnosticStory(initiallyGeneral: true);

extension _PortableDiagnosticStoryContext on BuildContext {
  Widget diagnosticStory({bool initiallyGeneral = false}) => FakeApp(
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: knobs.double.slider(
            label: "Diagnostic width",
            initialValue: 480,
            min: 320,
            max: 900,
          ),
          height: 520,
          child: PortableDiagnosticGallery(
            severity: knobs.object.dropdown(
              label: "Diagnostic severity",
              options: [
                skir.DiagnosticSeverity.information,
                skir.DiagnosticSeverity.warning,
                skir.DiagnosticSeverity.error,
              ],
              initialOption: skir.DiagnosticSeverity.error,
            ),
            role: knobs.object.dropdown(
              label: "Presentation role",
              options: [
                skir.PresentationRole.inspector,
                skir.PresentationRole.editor,
                skir.PresentationRole.authoringResult,
              ],
              initialOption: skir.PresentationRole.inspector,
            ),
            diagnosticFallback: knobs.object.dropdown(
              label: "Diagnostic owner",
              options: PortableDiagnosticFallback.values,
              initialOption: PortableDiagnosticFallback.presentation,
            ),
            general: knobs.boolean(
              label: "General message",
              initialValue: initiallyGeneral,
            ),
            readOnly: knobs.boolean(label: "Read only", initialValue: false),
          ),
        ),
      ),
    ),
  );
}

class PortableDiagnosticGallery extends HookWidget {
  const PortableDiagnosticGallery({
    required this.severity,
    required this.role,
    required this.general,
    required this.readOnly,
    this.diagnosticFallback = PortableDiagnosticFallback.presentation,
    super.key,
  });
  final skir.DiagnosticSeverity severity;
  final skir.PresentationRole role;
  final bool general;
  final PortableDiagnosticFallback diagnosticFallback;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final host = useMemoized(
      () => _PortableDiagnosticGalleryHost(
        severity: severity,
        role: role,
        general: general,
        diagnosticFallback: diagnosticFallback,
        readOnly: readOnly,
      ),
      [severity, role, general, readOnly, diagnosticFallback],
    );
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

// Reuse the existing binding schemas, root header, and controls.
class _PortableDiagnosticGalleryHost extends _PortableGalleryHost {
  _PortableDiagnosticGalleryHost({
    required this.severity,
    required this.role,
    required this.general,
    required this.readOnly,
    this.diagnosticFallback = PortableDiagnosticFallback.presentation,
  }) {
    _values[_title] = skir.DataValue.wrapStringValue("ga");
    _diagnostics = [_titleDiagnostic];
  }
  final skir.DiagnosticSeverity severity;
  final skir.PresentationRole role;
  final bool general;
  final PortableDiagnosticFallback diagnosticFallback;
  @override
  final bool readOnly;
  List<PortablePresentationDiagnostic> _diagnostics = const [];

  PortablePresentationDiagnostic get _titleDiagnostic =>
      PortablePresentationDiagnostic(
        code: "gallery_title",
        message: "Use at least three characters",
        severity: severity,
        targets: general
            ? const []
            : [
                PortableDiagnosticTarget.binding(
                  skir.BindingRef(bindingId: _title, path: editorRootPath),
                ),
              ],
      );

  @override
  PortablePresentationDocument get document {
    final source = super.document;
    return PortablePresentationDocument(
      catalog: source.catalog,
      root: source.root,
      bindings: source.bindings,
      budget: source.budget,
      role: role,
      diagnostics: _diagnostics,
      diagnosticFallback: diagnosticFallback,
      material: source.material,
      activePresentations: source.activePresentations,
      slots: source.slots,
    );
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    if (reference.bindingId == _title && reference.path.segments.isEmpty) {
      if (value case skir.DataValue_stringValueWrapper(value: final text)
          when text.length < 3) {
        return PortablePresentationWriteResult.rejected([_titleDiagnostic]);
      }
    }
    _diagnostics = const [];
    return super.write(reference, value, context: context);
  }
}
