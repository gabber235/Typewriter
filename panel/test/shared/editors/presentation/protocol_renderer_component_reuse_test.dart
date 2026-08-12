import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("renders text controls through DecoratedTextField", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("before"),
        presentation: const PresentationNode(
          id: "text",
          element: TextInputElement(
            control: BoundControl(binding: _rootBinding),
            multiline: true,
          ),
        ),
      ),
    );

    final field = tester.widget<DecoratedTextField>(
      find.byType(DecoratedTextField),
    );
    expect(field.minLines, 1);
    expect(field.maxLines, 8);
  });

  testWidgets("renders select adaptively and enum through Dropdown", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Column(
        children: [
          _renderer(
            type: const StringType(),
            value: const StringValue("one"),
            presentation: PresentationNode(
              id: "select",
              element: SelectInputElement(
                control: const BoundControl(binding: _rootBinding),
                options: [
                  SelectOption(
                    id: "one",
                    label: "One".asStringLiteral,
                    value: "one".asStringLiteral,
                  ),
                ],
              ),
            ),
          ),
          _renderer(
            type: const EnumType(
              valueType: StringType(),
              values: [StringValue("one")],
            ),
            value: const StringValue("one"),
            presentation: const PresentationNode(
              id: "enum",
              element: EnumInputElement(BoundControl(binding: _rootBinding)),
            ),
          ),
        ],
      ),
    );

    expect(find.byType(AdaptiveChoiceControl<DataValue>), findsOneWidget);
    expect(find.byType(Dropdown<DataValue>), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<DataValue>), findsNothing);
  });

  testWidgets("updates typed bindings through adaptive selection", (
    tester,
  ) async {
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

    tester
        .widget<AdaptiveChoiceControl<DataValue>>(
          find.byType(AdaptiveChoiceControl<DataValue>),
        )
        .onSelected(const StringValue("two"));
    await tester.pump();

    expect(find.text("two"), findsOneWidget);
  });

  testWidgets("moves tabs through the content sized page view", (tester) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: PresentationNode(
          id: "tabs",
          element: TabsElement(
            tabs: [
              TabItem(
                id: "one",
                label: "One".asStringLiteral,
                child: PresentationNode(
                  id: "first",
                  element: TextElement("First".asStringLiteral),
                ),
              ),
              TabItem(
                id: "two",
                label: "Two".asStringLiteral,
                child: PresentationNode(
                  id: "second",
                  element: TextElement("Second".asStringLiteral),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final choice = tester.widget<AdaptiveChoiceControl<String>>(
      find.byType(AdaptiveChoiceControl<String>),
    );
    final pages = tester.widget<ContentSizeTabBarView>(
      find.byType(ContentSizeTabBarView),
    );

    expect(choice.selected, "one");
    expect(pages.controller!.index, 0);

    choice.onSelected("two");
    await tester.pumpAndSettle();

    expect(pages.controller!.index, 1);
    expect(
      tester
          .widget<AdaptiveChoiceControl<String>>(
            find.byType(AdaptiveChoiceControl<String>),
          )
          .selected,
      "two",
    );
  });

  testWidgets("switches polymorphic content directionally", (tester) async {
    await tester.pumpTestApp(child: _polymorphicRenderer());

    expect(find.byType(DirectionalContentSwitcher), findsOneWidget);
    expect(
      tester
          .widget<DirectionalContentSwitcher>(
            find.byType(DirectionalContentSwitcher),
          )
          .index,
      0,
    );

    tester
        .widget<AdaptiveChoiceControl<ResolvedTypeRef>>(
          find.byType(AdaptiveChoiceControl<ResolvedTypeRef>),
        )
        .onSelected(_catType);
    await tester.pumpAndSettle();

    final switcher = tester.widget<DirectionalContentSwitcher>(
      find.byType(DirectionalContentSwitcher),
    );
    expect(switcher.index, 1);
    expect(switcher.child.key, const ValueKey(_catType));
  });

  testWidgets("uses panel icon and menu components for interactions", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: PresentationNode(
          id: "interactions",
          element: ColumnElement(
            children: [
              PresentationNode(
                id: "iconButton",
                element: IconButtonElement(
                  icon: TypedExpression(
                    resultType: NamedType(standardTypeRefs.icon),
                    expression: LiteralExpression(
                      const IconValue.svg(Fa6Solid.plus).typedValue,
                    ),
                  ),
                  semanticLabel: "Add".asStringLiteral,
                  action: const EditorAction.local(
                    SetValueAction(
                      target: _rootBinding,
                      value: TypedExpression(
                        resultType: UnitType(),
                        expression: LiteralExpression(UnitValue()),
                      ),
                    ),
                  ),
                ),
              ),
              PresentationNode(
                id: "menu",
                element: MenuElement(
                  label: "Options".asStringLiteral,
                  items: [
                    PresentationMenuItem(
                      id: "noop",
                      label: "No operation".asStringLiteral,
                      action: const EditorAction.local(
                        SetValueAction(
                          target: _rootBinding,
                          value: TypedExpression(
                            resultType: UnitType(),
                            expression: LiteralExpression(UnitValue()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Icones), findsOneWidget);
    expect(find.byType(ContextMenuRegion), findsOneWidget);
    expect(find.byType(PopupMenuButton<PresentationMenuItem>), findsNothing);
  });

  testWidgets("renders protocol sections through the panel Section", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: PresentationNode(
          id: "section",
          element: SectionElement(
            title: "General".asStringLiteral,
            description: "Details".asStringLiteral,
            child: PresentationNode(
              id: "content",
              element: TextElement("Content".asStringLiteral),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Section), findsOneWidget);
    expect(find.byType(PresentationHeaderChrome), findsOneWidget);
    expect(find.byType(SectionTitle), findsOneWidget);
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

Widget _renderer({
  required TypeExpression type,
  required DataValue value,
  required PresentationNode presentation,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "componentReuse"),
    revision: 1,
  );
  return SizedBox(
    width: 500,
    child: EditorProtocolRenderer(
      envelope: TypedValueEnvelope(rootType: root, rootValue: value),
      typeCatalog: TypeCatalog([
        TypeDefinition(
          id: root,
          kind: NominalTypeKind.concrete,
          representation: type,
        ),
      ]),
      presentation: presentation,
    ),
  );
}

Widget _polymorphicRenderer() => SizedBox(
  width: 500,
  child: EditorProtocolRenderer(
    envelope: TypedValueEnvelope(
      rootType: _polymorphicRootType,
      rootValue: RecordValue({
        "choice": PolymorphicValue(concreteType: _dogType, value: UnitValue()),
      }),
    ),
    typeCatalog: TypeCatalog([
      const TypeDefinition(
        id: _polymorphicRootType,
        kind: NominalTypeKind.concrete,
        representation: RecordType(
          fields: {
            "choice": TypeField(name: "choice", type: NamedType(_animalType)),
          },
        ),
      ),
      const TypeDefinition(
        id: _animalType,
        kind: NominalTypeKind.openAbstract,
        representation: UnitType(),
      ),
      const TypeDefinition(
        id: _dogType,
        kind: NominalTypeKind.concrete,
        parents: [_animalType],
        representation: UnitType(),
      ),
      const TypeDefinition(
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
  ),
);

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
