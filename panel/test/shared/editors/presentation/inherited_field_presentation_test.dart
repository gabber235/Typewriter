import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

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
        final hiddenPrefix = presentationNode(
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
          sourceName: presentationNode(
            "element.name",
            skir.PresentationElement.wrapRecordInput(
              (skir.RecordControl.mutable()
                    ..control = inheritedFieldControl(
                      label: "Name",
                      prefix: hiddenPrefix,
                    )
                    ..fieldPresentation = presentationNode(
                      "source.body",
                      skir.PresentationElement.wrapScopedBinding(
                        skir.ScopedBindingElement(
                          binding: skir.BindingRef(
                            bindingId: inheritedConfiguredValue,
                            path: editorRootPath.field("name"),
                          ),
                          scopeBinding: declareBinding(
                            inheritedConfiguredValue,
                            skir.TypeTemplate.createNamed(
                              definition: definition,
                              arguments: const [],
                            ),
                          ),
                          child: inheritedFieldRemaining,
                        ),
                      ),
                    ))
                  .toFrozen(),
            ),
          ),
          layout: inheritedFieldRequest(
            control: inheritedFieldControl(
              prefix: replacePrefix
                  ? presentationText(
                      "Local prefix",
                      textLiteral("Local prefix"),
                    )
                  : null,
            ),
          ),
        );
        addTearDown(fixture.dispose);
        await tester.showPresentationHost(fixture.host);
        expect(
          find.text("Local prefix"),
          replacePrefix ? findsOneWidget : findsNothing,
        );
        expect(visibleTextFields(), hasLength(replacePrefix ? 2 : 1));
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
        sourceName: _siblingEditingName,
        layout: inheritedFieldColumn([
          inheritedFieldRequest(),
          inheritedFieldRemaining,
        ]),
      );
      addTearDown(fixture.dispose);
      await tester.showPresentationHost(fixture.host);
      expect(tester.takeException(), isNull);
      expect(visibleTextFields(), hasLength(1));
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
      expect(visibleFieldValues(), ["Hello player"]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final sourceInspector in [true, false]) {
    testWidgets(
      "unpublished multi field source ${sourceInspector ? 'renders locally' : 'allows consumer fallback'}",
      (tester) async {
        final fixture = InheritedFieldPresentationScenario(
          sourceName: _siblingEditingName,
          publishNameDefault: false,
          useSourceInspector: sourceInspector,
        );
        addTearDown(fixture.dispose);
        final panel = await tester.showPresentationHost(fixture.host);
        expect(visibleTextFields(), hasLength(sourceInspector ? 1 : 2));
        expect(
          find.textContaining("Field presentation test:element"),
          findsNothing,
        );
        await panel.fieldAt(0).type("  Local policy  ");
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
      final inspector = ValueInspector(
        compiledSdkElementValue,
        catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
      );
      final host = inspector.host();
      addTearDown(host.dispose);
      final panel = await tester.showComponent(
        Scaffold(body: PortablePresentationRenderer(host: host)),
      );
      final name = visibleFieldValues().indexOf(
        compiledSdkElementValue.authoredField("name")!.authoredString!,
      );
      expect(name, isNot(-1));
      await panel.fieldAt(name).type("  Compiled greeting  ");
      await panel.press(LogicalKeyboardKey.escape);
      expect(
        inspector.value.authoredField("name")?.authoredString,
        "Compiled greeting",
      );
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
      sourceName: presentationNode(
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
    final panel = await tester.showPresentationHost(fixture.host);
    expect(visibleTextFields(), hasLength(1));
    expect(find.text("Optional name"), findsOneWidget);
    expect(find.text("Name"), findsNothing);
    await panel.fieldAt(0).type("  Optional quest  ");
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(fixture.name, "Optional quest");
    expect(tester.takeException(), isNull);
  });
  for (final localPrefix in [false, true]) {
    testWidgets(
      "${localPrefix ? 'local' : 'inherited'} prefix lists its collection from its declaring material",
      (tester) async {
        final row = skir.ExpressionBindingId(value: "shared.row");
        skir.PresentationDependencies dependencies(String relation) =>
            (skir.PresentationDependencies.mutable()
                  ..collections = [
                    (skir.PresentationCollectionDefinition.mutable()
                          ..sourceId = "shared.source"
                          ..rowBinding = declareBinding(row, textTemplate)
                          ..key = skir.ExpressionNode.createInput(
                            binding: row,
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
                          ]
                          ..projection =
                              (skir.PresentationCollectionProjection.mutable()
                                    ..root = skir.NamedTypeTemplate(
                                      definition:
                                          inheritedActionType.definition,
                                      arguments: const [],
                                    )
                                    ..resourceBinding = declareNamedBinding(
                                      "shared.resource",
                                      skir.TypeUse.wrapNamed(
                                        skir.resourceIdType,
                                      ).portableTemplate,
                                    ))
                                  .toFrozen())
                        .toFrozen(),
                  ])
                .toFrozen();
        // Shows the row whose key is the record's name, as the collection
        // the prefix reads lists it.
        final prefix = presentationNode(
          "shared.lookup",
          skir.PresentationElement.wrapCollectionLookup(
            (skir.CollectionLookupElement.mutable()
                  ..sourceId = "shared.source"
                  ..key = skir.BindingRef(
                    bindingId: inheritedConfiguredValue,
                    path: editorRootPath.field("message"),
                  )
                  ..found = presentationNode(
                    "shared.found",
                    skir.PresentationElement.wrapText(
                      (skir.TextContent.mutable()
                            ..value = skir.ExpressionNode.createInput(
                              binding: row,
                              path: editorRootPath,
                            ))
                          .toFrozen(),
                    ),
                  )
                  ..missing = presentationText(
                    "shared.missing",
                    textLiteral("No row"),
                  ))
                .toFrozen(),
          ),
        );
        final fixture = InheritedFieldPresentationScenario(
          sourceDependencies: dependencies("source relation"),
          customDependencies: dependencies("caller relation"),
          sourceName: inheritedFieldTextInput(
            "element.name",
            control: inheritedFieldControl(label: "Name", prefix: prefix),
            trim: true,
          ),
          layout: inheritedFieldRequest(
            control: inheritedFieldControl(prefix: localPrefix ? prefix : null),
          ),
        );
        addTearDown(fixture.dispose);
        // A Realm whose collection rows depend on the collection definition
        // the presentation material declares: each relation lists its own
        // row for the message the record holds.
        final host = ProjectingHost(
          fixture.host,
          collections: (sourceId, material) {
            final definition = material.dependencies.collections.singleWhere(
              (candidate) => candidate.sourceId == sourceId,
            );
            final key = skir.DataValue.wrapStringValue("Hello player");
            return PortableCollectionProjection(
              definition: definition,
              rows: [
                PortableCollectionRowProjection(
                  resource: skir.ResourceId(value: "shared:row"),
                  configuration: skir.TypeSelection.unknown,
                  label: "Row",
                  row: skir.DataValue.wrapStringValue(
                    "Row of ${definition.relations.single.relationId}",
                  ),
                  key: key,
                  canonicalKey: canonicalAuthoredValue(key),
                  selectable: true,
                ),
              ],
            );
          },
        );
        await tester.showComponent(
          Scaffold(body: PortablePresentationRenderer(host: host)),
        );
        expect(
          find.text(
            localPrefix ? "Row of caller relation" : "Row of source relation",
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            localPrefix ? "Row of source relation" : "Row of caller relation",
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    "the same inherited source writes each nested owner independently",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(nestedOwners: true);
      addTearDown(fixture.dispose);
      final panel = await tester.showPresentationHost(fixture.host);
      expect(visibleTextFields(), hasLength(4));
      for (final (index, owner) in [(0, "first"), (2, "second")]) {
        await panel.fieldAt(index).type("  $owner quest  ");
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
      await tester.showPresentationHost(fixture.host);
      expect(visibleTextFields(), hasLength(2));
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
          final panel = await tester.showPresentationHost(fixture.host);
          expect(visibleTextFields(), hasLength(2));
          expect(find.text("Name"), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(panel.fieldAt(0).isFocused, isTrue);
          await panel.fieldAt(0).type("  Quest name  ");
          await tester.sendKeyEvent(key);
          if (key == LogicalKeyboardKey.enter) {
            expect(
              tester.testTextInput.setClientArgs?["inputAction"],
              TextInputAction.done.toString(),
            );
            // The test engine delivers platform text actions separately.
            await tester.testTextInput.receiveAction(TextInputAction.done);
          }
          await tester.pumpAndSettle();
          expect(fixture.name, "Quest name");
          expect(fixture.writes.last.$1, editorRootPath.field("name"));
          if (key == LogicalKeyboardKey.tab) {
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pumpAndSettle();
            expect(panel.fieldAt(1).isFocused, isTrue);
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
    final panel = await tester.showPresentationHost(fixture.host);
    expect(find.text("Exact name"), findsOneWidget);
    expect(find.text("Name"), findsNothing);
    await panel.fieldAt(0).type("  Exact name  ");
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(fixture.name, "  Exact name  ");
    expect(tester.takeException(), isNull);
  });

  testWidgets("local labels reach the focused native editor and retain trim", (
    tester,
  ) async {
    final fixture = InheritedFieldPresentationScenario(
      variant: InheritedFieldVariant.localLabel,
    );
    addTearDown(fixture.dispose);
    final panel = await tester.showPresentationHost(fixture.host);
    expect(find.text("Action name"), findsOneWidget);
    expect(find.text("Name"), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(panel.fieldAt(0).isFocused, isTrue);
    expect(visibleTextFields().first.spoken, "Action name");
    await panel.fieldAt(0).type("  With label  ");
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(fixture.name, "With label");
    // Escape ends editing: the field takes no more typed text.
    expect(tester.testTextInput.hasAnyClients, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets("semantic label overrides visible label independently", (
    tester,
  ) async {
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
    await tester.showPresentationHost(fixture.host);
    expect(find.text("Short label"), findsOneWidget);
    expect(visibleTextFields().single.spoken, "Quest display name");
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
      final panel = await tester.showPresentationHost(fixture.host);
      expect(visibleTextFields(), hasLength(1));
      expect(find.text("Name"), findsNothing);
      expect(find.text("name"), findsNothing);
      await panel.fieldAt(0).type("  Empty label  ");
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
    final panel = await tester.showPresentationHost(fixture.host);
    expect(find.text("Hello player"), findsNWidgets(2));
    await panel.fieldAt(1).type("Current message");
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
          prefix: presentationText(
            "Inherited prefix",
            textLiteral("Inherited prefix"),
          ),
        ),
        trim: true,
      ),
      layout: inheritedFieldRequest(
        control: inheritedFieldControl(
          prefix: presentationText("Local prefix", textLiteral("Local prefix")),
        ),
      ),
    );
    addTearDown(fixture.dispose);
    await tester.showPresentationHost(fixture.host);
    expect(find.text("Local prefix"), findsOneWidget);
    expect(find.text("Inherited prefix"), findsNothing);
    expect(visibleTextFields(), hasLength(1));
  });

  testWidgets("hidden name requests stay reserved from remaining fields", (
    tester,
  ) async {
    final hidden = presentationNode(
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
    await tester.showPresentationHost(fixture.host);
    expect(visibleTextFields(), hasLength(1));
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
    final panel = await tester.showPresentationHost(fixture.host);
    expect(panel.fieldAt(0).isReadOnly, isTrue);
    expect(panel.fieldAt(1).isReadOnly, isFalse);
    await panel.fieldAt(0).enter("Changed name");
    expect(fixture.name, "Welcome");
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
    final panel = await tester.showPresentationHost(fixture.host);
    expect(panel.fieldAt(0).isReadOnly, isTrue);
    expect(panel.fieldAt(1).isReadOnly, isFalse);
    await panel.fieldAt(0).enter("Changed name");
    expect(fixture.name, "Welcome");
    expect(fixture.writes, isEmpty);
  });

  testWidgets(
    "a malformed winning reference diagnoses instead of falling back",
    (tester) async {
      final fixture = InheritedFieldPresentationScenario(
        referenceNodeId: "missing.name",
      );
      addTearDown(fixture.dispose);
      await tester.showPresentationHost(fixture.host);
      expect(visibleTextFields(), hasLength(1));
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
      await tester.showPresentationHost(fixture.host);
      expect(visibleTextFields(), hasLength(2));
      expect(find.text("Exact name"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final _siblingEditingName = inheritedFieldTextInput(
  "element.name",
  control: inheritedFieldControl(
    label: "Name",
    prefix: presentationNode(
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
