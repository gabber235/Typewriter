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

final class PortablePresentationGallery extends StatefulWidget {
  const PortablePresentationGallery({super.key});

  @override
  State<PortablePresentationGallery> createState() =>
      _PortablePresentationGalleryState();
}

final class _PortablePresentationGalleryState
    extends State<PortablePresentationGallery> {
  final _PortableGalleryHost _host = _PortableGalleryHost();

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PortablePresentationRenderer(host: _host);
}

final class _PortableGalleryHost extends ChangeNotifier
    implements PortablePresentationHost {
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
    skir.EditorAction editorAction,
  ) async => const PortablePresentationWriteResult.rejected(
    "This gallery action has no persistence owner",
  );

  @override
  skir.TypeUse? expectedType(skir.BindingRef reference) =>
      switch (reference.bindingId) {
        final value when value == _title => _textType,
        final value when value == _count => _integerType,
        _ => null,
      };

  @override
  skir.ValueLocation? location(skir.BindingRef reference) => null;

  @override
  skir.DataValue? read(skir.BindingRef reference) =>
      reference.path.segments.isEmpty ? _values[reference.bindingId] : null;

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value,
  ) async {
    if (reference.path.segments.isNotEmpty ||
        !_values.containsKey(reference.bindingId)) {
      return const PortablePresentationWriteResult.rejected(
        "The gallery binding is unavailable",
      );
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
              multiline: false,
              placeholder: _literal("Quest objective"),
              inputFormatters: const [],
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "count",
            skir.PresentationElement.wrapNumericInput(
              _control(_count, "Count"),
            ),
          ),
        ),
      ],
      layout: skir.AxisChildrenLayout(
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
