import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "renders a nested named payload and preserves its actual type on write",
    (tester) async {
      skir.BindingRef? writtenReference;
      skir.DataValue? writtenValue;
      final presentationHost = _NamedTestHost(
        onWrite: (reference, value) {
          writtenReference = reference;
          writtenValue = value;
        },
      );
      addTearDown(presentationHost.dispose);

      Widget host(bool visible) => testApp(
        child: Scaffold(
          body: PortablePresentationNodeRenderer(
            node: _rootPresentation(),
            scope: PortablePresentationScope(
              bindings: _bindings(visible),
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
              host: presentationHost,
            ),
          ),
        ),
      );

      await tester.pumpWidget(host(true));
      expect(find.text("Custom style"), findsOneWidget);
      expect(find.text("Original"), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey("style.title.input")),
        "Changed",
      );
      await tester.pump();

      expect(writtenReference, _styleReference);
      final named = writtenValue! as skir.DataValue_namedWrapper;
      expect(named.value.actualType, _styleType);
      expect(
        named.value.payload.authoredField("title")?.authoredString,
        "Changed",
      );

      await tester.pumpWidget(host(false));
      await tester.pump();
      expect(find.text("Custom style"), findsNothing);
    },
  );

  testWidgets("disabled nodes reject keyboard edits", (tester) async {
    var writes = 0;
    final presentationHost = _NamedTestHost(onWrite: (_, _) => writes++);
    addTearDown(presentationHost.dispose);
    final control =
        _control().payloadPresentation!.element!
            as skir.PresentationElement_childrenWrapper;
    final children = control.value as skir.ChildrenElement_columnWrapper;
    final title =
        (children.value.children.last as skir.AxisChild_fixedWrapper).value;
    final disabled = skir.PresentationNode(
      nodeId: title.nodeId,
      properties: skir.PresentationProperties(
        enabledIf: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapBoolean(false),
        ),
        readOnly: false,
      ),
      element: title.element,
      header: null,
    );
    await tester.pumpWidget(
      testApp(
        child: Scaffold(
          body: PortablePresentationNodeRenderer(
            node: disabled,
            scope: PortablePresentationScope(
              bindings: {
                skir.ExpressionBindingId(
                  value: "configured_value",
                ): PortableExpressionBinding(
                  value: skir.DataValue.createRecord(
                    fields: [
                      skir.FieldValue(
                        name: "title",
                        value: skir.DataValue.wrapStringValue("Original"),
                      ),
                    ],
                  ),
                ),
              },
              budget: skir.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
              host: presentationHost,
            ),
          ),
        ),
      ),
    );

    final field = find.byType(TextFormField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextFormField>(field).enabled, isFalse);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.focusNode.requestFocus();
    await tester.pump();
    expect(editable.focusNode.hasFocus, isFalse);
    await tester.enterText(field, "Changed");
    await tester.pump();
    expect(writes, 0);
  });
}

final _rootBinding = skir.ExpressionBindingId(value: "element");
final _styleReference = skir.BindingRef(
  bindingId: _rootBinding,
  path: _fieldPath("style"),
);
final _styleType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.wrapQualified(
      skir.QualifiedTypeId(namespace: "example", name: "MessageStyle"),
    ),
    revision: 1,
  ),
  arguments: const [],
);

Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings(
  bool visible,
) => {
  _rootBinding: PortableExpressionBinding(
    value: skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "style",
          value: skir.DataValue.createNamed(
            actualType: _styleType,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "visible",
                  value: skir.DataValue.wrapBoolean(visible),
                ),
                skir.FieldValue(
                  name: "title",
                  value: skir.DataValue.wrapStringValue("Original"),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    location: skir.ValueLocation(
      resource: skir.ResourceId(value: "element:message"),
      path: skir.ValuePath(segments: const []),
    ),
  ),
};

skir.NamedControl _control() => skir.NamedControl(
  control: skir.BoundControl(
    binding: _styleReference,
    label: null,
    description: null,
    prefix: null,
    semanticLabel: null,
  ),
  payloadPresentation: skir.PresentationNode(
    nodeId: "style.custom",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        children: [
          skir.AxisChild.wrapFixed(
            skir.PresentationNode(
              nodeId: "style.conditional",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.createConditional(
                condition: skir.ExpressionNode.createRead(
                  binding: skir.ExpressionBindingId(value: "configured_value"),
                  path: _fieldPath("visible"),
                ),
                whenTrue: skir.PresentationNode(
                  nodeId: "style.visible",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: skir.PresentationElement.createText(
                    value: skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapStringValue("Custom style"),
                    ),
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
                  header: null,
                ),
                whenFalse: null,
              ),
              header: null,
            ),
          ),
          skir.AxisChild.wrapFixed(
            skir.PresentationNode(
              nodeId: "style.title",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.createTextInput(
                control: skir.BoundControl(
                  binding: skir.BindingRef(
                    bindingId: skir.ExpressionBindingId(
                      value: "configured_value",
                    ),
                    path: _fieldPath("title"),
                  ),
                  label: null,
                  description: null,
                  prefix: null,
                  semanticLabel: null,
                ),
                multiline: false,
                placeholder: null,
                inputFormatters: const [],
              ),
              header: null,
            ),
          ),
        ],
        layout: skir.AxisChildrenLayout(
          spacing: 8,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
      ),
    ),
    header: null,
  ),
);

skir.PresentationNode _rootPresentation() => skir.PresentationNode(
  nodeId: "style.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapNamedInput(_control()),
  header: null,
);

skir.ValuePath _fieldPath(String name) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]);

final class _NamedTestHost extends ChangeNotifier
    implements PortablePresentationHost {
  _NamedTestHost({required this.onWrite});

  final void Function(skir.BindingRef reference, skir.DataValue value) onWrite;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  PortablePresentationDocument get document => PortablePresentationDocument(
    catalog: skir.EditorCatalogWireSnapshot.defaultInstance
        .asTrustedLocalCatalog(),
    root: skir.PresentationNode.defaultInstance,
    bindings: const {},
    budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
  );

  @override
  bool get enabled => true;

  @override
  bool get readOnly => false;

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async => const PortablePresentationWriteApplied();

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => reference == _styleReference
      ? skir.TypeUse.wrapNamed(_styleType)
      : skir.TypeUse.wrapScalar(skir.ScalarKind.text);

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
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
    final root = context.bindings[reference.bindingId]?.value;
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
    onWrite(reference, value);
    return const PortablePresentationWriteApplied();
  }
}
