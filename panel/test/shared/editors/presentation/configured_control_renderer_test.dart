import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  for (final sourceName in ["source", "configured_value"]) {
    testWidgets(
      "default provider guidance preserves two native fields and an action from $sourceName",
      (tester) async {
        final semantics = tester.ensureSemantics();

        final source = skir.ExpressionBindingId(value: sourceName);
        final configured = skir.ExpressionBindingId(value: "configured_value");
        final definition = skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "test",
            name: "ConfiguredText",
          ),
          revision: 1,
        );
        final actual = skir.NamedTypeUse(
          definition: definition,
          arguments: const [],
        );
        final provider = skir.PresentationId(
          namespace: "test",
          name: "compound",
        );
        skir.DataValue named(String text) => skir.DataValue.createNamed(
          actualType: actual,
          payload: skir.DataValue.wrapStringValue(text),
        );
        final rootReference = skir.BindingRef(
          bindingId: source,
          path: editorRootPath,
        );
        final innerReference = skir.BindingRef(
          bindingId: configured,
          path: editorRootPath,
        );
        skir.PresentationNode field(String label) => presentationNode(
          label,
          skir.PresentationElement.wrapTextInput(
            (skir.TextControl.mutable()
                  ..control = (skir.BoundControl.mutable()
                    ..binding = innerReference
                    ..label = textLiteral(label)
                    ..semanticLabel = textLiteral(label)))
                .toFrozen(),
          ),
        );
        final action = skir.EditorAction.wrapLocal(
          skir.LocalEditorAction.createSetValue(
            target: innerReference,
            value: skir.ExpressionNode.wrapLiteral(named("action")),
          ),
        );
        final body = presentationColumn("column", [
          field("Left input"),
          field("Right input"),
          presentationNode(
            "action",
            skir.PresentationElement.wrapButton(
              (skir.ButtonElement.mutable()
                    ..label = textLiteral("Apply value")
                    ..action = action)
                  .toFrozen(),
            ),
          ),
        ]);
        final material =
            (skir.PresentationMaterial.mutable()
                  ..provider = provider
                  ..target = skir.PresentationTarget.createNamed(
                    definition: definition,
                    arguments: const [],
                  )
                  ..role = skir.PresentationRole.inspector
                  ..layout = body
                  ..subject = skir.TypeTemplate.createNamed(
                    definition: definition,
                    arguments: const [],
                  ))
                .toFrozen();
        final published =
            (skir.PublishedType.mutable()
                  ..status = skir.DeclarationStatus.ready
                  ..definition = (skir.TypeDefinition.mutable()
                    ..id = definition
                    ..representation = skir.RepresentationTemplate.createScalar(
                      kind: skir.ScalarKind.text,
                    )))
                .toFrozen();
        final catalog = CheckedEditorCatalog(
          (skir.EditorCatalog.mutable()
                ..generation = skir.CatalogGeneration(value: "configured")
                ..types = [published]
                ..presentationMaterials = [material])
              .toFrozen(),
        );
        var value = named("initial");
        final writes = <skir.DataValue>[];
        final root = presentationNode(
          "default",
          skir.PresentationElement.wrapDefaultPresentation(
            (skir.DefaultPresentationElement.mutable()
                  ..control = (skir.BoundControl.mutable()
                    ..binding = rootReference
                    ..label = textLiteral("Compound guidance")
                    ..description = textLiteral("Edit either view"))
                  ..presentationId = provider)
                .toFrozen(),
          ),
        );
        final host = BoundPresentationHost(
          catalog: catalog,
          root: () => root,
          bindings: [
            BoundPresentationBinding(
              id: source,
              use: skir.TypeUse.wrapNamed(actual),
              read: (_) => value,
              write: (_, next) {
                value = next;
                writes.add(next);
                return const PortablePresentationWriteApplied();
              },
            ),
          ],
          budget: skir.EvaluationBudget(
            maxSteps: 1000,
            maxCollectionItems: 1000,
          ),
        );
        addTearDown(host.dispose);
        await tester.pumpTestApp(
          child: Scaffold(body: PortablePresentationRenderer(host: host)),
        );
        expect(find.text("Compound guidance"), findsOneWidget);
        expect(find.byType(PortableDiagnosticFrame), findsNWidgets(2));
        final fields = find.byType(TextFormField);
        expect(fields, findsNWidgets(2));
        expect(
          tester.getSemantics(fields.at(0)).getSemanticsData().label,
          contains("Left input"),
        );
        expect(
          tester.getSemantics(fields.at(1)).getSemanticsData().label,
          contains("Right input"),
        );
        final button = find.byType(FilledButton);
        expect(button, findsOneWidget);
        expect(
          tester
              .getSemantics(button)
              .getSemanticsData()
              .flagsCollection
              .isButton,
          isTrue,
        );
        await tester.enterText(fields.at(0), "left");
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(
                find.descendant(
                  of: fields.at(1),
                  matching: find.byType(EditableText),
                ),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        await tester.enterText(fields.at(1), "right");
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(value.authoredPayload, skir.DataValue.wrapStringValue("action"));
        expect(writes, hasLength(3));
        semantics.dispose();
      },
    );
  }
  testWidgets(
    "completion follows pending typing and display remains separate from exact editing",
    (tester) async {
      final id = skir.ExpressionBindingId(value: "number");
      final candidate = skir.ExpressionBindingId(value: "candidate");
      final read = skir.ExpressionNode.createInput(
        binding: candidate,
        path: editorRootPath,
      );
      final mappings = skir.ValueMappings(
        completion: skir.ExpressionMapping(
          inputBinding: declareBinding(
            candidate,
            scalarTemplate(
              skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
            ),
          ),
          body: portableCall("number.round", [
            read,
            literalExpression(skir.DataValue.wrapFloat(0.5)),
            skir.ExpressionNode.wrapLiteral(
              skir.RoundingMode.nearestTiesToEven.toDataValue(),
            ),
          ]),
        ),
        display: skir.ExpressionMapping(
          inputBinding: declareBinding(
            candidate,
            scalarTemplate(
              skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
            ),
          ),
          body: portableCall("number.format", [
            read,
            literalExpression(skir.DataValue.wrapInteger("2")),
            textLiteral("en-US"),
          ]),
        ),
      );
      final control =
          (skir.NumericControl.mutable()
                ..control = (skir.BoundControl.mutable()
                  ..binding = skir.BindingRef(
                    bindingId: id,
                    path: editorRootPath,
                  ))
                ..mappings = mappings)
              .toFrozen();
      var value = skir.DataValue.wrapFloat(1.0);
      final writes = <skir.DataValue>[];
      final pending = Completer<void>();
      final host = BoundPresentationHost(
        catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
        root: () => presentationNode(
          "numeric",
          skir.PresentationElement.wrapNumericInput(control),
        ),
        bindings: [
          BoundPresentationBinding(
            id: id,
            use: skir.TypeUse.wrapScalar(
              skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
            ),
            read: (_) => value,
            write: (_, next) async {
              writes.add(next);
              if (writes.length == 1) await pending.future;
              value = next;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      );
      addTearDown(host.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: PortablePresentationRenderer(host: host)),
      );
      final field = find.byType(TextFormField);
      await tester.enterText(field, "1.25");
      await tester.pump();
      await tester.enterText(field, "1.26");
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        "1.26",
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(writes, [skir.DataValue.wrapFloat(1.25)]);
      pending.complete();
      await tester.pumpAndSettle();
      expect(writes, [
        skir.DataValue.wrapFloat(1.25),
        skir.DataValue.wrapFloat(1.26),
        skir.DataValue.wrapFloat(1.5),
      ]);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        "1.50",
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        "1.5",
      );
      await tester.enterText(field, "");
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(value, skir.DataValue.unfilled);
      expect(writes, hasLength(4));
    },
  );

  testWidgets("explicit Float32 completion reuses scalar width admission", (
    tester,
  ) async {
    final id = skir.ExpressionBindingId(value: "float32");
    final candidate = skir.ExpressionBindingId(value: "candidate");
    final use = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
    );
    var value = admitPortableNumericInput(
      current: skir.DataValue.unfilled,
      expected: use,
      text: "0.1",
    )!;
    final control =
        (skir.NumericControl.mutable()
              ..control = (skir.BoundControl.mutable()
                ..binding = skir.BindingRef(
                  bindingId: id,
                  path: editorRootPath,
                ))
              ..mappings = skir.ValueMappings(
                display: null,
                completion: skir.ExpressionMapping(
                  inputBinding: declareBinding(candidate, use.portableTemplate),
                  body: portableCall("number.round", [
                    skir.ExpressionNode.createInput(
                      binding: candidate,
                      path: editorRootPath,
                    ),
                    literalExpression(skir.DataValue.wrapFloat(0.1)),
                    skir.ExpressionNode.wrapLiteral(
                      skir.RoundingMode.nearestTiesToEven.toDataValue(),
                    ),
                  ]),
                ),
              ))
            .toFrozen();
    final host = BoundPresentationHost(
      catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
      root: () => presentationNode(
        "float32",
        skir.PresentationElement.wrapNumericInput(control),
      ),
      bindings: [
        BoundPresentationBinding(
          id: id,
          use: use,
          read: (_) => value,
          write: (_, next) {
            value = next;
            return const PortablePresentationWriteApplied();
          },
        ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    );
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Scaffold(body: PortablePresentationRenderer(host: host)),
    );
    await tester.enterText(find.byType(TextFormField), "0.26");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      value,
      admitPortableNumericInput(
        current: skir.DataValue.unfilled,
        expected: use,
        text: "0.3",
      ),
    );
  });

  testWidgets(
    "duration boundary edits remain finite and invalid drafts remain visible",
    (tester) async {
      final id = skir.ExpressionBindingId(value: "duration");
      var value = skir.DataValue.createDuration(
        value: skir.Duration(
          milliseconds: PortableDurationMilliseconds.maximum,
        ),
      );
      final host = BoundPresentationHost(
        catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
        root: () => presentationNode(
          "duration",
          skir.PresentationElement.wrapDurationInput(
            (skir.DurationControl.mutable()
                  ..control = (skir.BoundControl.mutable()
                    ..binding = skir.BindingRef(
                      bindingId: id,
                      path: editorRootPath,
                    )))
                .toFrozen(),
          ),
        ),
        bindings: [
          BoundPresentationBinding(
            id: id,
            use: skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
            read: (_) => value,
            write: (_, next) {
              value = next;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      );
      addTearDown(host.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: PortablePresentationRenderer(host: host)),
      );
      final field = find.byType(TextFormField);
      final encoded = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller
          .text;
      await tester.enterText(field, encoded);
      await tester.pumpAndSettle();
      expect(
        value,
        skir.DataValue.createDuration(
          value: skir.Duration(
            milliseconds: PortableDurationMilliseconds.maximum,
          ),
        ),
      );
      for (final entry in {
        "2w 5d 23h 59m 59s 999ms": 1727999999,
        "-1h 2min 3s": -3723000,
        "+1000us": 1,
        "0ms": 0,
      }.entries) {
        await tester.enterText(field, entry.key);
        await tester.pumpAndSettle();
        expect(
          value,
          skir.DataValue.createDuration(
            value: skir.Duration(milliseconds: entry.value),
          ),
        );
      }
      for (final invalid in ["1.5s", "1us", "1m 2min", "1h, 2m", "01:02:03"]) {
        await tester.enterText(field, invalid);
        await tester.pumpAndSettle();
        expect(
          value,
          skir.DataValue.createDuration(value: skir.Duration(milliseconds: 0)),
        );
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          invalid,
        );
      }
      await tester.enterText(
        field,
        "-${PortableDurationMilliseconds.maximum}ms",
      );
      await tester.pumpAndSettle();
      expect(
        value,
        skir.DataValue.createDuration(
          value: skir.Duration(
            milliseconds: -PortableDurationMilliseconds.maximum,
          ),
        ),
      );
      final invalid =
          "${BigInt.from(PortableDurationMilliseconds.maximum) + BigInt.one}ms";
      await tester.enterText(field, invalid);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        invalid,
      );
      expect(
        value,
        skir.DataValue.createDuration(
          value: skir.Duration(
            milliseconds: -PortableDurationMilliseconds.maximum,
          ),
        ),
      );
      expect(find.text("Duration exceeds the supported range"), findsOneWidget);
    },
  );
  testWidgets(
    "native focus hover and invalid observation styles the same control label",
    (tester) async {
      final id = skir.ExpressionBindingId(value: "states");
      skir.PresentationColor paint(int value) =>
          skir.PresentationColor.wrapValue(
            literalExpression(skir.DataValue.wrapInteger(value.toString())),
          );
      final policy = skir.PresentationColor.wrapStates(
        skir.PresentationStateColor(
          rules: [
            for (final entry in {
              skir.PresentationInteractionState.invalid: 0xffa00000,
              skir.PresentationInteractionState.focused: 0xff008000,
              skir.PresentationInteractionState.hovered: 0xff0000a0,
            }.entries)
              skir.PresentationStateColorRule(
                match: skir.PresentationStateMatch(
                  required_: [entry.key],
                  excluded: const [],
                ),
                color: paint(entry.value),
              ),
          ],
          fallback: paint(0xff101010),
        ),
      );
      var value = skir.DataValue.wrapFloat(1);
      final control =
          (skir.NumericControl.mutable()
                ..control = (skir.BoundControl.mutable()
                  ..binding = skir.BindingRef(
                    bindingId: id,
                    path: editorRootPath,
                  )
                  ..label = textLiteral("Native states"))
                ..appearance =
                    (skir.InputAppearance.mutable()
                          ..labelStyle =
                              (skir.InputTextStyle.mutable()..color = policy)
                                  .toFrozen()
                          ..iconColor = policy)
                        .toFrozen())
              .toFrozen();
      final host = BoundPresentationHost(
        catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
        root: () => presentationNode(
          "states",
          skir.PresentationElement.wrapNumericInput(control),
        ),
        bindings: [
          BoundPresentationBinding(
            id: id,
            use: skir.TypeUse.wrapScalar(
              skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
            ),
            read: (_) => value,
            write: (_, next) {
              value = next;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      );
      addTearDown(host.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: PortablePresentationRenderer(host: host)),
      );
      Color? labelColor() => tester
          .widget<LabeledMessage>(find.byType(LabeledMessage))
          .labelStyle
          ?.color;
      expect(labelColor(), const Color(0xff101010));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(TextField)));
      await tester.pumpAndSettle();
      expect(labelColor(), const Color(0xff0000a0));
      await tester.enterText(find.byType(TextFormField), "2");
      await tester.pumpAndSettle();
      expect(labelColor(), const Color(0xff008000));
      await tester.enterText(find.byType(TextFormField), "2e");
      await tester.pumpAndSettle();
      expect(labelColor(), const Color(0xffa00000));
      expect(value, skir.DataValue.wrapFloat(2));
      await mouse.removePointer();
    },
  );

  testWidgets(
    "group appearance retains declaration bindings across a nested control alias",
    (tester) async {
      final configured = skir.ExpressionBindingId(value: "configured_value");
      final number = skir.ExpressionBindingId(value: "number");
      var value = skir.DataValue.wrapFloat(3);
      final root = presentationNode(
        "group",
        skir.PresentationElement.wrapAppearanceDefaults(
          skir.AppearanceDefaultsElement(
            appearance:
                (skir.InputAppearance.mutable()
                      ..iconColor = skir.PresentationColor.wrapValue(
                        skir.ExpressionNode.createInput(
                          binding: configured,
                          path: editorRootPath,
                        ),
                      ))
                    .toFrozen(),
            child: presentationNode(
              "alias",
              skir.PresentationElement.wrapScopedBinding(
                skir.ScopedBindingElement(
                  binding: skir.BindingRef(
                    bindingId: number,
                    path: editorRootPath,
                  ),
                  scopeBinding: declareBinding(
                    configured,
                    scalarTemplate(
                      skir.ScalarKind.createFloat(
                        width: skir.FloatWidth.sixtyFour,
                      ),
                    ),
                  ),
                  child: presentationNode(
                    "number",
                    skir.PresentationElement.wrapNumericInput(
                      (skir.NumericControl.mutable()
                            ..control = (skir.BoundControl.mutable()
                              ..binding = skir.BindingRef(
                                bindingId: configured,
                                path: editorRootPath,
                              )))
                          .toFrozen(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final host = BoundPresentationHost(
        catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
        root: () => root,
        bindings: [
          BoundPresentationBinding(
            id: configured,
            use: skir.TypeUse.wrapScalar(
              skir.ScalarKind.createInteger(
                width: skir.IntegerWidth.unsignedThirtyTwo,
              ),
            ),
            read: (_) => skir.DataValue.wrapInteger("4278255360"),
          ),
          BoundPresentationBinding(
            id: number,
            use: skir.TypeUse.wrapScalar(
              skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
            ),
            read: (_) => value,
            write: (_, next) {
              value = next;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      );
      addTearDown(host.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: PortablePresentationRenderer(host: host)),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.numbers)).color,
        const Color(0xff00ff00),
      );
      await tester.enterText(find.byType(TextFormField), "4");
      await tester.pumpAndSettle();
      expect(value, skir.DataValue.wrapFloat(4));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.numbers)).color,
        const Color(0xff00ff00),
      );
    },
  );
}
