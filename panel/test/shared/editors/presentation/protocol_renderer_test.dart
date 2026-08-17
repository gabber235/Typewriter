import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("renders expression backed text styling", (tester) async {
    const textColor = Color(0xFF967BFA);
    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: PresentationNode(
          id: "styledText",
          element: TextElement(
            "Styled text".asStringLiteral,
            color: textColor.asColorLiteral,
            fontSize: 22.asFloatLiteral,
            fontWeight: 575.5.asFloatLiteral,
            fontItalic: 0.65.asFloatLiteral,
            fontOpticalSize: 18.asFloatLiteral,
            fontSlant: (-8).asFloatLiteral,
            fontWidth: 112.5.asFloatLiteral,
            textAlignment: "center".asStringLiteral,
            lineHeight: 1.4.asFloatLiteral,
            letterSpacing: 1.5.asFloatLiteral,
            decoration: "underline".asStringLiteral,
            semanticLabel: "Styled example".asStringLiteral,
          ),
        ),
      ),
    );

    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(text.semanticsLabel, "Styled example");
    expect(text.textAlign, TextAlign.center);
    expect(text.style?.color, textColor);
    expect(text.style?.fontSize, 22);
    expect(text.style?.fontVariations, const [
      FontVariation.weight(575.5),
      FontVariation.italic(0.65),
      FontVariation.opticalSize(18),
      FontVariation.slant(-8),
      FontVariation.width(112.5),
    ]);
    expect(text.style?.height, 1.4);
    expect(text.style?.letterSpacing, 1.5);
    expect(text.style?.decoration, TextDecoration.underline);
  });

  testWidgets("updates expression backed text styling", (tester) async {
    const weightExpression = TypedExpression(
      resultType: IntegerType(width: IntegerWidth.signed64),
      expression: BindingExpression(_rootBinding),
    );
    await tester.pumpTestApp(
      child: _renderer(
        type: const IntegerType(width: IntegerWidth.signed64),
        value: IntegerValue(BigInt.from(350)),
        presentation: PresentationNode(
          id: "dynamicText",
          element: ColumnElement(
            children: [
              PresentationNode(
                id: "text",
                element: TextElement(
                  "Dynamic weight".asStringLiteral,
                  fontWeight: weightExpression,
                ),
              ),
              PresentationNode(
                id: "update",
                element: ButtonElement(
                  label: "Update weight".asStringLiteral,
                  action: EditorAction.local(
                    SetValueAction(
                      target: _rootBinding,
                      value: 650.asIntegerLiteral,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    SelectableText text() => tester.widget(find.byType(SelectableText));
    expect(text().style?.fontVariations, const [FontVariation.weight(350)]);

    await tester.tap(find.text("Update weight"));
    await tester.pump();

    expect(text().style?.fontVariations, const [FontVariation.weight(650)]);
  });

  testWidgets("diagnoses invalid text styling", (tester) async {
    final cases = [
      (
        TextElement("Invalid".asStringLiteral, fontWeight: 0.asFloatLiteral),
        "Font weight must be at least 1.0",
      ),
      (
        TextElement("Invalid".asStringLiteral, fontItalic: 1.1.asFloatLiteral),
        "Font italic must be at most 1.0",
      ),
      (
        TextElement(
          "Invalid".asStringLiteral,
          fontOpticalSize: 0.asFloatLiteral,
        ),
        "Font optical size must be greater than 0.0",
      ),
      (
        TextElement("Invalid".asStringLiteral, fontSlant: 90.asFloatLiteral),
        "Font slant must be less than 90.0",
      ),
      (
        TextElement("Invalid".asStringLiteral, fontWidth: 0.asFloatLiteral),
        "Font width must be greater than 0.0",
      ),
    ];

    for (final (element, message) in cases) {
      await tester.pumpTestApp(
        child: _renderer(
          type: const UnitType(),
          value: const UnitValue(),
          presentation: PresentationNode(id: "invalidText", element: element),
        ),
      );

      expect(find.text(message), findsOneWidget);
    }
  });

  testWidgets("renders Markdown text with selection semantics", (tester) async {
    const markdown = "# Quest notes\n\nUse **clear objectives**.";

    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: PresentationNode(
          id: "markdown",
          element: MarkdownElement(markdown.asStringLiteral),
        ),
      ),
    );

    final semantics = tester.ensureSemantics();

    expect(find.text("Quest notes", findRichText: true), findsOneWidget);
    expect(
      find.text("Use clear objectives.", findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text("Quest notes", findRichText: true));
    await tester.pump();
    expect(
      tester
          .getSemantics(find.byType(EditableText).first)
          .getSemanticsData()
          .hasAction(SemanticsAction.setSelection),
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets("renders a chip using its entity color", (tester) async {
    const entityColor = Color(0xFF967BFA);
    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: PresentationNode(
          id: "chip",
          element: ChipElement(
            label: "Adventure".asStringLiteral,
            color: TypedExpression(
              resultType: NamedType(standardTypeRefs.color),
              expression: LiteralExpression(
                IntegerValue(BigInt.from(0xFF967BFA)),
              ),
            ),
          ),
        ),
      ),
    );

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(find.text("Adventure"), findsOneWidget);
    expect(chip.side, const BorderSide(color: entityColor));
    expect(chip.backgroundColor, entityColor.withValues(alpha: 0.18));
  });

  testWidgets("selecting an option updates its bound value", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("one"),
        presentation: PresentationNode(
          id: "selectRoot",
          element: ColumnElement(
            children: [
              PresentationNode(
                id: "select",
                element: SelectInputElement(
                  control: const BoundControl(binding: _rootBinding),
                  options: [
                    SelectOption(
                      id: "one",
                      label: "One".asStringLiteral,
                      value: "one".asStringLiteral,
                    ),
                    SelectOption(
                      id: "two",
                      label: "Two".asStringLiteral,
                      value: "two".asStringLiteral,
                    ),
                  ],
                ),
              ),
              const PresentationNode(
                id: "value",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: BindingExpression(_rootBinding),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("one"), findsOneWidget);

    await tester.tap(find.text("Two"));
    await tester.pump();

    expect(find.text("two"), findsOneWidget);
    expect(find.text("one"), findsNothing);
  });

  testWidgets("switching a polymorphic type changes its visible content", (
    tester,
  ) async {
    await tester.pumpTestApp(child: _polymorphicRenderer());

    expect(find.text("Dog content"), findsOneWidget);
    expect(find.text("Cat content"), findsNothing);

    await tester.tap(find.text("Cat"));
    await tester.pumpAndSettle();

    expect(find.text("Dog content"), findsNothing);
    expect(find.text("Cat content"), findsOneWidget);
  });

  testWidgets("executes local actions and refreshes bound content", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          PresentationNode(
            id: "value",
            element: TextElement(
              const TypedExpression(
                resultType: StringType(),
                expression: BindingExpression(_rootBinding),
              ),
            ),
          ),
          PresentationNode(
            id: "set",
            element: ButtonElement(
              label: "Set value".asStringLiteral,
              action: EditorAction.local(
                SetValueAction(
                  target: _rootBinding,
                  value: "after".asStringLiteral,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("before"),
        presentation: presentation,
      ),
    );
    expect(find.text("before"), findsOneWidget);

    await tester.tap(find.text("Set value"));
    await tester.pump();

    expect(find.text("after"), findsOneWidget);
    expect(find.text("before"), findsNothing);
  });

  testWidgets("keeps valid siblings when one control is invalid", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          PresentationNode(
            id: "valid",
            element: TextElement("Still available".asStringLiteral),
          ),
          const PresentationNode(
            id: "invalid",
            element: NumericInputElement(BoundControl(binding: _rootBinding)),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("text"),
        presentation: presentation,
      ),
    );

    expect(find.text("Still available"), findsOneWidget);
    expect(
      find.text("Control does not accept its binding type"),
      findsOneWidget,
    );
  });

  testWidgets("renders declared repeated empty content", (tester) async {
    const source = TypedExpression(
      resultType: ListType(element: StringType()),
      expression: BindingExpression(_rootBinding),
    );
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([]),
        presentation: PresentationNode(
          id: "repeated",
          element: RepeatedElement(
            source: source,
            itemBindingId: const BindingId(1),
            presentation: SequencePresentation(
              item: PresentationNode(
                id: "item",
                element: TextElement("Item".asStringLiteral),
              ),
              empty: PresentationNode(
                id: "empty",
                element: TextElement("Custom empty content".asStringLiteral),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text("Custom empty content"), findsOneWidget);
    expect(find.text("No items found"), findsNothing);
  });

  testWidgets("renders repeated items with declared separators", (
    tester,
  ) async {
    const source = TypedExpression(
      resultType: ListType(element: StringType()),
      expression: BindingExpression(_rootBinding),
    );
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([StringValue("One"), StringValue("Two")]),
        presentation: const PresentationNode(
          id: "repeated",
          element: RepeatedElement(
            source: source,
            itemBindingId: BindingId(1),
            presentation: SequencePresentation(
              item: PresentationNode(
                id: "item",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: BindingExpression(
                      BindingReference(bindingId: BindingId(1)),
                    ),
                  ),
                ),
              ),
              separator: PresentationNode(
                id: "separator",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: LiteralExpression(StringValue(">")),
                  ),
                ),
              ),
              layout: PresentationChildrenLayout.wrap(
                spacing: 4,
                runSpacing: 8,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text("One"), findsOneWidget);
    expect(find.text("Two"), findsOneWidget);
    expect(find.text(">"), findsOneWidget);
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.spacing, 4);
    expect(wrap.runSpacing, 8);
  });

  testWidgets("uses conditional content and read only local actions", (
    tester,
  ) async {
    final action = EditorAction.local(
      SetValueAction(target: _rootBinding, value: "changed".asStringLiteral),
    );
    final presentation = PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          const PresentationNode(
            id: "conditional",
            element: ConditionalElement(
              condition: TypedExpression(
                resultType: BooleanType(),
                expression: LiteralExpression(BooleanValue(false)),
              ),
              whenTrue: PresentationNode(
                id: "hidden",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: LiteralExpression(StringValue("Hidden")),
                  ),
                ),
              ),
            ),
          ),
          PresentationNode(
            id: "readonly",
            element: ButtonElement(
              label: "Read only".asStringLiteral,
              action: action,
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("value"),
        presentation: presentation,
        readOnly: true,
      ),
    );

    expect(find.text("Hidden"), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, "Read only"))
          .onPressed,
      isNull,
    );
  });

  testWidgets("dispatches realm reload independently of local edit state", (
    tester,
  ) async {
    var reloads = 0;
    final presentation = PresentationNode(
      id: "root",
      element: ButtonElement(
        label: "Reload realm".asStringLiteral,
        action: const EditorAction.realm(ReloadRealmAction()),
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: presentation,
        readOnly: true,
        onRealmAction: (action) {
          if (action is ReloadRealmAction) reloads++;
          return const MutationSuccess(revision: 0, value: UnitValue());
        },
      ),
    );

    await tester.tap(find.text("Reload realm"));
    await tester.pump();

    expect(reloads, 1);
  });

  testWidgets("rejects a realm callback with an invalid typed payload", (
    tester,
  ) async {
    var calls = 0;
    const actionId = RealmActionId(namespace: "test", name: "callback");
    final payloadType = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Payload"),
      revision: 1,
    );
    final root = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Root"),
      revision: 1,
    );

    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: root,
          rootValue: const UnitValue(),
        ),
        typeCatalog: TypeCatalog([
          TypeDefinition(
            id: root,
            kind: NominalTypeKind.concrete,
            representation: const UnitType(),
          ),
          TypeDefinition(
            id: payloadType,
            kind: NominalTypeKind.concrete,
            representation: const BooleanType(),
          ),
        ]),
        realmActions: [
          RealmActionDefinition(id: actionId, payloadType: payloadType),
        ],
        presentation: PresentationNode(
          id: "callback",
          element: ButtonElement(
            label: "Invoke callback".asStringLiteral,
            action: EditorAction.realm(
              InvokeRealmCallbackAction(
                actionId: actionId,
                payload: "invalid".asStringLiteral,
              ),
            ),
          ),
        ),
        onRealmAction: (action) {
          calls++;
          return const MutationSuccess(revision: 0, value: UnitValue());
        },
      ),
    );

    await tester.tap(find.text("Invoke callback"));
    await tester.pump();

    expect(calls, 0);
    expect(find.textContaining("StringValue is not valid"), findsOneWidget);
  });

  testWidgets("metadata refresh preserves the active local draft", (
    tester,
  ) async {
    late StateSetter rebuild;
    var diagnostics = <TypeDiagnostic>[];
    const presentation = PresentationNode(
      id: "text",
      element: TextInputElement(
        control: BoundControl(binding: _rootBinding),
        multiline: false,
      ),
    );
    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return _renderer(
            type: const StringType(),
            value: const StringValue("Before"),
            presentation: presentation,
            diagnostics: diagnostics,
          );
        },
      ),
    );

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.enterText(field, "Draft");
    await tester.pump();

    rebuild(() {
      diagnostics = [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Metadata changed",
        ),
      ];
    });
    await tester.pump();

    expect(tester.widget<TextField>(field).controller?.text, "Draft");
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);
    expect(find.text("Metadata changed"), findsOneWidget);
  });
}

