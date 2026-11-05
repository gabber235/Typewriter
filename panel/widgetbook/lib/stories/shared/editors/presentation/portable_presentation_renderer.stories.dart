import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Collections", type: PortablePresentationRenderer)
Widget collectionPresentationUseCase(BuildContext context) {
  final example = context.knobs.object.dropdown(
    label: "Collection example",
    options: CollectionEditorExample.values,
    labelBuilder: (value) => switch (value) {
      CollectionEditorExample.textList => "Text list",
      CollectionEditorExample.textSet => "Text set",
      CollectionEditorExample.scalarMap => "Scalar map",
      CollectionEditorExample.authoredSteps => "Authored step headers",
      CollectionEditorExample.fallbackSteps => "Generated step headers",
      CollectionEditorExample.structuredMap => "Structured map values",
      CollectionEditorExample.nestedLists => "Nested lists",
      CollectionEditorExample.unfinishedSteps => "Unfinished steps",
      CollectionEditorExample.directLinks => "Direct resource links",
    },
  );
  return Story(
    const [],
    at: PanelLocation.component(
      _Scrolling(
        width: context.knobs.double.slider(
          label: "Collection width",
          initialValue: 400,
          min: 320,
          max: 900,
        ),
        child: _CollectionPresentation(
          example: example,
          longTitles: context.knobs.boolean(label: "Long collection titles"),
          empty: context.knobs.boolean(label: "Empty collection"),
          readOnly: context.knobs.boolean(label: "Collection read only"),
          enabled: context.knobs.boolean(
            label: "Collection enabled",
            initialValue: true,
          ),
        ),
      ),
    ),
  );
}

class _CollectionPresentation extends HookWidget {
  const _CollectionPresentation({
    required this.example,
    required this.longTitles,
    required this.empty,
    required this.readOnly,
    required this.enabled,
  });

  final CollectionEditorExample example;
  final bool longTitles;
  final bool empty;
  final bool readOnly;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scenario = useMemoized(
      () => CollectionEditorScenario(
        example: example,
        longTitles: longTitles,
        empty: empty,
      ),
      [example, longTitles, empty],
    );
    useEffect(() => scenario.dispose, [scenario]);
    return CollectionEditorScenarioView(
      scenario: scenario,
      readOnly: readOnly,
      enabled: enabled,
    );
  }
}

@widgetbook.UseCase(
  name: "Inherited field presentation",
  type: PortablePresentationRenderer,
)
Widget inheritedFieldPresentationUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: "Name presentation",
    options: InheritedFieldVariant.values,
    labelBuilder: (value) => switch (value) {
      InheritedFieldVariant.inherited => "Inherited trim",
      InheritedFieldVariant.localLabel => "Local label with inherited trim",
      InheritedFieldVariant.explicitControl => "Explicit control",
      InheritedFieldVariant.disabled => "Disabled",
    },
  );
  return Story(
    const [],
    at: PanelLocation.component(
      _Scrolling(
        width: context.knobs.double.slider(
          label: "Editor width",
          initialValue: 640,
          min: 320,
          max: 900,
        ),
        child: _InheritedFieldPresentation(variant: variant),
      ),
    ),
  );
}

class _InheritedFieldPresentation extends HookWidget {
  const _InheritedFieldPresentation({required this.variant});

  final InheritedFieldVariant variant;

  @override
  Widget build(BuildContext context) {
    final scenario = useMemoized(
      () => InheritedFieldPresentationScenario(variant: variant),
      [variant],
    );
    useEffect(() => scenario.dispose, [scenario]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const Text("Quest action"),
        PortablePresentationRenderer(host: scenario.host),
      ],
    );
  }
}

@widgetbook.UseCase(
  name: "Inherited inspector layout",
  type: PortablePresentationRenderer,
)
Widget inheritedInspectorLayoutUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: "Inspector layout",
    options: InheritedInspectorLayoutVariant.values,
    labelBuilder: (value) => switch (value) {
      InheritedInspectorLayoutVariant.childOrder => "Child controls order",
      InheritedInspectorLayoutVariant.excludedHeading => "Excluded heading",
      InheritedInspectorLayoutVariant.replacedDetails => "Replaced details",
    },
  );
  return Story(
    const [],
    at: PanelLocation.component(
      _Scrolling(
        width: context.knobs.double.slider(
          label: "Inspector width",
          initialValue: 640,
          min: 320,
          max: 900,
        ),
        child: _InheritedInspectorLayout(variant: variant),
      ),
    ),
  );
}

class _InheritedInspectorLayout extends HookWidget {
  const _InheritedInspectorLayout({required this.variant});

  final InheritedInspectorLayoutVariant variant;

  @override
  Widget build(BuildContext context) {
    final scenario = useMemoized(
      () => InheritedInspectorLayoutScenario(variant: variant),
      [variant],
    );
    useEffect(() => scenario.dispose, [scenario]);
    return PortablePresentationRenderer(host: scenario.host);
  }
}

