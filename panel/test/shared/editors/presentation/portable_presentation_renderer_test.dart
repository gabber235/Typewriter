import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "composite metadata prefix remains an independent interactive sibling",
    (tester) async {
      final semantics = tester.ensureSemantics();
      final prefix = presentationNode(
        "collection.prefix.action",
        skir.PresentationElement.createButton(
          label: textLiteral("Prefix insertion"),
          action: skir.EditorAction.wrapLocal(
            skir.LocalEditorAction.createAppendListItem(
              target: skir.BindingRef(
                bindingId: RendererWorkspace.bindingId,
                path: skir.ValuePath(
                  segments: [skir.PathSegment.createField(name: "items")],
                ),
              ),
              value: textLiteral("From prefix"),
            ),
          ),
          appearance: null,
          icon: null,
        ),
      );
      final fixture = authoredListInput(
        value: skir.DataValue.createListValue(items: const []),
        allowAdd: true,
        label: "Coordinates",
        prefix: prefix,
      );
      await tester.showComponent(fixture.widget);
      expect(find.text("Prefix insertion"), findsOneWidget);
      expect(find.text("Coordinates"), findsOneWidget);
      expect(find.tooltip("Add item"), findsOneWidget);
      expect(
        tester
            .getSemantics(find.widgetWithText(FilledButton, "Prefix insertion"))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      semantics.dispose();
      await tester.tap(find.text("Prefix insertion"));
      await tester.pumpAndSettle();
      final submitted = await fixture.document.submit(tester);
      expect(
        (submitted.intents.single as skir.EditIntent_insertWrapper)
            .value
            .item
            .value,
        skir.DataValue.wrapStringValue("From prefix"),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    "collection operations inherit group appearance and explicit operation density wins",
    (tester) async {
      final shared =
          (skir.InputAppearance.mutable()
                ..density = skir.ControlDensity.compact
                ..valueStyle = (skir.InputTextStyle.mutable()..weight = 600)
                    .toFrozen())
              .toFrozen();
      final inherited = authoredListInput(
        value: skir.DataValue.createListValue(items: const []),
        allowAdd: true,
        inputDefaults: shared,
      );
      await tester.showComponent(inherited.widget);
      final compact = tester.getSize(find.tooltip("Add item"));
      final local = authoredListInput(
        value: skir.DataValue.createListValue(items: const []),
        allowAdd: true,
        inputDefaults: shared,
        content:
            (skir.CollectionContent.mutable()
                  ..operationDensity = skir.ControlDensity.comfortable)
                .toFrozen(),
      );
      await tester.showComponent(local.widget);
      final comfortable = tester.getSize(find.tooltip("Add item"));
      expect(compact.height, lessThan(comfortable.height));
      expect(compact.width, lessThan(comfortable.width));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "configured empty content and add action keep the existing insertion owner",
    (tester) async {
      await tester.showComponent(
        authoredListInput(
          value: skir.DataValue.createListValue(items: const []),
          allowAdd: true,
        ).widget,
      );
      final standard = tester.getSize(find.tooltip("Add item"));
      final fixture = authoredListInput(
        value: skir.DataValue.createListValue(items: const []),
        allowAdd: true,
        content: skir.CollectionContent(
          addLabel: textLiteral("New coordinate"),
          empty: presentationText(
            "configured.empty",
            textLiteral("No coordinates"),
          ),
          operationDensity: skir.ControlDensity.compact,

          emptyText: null,
          addIcon: null,
          removeLabel: null,
          reorderIcon: null,
          removeIcon: null,
          chooseLabel: null,
          chooseIcon: null,
          unlinkLabel: null,
          unlinkIcon: null,
          operationTooltip: null,
          keyLabel: null,
          valueLabel: null,
        ),
      );
      await tester.showComponent(fixture.widget);
      expect(find.text("No coordinates"), findsOneWidget);
      expect(find.text("No items"), findsNothing);
      expect(find.tooltip("New coordinate"), findsOneWidget);
      expect(
        tester.getSize(find.tooltip("New coordinate")).height,
        lessThan(standard.height),
      );
      await tester.tap(find.tooltip("New coordinate"));
      await tester.pumpAndSettle();
      final submitted = await fixture.document.submit(tester);
      expect(submitted.intents, hasLength(1));
      expect(submitted.intents.single, isA<skir.EditIntent_insertWrapper>());
    },
  );

  testWidgets(
    "configured collection row spacing and removal affordances preserve item identity",
    (tester) async {
      final fixture = authoredListInput(
        value: skir.DataValue.createListValue(
          items: [
            skir.ListItem(
              id: skir.ItemId(value: "first"),
              value: skir.DataValue.wrapStringValue("First"),
            ),
            skir.ListItem(
              id: skir.ItemId(value: "second"),
              value: skir.DataValue.wrapStringValue("Second"),
            ),
          ],
        ),
        allowAdd: false,
        appearance: skir.CollectionAppearance(
          itemSpacing: 14,
          itemPadding: skir.PresentationInsets.wrapAll(4),

          itemBackground: null,
          itemForeground: null,
          itemBorder: null,
          itemRadius: null,
          itemTransition: null,
          itemShadows: const [],
          itemArrival: null,
          itemLeave: null,
        ),
        content: skir.CollectionContent(
          removeLabel: textLiteral("Remove coordinate"),
          removeIcon: presentationText(
            "configured.remove",
            textLiteral("Remove glyph"),
          ),

          emptyText: null,
          empty: null,
          addLabel: null,
          addIcon: null,
          reorderIcon: null,
          chooseLabel: null,
          chooseIcon: null,
          unlinkLabel: null,
          unlinkIcon: null,
          operationTooltip: null,
          operationDensity: null,
          keyLabel: null,
          valueLabel: null,
        ),
      );
      await tester.showComponent(fixture.widget);
      expect(find.tooltip("Remove coordinate"), findsNWidgets(2));
      expect(find.text("Remove glyph"), findsNWidgets(2));
      final cards = collectionRowSurfaces(tester, "Remove coordinate");
      expect(cards, hasLength(2));
      expect(cards[1].top - cards[0].bottom, closeTo(14, 0.01));
      final remove = find.tooltip("Remove coordinate").first;
      expect(tester.getSemantics(remove).isEnabled, isTrue);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(fixture.document.workspace.state.groups, isNotEmpty);
      final submitted = await fixture.document.submit(tester);
      expect(submitted.intents, hasLength(1));
      final removal = submitted.intents.single as skir.EditIntent_removeWrapper;
      expect(removal.value.item.value, "first");
    },
  );

  testWidgets(
    "configured link affordances retain checked resource choices and popup styling",
    (tester) async {
      final fixture = authoredLinkCollection(
        withPartialLinks: true,
        content: skir.CollectionContent(
          chooseLabel: textLiteral("Choose node"),
          unlinkLabel: textLiteral("Disconnect node"),

          emptyText: null,
          empty: null,
          addLabel: null,
          addIcon: null,
          removeLabel: null,
          reorderIcon: null,
          removeIcon: null,
          chooseIcon: null,
          unlinkIcon: null,
          operationTooltip: null,
          operationDensity: null,
          keyLabel: null,
          valueLabel: null,
        ),
        inputAppearance: skir.InputAppearance(
          density: skir.ControlDensity.compact,

          iconColor: null,
          iconSize: null,
          valueStyle: null,
          placeholderStyle: null,
          labelStyle: null,
          descriptionStyle: null,
          alignment: null,
          padding: null,
          fill: null,
          border: null,
          radius: null,
        ),
        inputContent: skir.InputContent(
          placeholder: textLiteral("Select destination"),
          leading: skir.InputAdornment.none,

          suffix: null,
        ),
        popup: skir.PopupAppearance(
          maximumWidth: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapFloat(480),
          ),
          padding: skir.PresentationInsets.wrapAll(6),

          minimumWidth: null,
          maximumExtent: null,
          fill: null,
          border: null,
          radius: null,
        ),
      );
      final panel = await tester.showComponent(fixture.widget);
      expect(find.tooltip("Disconnect node"), findsOneWidget);
      expect(find.tooltip("Choose node"), findsNWidgets(2));
      expect(find.text("Select destination"), findsOneWidget);
      await panel.tapOn(find.tooltip("Choose node").last);
      expect(panel.queryBar.isFocused, isTrue);
      expect(find.text("Select destination"), findsNWidgets(2));
      expect(find.byIcon(Icons.search_rounded), findsNothing);
      expect(panel.queryBar.rect.width, lessThanOrEqualTo(480));
      expect(panel.queryBar.rect.width, greaterThan(400));
      expect(tester.takeException(), isNull);
    },
  );
  for (final family in ["typed", "nullable"]) {
    testWidgets(
      "compiled SDK $family body preserves source ownership on write",
      (tester) async {
        final layout = family == "typed"
            ? compiledSdkTypedLayout
            : compiledSdkNullableLayout;
        final value = family == "typed"
            ? compiledSdkTypedValue
            : compiledSdkNullableValue;
        final binding = family == "typed"
            ? _configuredBindingId
            : skir.ExpressionBindingId(value: "map_value");
        final writes = <(skir.BindingRef, skir.DataValue)>[];
        final host = FakePresentationHost(
          document: FakePresentationHost.emptyDocument(
            catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
          ),
          expected: family == "typed"
              ? skir.TypeUse.wrapScalar(skir.ScalarKind.text)
              : _integerType,
          onWrite: (reference, changed) => writes.add((reference, changed)),
        );
        addTearDown(host.dispose);
        final scope = PortablePresentationScope(
          operations: testPortableOperations(),
          bindings: {binding: PortableExpressionBinding(value: value)},
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          host: host,
        );
        final panel = await tester.showComponent(
          Material(
            child: PortablePresentationNodeRenderer(node: layout, scope: scope),
          ),
        );
        expect(visibleFieldValues(), [
          if (family == "typed") "Authored title" else "42",
        ]);
        await panel.fieldAt(0).type(family == "typed" ? "Changed title" : "43");
        expect(writes, hasLength(1));
        expect(writes.single.$1.bindingId, binding);
        expect(
          writes.single.$1.path.segments,
          family == "typed"
              ? [skir.PathSegment.createField(name: "title")]
              : isEmpty,
        );
        expect(
          writes.single.$2,
          family == "typed"
              ? skir.DataValue.wrapStringValue("Changed title")
              : skir.DataValue.wrapInteger("43"),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final (initial, field, expected, typed) in [
    (
      "Authored code",
      "code",
      skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      "Changed code",
    ),
    ("7", "position", _integerType, "9"),
  ]) {
    testWidgets(
      "compiled SDK $field body retains its lexical source and write path",
      (tester) async {
        final value = compiledSdkCompositeValue;
        final writes = <(skir.BindingRef, skir.DataValue)>[];
        final host = FakePresentationHost(
          document: FakePresentationHost.emptyDocument(
            catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
          ),
          expected: expected,
          onWrite: (reference, changed) => writes.add((reference, changed)),
        );
        addTearDown(host.dispose);
        final scope = PortablePresentationScope(
          operations: testPortableOperations(),
          bindings: {
            _configuredBindingId: PortableExpressionBinding(
              value: value,
              location: skir.ValueLocation(
                resource: RendererWorkspace.resource,
                path: skir.ValuePath(segments: const []),
              ),
            ),
          },
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          host: host,
        );
        final panel = await tester.showComponent(
          Material(
            child: SingleChildScrollView(
              child: PortablePresentationNodeRenderer(
                node: compiledSdkCompositeLayout,
                scope: scope,
              ),
            ),
          ),
        );
        expect(visibleFieldValues(), contains(initial));
        final input = panel.fieldAt(visibleFieldValues().indexOf(initial));
        await input.type(typed);
        expect(writes, hasLength(1));
        expect(writes.single.$1.bindingId, _configuredBindingId);
        expect(
          writes.single.$1.path.segments.first,
          skir.PathSegment.createField(name: field),
        );
        if (field == "position") {
          expect(
            writes.single.$1.path.segments.last,
            skir.PathSegment.createField(name: "x"),
          );
          expect(writes.single.$2, skir.DataValue.wrapInteger("9"));
        } else {
          expect(
            writes.single.$2.authoredActualType,
            value.authoredField("code")?.authoredActualType,
          );
          expect(writes.single.$2.authoredString, "Changed code");
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    "compiled nested remainder reserves authored x and renders only position y",
    (tester) async {
      final writes = <(skir.BindingRef, skir.DataValue)>[];
      skir.NamedTypeUse? writeOwner;
      final catalog = compiledSdkNestedRemainderCatalog.asTrustedLocalCatalog();
      final host = FakePresentationHost(
        document: FakePresentationHost.emptyDocument(catalog: catalog),
        expected: _integerType,
        onWrite: (reference, value) => writes.add((reference, value)),
        onWriteContext: (_, _, context) => writeOwner = context
            .bindings[_configuredBindingId]
            ?.value
            .authoredField("position")
            ?.authoredActualType,
      );
      addTearDown(host.dispose);
      final scope = PortablePresentationScope(
        operations: testPortableOperations(),
        catalog: catalog,
        bindings: {
          _configuredBindingId: PortableExpressionBinding(
            value: compiledSdkCompositeValue,
          ),
        },
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        host: host,
      );
      final panel = await tester.showComponent(
        Material(
          child: PortablePresentationNodeRenderer(
            node: compiledSdkNestedRemainderLayout,
            scope: scope,
          ),
        ),
      );
      expect(visibleFieldValues(), ["7", "8"]);
      expect(find.text("y"), findsOneWidget);
      expect(find.text("code"), findsNothing);
      expect(find.text("Authored code"), findsNothing);
      await panel.field("y").type("10");
      expect(writes, hasLength(1));
      expect(writes.single.$2, skir.DataValue.wrapInteger("10"));
      expect(
        writeOwner,
        compiledSdkCompositeValue.authoredField("position")?.authoredActualType,
      );
      expect(writes.single.$1.path.segments, [
        skir.PathSegment.createField(name: "position"),
        skir.PathSegment.createField(name: "y"),
      ]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    "remaining fields reserve hidden nested authoring independent of order and keep manual omissions",
    (tester) async {
      final definition = skir.TypeDefinitionId(
        typeId: skir.TypeId.createQualified(
          namespace: "test",
          name: "Remainder",
        ),
        revision: 1,
      );
      final named = skir.NamedTypeUse(
        definition: definition,
        arguments: const [],
      );
      final integer = skir.TypeTemplate.wrapScalar(
        skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
      );
      const names = ["X", "Y", "Z", "W"];
      final fields = [
        for (final name in names)
          skir.FieldDeclaration(
            owner: skir.FieldOwner(definition: definition, name: name),
            type: integer,
            overrides: const [],
            hasConstructorDefault: false,
          ),
      ];
      final published = publishedType(
        definition,
        representation: skir.RepresentationTemplate.createRecord(
          form: skir.RecordForm.concrete,
          fields: fields,
        ),
        fields: [
          for (final field in fields)
            skir.EffectiveFieldTemplate(
              key: field.owner.name,
              owner: field.owner,
              type: field.type,
              rules: const [],
            ),
        ],
      );
      final catalog =
          (skir.EditorCatalog.mutable()
                ..generation = skir.CatalogGeneration(value: "remainder proof")
                ..types = [published])
              .toFrozen()
              .asTrustedLocalCatalog();
      final root = skir.DataValue.createNamed(
        actualType: named,
        payload: skir.DataValue.createRecord(
          fields: [
            for (final (index, name) in names.indexed)
              skir.FieldValue(
                name: name,
                value: skir.DataValue.wrapInteger((index + 1).toString()),
              ),
          ],
        ),
      );
      final writes = <(skir.BindingRef, skir.DataValue)>[];
      final host = FakePresentationHost(
        document: FakePresentationHost.emptyDocument(catalog: catalog),
        expected: _integerType,
        onWrite: (reference, value) => writes.add((reference, value)),
      );
      addTearDown(host.dispose);
      skir.PresentationNode field(String name) => presentationNode(
        "authored.$name",
        skir.PresentationElement.wrapNumericInput(
          (skir.NumericControl.mutable()
                ..control = skir.BoundControl(
                  binding: skir.BindingRef(
                    bindingId: _configuredBindingId,
                    path: skir.ValuePath(
                      segments: [skir.PathSegment.createField(name: name)],
                    ),
                  ),
                  label: skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapStringValue(name),
                  ),
                  description: null,
                  prefix: null,
                  semanticLabel: null,
                )
                ..content =
                    (skir.InputContent.mutable()
                          ..placeholder = skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapStringValue("$name editor"),
                          ))
                        .toFrozen())
              .toFrozen(),
        ),
      );
      final remaining = presentationNode(
        "remaining",
        skir.PresentationElement.wrapRemainingFields(
          skir.RemainingFieldsElement(
            excluded: [
              skir.RelativeFieldPattern(
                segments: [skir.FieldPatternSegment.createField(name: "Z")],
              ),
            ],
            excludedParts: const [],
          ),
        ),
      );
      final hidden = presentationNode(
        "hidden.X",
        skir.PresentationElement.wrapConditional(
          (skir.ConditionalElement.mutable()
                ..condition = skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapBoolean(false),
                )
                ..whenTrue = field("X"))
              .toFrozen(),
        ),
      );
      final row = presentationNode(
        "authored.row",
        skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createRow(
            children: [
              skir.AxisChild.wrapFixed(hidden),
              skir.AxisChild.createFlexible(
                child: field("Y"),
                flex: 1,
                fit: skir.FlexFit.tight,
              ),
            ],
            layout: skir.AxisChildrenLayout(
              clipOverflow: false,

              spacing: 8,
              mainAxisAlignment: skir.MainAxisAlignment.start,
              crossAxisAlignment: skir.CrossAxisAlignment.center,
            ),
          ),
        ),
      );
      final layout = presentationNode(
        "record",
        skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createColumn(
            children: [
              skir.AxisChild.wrapFixed(remaining),
              skir.AxisChild.wrapFixed(row),
            ],
            layout: skir.AxisChildrenLayout(
              clipOverflow: false,

              spacing: 8,
              mainAxisAlignment: skir.MainAxisAlignment.start,
              crossAxisAlignment: skir.CrossAxisAlignment.stretch,
            ),
          ),
        ),
      );
      final scope = PortablePresentationScope(
        operations: testPortableOperations(),
        catalog: catalog,
        bindings: {
          _configuredBindingId: PortableExpressionBinding(
            value: root,
            schema: PortablePresentationBindingSchema.complete(
              skir.TypeUse.wrapNamed(named),
            ),
          ),
        },
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        host: host,
      );
      final panel = await tester.showComponent(
        Material(
          child: PortablePresentationNodeRenderer(node: layout, scope: scope),
        ),
      );
      expect(find.text("X"), findsNothing);
      expect(find.text("Z"), findsNothing);
      expect(find.text("Y"), findsOneWidget);
      expect(find.text("W"), findsOneWidget);
      expect(visibleFieldValues(), ["4", "2"]);
      await panel.field("Y").type("9");
      await panel.field("W").type("10");
      expect(
        writes.any(
          (write) =>
              write.$1.path.segments.single ==
                  skir.PathSegment.createField(name: "Y") &&
              write.$2 == skir.DataValue.wrapInteger("9"),
        ),
        isTrue,
      );
      expect(
        writes.any(
          (write) =>
              write.$1.path.segments.single ==
                  skir.PathSegment.createField(name: "W") &&
              write.$2 == skir.DataValue.wrapInteger("10"),
        ),
        isTrue,
      );
      expect(
        writes.every((write) => write.$1.bindingId == _configuredBindingId),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets("scope keeps rendering inputs the caller mutates afterwards", (
    tester,
  ) async {
    final bindingId = skir.ExpressionBindingId(value: "retained");
    final bindings = <skir.ExpressionBindingId, PortableExpressionBinding>{
      bindingId: PortableExpressionBinding(
        value: skir.DataValue.wrapStringValue("Original value"),
      ),
    };
    final slots = <String, skir.PresentationNode>{
      "authored": presentationText(
        "retained.authored",
        textLiteral("Authored slot"),
      ),
    };
    final slotBuilders = <String, PortableSlotBuilder>{
      "built": (_) => const Text("Built slot"),
    };
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: bindings,
      budget: skir.EvaluationBudget(maxSteps: 10, maxCollectionItems: 10),
      slots: slots,
      slotBuilders: slotBuilders,
    );
    final node = presentationColumn("retained", [
      presentationText("retained.value", inputExpression(bindingId)),
      presentationNode(
        "retained.authored.slot",
        skir.PresentationElement.createSlot(slotId: "authored"),
      ),
      presentationNode(
        "retained.built.slot",
        skir.PresentationElement.createSlot(slotId: "built"),
      ),
    ]);
    Widget render() => Material(
      child: PortablePresentationNodeRenderer(node: node, scope: scope),
    );

    var panel = await tester.showComponent(render());
    expect(panel.shows("Original value"), isTrue);

    bindings[bindingId] = PortableExpressionBinding(
      value: skir.DataValue.wrapStringValue("Mutated value"),
    );
    slots.clear();
    slotBuilders.clear();
    panel = await tester.showComponent(render());

    expect(panel.shows("Original value"), isTrue);
    expect(panel.shows("Mutated value"), isFalse);
    expect(panel.shows("Authored slot"), isTrue);
    expect(panel.shows("Built slot"), isTrue);
  });

  testWidgets(
    "nested resource reads shared context and writes only its own resource",
    (tester) async {
      final document = compiledTagInheritanceDocument(
        tags: const [],
        roots: const [],
      );
      final record = document.resource(compiledInheritanceTagId)!;
      final selected = document.catalog.selectPresentation(
        record.configuration,
        skir.PresentationRole.item,
      ) as SelectedEditorPresentation;
      final imported = skir.ExpressionBindingId(value: "context:test.page");
      final pageField = skir.ExpressionBindingId(value: "page_field");
      final contextType = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
      final dependencies = selected.material.dependencies.toMutable()
        ..contextInputs = [
          skir.PresentationContextInput(
            source: skir.PresentationContextSource.caller,
            binding: declareBinding(imported, contextType.portableTemplate),
          ),
        ];
      final nested = SelectedEditorPresentation(
        requestedRole: selected.requestedRole,
        resolvedRole: selected.resolvedRole,
        descriptor: selected.descriptor,
        material:
            (selected.material.toMutable()
                  ..dependencies = dependencies.toFrozen())
                .toFrozen(),
      );
      final writes = <(skir.BindingRef, skir.ValueLocation?)>[];
      final host = FakePresentationHost(
        document: FakePresentationHost.emptyDocument(catalog: document.catalog),
        expected: contextType,
        onWriteContext: (reference, value, context) => writes.add((
          reference,
          context.location(reference, document.catalog.snapshot.generation),
        )),
      );
      addTearDown(host.dispose);
      final nameReference = skir.BindingRef(
        bindingId: configuredValueBindingId,
        path: editorRootPath.field("name"),
      );
      final layout = presentationColumn("nested", [
        presentationText("nested.context", inputExpression(imported)),
        presentationText("nested.page", inputExpression(pageField)),
        presentationNode(
          "nested.slot",
          skir.PresentationElement.createSlot(slotId: "body"),
        ),
        presentationNode(
          "nested.name",
          textInputElement(nameReference, label: "Tag name"),
        ),
      ]);

      Widget render({required bool readOnly}) {
        final parent = PortablePresentationScope(
          bindings: {
            imported: PortableExpressionBinding(
              value: skir.DataValue.wrapStringValue("Shared context"),
              schema: CompletePortablePresentationBinding(contextType),
            ),
            pageField: PortableExpressionBinding(
              value: skir.DataValue.wrapStringValue("Page title"),
              location: skir.ValueLocation(
                resource: compiledInheritanceBookId,
                path: editorRootPath.field("title"),
              ),
            ),
          },
          catalog: document.catalog,
          queries: PortableExpressionQueries(
            catalog: document.catalog,
            authored: document,
          ),
          operations: testPortableOperations(),
          budget: skir.EvaluationBudget(
            maxSteps: 1000,
            maxCollectionItems: 100,
          ),
          resource: compiledInheritanceBookId,
          readOnly: readOnly,
          host: host,
          slotBuilders: {"body": (_) => const Text("Page content")},
        );
        final child = parent.forResourcePresentation(
          PortableResourceProjection(
            resource: compiledInheritanceTagId,
            configuration: record.configuration,
            appearance: skir.ResourceAppearance(
              label: "Inheritance subject",
              accent: const Color(0xff607d8b).toSkirColor(),
              icon: skir.Icon.wrapIconify("material-symbols:category"),
            ),
            value: skir.DataValue.createNamed(
              actualType:
                  (record.configuration as skir.TypeSelection_completeWrapper)
                      .value,
              payload: skir.DataValue.createRecord(fields: record.fields),
            ),
          ),
          nested,
        );
        return Material(
          child: PortablePresentationNodeRenderer(node: layout, scope: child),
        );
      }

      final panel = await tester.showComponent(render(readOnly: true));
      expect(panel.shows("Shared context"), isTrue);
      expect(panel.shows("Page title"), isFalse);
      expect(panel.shows("Page content"), isFalse);
      expect(panel.field("Tag name").value, "Inheritance subject");
      expect(panel.field("Tag name").isReadOnly, isTrue);

      await tester.showComponent(render(readOnly: false));
      await panel.field("Tag name").type("Renamed subject");

      expect(writes, [
        (
          nameReference,
          skir.ValueLocation(
            resource: compiledInheritanceTagId,
            path: editorRootPath.field("name"),
          ),
        ),
      ]);
    },
  );

  testWidgets("relative time refreshes without a new host snapshot", (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 5, 12);
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        root: skir.PresentationNode(
          nodeId: "relative",
          properties: skir.PresentationProperties.defaultInstance,
          header: null,
          element: skir.PresentationElement.createRelativeTime(
            value: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapTimestamp(now),
            ),
            style: skir.RelativeTimeStyle.natural,
            timeZone: skir.DateTimeZone.utc,
            options: null,
          ),
        ),
        bindings: _integerBinding,
      ),
      expected: _integerType,
      updatesDocument: true,
    );
    addTearDown(host.dispose);
    await withClock(Clock(() => now), () async {
      await tester.showComponent(
        Material(child: PortablePresentationRenderer(host: host)),
      );
      expect(find.text("Just now"), findsOneWidget);
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      expect(find.text("1 minute ago"), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("grid cells keep their content height", (tester) async {
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        root: skir.PresentationNode(
          nodeId: "grid",
          properties: skir.PresentationProperties.defaultInstance,
          header: null,
          element: skir.PresentationElement.wrapChildren(
            skir.ChildrenElement.createGrid(
              layout: skir.GridChildrenLayout(
                columns: 2,
                horizontalSpacing: 12,
                verticalSpacing: 12,
              ),
              children: [
                presentationText("grid.first", textLiteral("Alpha")),
                presentationText("grid.second", textLiteral("Beta")),
                presentationText("grid.third", textLiteral("Gamma")),
              ],
            ),
          ),
        ),
        bindings: _integerBinding,
      ),
      expected: _integerType,
      updatesDocument: true,
    );
    addTearDown(host.dispose);
    await tester.showComponent(
      Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            child: PortablePresentationRenderer(host: host),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.text("Alpha")).height, lessThan(100));
    expect(
      tester.getTopLeft(find.text("Gamma")).dy -
          tester.getTopLeft(find.text("Alpha")).dy,
      lessThan(100),
    );
    expect(
      tester.getTopLeft(find.text("Beta")).dx,
      greaterThan(tester.getTopLeft(find.text("Alpha")).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("text content retains inherited typography", (tester) async {
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        root: presentationText("typography", textLiteral("Inherited text")),
        bindings: _integerBinding,
      ),
      expected: _integerType,
      updatesDocument: true,
    );
    await tester.showRenderer(host);
    final text = find.text("Inherited text");
    expect(
      tester.widget<Text>(text).style?.fontFamily,
      DefaultTextStyle.of(tester.element(text)).style.fontFamily,
    );
  });

  testWidgets("section surfaces include their collapsible headers", (
    tester,
  ) async {
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        root: skir.PresentationNode(
          nodeId: "section",
          properties: skir.PresentationProperties.defaultInstance,
          element: skir.PresentationElement.createSection(
            child: presentationText(
              "section.body",
              textLiteral("Section body"),
            ),
            border: null,
          ),
          header: skir.PresentationHeader(
            binding: null,
            title: skir.PresentationHeaderTitle.wrapText(
              skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Section title"),
              ),
            ),
            description: null,
            initiallyExpanded: true,
            items: const [],
            headerPadding: null,
            contentPadding: null,
          ),
        ),
        bindings: _integerBinding,
      ),
      expected: _integerType,
      updatesDocument: true,
    );
    final panel = await tester.showRenderer(host);
    final title = semanticsLabeled("Section title").single;
    final body = semanticsLabeled("Section body").single;
    final surface = title.parent!;
    expect(surface.descendants, contains(body));
    for (final part in [title.screenRect, body.screenRect]) {
      expect(surface.screenRect.expandToInclude(part), surface.screenRect);
    }

    await panel.tapOn(find.tooltip("Collapse"));
    expect(panel.shows("Section body"), isFalse);
    await panel.tapOn(find.tooltip("Expand"));
    expect(panel.shows("Section body"), isTrue);
  });

  for (final (name, value) in [
    (
      "a text status keeps its source label and online tone",
      skir.DataValue.wrapStringValue("Connected"),
    ),
    (
      "an enum status uses its case as the default label",
      skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(
          definition: skir.TypeDefinitionId(
            typeId: skir.TypeId.createQualified(
              namespace: "test",
              name: "connection",
            ),
            revision: 1,
          ).member("Connected"),
          arguments: const [],
        ),
        payload: skir.DataValue.unit,
      ),
    ),
  ]) {
    testWidgets(name, (tester) async {
      final host = FakePresentationHost(
        document: FakePresentationHost.emptyDocument(
          root: skir.PresentationNode(
            nodeId: "status",
            properties: skir.PresentationProperties.defaultInstance,
            header: null,
            element: skir.PresentationElement.createStatus(
              value: skir.ExpressionNode.wrapLiteral(value),
              cases: [
                skir.StatusCase(
                  match: value,
                  appearance: skir.StatusAppearance(
                    tone: skir.StatusTone.online,
                    label: null,
                    options: null,
                  ),
                ),
              ],
              fallback: null,
            ),
          ),
          bindings: _integerBinding,
        ),
        expected: _integerType,
        updatesDocument: true,
      );
      await tester.showRenderer(host);
      expect(find.text("Connected"), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      final context = tester.element(find.text("Connected"));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.cloud_done_outlined)).color,
        context.colors.online,
      );
      expect(
        tester.widget<Text>(find.text("Connected")).style?.color,
        context.colors.online,
      );
    });
  }

  for (final (name, expected, typed, written) in [
    ("a signed integer", _integerType, "7", skir.DataValue.wrapInteger("7")),
    (
      "a float",
      skir.TypeUse.wrapScalar(
        skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
      ),
      "7.5",
      skir.DataValue.wrapFloat(7.5),
    ),
  ]) {
    testWidgets("writes typed input as the host's expected $name", (
      tester,
    ) async {
      final host = documentHost(
        _numericNode,
        bindings: _integerBinding,
        expected: expected,
      );
      final panel = await tester.showRenderer(host);

      await panel.fieldAt(0).type(typed);

      expect(host.writes, [(_reference, written)]);
    });
  }

  testWidgets("rejects input outside the host's expected integer range", (
    tester,
  ) async {
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        root: _numericNode,
        bindings: _integerBinding,
      ),
      expected: skir.TypeUse.wrapScalar(
        skir.ScalarKind.createInteger(width: skir.IntegerWidth.unsignedEight),
      ),
      updatesDocument: true,
    );
    final panel = await tester.showRenderer(host);

    await panel.fieldAt(0).type("300");

    expect(host.writes, isEmpty);
  });

  testWidgets("escape leaves typed values applied", (tester) async {
    final host = documentHost(
      _numericNode,
      bindings: _integerBinding,
      expected: _integerType,
    );
    final panel = await tester.showRenderer(host);
    final field = panel.fieldAt(0);

    await field.type("7");
    await panel.press(LogicalKeyboardKey.escape);

    expect(
      host
          .document
          .bindings[RendererWorkspace.bindingId]
          ?.value
          .authoredInteger,
      BigInt.from(7),
    );
    expect(field.value, "7");

    await field.type("8");
    await panel.pressPrimary(LogicalKeyboardKey.escape);

    expect(
      host
          .document
          .bindings[RendererWorkspace.bindingId]
          ?.value
          .authoredInteger,
      BigInt.from(8),
    );
    expect(field.value, "8");
  });

  testWidgets("surfaces a write the host rejects beside its control", (
    tester,
  ) async {
    final host = documentHost(
      _actionNode,
      bindings: _integerBinding,
      expected: _integerType,
      rejectWrites: true,
    );
    final panel = await tester.showRenderer(host);

    await panel.fieldAt(0).type("8");

    expect(find.tooltip("The document rejected this write"), findsOneWidget);
    expect(panel.shows("Presentation error"), isTrue);
  });

  testWidgets("delivers the authored button action to the host", (
    tester,
  ) async {
    final host = documentHost(
      _actionNode,
      bindings: _integerBinding,
      expected: _integerType,
    );
    final panel = await tester.showRenderer(host);

    await panel.tapOn(find.text("Run action"));

    expect(host.actions, [
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createSetValue(
          target: _reference,
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("9"),
          ),
        ),
      ),
    ]);
  });

  testWidgets("compact indicators do not steal card selection", (tester) async {
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        root: _compactNode,
        bindings: _integerBinding,
        diagnostics: [
          PortablePresentationDiagnostic(
            code: "compact_error",
            message: "Compact problem",
            severity: skir.DiagnosticSeverity.error,
          ),
        ],
      ),
      expected: _integerType,
      updatesDocument: true,
    );
    var cardTaps = 0;
    addTearDown(host.dispose);
    await tester.showComponent(
      Material(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => cardTaps++,
          child: PortablePresentationRenderer(host: host),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byIcon(Icons.error_outline_rounded)),
    );
    expect(cardTaps, 1);
  });

  testWidgets("editor and inspector roles keep full status messages", (
    tester,
  ) async {
    for (final role in [
      skir.PresentationRole.workspace,
      skir.PresentationRole.inspector,
    ]) {
      final host = FakePresentationHost(
        document: FakePresentationHost.emptyDocument(
          root: _actionNode,
          bindings: _integerBinding,
          role: role,
        ),
        expected: _integerType,
        updatesDocument: true,
        rejectWrites: true,
      );
      addTearDown(host.dispose);
      final panel = await tester.showComponent(
        Material(
          child: SizedBox(
            height: 300,
            child: PortablePresentationRenderer(host: host),
          ),
        ),
      );

      await panel.fieldAt(0).type("8");

      expect(find.text("The document rejected this write"), findsOneWidget);
      expect(panel.labeled("Presentation error"), findsNothing);
    }
  });

  testWidgets("compact information remains visibly informational", (
    tester,
  ) async {
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        root: _numericNode,
        bindings: _integerBinding,
        diagnostics: [
          PortablePresentationDiagnostic(
            code: "informational",
            message: "This value was inferred",
            severity: skir.DiagnosticSeverity.information,
          ),
        ],
      ),
      expected: _integerType,
      updatesDocument: true,
    );
    final panel = await tester.showRenderer(host);

    expect(panel.labeled("Presentation information"), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets("separates an unspecified header from its first control", (
    tester,
  ) async {
    final host = documentHost(
      _headerNode,
      bindings: _integerBinding,
      expected: _integerType,
    );
    await tester.showRenderer(host);

    final description = tester.getRect(find.text("Document description"));
    final control = visibleTextFields().single.screenRect;
    expect(control.top - description.bottom, greaterThanOrEqualTo(8));
    final label = tester.getRect(find.text("Count"));
    expect(control.top - label.bottom, greaterThanOrEqualTo(6));
  });

  testWidgets("does not repeat a control label supplied by its header", (
    tester,
  ) async {
    final host = documentHost(
      _matchingHeaderNode,
      bindings: _integerBinding,
      expected: _integerType,
    );
    await tester.showRenderer(host);

    expect(find.text("Count"), findsOneWidget);
    expect(visibleTextFields().single.spoken, startsWith("Count"));
  });

  testWidgets("collapsing a header preserves a local invalid draft", (
    tester,
  ) async {
    final host = documentHost(
      _headerNode,
      bindings: _integerBinding,
      expected: _integerType,
    );
    final panel = await tester.showRenderer(host);

    await panel.field("Count").type("-");
    await panel.tapOn(find.tooltip("Collapse"));
    await panel.tapOn(find.tooltip("Expand"));

    expect(panel.field("Count").value, "-");
    expect(host.writes, isEmpty);
  });

  testWidgets("narrow headers move trailing actions into overflow", (
    tester,
  ) async {
    final host = documentHost(
      _overflowHeaderNode,
      bindings: _integerBinding,
      expected: _integerType,
    );
    addTearDown(host.dispose);
    final panel = await tester.showComponent(
      Material(
        child: SizedBox(
          width: 280,
          child: PortablePresentationRenderer(host: host),
        ),
      ),
    );

    final moved = find.tooltip("Action 5").hitTestable();
    expect(moved, findsNothing);
    await panel.tapOn(find.tooltip("More actions"));
    await panel.tapOn(moved);

    expect(host.actions, [
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createSetValue(
          target: _reference,
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("5"),
          ),
        ),
      ),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets("renders published icon values with resolved styling", (
    tester,
  ) async {
    const color = Color(0xFF336699);
    await tester.showComponent(
      Material(
        child: PortablePresentationNodeRenderer(
          node: presentationNode(
            "icon",
            skir.PresentationElement.createIcon(
              name: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue(
                  '<svg xmlns="http://www.w3.org/2000/svg" '
                  'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
                ),
              ),
              semanticLabel: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Book icon"),
              ),
              color: skir.PresentationColor.wrapValue(
                skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapInteger(color.toARGB32().toString()),
                ),
              ),
              size: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapFloat(28),
              ),
            ),
          ),
          scope: PortablePresentationScope(
            operations: testPortableOperations(),
            bindings: const {},
            budget: skir.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
          ),
        ),
      ),
    );

    final icon = tester.widget<Icones>(find.byType(Icones));
    expect((icon.iconValue! as SvgIconValue).source, contains("<svg"));
    expect(icon.color, color);
    expect(
      semanticsLabeled("Book icon").single.screenRect.size,
      const Size(28, 28),
    );
  });

  testWidgets("renders typed icon values such as a type display icon", (
    tester,
  ) async {
    await tester.showComponent(
      Material(
        child: PortablePresentationNodeRenderer(
          node: presentationNode(
            "icon",
            skir.PresentationElement.createIcon(
              name: skir.ExpressionNode.wrapLiteral(
                iconValue(skir.Icon.wrapIconify("material-symbols:book")),
              ),
              semanticLabel: null,
              color: null,
              size: null,
            ),
          ),
          scope: PortablePresentationScope(
            operations: testPortableOperations(),
            bindings: const {},
            budget: skir.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<Icones>(find.byType(Icones)).iconValue,
      const IconValue.iconify("material-symbols:book"),
    );
  });

  testWidgets("generated Tag cards adapt to one cell and wider placements", (
    tester,
  ) async {
    skir.PresentationNode tagCard(String tagName) {
      final label = tagName.isEmpty ? "Unnamed tag" : tagName;
      final icon = presentationNode(
        "tag.icon",
        skir.PresentationElement.createIcon(
          name: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(
              '<svg xmlns="http://www.w3.org/2000/svg" '
              'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
            ),
          ),
          semanticLabel: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Tag"),
          ),
          color: null,
          size: null,
        ),
      );
      final coloredIcon = coloredIconTile("tag.icon", icon);
      final center = presentationNode(
        "tag.name",
        textElement(
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(label),
          ),
        ),
      );
      final card = presentationNode(
        "tag.card",
        skir.PresentationElement.createAdaptiveLeading(
          leading: coloredIcon,
          center: center,
          suffix: null,
          padding: skir.PresentationInsets.wrapAll(8),
          compactPadding: skir.PresentationInsets.wrapAll(4),
          gap: 12,
          minimumCenterWidth: 80,
        ),
      );
      return presentationNode(
        "tag.root",
        skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createColumn(
            children: [skir.AxisChild.wrapFixed(card)],
            layout: skir.AxisChildrenLayout(
              clipOverflow: false,

              spacing: 0,
              mainAxisAlignment: skir.MainAxisAlignment.start,
              crossAxisAlignment: skir.CrossAxisAlignment.start,
            ),
          ),
        ),
      );
    }

    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );
    Future<PanelDriver> show({required double width, required String tagName}) {
      final card = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: PortablePresentationNodeRenderer(
          node: tagCard(tagName),
          scope: scope,
        ),
      );
      return tester.showComponent(
        Material(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: Semantics(
                container: true,
                label: "Placement",
                child: width == 48
                    ? SizedBox(width: width, height: 48, child: card)
                    : SizedBox(
                        width: width,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [card],
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    await show(width: 48, tagName: "");
    expect(tester.takeException(), isNull);
    final cell = tester.getRect(find.bySemanticsLabel("Placement"));
    final cellIcon = tester.getRect(find.bySemanticsLabel("Tag"));
    expect(cell.expandToInclude(cellIcon), cell);
    expect(semanticsLabeled("Unnamed tag"), hasLength(1));

    await show(width: 180, tagName: "Quest");
    expect(tester.takeException(), isNull);
    final icon = tester.getRect(find.bySemanticsLabel("Tag"));
    final label = tester.getRect(find.text("Quest"));
    final placement = tester.getRect(find.bySemanticsLabel("Placement"));
    expect(label.left, greaterThanOrEqualTo(icon.right));
    expect(placement.expandToInclude(label), placement);
    expect(label.center.dy, closeTo(icon.center.dy, 4));
  });

  testWidgets("applies portable text styling and exposes style failures", (
    tester,
  ) async {
    const color = Color(0xFF884422);
    skir.PresentationNode textNode(skir.ExpressionNode weight) =>
        presentationNode(
          "styled.text",
          textElement(
            skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("Styled title"),
            ),
            color: skir.PresentationColor.wrapValue(
              skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapInteger(color.toARGB32().toString()),
              ),
            ),
            sizing: skir.TextSizing.wrapExact(
              skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(22)),
            ),
            fontWeight: weight,
            fontItalic: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapFloat(1),
            ),
            textAlignment: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("center"),
            ),
            decoration: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("underline"),
            ),
            semanticLabel: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("Styled heading"),
            ),
            paragraph: skir.TextParagraph(
              maxLines: 1,
              overflow: skir.PresentationTextOverflow.ellipsis,
              softWrap: false,
              selectable: false,
              tone: skir.PresentationTextTone.primary,
            ),
          ),
        );
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );
    await tester.showComponent(
      Material(
        child: PortablePresentationNodeRenderer(
          node: textNode(
            skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(700)),
          ),
          scope: scope,
        ),
      ),
    );

    final text = tester.widget<Text>(find.text("Styled title"));
    expect(text.style?.color, color);
    expect(text.style?.fontSize, 22);
    expect(text.style?.decoration, TextDecoration.underline);
    expect(text.textAlign, TextAlign.center);
    expect(text.semanticsLabel, "Styled heading");
    expect(text.style?.fontVariations, isNotEmpty);

    await tester.showComponent(
      Material(
        child: PortablePresentationNodeRenderer(
          node: textNode(
            skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("heavy"),
            ),
          ),
          scope: scope,
        ),
      ),
    );
    expect(
      find.text("Font weight must evaluate to a finite number"),
      findsOneWidget,
    );
  });

  testWidgets("invokes the presentation for a configured concrete value", (
    tester,
  ) async {
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        catalog: _polymorphicCatalog,
      ),
      expected: skir.TypeUse.wrapNamed(_iconifyType),
    );
    addTearDown(host.dispose);
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        RendererWorkspace.bindingId: PortableExpressionBinding(
          value: skir.DataValue.createNamed(
            actualType: _iconifyType,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "value",
                  value: skir.DataValue.wrapStringValue(
                    "material-symbols:book",
                  ),
                ),
              ],
            ),
          ),
          schema: PortablePresentationBindingSchema.complete(
            skir.TypeUse.wrapNamed(_iconifyType),
          ),
        ),
      },
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      catalog: _polymorphicCatalog,
      host: host,
    );

    await tester.showComponent(
      Material(
        child: PortablePresentationNodeRenderer(
          node: _polymorphicNode,
          scope: scope,
        ),
      ),
    );

    expect(
      find.text("The selected concrete type is unavailable"),
      findsNothing,
    );
    expect(find.text("The invoked presentation is unavailable"), findsNothing);
    expect(visibleFieldValues(), ["material-symbols:book"]);
  });

  testWidgets("an enum's control offers its cases and saves the chosen one", (
    tester,
  ) async {
    final fixture = EditedValue(
      enumValue("Door", "Shut"),
      skir.TypeUse.wrapNamed(typeUse("Door")),
    );
    final panel = await fixture.show(
      tester,
      skir.PresentationElement.createDefaultPresentation(
        control: fixture.control,
        presentationId: null,
      ),
      catalog: authoredCatalog(declaredEnum("Door", ["Shut", "Open", "Ajar"])),
    );
    bool chosen(String name) => semanticsLabeled(name).any(
      (node) =>
          node.getSemanticsData().flagsCollection.isSelected == Tristate.isTrue,
    );
    for (final name in ["Shut", "Open", "Ajar"]) {
      expect(panel.shows(name), isTrue);
    }
    expect(chosen("Shut"), isTrue);
    await panel.tapOn(panel.labeled("Open"));

    expect(fixture.value, enumValue("Door", "Open"));
    expect(chosen("Open"), isTrue);
    expect(chosen("Shut"), isFalse);
  });

  testWidgets("a closed union with a case holding fields shows no dropdown", (
    tester,
  ) async {
    final fixture = EditedValue(
      typedValue(
        "Circle",
        skir.DataValue.createRecord(
          fields: [
            skir.FieldValue(
              name: "label",
              value: skir.DataValue.wrapStringValue("round"),
            ),
          ],
        ),
      ),
      skir.TypeUse.wrapNamed(typeUse("Shape")),
    );
    final panel = await fixture.show(
      tester,
      skir.PresentationElement.createDefaultPresentation(
        control: fixture.control,
        presentationId: null,
      ),
      catalog: authoredCatalog([
        declaredRecord("Shape", cases: ["Circle"]),
        declaredRecord(
          "Circle",
          fields: {"label": skir.ScalarKind.text},
          parents: ["Shape"],
        ),
      ]),
    );

    expect(panel.shows("The enumeration binding is unavailable"), isFalse);
    expect(visibleFieldValues(), contains("round"));
  });

  testWidgets("record input preserves authored absolute field paths", (
    tester,
  ) async {
    final writes = <(skir.BindingRef, skir.DataValue)>[];
    final placementReference = skir.BindingRef(
      bindingId: _configuredBindingId,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "placement")],
      ),
    );
    final xReference = skir.BindingRef(
      bindingId: _configuredBindingId,
      path: skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "placement"),
          skir.PathSegment.createField(name: "x"),
        ],
      ),
    );
    final root = skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "placement",
          value: skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse.defaultInstance,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "x",
                  value: skir.DataValue.wrapInteger("4"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
      ),
      expected: _integerType,
      onWrite: (reference, value) => writes.add((reference, value)),
    );
    addTearDown(host.dispose);
    final node = presentationNode(
      "placement",
      skir.PresentationElement.createRecordInput(
        control: skir.BoundControl(
          binding: placementReference,
          label: null,
          description: null,
          prefix: null,
          semanticLabel: null,
        ),
        fieldPresentation: presentationNode(
          "placement.x",
          skir.PresentationElement.wrapNumericInput(
            (skir.NumericControl.mutable()
                  ..control = skir.BoundControl(
                    binding: xReference,
                    label: null,
                    description: null,
                    prefix: null,
                    semanticLabel: null,
                  ))
                .toFrozen(),
          ),
        ),
        appearance: null,
        content: null,
      ),
    );
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {_configuredBindingId: PortableExpressionBinding(value: root)},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      host: host,
    );

    final panel = await tester.showComponent(
      Material(
        child: PortablePresentationNodeRenderer(node: node, scope: scope),
      ),
    );

    expect(panel.shows("The numeric control binding is unavailable"), isFalse);
    final input = panel.fieldAt(0);
    expect(input.value, "4");
    await input.type("6");
    expect(writes, [(xReference, skir.DataValue.wrapInteger("6"))]);
  });

  testWidgets("a row alias reorders its authoritative collection item", (
    tester,
  ) async {
    final first = skir.ItemId(value: "item:one");
    final second = skir.ItemId(value: "item:two");
    final root = skir.ExpressionBindingId(value: "root");
    final row = skir.ExpressionBindingId(value: "row");
    final resource = skir.ResourceId(value: "resource:rows");
    final rootLocation = skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(segments: const []),
    );
    final rootValue = skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "items",
          value: skir.DataValue.createListValue(
            items: [
              skir.ListItem(
                id: first,
                value: skir.DataValue.wrapStringValue("Row"),
              ),
              skir.ListItem(
                id: second,
                value: skir.DataValue.wrapStringValue("Next"),
              ),
            ],
          ),
        ),
      ],
    );
    final items = skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "items")],
    );
    final actions = <skir.EditorAction>[];
    final host = FakePresentationHost(
      document: FakePresentationHost.emptyDocument(
        catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
        bindings: {
          root: PortablePresentationBinding(
            schema: CompletePortablePresentationBinding(_integerType),
            value: rootValue,
            editable: true,
            location: rootLocation,
          ),
        },
      ),
      expected: _integerType,
      onExecute: actions.add,
    );
    addTearDown(host.dispose);
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        root: PortableExpressionBinding(
          value: rootValue,
          location: rootLocation,
        ),
        row: PortableExpressionBinding(
          value: skir.DataValue.wrapStringValue("Row"),
          location: skir.ValueLocation(
            resource: resource,
            path: skir.ValuePath(
              segments: [
                ...items.segments,
                skir.PathSegment.createItem(id: first),
              ],
            ),
          ),
        ),
      },
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      host: host,
    );
    final node = skir.PresentationNode(
      nodeId: "row",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.wrapText(
        (skir.TextContent.mutable()..value = inputExpression(row)).toFrozen(),
      ),
      header: skir.PresentationHeader(
        binding: null,
        title: skir.PresentationHeaderTitle.wrapText(textLiteral("Row")),
        description: null,
        initiallyExpanded: null,
        items: [
          skir.HeaderItem.createReorderHandle(
            itemId: skir.HeaderItemId(namespace: "test", name: "reorder"),
            label: textLiteral("Reorder row"),
            source: skir.BindingRef(
              bindingId: row,
              path: skir.ValuePath(segments: const []),
            ),
            tooltip: null,
            visibleIf: null,
            enabledIf: null,
          ),
        ],
        headerPadding: null,
        contentPadding: null,
      ),
    );
    final panel = await tester.showComponent(
      Material(
        child: PortablePresentationNodeRenderer(node: node, scope: scope),
      ),
    );

    await panel.tapOn(find.tooltip("Reorder row"));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await panel.press(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    expect(actions, [
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createMoveListItem(
          target: skir.BindingRef(bindingId: root, path: items),
          item: first,
          after: second,
        ),
      ),
    ]);
  });

  testWidgets("repairs an Unfilled collection with its normal item default", (
    tester,
  ) async {
    final fixture = authoredListInput(
      value: skir.DataValue.unfilled,
      allowAdd: true,
    );
    await tester.showComponent(fixture.widget);

    expect(find.text("The collection binding is unavailable"), findsNothing);
    await tester.tap(find.tooltip("Add item"));
    await tester.pumpAndSettle();

    final submitted = await fixture.document.submit(tester);
    expect(submitted.intents, hasLength(1));
    expect(
      (submitted.intents.single as skir.EditIntent_insertWrapper)
          .value
          .item
          .value,
      skir.DataValue.wrapStringValue(""),
    );
  });

  testWidgets("empty collection controls retain their field guidance", (
    tester,
  ) async {
    final list = authoredListInput(
      value: skir.DataValue.createListValue(items: const []),
      allowAdd: true,
      label: "Pages",
      description: "Pages in this book",
    );
    await tester.showComponent(list.widget);
    expect(find.text("Pages"), findsOneWidget);
    expect(find.text("Pages in this book"), findsOneWidget);
    expect(find.tooltip("Add item"), findsOneWidget);

    final map = authoredMapInput(label: "Translations");
    await tester.showComponent(map.widget);
    expect(find.text("Translations"), findsOneWidget);
    expect(find.tooltip("Add entry"), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == "Add entry",
      ),
      findsOneWidget,
    );
  });

  testWidgets("does not offer collection insertion when addition is disabled", (
    tester,
  ) async {
    final fixture = authoredListInput(
      value: skir.DataValue.createListValue(items: const []),
      allowAdd: false,
    );
    await tester.showComponent(fixture.widget);

    expect(find.tooltip("Add item"), findsNothing);
    expect(fixture.document.workspace.state.groups, isEmpty);
  });

  testWidgets("adds a stable row to an Unfilled map", (tester) async {
    final fixture = authoredMapInput();
    await tester.showComponent(fixture.widget);

    expect(find.text("The map binding is unavailable"), findsNothing);
    await tester.tap(find.tooltip("Add entry"));
    await tester.pump();

    final submitted = await fixture.document.submit(tester);
    final row =
        ((submitted.intents.single as skir.EditIntent_setValueWrapper)
                    .value
                    .value
                    .authoredPayload
                as skir.DataValue_mapValueWrapper)
            .value
            .rows
            .single;
    expect(row.id.value, startsWith("panel:"));
    expect(row.key, skir.DataValue.wrapStringValue(""));
    expect(row.value, skir.DataValue.wrapStringValue(""));
  });

  testWidgets("selects the first link before inserting an empty set item", (
    tester,
  ) async {
    final fixture = authoredLinkCollection();
    final panel = await tester.showComponent(fixture.widget);

    await panel.tapOn(find.tooltip("Add link"));
    expect(find.text("Target Alpha"), findsOneWidget);
    expect(find.text(fixture.target.value), findsNothing);
    await panel.search.result("Target Alpha").tap();

    final submitted = await fixture.document.submit(tester);
    final connection = submitted.intents
        .whereType<skir.EditIntent_connectRelationWrapper>()
        .single
        .value;
    expect(connection.target, fixture.target);
    expect(
      connection.source.id.location.path.segments.last,
      isA<skir.PathSegment_itemWrapper>(),
    );
  });

  testWidgets("cancelling first link selection leaves the set untouched", (
    tester,
  ) async {
    final fixture = authoredLinkCollection();
    final panel = await tester.showComponent(fixture.widget);

    await panel.tapOn(find.tooltip("Add link"));
    await panel.press(LogicalKeyboardKey.escape);

    expect(fixture.document.workspace.state.groups, isEmpty);
    unawaited(fixture.document.binding.save());
    await panel.settle();
    expect(fixture.document.realm.saves, isEmpty);
  });

  testWidgets("searches and selects a linked resource with the keyboard", (
    tester,
  ) async {
    final fixture = authoredLinkCollection();
    final panel = await tester.showComponent(fixture.widget);

    await panel.tapOn(find.tooltip("Add link"));
    await panel.fieldAt(0).type("Target Beta");

    expect(panel.search.result("Target Alpha").isShown, isFalse);
    expect(panel.search.result("Target Beta").isShown, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await panel.settle();

    final submitted = await fixture.document.submit(tester);
    expect(
      submitted.intents
          .whereType<skir.EditIntent_connectRelationWrapper>()
          .single
          .value
          .target,
      fixture.secondTarget,
    );
  });

  testWidgets("presents an existing link by its authored resource label", (
    tester,
  ) async {
    final fixture = authoredLinkCollection(withPartialLinks: true);
    await tester.showComponent(fixture.widget);

    expect(find.text("Target Alpha"), findsOneWidget);
    expect(find.text(fixture.target.value), findsNothing);
    expect(find.tooltip("Clear link"), findsOneWidget);
  });

  testWidgets("presents a link to a missing resource as missing", (
    tester,
  ) async {
    final fixture = authoredLinkCollection(
      withPartialLinks: true,
      missingTarget: true,
    );
    await tester.showComponent(fixture.widget);

    expect(find.text("Missing resource"), findsOneWidget);
    expect(find.text(fixture.target.value), findsNothing);
  });

  testWidgets("keeps selected link identity beside compact row actions", (
    tester,
  ) async {
    final fixture = authoredLinkCollection(
      withPartialLinks: true,
      adaptiveAppearance: true,
    );
    await tester.showComponent(SizedBox(width: 376, child: fixture.widget));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Target Alpha"), findsOneWidget);
    expect(find.tooltip("Change linked resource"), findsOneWidget);
    expect(find.tooltip("Clear link"), findsOneWidget);
    expect(find.tooltip("Remove item"), findsNWidgets(2));
    expect(find.text("Change"), findsNothing);
  });

  testWidgets(
    "ordinary link collection rows own one surface and one spacing boundary",
    (tester) async {
      final fixture = authoredLinkCollection(
        withPartialLinks: true,
        collectionAppearance:
            (skir.CollectionAppearance.mutable()..itemSpacing = 14).toFrozen(),
      );
      await tester.showComponent(fixture.widget);
      final rows = collectionRowSurfaces(tester, "Remove item");
      expect(rows, hasLength(2));
      expect(rows[1].top - rows[0].bottom, closeTo(14, 0.01));
      expect(find.text("Target Alpha"), findsOneWidget);
      expect(find.tooltip("Change linked resource"), findsOneWidget);
      expect(find.tooltip("Clear link"), findsOneWidget);
      expect(find.tooltip("Remove item"), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("frames a link collection once with explicit reorder handles", (
    tester,
  ) async {
    final fixture = authoredLinkCollection(
      withPartialLinks: true,
      directCollection: true,
      label: "Related nodes",
    );
    final panel = await tester.showComponent(fixture.widget);

    expect(find.text("Related nodes"), findsOneWidget);
    expect(find.tooltip("Reorder linked resource 1"), findsOneWidget);
    expect(find.tooltip("Reorder linked resource 2"), findsOneWidget);

    await panel.tapOn(find.tooltip("Reorder linked resource 1"));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await panel.press(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    final submitted = await fixture.document.submit(tester);
    final move = submitted.intents
        .whereType<skir.EditIntent_moveWrapper>()
        .single
        .value;
    expect(move.item, RendererWorkspace.knownLinkItem);
    expect(move.after, RendererWorkspace.unfinishedLinkItem);
  });

  test("known link edits preserve an unfinished sibling", () {
    final fixture = authoredLinkCollection(withPartialLinks: true);
    final branch = AuthoringEdit.fromDocument(
      fixture.document.workspace.document,
    );
    replacePortableLinkCollection(
      draft: branch,
      catalog: fixture.catalog,
      resource: RendererWorkspace.resource,
      field: "links",
      expected: [fixture.target],
      proposed: const [],
    );
    final remaining = branch
        .resource(RendererWorkspace.resource)!
        .authoredField("links")!
        .authoredItems!;
    expect(remaining.single.id, RendererWorkspace.unfinishedLinkItem);
    expect(remaining.single.value, skir.DataValue.unfilled);
    expect(
      branch.intents.single,
      isA<skir.EditIntent_disconnectRelationWrapper>(),
    );
  });

  for (final count in [1, 2, 4]) {
    testWidgets("an Unfilled type selector adapts to $count concrete forms", (
      tester,
    ) async {
      final additional = [
        for (final name in ["SVG", "Emoji", "Texture"].take(count - 1))
          skir.TypeDefinitionId(
            typeId: skir.TypeId.createQualified(namespace: "test", name: name),
            revision: 1,
          ),
      ];
      final catalog = CheckedEditorCatalog(
        (_polymorphicCatalog.snapshot.toMutable()
              ..types = [
                ..._polymorphicCatalog.snapshot.types,
                for (final id in additional)
                  (skir.PublishedType.mutable()
                        ..status = skir.DeclarationStatus.ready
                        ..definition =
                            (skir.TypeDefinition.mutable()
                                  ..id = id
                                  ..representation =
                                      skir.RepresentationTemplate.createRecord(
                                        fields: const [],
                                        form: skir.RecordForm.concrete,
                                      ))
                                .toFrozen())
                      .toFrozen(),
              ])
            .toFrozen(),
      );
      final document = RendererWorkspace(
        catalog: catalog,
        resources: {
          RendererWorkspace.resource: skir.AuthoringRecord(
            types: const [],
            configuration: skir.TypeSelection.unknown,
            fields: [
              skir.FieldValue(name: "icon", value: skir.DataValue.unfilled),
            ],
          ),
        },
      );
      skir.ValuePreparationRequest? request;
      final host = document.host(
        prepareValue: (value) async {
          request = value;
          return skir.PreparedValue(
            content: skir.PreparedContent.wrapRecord(
              skir.AuthoringRecord(
                types: const [],
                configuration: value.recordSelection,
                fields: [
                  skir.FieldValue(
                    name: "value",
                    value: skir.DataValue.wrapStringValue(""),
                  ),
                ],
              ),
            ),
            findings: const [],
          );
        },
      );
      await tester.showComponent(
        Material(
          child: PortablePresentationNodeRenderer(
            node:
                (_polymorphicNode.toMutable()
                      ..element = skir.PresentationElement.wrapPolymorphicInput(
                        ((_polymorphicNode.element!
                                    as skir.PresentationElement_polymorphicInputWrapper)
                                .value
                                .toMutable()
                              ..concreteTypes = [
                                ...(_polymorphicNode.element!
                                        as skir.PresentationElement_polymorphicInputWrapper)
                                    .value
                                    .concreteTypes,
                                for (final (index, id) in additional.indexed)
                                  skir.ConcreteTypePresentation(
                                    concreteType: skir.TypeUse.createNamed(
                                      definition: id,
                                      arguments: const [],
                                    ),
                                    label: skir.ExpressionNode.wrapLiteral(
                                      skir.DataValue.wrapStringValue(
                                        ["SVG", "Emoji", "Texture"][index],
                                      ),
                                    ),
                                    presentation: null,
                                  ),
                              ]
                              ..content =
                                  (skir.CollectionContent.mutable()
                                        ..operationDensity =
                                            skir.ControlDensity.comfortable)
                                      .toFrozen())
                            .toFrozen(),
                      ))
                    .toFrozen(),
            scope:
                PortablePresentationScope(
                  operations: testPortableOperations(),
                  bindings: {
                    RendererWorkspace.bindingId: PortableExpressionBinding(
                      value: skir.DataValue.unfilled,
                      location: skir.ValueLocation(
                        resource: RendererWorkspace.resource,
                        path: skir.ValuePath(
                          segments: [
                            skir.PathSegment.createField(name: "icon"),
                          ],
                        ),
                      ),
                    ),
                  },
                  budget: skir.EvaluationBudget(
                    maxSteps: 100,
                    maxCollectionItems: 100,
                  ),
                  catalog: catalog,
                  host: host,
                ).withAppearance(
                  (skir.InputAppearance.mutable()
                        ..density = skir.ControlDensity.compact)
                      .toFrozen(),
                ),
          ),
        ),
      );

      expect(find.text("Icon form"), findsOneWidget);
      if (count == 2) {
        expect(find.text("Iconify"), findsOneWidget);
        expect(find.text("Choose a type"), findsNothing);
      } else {
        expect(find.text("Choose a type"), findsOneWidget);
        await tester.tap(find.text("Choose a type"));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text("Iconify").last);
      await tester.pumpAndSettle();

      expect(
        request?.recordSelection,
        skir.TypeSelection.wrapComplete(_iconifyType),
      );
      expect(
        document.workspace.document
            .resource(RendererWorkspace.resource)!
            .authoredField("icon")!
            .authoredActualType,
        _iconifyType,
      );
    });
  }

  testWidgets("hierarchy sequences preserve branches spacing and flattening", (
    tester,
  ) async {
    final itemBinding = skir.ExpressionBindingId(value: "hierarchy.item");
    skir.ConnectorStyle connector() => skir.ConnectorStyle(
      stroke: skir.ConnectorStroke(
        color: skir.PresentationColor.wrapValue(
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4286611584"),
          ),
        ),
        width: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(2)),
      ),
      cornerRadius: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapFloat(6),
      ),
      startMarker: null,
      endMarker: null,
    );
    skir.PresentationNode hierarchy(List<String> values) => presentationNode(
      "hierarchy",
      skir.PresentationElement.createRepeated(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.createListValue(
            items: [
              for (final (index, value) in values.indexed)
                skir.ListItem(
                  id: skir.ItemId(value: "hierarchy:$index"),
                  value: skir.DataValue.wrapStringValue(value),
                ),
            ],
          ),
        ),
        itemBinding: declareBinding(itemBinding, textTemplate),
        presentation: skir.SequencePresentation(
          item: presentationNode(
            "hierarchy.item",
            textElement(
              skir.ExpressionNode.createInput(
                binding: itemBinding,
                path: skir.ValuePath(segments: const []),
              ),
            ),
          ),
          empty: null,
          separator: null,
          layout: skir.SequenceLayout.createHierarchy(
            unaryConnector: connector(),
            trunkConnector: connector(),
            branchConnector: connector(),
            itemSpacing: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapFloat(20),
            ),
            indentation: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapFloat(24),
            ),
            leadingSpacing: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapFloat(12),
            ),
            itemAnchor: skir.ConnectorAnchor.center,
            flattenSingleItem: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(true),
            ),
            crossAxisAlignment: skir.CrossAxisAlignment.stretch,
          ),
        ),
      ),
    );
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    );
    Future<void> showHierarchy(List<String> values) => tester.showComponent(
      Material(
        child: SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edge"),
              PortablePresentationNodeRenderer(
                node: hierarchy(values),
                scope: scope,
              ),
            ],
          ),
        ),
      ),
    );

    await showHierarchy(["First", "Second"]);
    final edge = tester.getRect(find.text("Edge")).left;
    final first = tester.getRect(find.text("First"));
    final second = tester.getRect(find.text("Second"));
    expect(first.left - edge, closeTo(24, 0.01));
    expect(second.left - edge, closeTo(24, 0.01));
    expect(second.top - first.bottom, closeTo(20, 0.01));

    await showHierarchy(["First"]);
    expect(tester.getRect(find.text("First")).left - edge, closeTo(0, 0.01));
  });
}

