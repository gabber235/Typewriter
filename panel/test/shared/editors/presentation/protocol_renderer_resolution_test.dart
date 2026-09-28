import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("substitutes generic presentation parameters", (tester) async {
    const presentationId = PresentationId(
      namespace: "test",
      name: "box.default",
    );
    final declaration = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Box"),
      revision: 1,
    );
    final exact = declaration.withArguments(const [StringType()]);
    final target = declaration.withArguments(const [ParameterType("T")]);

    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: exact,
          rootValue: const StringValue("value"),
        ),
        typeCatalog: receivedRealmCatalog([
          TypeDefinition(
            id: declaration,
            kind: NominalTypeKind.concrete,
            representation: const ParameterType("T"),
            parameters: const [TypeParameter(name: "T")],
            rolePresentations: const {
              PresentationRole.editor: RolePresentationStatus.ready(
                presentationId,
              ),
            },
          ),
        ]),
        presentations: [
          PresentationDefinition.single(
            id: presentationId,
            target: NamedType(target),
            root: const PresentationNode(
              id: "generic",
              element: TypedFieldElement(
                binding: _rootBinding,
                expectedType: ParameterType("T"),
              ),
            ),
          ),
        ],
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("value"), findsOneWidget);
  });

  testWidgets("localizes recursive default delegation", (tester) async {
    const id = PresentationId(namespace: "test", name: "recursive");
    final root = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Recursive"),
      revision: 1,
    );
    final node = const PresentationNode(
      id: "recursive",
      element: DefaultPresentationElement(
        binding: _rootBinding,
        presentationId: id,
      ),
    );

    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: root,
          rootValue: const StringValue("value"),
        ),
        typeCatalog: receivedRealmCatalog([
          TypeDefinition(
            id: root,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
            rolePresentations: const {
              PresentationRole.editor: RolePresentationStatus.ready(id),
            },
          ),
        ]),
        presentations: [
          PresentationDefinition.single(
            id: id,
            target: NamedType(root),
            root: node,
          ),
        ],
      ),
    );

    expect(find.text("Presentation delegation is recursive"), findsOneWidget);
  });

  testWidgets("renders independent map key and value presentations", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "map",
      element: MapInputElement(
        control: const BoundControl(binding: _rootBinding),
        keyPresentation: const PresentationNode(
          id: "key",
          element: TextInputElement(
            control: BoundControl(
              binding: BindingReference(bindingId: BindingId(1)),
            ),
            multiline: false,
          ),
        ),
        valuePresentation: const PresentationNode(
          id: "value",
          element: TextElement(
            TypedExpression(
              resultType: StringType(),
              expression: BindingExpression(
                BindingReference(bindingId: BindingId(2)),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const MapType(key: StringType(), value: StringType()),
        value: MapValue(const [
          DataMapEntry(
            key: StringValue("old key"),
            value: StringValue("rendered value"),
          ),
        ]),
        presentation: presentation,
      ),
    );

    await tester.tap(find.text("old key"));
    await tester.pumpAndSettle();
    expect(find.text("rendered value"), findsOneWidget);
    final keyField = find.byType(TextField);
    expect(tester.widget<TextField>(keyField).controller?.text, "old key");

    await tester.enterText(keyField, "new key");
    await tester.pumpAndSettle();

    final updatedKeyField = find.byType(TextField);
    expect(
      tester.widget<TextField>(updatedKeyField).controller?.text,
      "new key",
    );
    expect(
      tester.widget<TextField>(updatedKeyField).focusNode?.hasFocus,
      isTrue,
    );
    expect(find.text("rendered value"), findsOneWidget);
  });

  testWidgets(
    "uses the concrete default presentation inside a polymorphic input",
    (tester) async {
      const presentationId = PresentationId(
        namespace: "typewritermc:realm",
        name: "icon.iconify.editor",
      );
      await tester.pumpTestApp(
        child: EditorProtocolRenderer(
          envelope: TypedValueEnvelope(
            rootType: standardTypeRefs.icon,
            rootValue: PolymorphicValue(
              concreteType: standardTypeRefs.iconifyIcon,
              value: RecordValue({"value": const StringValue("mdi:account")}),
            ),
          ),
          typeCatalog: receivedRealmCatalog(),
          presentations: [_iconifySearchPresentation(presentationId)],
          presentation: PresentationNode(
            id: "icon",
            element: PolymorphicInputElement(
              control: const BoundControl(binding: _rootBinding),
              concreteTypes: [
                ConcreteTypePresentation(
                  type: standardTypeRefs.iconifyIcon,
                  label: "Iconify".asStringLiteral,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == "Activate search input",
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets("Iconify search edits a polymorphic creation draft", (
    tester,
  ) async {
    const presentationId = PresentationId(
      namespace: "typewritermc:realm",
      name: "icon.iconify.editor",
    );
    const book = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "test", name: "Book"),
      revision: 1,
    );
    final catalog = receivedRealmCatalog([
      TypeDefinition(
        id: book,
        kind: NominalTypeKind.concrete,
        representation: RecordType(
          fields: {
            "icon": TypeField(
              name: "icon",
              type: NamedType(standardTypeRefs.icon),
            ),
          },
        ),
      ),
    ]);
    final draft = CreationDraft.fromMaterialized(
      rootType: const NamedType(book),
      value: RecordValue({
        "icon": PolymorphicValue(
          concreteType: standardTypeRefs.iconifyIcon,
          value: RecordValue({"value": const StringValue("mdi:old")}),
        ),
      }),
      registry: TypeRegistry(catalog),
    );
    addTearDown(draft.dispose);
    expect(draft.polymorphicStructure(DataPath.root.field("icon")), isNotNull);

    final model = PresentationModel.editor(
      owner: draft,
      presentation: PresentationNode(
        id: "book.create",
        element: DefaultPresentationElement(
          binding: _rootBinding.at(DataPath.root.field("icon")),
        ),
      ),
      presentations: [_iconifySearchPresentation(presentationId)],
    );
    expect(
      selectAutomaticEditor(
        registry: TypeRegistry(model.catalog),
        type: NamedType(standardTypeRefs.iconifyIcon),
        presentations: model.presentations,
        access: PresentationInputAccess.edit,
      ).valueOrNull,
      isNotNull,
    );
    await tester.pumpTestApp(child: ComposedEditor(model: model));

    final searchActivation = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == "Activate search input",
    );
    expect(searchActivation, findsOneWidget);
    await tester.tap(searchActivation);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    expect(find.text("mdi:star"), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      draft.finalize().valueOrNull,
      RecordValue({
        "icon": PolymorphicValue(
          concreteType: standardTypeRefs.iconifyIcon,
          value: RecordValue({"value": const StringValue("mdi:star")}),
        ),
      }),
    );
  });

  testWidgets("declared editor missing from catalog shows a field error", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: standardTypeRefs.iconifyIcon,
          rootValue: RecordValue({"value": const StringValue("mdi:old")}),
        ),
        typeCatalog: receivedRealmCatalog(),
      ),
    );

    expect(find.textContaining("Declared editor"), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets("rejected Iconify editor shows its failure at the field", (
    tester,
  ) async {
    final base = receivedRealmCatalog();
    final iconify = base.definitions.singleWhere(
      (definition) => definition.id == standardTypeRefs.iconifyIcon,
    );
    final catalog = receivedRealmCatalog([
      iconify.copyWith(
        rolePresentations: const {
          PresentationRole.editor: RolePresentationStatus.rejected(
            "coreIconifyEditor: Kotlin reflection implementation is not found",
          ),
        },
      ),
    ]);

    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: standardTypeRefs.iconifyIcon,
          rootValue: RecordValue({
            "value": const StringValue("material-symbols:book"),
          }),
        ),
        typeCatalog: catalog,
      ),
    );

    expect(find.textContaining("coreIconifyEditor"), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets("Book creation keeps a rejected Iconify editor visible", (
    tester,
  ) async {
    const book = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "test", name: "BookWithIcon"),
      revision: 1,
    );
    final base = receivedRealmCatalog();
    final iconify = base.definitions.singleWhere(
      (definition) => definition.id == standardTypeRefs.iconifyIcon,
    );
    final catalog = receivedRealmCatalog([
      iconify.copyWith(
        rolePresentations: const {
          PresentationRole.editor: RolePresentationStatus.rejected(
            "coreIconifyEditor failed",
          ),
        },
      ),
      TypeDefinition(
        id: book,
        kind: NominalTypeKind.concrete,
        representation: RecordType(
          fields: {
            "icon": TypeField(
              name: "icon",
              type: NamedType(standardTypeRefs.icon),
            ),
          },
        ),
      ),
    ]);
    final draft = CreationDraft.fromMaterialized(
      rootType: const NamedType(book),
      value: RecordValue({
        "icon": PolymorphicValue(
          concreteType: standardTypeRefs.iconifyIcon,
          value: RecordValue({
            "value": const StringValue("material-symbols:book"),
          }),
        ),
      }),
      registry: TypeRegistry(catalog),
    );
    addTearDown(draft.dispose);

    await tester.pumpTestApp(
      child: ComposedEditor(
        model: PresentationModel.editor(
          owner: draft,
          presentation: PresentationNode(
            id: "book.create",
            element: DefaultPresentationElement(
              binding: _rootBinding.at(DataPath.root.field("icon")),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining("coreIconifyEditor failed"), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  test("automatic editor rejects a multi-input contract", () {
    const id = PresentationId(namespace: "test", name: "multi");
    final type = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Value"),
      revision: 1,
    );
    final registry = TypeRegistry(
      receivedRealmCatalog([
        TypeDefinition(
          id: type,
          kind: NominalTypeKind.concrete,
          representation: const StringType(),
          rolePresentations: const {
            PresentationRole.editor: RolePresentationStatus.ready(id),
          },
        ),
      ]),
    );
    final result = selectAutomaticEditor(
      registry: registry,
      type: NamedType(type),
      access: PresentationInputAccess.edit,
      presentations: [
        PresentationDefinition(
          id: id,
          inputs: [
            PresentationInputParameter(
              id: const BindingId(0),
              name: "first",
              type: NamedType(type),
            ),
            const PresentationInputParameter(
              id: BindingId(1),
              name: "second",
              type: StringType(),
            ),
          ],
          root: const PresentationNode(id: "multi", element: DividerElement()),
        ),
      ],
    );
    expect(result, isA<TypeFailure<PresentationDefinition?>>());
    expect(
      result.diagnostics.single.code,
      TypeDiagnosticCode.invalidPresentation,
    );
  });

  test("editable value without a declared editor uses generated fields", () {
    final catalog = receivedRealmCatalog();
    final iconify = catalog.definitions.singleWhere(
      (definition) => definition.id == standardTypeRefs.iconifyIcon,
    );
    final registry = TypeRegistry(
      receivedRealmCatalog([iconify.copyWith(rolePresentations: const {})]),
    );

    final result = selectAutomaticEditor(
      registry: registry,
      type: NamedType(standardTypeRefs.iconifyIcon),
      access: PresentationInputAccess.edit,
      presentations: const [],
    );

    expect(result, isA<TypeSuccess<PresentationDefinition?>>());
    expect(result.valueOrNull, isNull);
  });

  test(
    "read-only values can use generated fields when an editor is absent",
    () {
      final result = selectAutomaticEditor(
        registry: TypeRegistry(receivedRealmCatalog()),
        type: NamedType(standardTypeRefs.iconifyIcon),
        presentations: const [],
        access: PresentationInputAccess.read,
      );
      expect(result, isA<TypeSuccess<PresentationDefinition?>>());
      expect(result.valueOrNull, isNull);
    },
  );

  testWidgets("nested list values keep declared editor errors visible", (
    tester,
  ) async {
    final type = ListType(element: NamedType(standardTypeRefs.iconifyIcon));
    await tester.pumpTestApp(
      child: _renderer(
        type: type,
        value: ListValue([
          RecordValue({"value": const StringValue("mdi:old")}),
        ]),
        presentation: type.generateDefaultPresentation(
          registry: TypeRegistry(receivedRealmCatalog()),
        ),
      ),
    );
    await tester.tap(find.text("Item 1"));
    await tester.pumpAndSettle();
    expect(find.textContaining("Declared editor"), findsOneWidget);
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

PresentationDefinition _iconifySearchPresentation(PresentationId id) {
  const identifier = TypedExpression(
    resultType: StringType(),
    expression: BindingExpression(BindingReference(bindingId: BindingId(12))),
  );
  return PresentationDefinition.single(
    id: id,
    target: NamedType(standardTypeRefs.iconifyIcon),
    root: PresentationNode(
      id: "iconify.search",
      element: SearchInputElement(
        control: const BoundControl(binding: _rootBinding),
        selectionMode: SearchSelectionMode.single,
        queryBindingId: const BindingId(10),
        summaryBindingId: const BindingId(11),
        maximumExtent: 260.0.asFloatLiteral,
        provider: SearchProvider.staticValues(
          values: const ListValue([StringValue("mdi:star")])
              .asLiteral(const ListType(element: StringType())),
          result: SearchResultMapping(
            bindingId: const BindingId(12),
            key: identifier,
            selectedValue: TypedExpression(
              resultType: NamedType(standardTypeRefs.iconifyIcon),
              expression: RecordExpression({"value": identifier}),
            ),
            presentation: const PresentationNode(
              id: "result",
              element: TextElement(identifier),
            ),
          ),
        ),
      ),
    ),
  );
}

EditorProtocolRenderer _renderer({
  required TypeExpression type,
  required DataValue value,
  required PresentationNode presentation,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "root"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: receivedRealmCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    presentation: presentation,
  );
}
