import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final sourceName in ["source", "configured_value"]) {
    testWidgets(
      "default provider guidance offers two fields and an action from $sourceName",
      (tester) async {
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
        var value = named("initial");
        final inner = skir.BindingRef(
          bindingId: configured,
          path: editorRootPath,
        );
        skir.PresentationNode field(String label) => presentationNode(
          label,
          skir.PresentationElement.wrapTextInput(
            (skir.TextControl.mutable()
                  ..control = (skir.BoundControl.mutable()
                    ..binding = inner
                    ..label = textLiteral(label)
                    ..semanticLabel = textLiteral(label)))
                .toFrozen(),
          ),
        );
        final layout = presentationColumn("column", [
          field("Left input"),
          field("Right input"),
          presentationNode(
            "action",
            skir.PresentationElement.wrapButton(
              (skir.ButtonElement.mutable()
                    ..label = textLiteral("Apply value")
                    ..action = skir.EditorAction.wrapLocal(
                      skir.LocalEditorAction.createSetValue(
                        target: inner,
                        value: skir.ExpressionNode.wrapLiteral(named("action")),
                      ),
                    ))
                  .toFrozen(),
            ),
          ),
        ]);
        final catalog = CheckedEditorCatalog(
          (skir.EditorCatalog.mutable()
                ..generation = skir.CatalogGeneration(value: "configured")
                ..types = [
                  (skir.PublishedType.mutable()
                        ..status = skir.DeclarationStatus.ready
                        ..definition = (skir.TypeDefinition.mutable()
                          ..id = definition
                          ..representation =
                              skir.RepresentationTemplate.createScalar(
                                kind: skir.ScalarKind.text,
                              )))
                      .toFrozen(),
                ]
                ..presentationMaterials = [
                  (skir.PresentationMaterial.mutable()
                        ..provider = provider
                        ..target = skir.PresentationTarget.createNamed(
                          definition: definition,
                          arguments: const [],
                        )
                        ..role = skir.PresentationRole.inspector
                        ..layout = layout
                        ..subject = skir.TypeTemplate.createNamed(
                          definition: definition,
                          arguments: const [],
                        ))
                      .toFrozen(),
                ])
              .toFrozen(),
        );
        final root = presentationNode(
          "default",
          skir.PresentationElement.wrapDefaultPresentation(
            (skir.DefaultPresentationElement.mutable()
                  ..control = (skir.BoundControl.mutable()
                    ..binding = skir.BindingRef(
                      bindingId: source,
                      path: editorRootPath,
                    )
                    ..label = textLiteral("Compound guidance")
                    ..description = textLiteral("Edit either view"))
                  ..presentationId = provider)
                .toFrozen(),
          ),
        );
        final panel = await tester.showPresentation(
          () => root,
          bindings: [
            wholeValueBinding(
              source,
              skir.TypeUse.wrapNamed(actual),
              read: () => value,
              write: (next) => value = next,
            ),
          ],
          catalog: catalog,
        );
        expect(panel.shows("Compound guidance"), isTrue);
        expect(panel.field("Left input").exists, isTrue);
        expect(panel.field("Right input").exists, isTrue);
        expect(semanticsLabeled("Apply value").single.isButton, isTrue);

        await panel.field("Left input").type("left");
        await panel.press(LogicalKeyboardKey.escape);
        await panel.press(LogicalKeyboardKey.tab);
        await panel.press(LogicalKeyboardKey.space);
        expect(panel.field("Right input").isFocused, isTrue);
        await panel.field("Right input").type("right");
        await panel.press(LogicalKeyboardKey.escape);
        await panel.press(LogicalKeyboardKey.tab);
        await panel.press(LogicalKeyboardKey.enter);
        expect(value.authoredPayload, skir.DataValue.wrapStringValue("action"));
      },
    );
  }

  testWidgets("completion rounds the latest typing while an earlier write is "
      "still pending", (tester) async {
    final pending = Completer<void>();
    var value = skir.DataValue.wrapFloat(1);
    final id = skir.ExpressionBindingId(value: "number");
    final control = formattedNumberControl(id, rounded: true);
    var writes = 0;
    final panel = await tester.showPresentation(
      () => presentationNode(
        "numeric",
        skir.PresentationElement.wrapNumericInput(control),
      ),
      bindings: [
        BoundPresentationBinding(
          id: id,
          use: skir.TypeUse.wrapScalar(float64),
          read: (_) => value,
          write: (_, next) async {
            writes++;
            if (writes == 1) await pending.future;
            value = next;
            return const PortablePresentationWriteApplied();
          },
        ),
      ],
    );
    final field = panel.fieldAt(0);
    await field.type("1.25");
    await field.type("1.26");
    expect(field.value, "1.26");
    await panel.press(LogicalKeyboardKey.escape);
    pending.complete();
    await panel.settle();
    expect(value, skir.DataValue.wrapFloat(1.5));
  });

  testWidgets(
    "display formatting shows outside editing and the exact value while editing",
    (tester) async {
      var value = skir.DataValue.wrapFloat(1.5);
      final control = formattedNumberControl(
        skir.ExpressionBindingId(value: "number"),
      );
      final panel = await tester.showNumberInput(
        control,
        read: () => value,
        write: (next) => value = next,
      );
      final field = panel.fieldAt(0);
      expect(field.value, "1.50");
      await panel.press(LogicalKeyboardKey.tab);
      await panel.press(LogicalKeyboardKey.enter);
      expect(field.value, "1.5");
    },
  );

  testWidgets("clearing a mapped number writes unfilled", (tester) async {
    var value = skir.DataValue.wrapFloat(1.5);
    final control = formattedNumberControl(
      skir.ExpressionBindingId(value: "number"),
    );
    final panel = await tester.showNumberInput(
      control,
      read: () => value,
      write: (next) => value = next,
    );
    await panel.fieldAt(0).type("");
    await panel.press(LogicalKeyboardKey.escape);
    expect(value, skir.DataValue.unfilled);
  });

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
    final panel = await tester.showPresentation(
      () => presentationNode(
        "float32",
        skir.PresentationElement.wrapNumericInput(control),
      ),
      bindings: [
        wholeValueBinding(
          id,
          use,
          read: () => value,
          write: (next) => value = next,
        ),
      ],
    );
    await panel.fieldAt(0).type("0.26");
    await panel.press(LogicalKeyboardKey.escape);
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
    "an out of range duration draft stays visible with the range message",
    (tester) async {
      final id = skir.ExpressionBindingId(value: "duration");
      final maximum = skir.DataValue.createDuration(
        value: skir.Duration(
          milliseconds: PortableDurationMilliseconds.maximum,
        ),
      );
      var value = maximum;
      final panel = await tester.showPresentation(
        () => presentationNode(
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
          wholeValueBinding(
            id,
            skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
            read: () => value,
            write: (next) => value = next,
          ),
        ],
      );
      final field = panel.fieldAt(0);
      expect(
        field.value,
        PortableDurationMilliseconds.maximum.portableDurationText,
      );
      final invalid =
          "${BigInt.from(PortableDurationMilliseconds.maximum) + BigInt.one}ms";
      await field.type(invalid);
      await panel.press(LogicalKeyboardKey.escape);
      expect(field.value, invalid);
      expect(value, maximum);
      expect(panel.shows("Duration exceeds the supported range"), isTrue);
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
      final panel = await tester.showPresentation(
        () => presentationNode(
          "states",
          skir.PresentationElement.wrapNumericInput(control),
        ),
        bindings: [
          wholeValueBinding(
            id,
            skir.TypeUse.wrapScalar(
              skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
            ),
            read: () => value,
            write: (next) => value = next,
          ),
        ],
      );
      final field = panel.field("Native states");
      Color? labelColor() => tester
          .widget<LabeledMessage>(find.byType(LabeledMessage))
          .labelStyle
          ?.color;
      expect(labelColor(), const Color(0xff101010));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(field.rect.center);
      await panel.settle();
      expect(labelColor(), const Color(0xff0000a0));
      await field.type("2");
      expect(labelColor(), const Color(0xff008000));
      await field.type("2e");
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
      final panel = await tester.showPresentation(
        () => root,
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
          wholeValueBinding(
            number,
            skir.TypeUse.wrapScalar(
              skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
            ),
            read: () => value,
            write: (next) => value = next,
          ),
        ],
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.numbers)).color,
        const Color(0xff00ff00),
      );
      await panel.fieldAt(0).type("4");
      expect(value, skir.DataValue.wrapFloat(4));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.numbers)).color,
        const Color(0xff00ff00),
      );
    },
  );
}