final _reference = skir.BindingRef(
  bindingId: RendererWorkspace.bindingId,
  path: skir.ValuePath(segments: const []),
);
final _integerType = skir.TypeUse.wrapScalar(
  skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
);
final _iconifyDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "Iconify"),
  revision: 1,
);
final _iconifyType = skir.NamedTypeUse(
  definition: _iconifyDefinition,
  arguments: const [],
);
final _iconifyPresentation = skir.PresentationId(
  namespace: "test",
  name: "iconify.inspector",
);
final _configuredBindingId = skir.ExpressionBindingId(
  value: "configured_value",
);
final _configuredValueReference = skir.BindingRef(
  bindingId: _configuredBindingId,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: "value")]),
);
final _control = skir.BoundControl(
  binding: _reference,
  label: null,
  description: null,
  prefix: null,
  semanticLabel: null,
);
final _numericNode = presentationNode(
  "numeric",
  skir.PresentationElement.wrapNumericInput(
    (skir.NumericControl.mutable()..control = _control).toFrozen(),
  ),
);
final _polymorphicNode = presentationNode(
  "polymorphic",
  skir.PresentationElement.createPolymorphicInput(
    control: skir.BoundControl(
      binding: _reference,
      label: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Icon form"),
      ),
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
    concreteTypes: [
      skir.ConcreteTypePresentation(
        concreteType: skir.TypeUse.wrapNamed(_iconifyType),
        label: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Iconify"),
        ),
        presentation: presentationNode(
          "polymorphic.iconify",
          skir.PresentationElement.createInvocation(
            presentationId: _iconifyPresentation,
            arguments: const [],
          ),
        ),
      ),
    ],
    appearance: null,
    content: null,
    inputAppearance: null,
    inputContent: null,
    searchHint: null,
  ),
);
final _polymorphicCatalog = CheckedEditorCatalog(
  testCatalogSnapshot(
    generation: skir.CatalogGeneration(value: "test"),
    types: [
      declaredRecord(
        _iconifyDefinition,
        fields: {"value": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
      ),
    ],
    presentationMaterials: [
      skir.PresentationMaterial(
        inheritableNodes: const [],

        provider: _iconifyPresentation,
        target: skir.PresentationTarget.createNamed(
          definition: _iconifyDefinition,
          arguments: const [],
        ),
        role: skir.PresentationRole.inspector,
        layout: presentationNode(
          "iconify.value",
          textInputElement(_configuredValueReference, label: "Icon"),
        ),
        dependencies: skir.PresentationDependencies.defaultInstance,
        subject: skir.TypeTemplate.createNamed(
          definition: _iconifyDefinition,
          arguments: const [],
        ),
      ),
    ],
  ),
);
final _actionNode = presentationNode(
  "action.root",
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [
        skir.AxisChild.wrapFixed(_numericNode),
        skir.AxisChild.wrapFixed(
          presentationNode(
            "action.button",
            skir.PresentationElement.createButton(
              label: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Run action"),
              ),
              action: skir.EditorAction.wrapLocal(
                skir.LocalEditorAction.createSetValue(
                  target: _reference,
                  value: skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapInteger("9"),
                  ),
                ),
              ),
              appearance: null,
              icon: null,
            ),
          ),
        ),
      ],
      layout: skir.AxisChildrenLayout(
        clipOverflow: false,

        spacing: 8,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.stretch,
      ),
    ),
  ),
);
final _compactNode = presentationNode(
  "compact.root",
  textElement(
    skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue("Compact card"),
    ),
  ),
);
final _headerNode = skir.PresentationNode(
  nodeId: "header.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: numericInputElement(_reference, label: "Count"),
  header: skir.PresentationHeader(
    binding: _reference,
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Document"),
      ),
    ),
    description: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue("Document description"),
    ),
    initiallyExpanded: true,
    items: const [],
    headerPadding: null,
    contentPadding: null,
  ),
);
final _matchingHeaderNode = skir.PresentationNode(
  nodeId: "matching.header.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: numericInputElement(_reference, label: "Count"),
  header: skir.PresentationHeader(
    binding: _reference,
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue("Count")),
    ),
    description: null,
    initiallyExpanded: true,
    items: const [],
    headerPadding: null,
    contentPadding: null,
  ),
);
final _overflowHeaderNode = skir.PresentationNode(
  nodeId: "overflow.header.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapNumericInput(
    (skir.NumericControl.mutable()..control = _control).toFrozen(),
  ),
  header: skir.PresentationHeader(
    binding: _reference,
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Document with actions"),
      ),
    ),
    description: null,
    initiallyExpanded: null,
    items: [
      for (var index = 0; index < 6; index++)
        skir.HeaderItem.createButton(
          itemId: skir.HeaderItemId(namespace: "test", name: "action.$index"),
          icon: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("edit"),
          ),
          label: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Action $index"),
          ),
          tooltip: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Action $index"),
          ),
          action: skir.EditorAction.wrapLocal(
            skir.LocalEditorAction.createSetValue(
              target: _reference,
              value: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapInteger(index.toString()),
              ),
            ),
          ),
          priority: null,
          visibleIf: null,
          enabledIf: null,
          tone: skir.HeaderActionTone.neutral,
          confirmation: null,
          placement: skir.HeaderActionPlacement.end,
        ),
    ],
    headerPadding: null,
    contentPadding: null,
  ),
);

final _integerBinding = {
  RendererWorkspace.bindingId: PortablePresentationBinding(
    schema: PortablePresentationBindingSchema.complete(_integerType),
    value: skir.DataValue.wrapInteger("2"),
    editable: true,
  ),
};
