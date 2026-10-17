import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  for (final replacePrefix in [false, true]) {
    testWidgets(
      replacePrefix
          ? "replacing a source root prefix releases its descendant reservations"
          : "inherited prefix controls reserve only their own descendants",
      (tester) async {
        final definition = skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "test.inherited",
            name: "StructuredName",
          ),
          revision: 1,
        );
        final fields = [
          for (final name in ["first", "second"])
            skir.FieldDeclaration(
              owner: skir.FieldOwner(definition: definition, name: name),
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              overrides: const [],
              hasConstructorDefault: false,
            ),
        ];
        final published =
            (skir.PublishedType.mutable()
                  ..definition = skir.TypeDefinition(
                    id: definition,
                    parameters: const [],
                    parents: const [],
                    representation: skir.RepresentationTemplate.createRecord(
                      fields: fields,
                      abstract_: false,
                    ),
                  )
                  ..status = skir.DeclarationStatus.ready
                  ..effectiveFields = [
                    for (final field in fields)
                      skir.EffectiveFieldTemplate(
                        key: field.owner.name,
                        owner: field.owner,
                        type: field.type,
                        rules: const [],
                      ),
                  ])
                .toFrozen();
        final first = inheritedFieldControl().toMutable()
          ..binding = skir.BindingRef(
            bindingId: inheritedConfiguredValue,
            path: editorRootPath.field("name").field("first"),
          );
        final hiddenPrefix = inheritedFieldNode(
          "source.prefix",
          skir.PresentationElement.wrapConditional(
            (skir.ConditionalElement.mutable()
                  ..condition = skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapBoolean(false),
                  )
                  ..whenTrue = inheritedFieldRequest(control: first.toFrozen()))
                .toFrozen(),
          ),
        );
        final fixture = InheritedFieldPresentationScenario(
          nameType: skir.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
          nameValue: skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse(
              definition: definition,
              arguments: const [],
            ),
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "first",
                  value: skir.DataValue.wrapStringValue("First"),
                ),
                skir.FieldValue(
                  name: "second",
                  value: skir.DataValue.wrapStringValue("Second"),
                ),
              ],
            ),
          ),
          additionalTypes: [published],
          sourceName: inheritedFieldNode(
            "element.name",
            skir.PresentationElement.wrapRecordInput(
              (skir.RecordControl.mutable()
                    ..control = inheritedFieldControl(
                      label: "Name",
                      prefix: hiddenPrefix,
                    )
                    ..fieldPresentation = inheritedFieldNode(
                      "source.body",
                      skir.PresentationElement.wrapScopedBinding(
                        skir.ScopedBindingElement(
                          binding: skir.BindingRef(
                            bindingId: inheritedConfiguredValue,
                            path: editorRootPath.field("name"),
                          ),
                          scopeBindingId: inheritedConfiguredValue,
                          child: inheritedFieldRemaining,
                        ),
                      ),
                    ))
                  .toFrozen(),
            ),
          ),
          layout: inheritedFieldRequest(
            control: inheritedFieldControl(
              prefix: replacePrefix ? _prefix("Local prefix") : null,
            ),
          ),
        );
        addTearDown(fixture.dispose);
        await _pump(tester, fixture);
        expect(
          find.text("Local prefix"),
          replacePrefix ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(TextFormField),
          findsNWidgets(replacePrefix ? 2 : 1),
        );
        expect(
          find.text("First"),
          replacePrefix ? findsOneWidget : findsNothing,
        );
        expect(find.text("Second"), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    "externally referenced sibling editing defaults produce a diagnostic",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(
        sourceName: _siblingEditingName(),
        layout: inheritedFieldColumn([
          inheritedFieldRequest(),
          inheritedFieldRemaining,
        ]),
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text("Welcome"), findsNothing);
      expect(
        find.textContaining(
          "Field presentation test:element for name at element.name:",
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          "the source control edits outside its field subtree",
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextFormField &&
              widget.controller?.text == "Hello player",
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final sourceInspector in [true, false]) {
    testWidgets(
      "unpublished multi field source ${sourceInspector ? 'renders locally' : 'allows consumer fallback'}",
      (tester) async {
        final fixture = InheritedFieldPresentationScenario(
          sourceName: _siblingEditingName(),
          publishNameDefault: false,
          useSourceInspector: sourceInspector,
        );
        addTearDown(fixture.dispose);
        await _pump(tester, fixture);
        expect(
          find.byType(TextFormField),
          sourceInspector ? findsOneWidget : findsNWidgets(2),
        );
        expect(
          find.textContaining("Field presentation test:element"),
          findsNothing,
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          "  Local policy  ",
        );
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          fixture.name,
          sourceInspector ? "Local policy" : "  Local policy  ",
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    "compiled SDK custom inspector inherits the Element completion mapping",
    (tester) async {
      final catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
      var value = compiledSdkElementValue;
      final actual = value.authoredActualType!;
      final selected = catalog.selectPresentation(
        skir.TypeSelection.wrapComplete(actual),
        skir.PresentationRole.inspector,
      ) as SelectedEditorPresentation;
      expect(
        selected.descriptor.id,
        skir.PresentationId(namespace: "fixture", name: "entry inspector"),
      );
      final writes = <skir.ValuePath>[];
      final host = BoundPresentationHost(
        catalog: catalog,
        root: () => selected.material.layout,
        role: selected.resolvedRole,
        material: selected.material,
        bindings: [
          BoundPresentationBinding(
            id: inheritedConfiguredValue,
            use: skir.TypeUse.wrapNamed(actual),
            read: (path) => value.editorValueAt(path),
            write: (path, replacement) {
              final result = value.replaceAt(
                path,
                replacement,
              ) as PortablePathValue<skir.DataValue>;
              value = result.value;
              writes.add(path);
              return const PortablePresentationWriteResult.applied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      );
      addTearDown(host.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: PortablePresentationRenderer(host: host)),
      );
      await tester.pumpAndSettle();
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.controller?.text ==
                compiledSdkElementValue.authoredField("name")?.authoredString,
      );
      expect(name, findsOneWidget);
      await tester.enterText(name, "  Compiled greeting  ");
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(value.authoredField("name")?.authoredString, "Compiled greeting");
      expect(writes.last, editorRootPath.field("name"));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("a nullable inherited field keeps one label and its completion", (
    tester,
  ) async {
    final fixture = InheritedFieldPresentationScenario(
      nameType: skir.TypeTemplate.createNullable(
        value: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      ),
      sourceName: inheritedFieldNode(
        "element.name",
        skir.PresentationElement.wrapNullableInput(
          (skir.NullableControl.mutable()
                ..control = inheritedFieldControl(label: "Name")
                ..valuePresentation = inheritedFieldTextInput(
                  "element.name.value",
                  control: inheritedFieldControl(),
                  trim: true,
                ))
              .toFrozen(),
        ),
      ),
      layout: inheritedFieldRequest(
        control: inheritedFieldControl(label: "Optional name"),
      ),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text("Optional name"), findsOneWidget);
    expect(find.text("Name"), findsNothing);
    await tester.enterText(find.byType(TextFormField), "  Optional quest  ");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(fixture.name, "Optional quest");
    expect(tester.takeException(), isNull);
  });
  for (final localPrefix in [false, true]) {
    testWidgets(
      "${localPrefix ? 'local' : 'inherited'} prefix retains its material dependency table",
      (tester) async {
        skir.PresentationDependencies dependencies(String relation) =>
            (skir.PresentationDependencies.mutable()
                  ..collections = [
                    (skir.PresentationCollectionDefinition.mutable()
                          ..sourceId = "shared.source"
                          ..rowType = skir.TypeTemplate.wrapScalar(
                            skir.ScalarKind.text,
                          )
                          ..rowBindingId = skir.ExpressionBindingId(
                            value: "shared.row",
                          )
                          ..key = skir.ExpressionNode.createInput(
                            binding: skir.ExpressionBindingId(
                              value: "shared.row",
                            ),
                            path: editorRootPath,
                          )
                          ..selectability = skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapBoolean(true),
                          )
                          ..relations = [
                            (skir.PresentationCollectionRelationDefinition.mutable()
                                  ..relationId = relation
                                  ..targets = skir.ExpressionNode.wrapLiteral(
                                    skir.DataValue.createListValue(
                                      items: const [],
                                    ),
                                  ))
                                .toFrozen(),
                          ])
                        .toFrozen(),
                  ])
                .toFrozen();
        final slot = inheritedFieldNode(
          "scope.probe",
          skir.PresentationElement.wrapSlot(
            skir.PresentationSlotElement(slotId: "probe"),
          ),
        );
        final fixture = InheritedFieldPresentationScenario(
          sourceDependencies: dependencies("source relation"),
          customDependencies: dependencies("caller relation"),
          sourceName: inheritedFieldTextInput(
            "element.name",
            control: inheritedFieldControl(label: "Name", prefix: slot),
            trim: true,
          ),
          layout: inheritedFieldRequest(
            control: inheritedFieldControl(prefix: localPrefix ? slot : null),
          ),
        );
        addTearDown(fixture.dispose);
        skir.PresentationMaterial? observed;
        final document = fixture.host.document;
        final scope = PortablePresentationScope(
          bindings: {
            inheritedConfiguredValue: PortableExpressionBinding(
              value: fixture.value,
              schema: CompletePortablePresentationBinding(
                skir.TypeUse.wrapNamed(inheritedActionType),
              ),
            ),
          },
          budget: document.budget,
          operations: testPortableOperations(),
          catalog: fixture.catalog,
          queries: PortableExpressionQueries(catalog: fixture.catalog),
          role: skir.PresentationRole.inspector,
          host: fixture.host,
          slotBuilders: {
            "probe": (scope) {
              observed = scope.material;
              return const SizedBox.shrink();
            },
          },
        ).withMaterial(document.material!);
        await tester.pumpTestApp(
          child: Material(
            child: PortablePresentationNodeRenderer(
              node: document.root,
              scope: scope,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(observed, isNotNull);
        expect(
          observed!.dependencies.collections.single.sourceId,
          "shared.source",
        );
        expect(
          observed!.dependencies.collections.single.relations.single.relationId,
          localPrefix ? "caller relation" : "source relation",
        );
        expect(observed!.dependencies.collections, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    "the same inherited source writes each nested owner independently",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(nestedOwners: true);
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));
      for (final (index, owner) in [(0, "first"), (2, "second")]) {
        await tester.enterText(fields.at(index), "  $owner quest  ");
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          fixture.writes.last.$1,
          editorRootPath.field(owner).field("name"),
        );
        expect(
          fixture.value
              .authoredField(owner)
              ?.authoredField("name")
              ?.authoredString,
          "$owner quest",
        );
      }
      expect(
        fixture.value
            .authoredField("first")
            ?.authoredField("name")
            ?.authoredString,
        "first quest",
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "a field requested by its own prefix ends with a recursion diagnostic",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(
        sourceName: inheritedFieldTextInput(
          "element.name",
          control: inheritedFieldControl(
            label: "Name",
            prefix: inheritedFieldRequest(),
          ),
          trim: true,
        ),
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        find.text("Field name presentation inheritance is recursive"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final remaining in [false, true]) {
    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.tab]) {
      testWidgets(
        "${remaining ? 'remaining fields' : 'authored field'} inherits trim on ${key.keyLabel}",
        (tester) async {
          final fixture = InheritedFieldPresentationScenario(
            layout: remaining ? inheritedFieldRemaining : null,
          );
          addTearDown(fixture.dispose);
          await _pump(tester, fixture);
          final inputs = find.byType(TextFormField);
          expect(inputs, findsNWidgets(2));
          expect(find.text("Name"), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(_editable(tester, 0).focusNode.hasFocus, isTrue);
          await tester.enterText(inputs.first, "  Quest name  ");
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(key);
          if (key == LogicalKeyboardKey.enter) {
            expect(_editable(tester, 0).textInputAction, TextInputAction.done);
            // The test engine delivers platform text actions separately.
            await tester.testTextInput.receiveAction(TextInputAction.done);
          }
          await tester.pumpAndSettle();
          expect(fixture.name, "Quest name");
          expect(fixture.writes.last.$1, editorRootPath.field("name"));
          if (key == LogicalKeyboardKey.tab) {
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pumpAndSettle();
            expect(_editable(tester, 1).focusNode.hasFocus, isTrue);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets("an explicit input replaces inherited completion", (
    tester,
  ) async {
    final fixture = InheritedFieldPresentationScenario(
      variant: InheritedFieldVariant.explicitControl,
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.text("Exact name"), findsOneWidget);
    expect(find.text("Name"), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, "  Exact name  ");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(fixture.name, "  Exact name  ");
    expect(tester.takeException(), isNull);
  });

  testWidgets("local labels reach the focused native editor and retain trim", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final fixture = InheritedFieldPresentationScenario(
      variant: InheritedFieldVariant.localLabel,
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.text("Action name"), findsOneWidget);
    expect(find.text("Name"), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_editable(tester, 0).focusNode.hasFocus, isTrue);
    expect(
      tester.getSemantics(find.byType(EditableText).first).label,
      "Action name",
    );
    await tester.enterText(find.byType(TextFormField).first, "  With label  ");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(fixture.name, "With label");
    expect(_editable(tester, 0).focusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets("semantic label overrides visible label independently", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final fixture = InheritedFieldPresentationScenario(
      layout: inheritedFieldColumn([
        inheritedFieldRequest(
          control: inheritedFieldControl(
            label: "Short label",
            semanticLabel: "Quest display name",
          ),
        ),
      ]),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.text("Short label"), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(EditableText)).label,
      "Quest display name",
    );
    semantics.dispose();
  });

  testWidgets(
    "an explicitly empty label suppresses inherited and fallback labels",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(
        layout: inheritedFieldRequest(
          control: inheritedFieldControl(label: ""),
        ),
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text("Name"), findsNothing);
      expect(find.text("name"), findsNothing);
      await tester.enterText(find.byType(TextFormField), "  Empty label  ");
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(fixture.name, "Empty label");
    },
  );

  testWidgets("inherited expressions read siblings of the destination record", (
    tester,
  ) async {
    final control = inheritedFieldControl().toMutable()
      ..label = skir.ExpressionNode.createInput(
        binding: inheritedConfiguredValue,
        path: editorRootPath.field("message"),
      );
    final fixture = InheritedFieldPresentationScenario(
      sourceName: inheritedFieldTextInput(
        "element.name",
        control: control.toFrozen(),
        trim: true,
      ),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.text("Hello player"), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).last, "Current message");
    await tester.pumpAndSettle();
    expect(find.text("Current message"), findsNWidgets(2));
    expect(find.text("Hello player"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("local prefixes replace the inherited prefix once", (
    tester,
  ) async {
    final fixture = InheritedFieldPresentationScenario(
      sourceName: inheritedFieldTextInput(
        "element.name",
        control: inheritedFieldControl(
          label: "Name",
          prefix: _prefix("Inherited prefix"),
        ),
        trim: true,
      ),
      layout: inheritedFieldRequest(
        control: inheritedFieldControl(prefix: _prefix("Local prefix")),
      ),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.text("Local prefix"), findsOneWidget);
    expect(find.text("Inherited prefix"), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets("hidden name requests stay reserved from remaining fields", (
    tester,
  ) async {
    final hidden = inheritedFieldNode(
      "hidden.name",
      skir.PresentationElement.wrapConditional(
        (skir.ConditionalElement.mutable()
              ..condition = skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapBoolean(false),
              )
              ..whenTrue = inheritedFieldRequest())
            .toFrozen(),
      ),
    );
    final fixture = InheritedFieldPresentationScenario(
      layout: inheritedFieldColumn([inheritedFieldRemaining, hidden]),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text("Welcome"), findsNothing);
    expect(find.text("Hello player"), findsOneWidget);
    expect(find.text("Name"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("local metadata cannot relax inherited read only restrictions", (
    tester,
  ) async {
    final source =
        inheritedFieldTextInput(
            "element.name",
            control: inheritedFieldControl(label: "Name"),
            trim: true,
          ).toMutable()
          ..properties =
              (skir.PresentationProperties.mutable()..readOnly = true)
                  .toFrozen();
    final fixture = InheritedFieldPresentationScenario(
      sourceName: source.toFrozen(),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(_editable(tester, 0).readOnly, isTrue);
    expect(_editable(tester, 1).readOnly, isFalse);
    expect(fixture.writes, isEmpty);
  });

  testWidgets("a local enabled condition cannot relax an inherited condition", (
    tester,
  ) async {
    final source =
        inheritedFieldTextInput(
            "element.name",
            control: inheritedFieldControl(label: "Name"),
            trim: true,
          ).toMutable()
          ..properties =
              (skir.PresentationProperties.mutable()
                    ..enabledIf = skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapBoolean(false),
                    ))
                  .toFrozen();
    final request = inheritedFieldRequest().toMutable()
      ..properties =
          (skir.PresentationProperties.mutable()
                ..enabledIf = skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapBoolean(true),
                ))
              .toFrozen();
    final fixture = InheritedFieldPresentationScenario(
      sourceName: source.toFrozen(),
      layout: inheritedFieldColumn([
        request.toFrozen(),
        inheritedFieldRemaining,
      ]),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(_editable(tester, 0).readOnly, isTrue);
    expect(_editable(tester, 1).readOnly, isFalse);
    expect(fixture.writes, isEmpty);
  });

  testWidgets(
    "a malformed winning reference diagnoses instead of falling back",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(
        referenceNodeId: "missing.name",
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text("Welcome"), findsNothing);
      expect(find.text("Hello player"), findsOneWidget);
      expect(
        find.textContaining(
          "Field presentation test:element for name at missing.name:",
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "an explicit control renders despite a malformed inherited reference",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(
        referenceNodeId: "missing.name",
        variant: InheritedFieldVariant.explicitControl,
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text("Exact name"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  InheritedFieldPresentationScenario fixture,
) async {
  await tester.pumpTestApp(
    child: Scaffold(body: PortablePresentationRenderer(host: fixture.host)),
  );
  await tester.pumpAndSettle();
}

EditableText _editable(WidgetTester tester, int index) =>
    tester.widget<EditableText>(find.byType(EditableText).at(index));

skir.PresentationNode _prefix(String label) => inheritedFieldNode(
  label,
  skir.PresentationElement.wrapText(
    (skir.TextContent.mutable()..value = inheritedFieldText(label)).toFrozen(),
  ),
);

skir.PresentationNode _siblingEditingName() => inheritedFieldTextInput(
  "element.name",
  control: inheritedFieldControl(
    label: "Name",
    prefix: inheritedFieldNode(
      "element.message.hidden",
      skir.PresentationElement.wrapConditional(
        (skir.ConditionalElement.mutable()
              ..condition = skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapBoolean(false),
              )
              ..whenTrue = inheritedFieldTextInput(
                "element.message.prefix",
                control: inheritedFieldControl(
                  field: "message",
                  label: "Related message",
                ),
              ))
            .toFrozen(),
      ),
    ),
  ),
  trim: true,
);
