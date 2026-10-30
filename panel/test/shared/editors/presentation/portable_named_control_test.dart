import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "renders a nested named payload and writes its authored field path",
    (tester) async {
      skir.BindingRef? writtenReference;
      skir.DataValue? writtenValue;
      final presentationHost = FakePresentationHost(
        onWrite: (reference, value) {
          writtenReference = reference;
          writtenValue = value;
        },
        expected: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        types: {_styleReference: skir.TypeUse.wrapNamed(_styleType)},
        locates: true,
      );
      addTearDown(presentationHost.dispose);

      final operations = testPortableOperations();
      Widget host(bool visible) => PortablePresentationNodeRenderer(
        node: _rootPresentation,
        scope: PortablePresentationScope(
          operations: operations,
          bindings: {
            _rootBinding: PortableExpressionBinding(
              value: recordEditorValue({
                "style": namedRecordOf(_styleType, {
                  "visible": skir.DataValue.wrapBoolean(visible),
                  "title": skir.DataValue.wrapStringValue("Original"),
                }),
              }),
              location: skir.ValueLocation(
                resource: skir.ResourceId(value: "element:message"),
                path: skir.ValuePath(segments: const []),
              ),
            ),
          },
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          host: presentationHost,
        ),
      );

      final panel = await tester.showComponent(host(true));
      expect(panel.shows("Custom style"), isTrue);
      expect(visibleFieldValues(), ["Original"]);

      await panel.fieldAt(0).type("Changed");

      expect(writtenReference?.bindingId, _rootBinding);
      expect(writtenReference?.path.segments, [
        skir.PathSegment.createField(name: "style"),
        skir.PathSegment.createField(name: "title"),
      ]);
      expect(writtenValue, skir.DataValue.wrapStringValue("Changed"));

      await tester.showComponent(host(false));
      expect(panel.shows("Custom style"), isFalse);
    },
  );

  testWidgets("disabled nodes reject keyboard edits", (tester) async {
    var writes = 0;
    final presentationHost = FakePresentationHost(
      onWrite: (_, _) => writes++,
      expected: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      types: {_styleReference: skir.TypeUse.wrapNamed(_styleType)},
      locates: true,
    );
    addTearDown(presentationHost.dispose);
    final control =
        _control.payloadPresentation!.element!
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
    final panel = await tester.showComponent(
      PortablePresentationNodeRenderer(
        node: disabled,
        scope: PortablePresentationScope(
          operations: testPortableOperations(),
          bindings: {
            _rootBinding: PortableExpressionBinding(
              value: recordEditorValue({
                "style": namedRecordOf(_styleType, {
                  "visible": skir.DataValue.wrapBoolean(true),
                  "title": skir.DataValue.wrapStringValue("Original"),
                }),
              }),
              location: skir.ValueLocation(
                resource: skir.ResourceId(value: "element:message"),
                path: skir.ValuePath(segments: const []),
              ),
            ),
          },
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          host: presentationHost,
        ),
      ),
    );

    final field = panel.fieldAt(0);
    expect(field.isEnabled, isFalse);
    await field.focus();
    expect(field.isFocused, isFalse);
    await panel.press(LogicalKeyboardKey.keyC);
    expect(writes, 0);
  });
}

final _rootBinding = skir.ExpressionBindingId(value: "element");
final _styleReference = skir.BindingRef(
  bindingId: _rootBinding,
  path: editorRootPath.field("style"),
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

final _control = skir.NamedControl(
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
                condition: skir.ExpressionNode.createInput(
                  binding: _rootBinding,
                  path: skir.ValuePath(
                    segments: [
                      skir.PathSegment.createField(name: "style"),
                      skir.PathSegment.createField(name: "visible"),
                    ],
                  ),
                ),
                whenTrue: skir.PresentationNode(
                  nodeId: "style.visible",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: textElement(
                    skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapStringValue("Custom style"),
                    ),
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
              element: textInputElement(
                skir.BindingRef(
                  bindingId: _rootBinding,
                  path: skir.ValuePath(
                    segments: [
                      skir.PathSegment.createField(name: "style"),
                      skir.PathSegment.createField(name: "title"),
                    ],
                  ),
                ),
              ),
              header: null,
            ),
          ),
        ],
        layout: skir.AxisChildrenLayout(
          clipOverflow: false,

          spacing: 8,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
      ),
    ),
    header: null,
  ),
  appearance: null,
  content: null,
);

final _rootPresentation = skir.PresentationNode(
  nodeId: "style.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapNamedInput(_control),
  header: null,
);
