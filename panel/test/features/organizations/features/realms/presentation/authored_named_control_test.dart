import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "renders a nested named payload and preserves its actual type on write",
    (tester) async {
      binding.BindingRef? writtenReference;
      types.DataValue? writtenValue;

      Widget host(bool visible) => testApp(
        child: Scaffold(
          body: PortablePresentationNodeRenderer(
            node: _rootPresentation(),
            scope: PortablePresentationScope(
              bindings: _bindings(visible),
              budget: expression.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
              setBinding: (reference, value) {
                writtenReference = reference;
                writtenValue = value;
              },
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
      final named = writtenValue! as types.DataValue_namedWrapper;
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
    final control =
        _control().payloadPresentation!.element!
            as presentation.PresentationElement_childrenWrapper;
    final children =
        control.value as presentation.ChildrenElement_columnWrapper;
    final title =
        (children.value.children.last as presentation.AxisChild_fixedWrapper)
            .value;
    final disabled = presentation.PresentationNode(
      nodeId: title.nodeId,
      properties: presentation.PresentationProperties(
        enabledIf: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapBoolean(false),
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
                types.ExpressionBindingId(
                  value: "configured_value",
                ): PortableExpressionBinding(
                  value: types.DataValue.createRecord(
                    fields: [
                      types.FieldValue(
                        name: "title",
                        value: types.DataValue.wrapStringValue("Original"),
                      ),
                    ],
                  ),
                ),
              },
              budget: expression.EvaluationBudget(
                maxSteps: 100,
                maxCollectionItems: 100,
              ),
              setBinding: (_, _) => writes++,
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

final _rootBinding = types.ExpressionBindingId(value: "element");
final _styleReference = binding.BindingRef(
  bindingId: _rootBinding,
  path: _fieldPath("style"),
);
final _styleType = types.NamedTypeUse(
  definition: types.TypeDefinitionId(
    typeId: types.TypeId.wrapQualified(
      types.QualifiedTypeId(namespace: "example", name: "MessageStyle"),
    ),
    revision: 1,
  ),
  arguments: const [],
);

Map<types.ExpressionBindingId, PortableExpressionBinding> _bindings(
  bool visible,
) => {
  _rootBinding: PortableExpressionBinding(
    value: types.DataValue.createRecord(
      fields: [
        types.FieldValue(
          name: "style",
          value: types.DataValue.createNamed(
            actualType: _styleType,
            payload: types.DataValue.createRecord(
              fields: [
                types.FieldValue(
                  name: "visible",
                  value: types.DataValue.wrapBoolean(visible),
                ),
                types.FieldValue(
                  name: "title",
                  value: types.DataValue.wrapStringValue("Original"),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    location: types.ValueLocation(
      resource: types.ResourceId(value: "element:message"),
      path: types.ValuePath(segments: const []),
    ),
  ),
};

presentation.NamedControl _control() => presentation.NamedControl(
  control: presentation.BoundControl(
    binding: _styleReference,
    label: null,
    description: null,
    prefix: null,
    semanticLabel: null,
  ),
  payloadPresentation: presentation.PresentationNode(
    nodeId: "style.custom",
    properties: presentation.PresentationProperties.defaultInstance,
    element: presentation.PresentationElement.wrapChildren(
      presentation.ChildrenElement.createColumn(
        children: [
          presentation.AxisChild.wrapFixed(
            presentation.PresentationNode(
              nodeId: "style.conditional",
              properties: presentation.PresentationProperties.defaultInstance,
              element: presentation.PresentationElement.createConditional(
                condition: expression.ExpressionNode.createRead(
                  binding: types.ExpressionBindingId(value: "configured_value"),
                  path: _fieldPath("visible"),
                ),
                whenTrue: presentation.PresentationNode(
                  nodeId: "style.visible",
                  properties:
                      presentation.PresentationProperties.defaultInstance,
                  element: presentation.PresentationElement.createText(
                    value: expression.ExpressionNode.wrapLiteral(
                      types.DataValue.wrapStringValue("Custom style"),
                    ),
                    color: null,
                    fontSize: null,
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
                    paragraph: presentation.TextParagraph.defaultInstance,
                  ),
                  header: null,
                ),
                whenFalse: null,
              ),
              header: null,
            ),
          ),
          presentation.AxisChild.wrapFixed(
            presentation.PresentationNode(
              nodeId: "style.title",
              properties: presentation.PresentationProperties.defaultInstance,
              element: presentation.PresentationElement.createTextInput(
                control: presentation.BoundControl(
                  binding: binding.BindingRef(
                    bindingId: types.ExpressionBindingId(
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
        layout: presentation.AxisChildrenLayout(
          spacing: 8,
          mainAxisAlignment: presentation.MainAxisAlignment.start,
          crossAxisAlignment: presentation.CrossAxisAlignment.start,
        ),
      ),
    ),
    header: null,
  ),
);

presentation.PresentationNode _rootPresentation() =>
    presentation.PresentationNode(
      nodeId: "style.root",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.wrapNamedInput(_control()),
      header: null,
    );

types.ValuePath _fieldPath(String name) =>
    types.ValuePath(segments: [types.PathSegment.createField(name: name)]);
