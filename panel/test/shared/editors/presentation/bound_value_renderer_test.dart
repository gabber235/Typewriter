import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("hides the binding id from a custom select editor", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        value: const StringValue("story"),
        presentation: PresentationNode(
          id: "select",
          element: SelectInputElement(
            control: const BoundControl(binding: _rootBinding),
            allowCustomValue: true,
            options: [
              SelectOption(
                id: "story",
                label: "Story".asStringLiteral,
                value: "story".asStringLiteral,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("0"), findsNothing);
    expect(find.byType(AdaptiveChoiceControl<DataValue>), findsOneWidget);
    expect(
      tester.widget<EditorTextField>(find.byType(EditorTextField)).text,
      "story",
    );
  });

  testWidgets("hides the binding id from a typed field editor", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        value: const StringValue("typed field value"),
        presentation: const PresentationNode(
          id: "typedField",
          element: TypedFieldElement(
            binding: _rootBinding,
            expectedType: StringType(),
          ),
        ),
      ),
    );

    expect(find.text("0"), findsNothing);
    expect(
      tester.widget<EditorTextField>(find.byType(EditorTextField)).text,
      "typed field value",
    );
  });

  testWidgets("hides the nominal type id from a named value editor", (
    tester,
  ) async {
    const namedType = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "widgetbook", name: "NamedValue"),
      revision: 1,
    );
    await tester.pumpTestApp(
      child: _renderer(
        type: const NamedType(namedType),
        value: const StringValue("custom:quest-value"),
        definitions: const [
          TypeDefinition(
            id: namedType,
            kind: NominalTypeKind.concrete,
            representation: StringType(),
          ),
        ],
        presentation: const PresentationNode(
          id: "namedInput",
          element: NamedInputElement(BoundControl(binding: _rootBinding)),
        ),
      ),
    );

    expect(find.text("Widgetbook::Named Value"), findsNothing);
    expect(
      tester.widget<EditorTextField>(find.byType(EditorTextField)).text,
      "custom:quest-value",
    );
  });

  testWidgets("numeric controls keep the default prefix without a custom one", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const IntegerType(width: IntegerWidth.signed32),
        value: IntegerValue(BigInt.from(12)),
        presentation: const PresentationNode(
          id: "numericInput",
          element: NumericInputElement(BoundControl(binding: _rootBinding)),
        ),
      ),
    );

    final field = tester.widget<ValidatedTextField<DataValue>>(
      find.byType(ValidatedTextField<DataValue>),
    );
    expect(field.icon, HeroiconsSolid.hashtag);
    expect(field.decoration?.prefixIcon, isNull);
  });

  testWidgets("custom numeric prefixes replace the default without a title", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const IntegerType(width: IntegerWidth.signed32),
        value: IntegerValue(BigInt.from(12)),
        presentation: PresentationNode(
          id: "numericInput",
          element: NumericInputElement(
            BoundControl(
              binding: _rootBinding,
              prefix: PresentationNode(
                id: "xPrefix",
                element: TextElement("X".asStringLiteral),
              ),
              semanticLabel: "X position".asStringLiteral,
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<ValidatedTextField<DataValue>>(
      find.byType(ValidatedTextField<DataValue>),
    );
    expect(find.text("X"), findsOneWidget);
    expect(field.decoration?.prefixIcon, isNotNull);
    expect(find.text("X position"), findsNothing);
  });

  testWidgets("custom text prefixes replace the default pencil", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        value: const StringValue("west"),
        presentation: PresentationNode(
          id: "textInput",
          element: TextInputElement(
            control: BoundControl(
              binding: _rootBinding,
              prefix: PresentationNode(
                id: "directionPrefix",
                element: TextElement("X".asStringLiteral),
              ),
              semanticLabel: "Horizontal direction".asStringLiteral,
            ),
            multiline: false,
          ),
        ),
      ),
    );

    final field = tester.widget<EditorTextField>(find.byType(EditorTextField));
    expect(field.prefix, isNotNull);
    expect(find.text("X"), findsOneWidget);
  });

  testWidgets("semantic labels name controls without visible titles", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpTestApp(
      child: _renderer(
        type: const IntegerType(width: IntegerWidth.signed32),
        value: IntegerValue(BigInt.from(3)),
        presentation: PresentationNode(
          id: "numericInput",
          element: NumericInputElement(
            BoundControl(
              binding: _rootBinding,
              prefix: PresentationNode(
                id: "yPrefix",
                element: TextElement("Y".asStringLiteral),
              ),
              semanticLabel: "Y position".asStringLiteral,
            ),
          ),
        ),
      ),
    );

    final numericNode = find.byKey(const ValueKey("numericInput"));
    final numericField = find.descendant(
      of: numericNode,
      matching: find.byType(ValidatedTextField<DataValue>),
    );
    final mergedControl = find.ancestor(
      of: numericField,
      matching: find.byType(MergeSemantics),
    );
    final data = tester.getSemantics(mergedControl.first).getSemanticsData();
    expect(data.label, "Y position");
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasAction(SemanticsAction.focus), isTrue);

    final editor = find.descendant(
      of: numericNode,
      matching: find.byWidgetPredicate(
        (widget) => widget is EditableText && !widget.readOnly,
      ),
    );
    expect(editor, findsOneWidget);
    await tester.tap(editor);
    await tester.pump();
    final editorData = tester.getSemantics(editor).getSemanticsData();
    expect(editorData.hasAction(SemanticsAction.setText), isTrue);
    expect(find.bySemanticsLabel(RegExp(r"^Y$")), findsNothing);
    semantics.dispose();
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

EditorProtocolRenderer _renderer({
  required DataValue value,
  required PresentationNode presentation,
  TypeExpression type = const StringType(),
  List<TypeDefinition> definitions = const [],
}) {
  const root = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "BoundValueRenderer"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
      ...definitions,
    ]),
    presentation: presentation,
  );
}