/// A quest form whose title is too short, showing where the renderer places
/// diagnostics for each severity, role and owner.
@widgetbook.UseCase(name: "Field validation", type: PortableDiagnosticFrame)
Widget portableFieldValidationUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    SizedBox(
      width: context.knobs.double.slider(
        label: "Diagnostic width",
        initialValue: 480,
        min: 320,
        max: 900,
      ),
      height: 520,
      child: _QuestFormDiagnostics(
        severity: context.knobs.object.dropdown(
          label: "Diagnostic severity",
          options: const [
            skir.DiagnosticSeverity.information,
            skir.DiagnosticSeverity.warning,
            skir.DiagnosticSeverity.error,
          ],
          initialOption: skir.DiagnosticSeverity.error,
          labelBuilder: (severity) => switch (severity) {
            skir.DiagnosticSeverity.information => "Information",
            skir.DiagnosticSeverity.warning => "Warning",
            _ => "Error",
          },
        ),
        role: context.knobs.object.dropdown(
          label: "Presentation role",
          options: const [
            skir.PresentationRole.inspector,
            skir.PresentationRole.workspace,
            skir.PresentationRole.resourceSearchResult,
          ],
          initialOption: skir.PresentationRole.inspector,
          labelBuilder: (role) => switch (role) {
            skir.PresentationRole.workspace => "Workspace",
            skir.PresentationRole.resourceSearchResult => "Search result",
            _ => "Inspector",
          },
        ),
        owner: context.knobs.object.dropdown(
          label: "Diagnostic owner",
          options: PortableDiagnosticFallback.values,
          initialOption: PortableDiagnosticFallback.presentation,
          labelBuilder: (owner) => owner.name,
        ),
        general: context.knobs.boolean(label: "General message"),
        readOnly: context.knobs.boolean(label: "Read only"),
        collapsed: context.knobs.boolean(label: "Collapsed header"),
      ),
    ),
  ),
);

class _QuestFormDiagnostics extends HookWidget {
  const _QuestFormDiagnostics({
    required this.severity,
    required this.role,
    required this.owner,
    required this.general,
    required this.readOnly,
    required this.collapsed,
  });

  final skir.DiagnosticSeverity severity;
  final skir.PresentationRole role;
  final PortableDiagnosticFallback owner;
  final bool general;
  final bool readOnly;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final host = useMemoized(
      () => _QuestFormHost(
        severity: severity,
        role: role,
        owner: owner,
        general: general,
        readOnly: readOnly,
        collapsed: collapsed,
      ),
      [severity, role, owner, general, readOnly, collapsed],
    );
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

/// Holds a quest title and its objective count, refusing titles shorter than
/// three characters the way a realm validator would.
class _QuestFormHost extends ChangeNotifier
    implements PortablePresentationHost {
  _QuestFormHost({
    required this.severity,
    required this.role,
    required this.owner,
    required this.general,
    required this.readOnly,
    required this.collapsed,
  }) {
    _diagnostics = [_shortTitle];
  }

  final skir.DiagnosticSeverity severity;
  final skir.PresentationRole role;
  final PortableDiagnosticFallback owner;
  final bool general;
  final bool collapsed;

  @override
  final bool readOnly;

  final Map<skir.ExpressionBindingId, skir.DataValue> _values = {
    _title: skir.DataValue.wrapStringValue("Go"),
    _objectives: skir.DataValue.wrapInteger("3"),
  };
  List<PortablePresentationDiagnostic> _diagnostics = const [];

  PortablePresentationDiagnostic get _shortTitle =>
      PortablePresentationDiagnostic(
        code: "quest_title",
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
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  bool get enabled => true;

  @override
  PortablePresentationDocument get document => PortablePresentationDocument(
    catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
    root: _questForm(expanded: !collapsed),
    bindings: {
      _title: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_textType),
        value: _values[_title]!,
        editable: true,
      ),
      _objectives: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_integerType),
        value: _values[_objectives]!,
        editable: true,
      ),
    },
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    role: role,
    diagnostics: _diagnostics,
    diagnosticFallback: owner,
  );

  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async => const PortablePresentationWriteResult.applied();

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => switch (reference.bindingId) {
    final value when value == _title => _textType,
    final value when value == _objectives => _integerType,
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
    if (reference.bindingId == _title) {
      if (value case skir.DataValue_stringValueWrapper(value: final text)
          when text.length < 3) {
        return PortablePresentationWriteResult.rejected([_shortTitle]);
      }
    }
    _values[reference.bindingId] = value;
    _diagnostics = const [];
    notifyListeners();
    return const PortablePresentationWriteResult.applied();
  }
}

final _title = skir.ExpressionBindingId(value: "title");
final _objectives = skir.ExpressionBindingId(value: "objectives");
final _textType = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _integerType = skir.TypeUse.wrapScalar(
  skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
);

skir.PresentationNode _questForm({required bool expanded}) =>
    skir.PresentationNode(
      nodeId: "quest",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.wrapChildren(
        skir.ChildrenElement.createColumn(
          children: [
            skir.AxisChild.wrapFixed(
              presentationNode(
                "title",
                skir.PresentationElement.createTextInput(
                  control: _control(_title, "Title"),
                  content:
                      (skir.InputContent.mutable()
                            ..placeholder = textLiteral("Find the lantern"))
                          .toFrozen(),
                  appearance: null,
                  entry: null,
                  mappings: null,
                  options: skir.TextEditingOptions.defaultInstance,
                ),
              ),
            ),
            skir.AxisChild.wrapFixed(
              presentationNode(
                "objectives",
                skir.PresentationElement.wrapNumericInput(
                  (skir.NumericControl.mutable()
                        ..control = _control(_objectives, "Objectives"))
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
        binding: skir.BindingRef(bindingId: _title, path: editorRootPath),
        title: skir.PresentationHeaderTitle.wrapText(textLiteral("Quest")),
        description: textLiteral("The Lost Village"),
        initiallyExpanded: expanded,
        items: const [],
        headerPadding: null,
        contentPadding: null,
      ),
    );

skir.BoundControl _control(skir.ExpressionBindingId binding, String label) =>
    skir.BoundControl(
      binding: skir.BindingRef(bindingId: binding, path: editorRootPath),
      label: textLiteral(label),
      description: null,
      prefix: null,
      semanticLabel: null,
    );

/// Scrolls [child] at [width], the way an inspector column holds a form.
class _Scrolling extends StatelessWidget {
  const _Scrolling({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(width: width, child: child),
    );
  }
}