Widget _polymorphicRenderer() => EditorProtocolRenderer(
  envelope: TypedValueEnvelope(
    rootType: _polymorphicRootType,
    rootValue: RecordValue({
      "choice": PolymorphicValue(concreteType: _dogType, value: UnitValue()),
    }),
  ),
  typeCatalog: const TypeCatalog([
    TypeDefinition(
      id: _polymorphicRootType,
      kind: NominalTypeKind.concrete,
      representation: RecordType(
        fields: {
          "choice": TypeField(name: "choice", type: NamedType(_animalType)),
        },
      ),
    ),
    TypeDefinition(
      id: _animalType,
      kind: NominalTypeKind.openAbstract,
      representation: UnitType(),
    ),
    TypeDefinition(
      id: _dogType,
      kind: NominalTypeKind.concrete,
      parents: [_animalType],
      representation: UnitType(),
    ),
    TypeDefinition(
      id: _catType,
      kind: NominalTypeKind.concrete,
      parents: [_animalType],
      representation: UnitType(),
    ),
  ]),
  presentation: PresentationNode(
    id: "polymorphic",
    element: PolymorphicInputElement(
      control: const BoundControl(binding: _polymorphicBinding),
      concreteTypes: [
        ConcreteTypePresentation(
          type: _dogType,
          label: "Dog".asStringLiteral,
          presentation: PresentationNode(
            id: "dog",
            element: TextElement("Dog content".asStringLiteral),
          ),
        ),
        ConcreteTypePresentation(
          type: _catType,
          label: "Cat".asStringLiteral,
          presentation: PresentationNode(
            id: "cat",
            element: TextElement("Cat content".asStringLiteral),
          ),
        ),
      ],
    ),
  ),
);

const _rootBinding = BindingReference(bindingId: BindingId(0));
const _polymorphicBinding = BindingReference(
  bindingId: BindingId(0),
  path: DataPath([DataPathSegment.field("choice")]),
);
const _polymorphicRootType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: "PolymorphicRoot"),
  revision: 1,
);
const _animalType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: "Animal"),
  revision: 1,
);
const _dogType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: "Dog"),
  revision: 1,
);
const _catType = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: "Cat"),
  revision: 1,
);

EditorProtocolRenderer _renderer({
  required TypeExpression type,
  required DataValue value,
  required PresentationNode presentation,
  bool readOnly = false,
  List<TypeDiagnostic> diagnostics = const [],
  RealmActionExecutor? onRealmAction,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "root"),
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
    ]),
    presentation: presentation,
    diagnostics: diagnostics,
    readOnly: readOnly,
    onRealmAction: onRealmAction,
  );
}
