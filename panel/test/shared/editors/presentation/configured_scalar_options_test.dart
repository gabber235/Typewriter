import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final configured in [false, true]) {
    testWidgets(
      "dropdown ${configured ? "with" : "without"} sparse overrides opens and writes the chosen option",
      (tester) async {
        final fixture = EditedValue.scalar(
          skir.DataValue.wrapStringValue(""),
          skir.ScalarKind.text,
        );
        final input =
            (skir.SelectControl.mutable()
                  ..control =
                      (fixture.control.toMutable()
                            ..label = textLiteral("Realm target"))
                          .toFrozen()
                  ..options = [
                    (skir.SelectOption.mutable()
                          ..optionId = "paper"
                          ..label = textLiteral("typewritermc:paper")
                          ..value = textLiteral("paper"))
                        .toFrozen(),
                  ]
                  ..appearance = configured
                      ? (skir.InputAppearance.mutable()
                              ..density = skir.ControlDensity.compact)
                            .toFrozen()
                      : null
                  ..popup = configured
                      ? (skir.PopupAppearance.mutable()
                              ..fill = skir.PresentationColor.wrapValue(
                                literalExpression(
                                  skir.DataValue.wrapInteger("4278190335"),
                                ),
                              ))
                            .toFrozen()
                      : null)
                .toFrozen();
        final panel = await fixture.show(
          tester,
          skir.PresentationElement.wrapSelectInput(input),
        );
        bool menuOpen() => semanticsLabeled("typewritermc:paper").isNotEmpty;
        expect(menuOpen(), isFalse);

        if (configured) {
          await panel.press(LogicalKeyboardKey.tab);
          await panel.press(LogicalKeyboardKey.enter);
          expect(panel.fieldAt(0).isFocused, isTrue);
          tester.testTextInput.enterText("paper");
          await panel.press(LogicalKeyboardKey.arrowDown);
          expect(menuOpen(), isTrue);
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          await panel.fieldAt(0).focus();
          expect(menuOpen(), isTrue);
          await panel.tapOn(panel.labeled("typewritermc:paper"));
        }
        await panel.settle();
        expect(fixture.value, skir.DataValue.wrapStringValue("paper"));
        expect(menuOpen(), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final wrapped in [false, true]) {
    testWidgets(
      "leading glyph is centered and inherits icon defaults with column $wrapped",
      (tester) async {
        final fixture = EditedValue.scalar(
          skir.DataValue.wrapInteger("7"),
          skir.ScalarKind.createInteger(
            width: skir.IntegerWidth.signedThirtyTwo,
          ),
        );
        final text =
            (skir.PresentationNode.mutable()
                  ..nodeId = "glyph"
                  ..element = skir.PresentationElement.wrapText(
                    (skir.TextContent.mutable()..value = textLiteral("X"))
                        .toFrozen(),
                  ))
                .toFrozen();
        final leading = wrapped
            ? (skir.PresentationNode.mutable()
                    ..nodeId = "glyph.column"
                    ..element = skir.PresentationElement.wrapChildren(
                      skir.ChildrenElement.wrapColumn(
                        (skir.AxisChildrenElement.mutable()
                              ..children = [skir.AxisChild.wrapFixed(text)])
                            .toFrozen(),
                      ),
                    ))
                  .toFrozen()
            : text;
        final input =
            (skir.NumericControl.mutable()
                  ..control = fixture.control
                  ..content =
                      (skir.InputContent.mutable()
                            ..leading = skir.InputAdornment.wrapContent(
                              leading,
                            ))
                          .toFrozen()
                  ..appearance =
                      (skir.InputAppearance.mutable()
                            ..iconSize = wrapped ? numberLiteral(22) : null
                            ..iconColor = skir.PresentationColor.wrapValue(
                              literalExpression(
                                skir.DataValue.wrapInteger("4292030255"),
                              ),
                            ))
                          .toFrozen())
                .toFrozen();
        await fixture.show(
          tester,
          skir.PresentationElement.wrapNumericInput(input),
        );
        final glyph = find.text("X");
        final native = tester.widget<TextField>(find.byType(TextField));
        final slot = tester.getRect(
          find.byWidget(native.decoration!.prefixIcon!),
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: glyph, matching: find.byType(RichText)),
        );
        final bounds = paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 1),
            )
            .single
            .toRect()
            .shift(paragraph.localToGlobal(Offset.zero));
        expect(bounds.center.dx, closeTo(slot.center.dx, 0.5));
        expect(bounds.center.dy, closeTo(slot.center.dy, 0.5));
        final style = tester.widget<Text>(glyph).style!;
        expect(style.fontSize, wrapped ? 22 : 18);
        expect(style.color, const Color(0xffd32f2f));
        expect(tester.takeException(), isNull);

        final explicitText =
            (text.toMutable()
                  ..element = skir.PresentationElement.wrapText(
                    (skir.TextContent.mutable()
                          ..value = textLiteral("X")
                          ..sizing = skir.TextSizing.wrapExact(
                            numberLiteral(24),
                          )
                          ..color = skir.PresentationColor.wrapValue(
                            literalExpression(
                              skir.DataValue.wrapInteger("4278255360"),
                            ),
                          ))
                        .toFrozen(),
                  ))
                .toFrozen();
        final configured =
            (input.toMutable()
                  ..appearance =
                      (input.appearance!.toMutable()
                            ..iconSize = numberLiteral(20))
                          .toFrozen()
                  ..content =
                      (input.content!.toMutable()
                            ..leading = skir.InputAdornment.wrapContent(
                              explicitText,
                            ))
                          .toFrozen())
                .toFrozen();
        await fixture.show(
          tester,
          skir.PresentationElement.wrapNumericInput(configured),
        );
        final explicitStyle = tester.widget<Text>(find.text("X")).style!;
        expect(explicitStyle.fontSize, 24);
        expect(explicitStyle.color, const Color(0xff00ff00));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    "password text hides its value and filters typing to the allowed characters and length",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.wrapStringValue("AB"),
        skir.ScalarKind.text,
      );
      final input =
          (skir.TextControl.mutable()
                ..control = fixture.control
                ..entry = skir.TextEntryInteractionOptions(
                  selectAllOnFocus: true,
                )
                ..content =
                    (skir.InputContent.mutable()
                          ..leading = skir.InputAdornment.none
                          ..placeholder = textLiteral("Checkpoint"))
                        .toFrozen()
                ..options =
                    (skir.TextEditingOptions.mutable()
                          ..purpose = skir.TextPurpose.password
                          ..capitalization = skir.TextCapitalization.characters
                          ..suggestions = false
                          ..length = skir.TextLengthPolicy(
                            maximumGraphemes: 4,
                            enforceAfterComposition: true,
                          )
                          ..characterFilters = [
                            skir.CharacterFilter.wrapAllow("[A-Z]"),
                          ])
                        .toFrozen())
              .toFrozen();
      final panel = await fixture.show(
        tester,
        skir.PresentationElement.wrapTextInput(input),
      );
      final field = panel.fieldAt(0);
      expect(field.isObscured, isTrue);
      await field.type("AB1CDE");
      expect(fixture.value, skir.DataValue.wrapStringValue("ABCD"));
      await panel.press(LogicalKeyboardKey.escape);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets("byte encoding grouping and count retain exact authored bytes", (
    tester,
  ) async {
    final fixture = EditedValue.scalar(
      skir.DataValue.wrapBytes(skir.ByteString.fromBase16("0102")),
      skir.ScalarKind.bytes,
    );
    final input =
        (skir.BytesControl.mutable()
              ..control = fixture.control
              ..options =
                  (skir.BytesInteractionOptions.mutable()
                        ..editingEncoding = skir.BytesEditingEncoding.base64
                        ..groupSize = 2
                        ..showCount = true)
                      .toFrozen())
            .toFrozen();
    final panel = await fixture.show(
      tester,
      skir.PresentationElement.wrapBytesInput(input),
    );
    expect(panel.fieldAt(0).value, "AQ I=");
    expect(find.text("2 bytes"), findsOneWidget);
    await panel.fieldAt(0).type("AQ ID");
    expect(
      fixture.value,
      skir.DataValue.wrapBytes(skir.ByteString.fromBase16("010203")),
    );
    expect(find.text("3 bytes"), findsOneWidget);
  });
  testWidgets(
    "color entry edits rgb text and the picker offers hsl controls and the authored swatches",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.wrapInteger("4294901760"),
        skir.ScalarKind.createInteger(
          width: skir.IntegerWidth.unsignedThirtyTwo,
        ),
      );
      final input =
          (skir.ColorControl.mutable()
                ..control = fixture.control
                ..includeAlpha = false
                ..options =
                    (skir.ColorInteractionOptions.mutable()
                          ..editingRepresentation =
                              skir.ColorEditingRepresentation.rgb
                          ..pickerFormat = skir.ColorPickerFormat.hsl
                          ..showSwatch = false
                          ..showCopyAction = false
                          ..showFormatSelector = false
                          ..offeredSwatches = literalExpression(
                            skir.DataValue.createListValue(
                              items: [
                                skir.ListItem(
                                  id: skir.ItemId(value: "green"),
                                  value: skir.DataValue.wrapInteger(
                                    "4278255360",
                                  ),
                                ),
                              ],
                            ),
                          ))
                        .toFrozen()
                ..popup =
                    (skir.PopupAppearance.mutable()
                          ..minimumWidth = numberLiteral(250)
                          ..maximumWidth = numberLiteral(400)
                          ..maximumExtent = numberLiteral(500)
                          ..padding = skir.PresentationInsets.wrapAll(12)
                          ..radius = skir.PresentationRadius.large)
                        .toFrozen())
              .toFrozen();
      final panel = await fixture.show(
        tester,
        skir.PresentationElement.wrapColorInput(input),
      );
      expect(find.tooltip("Copy color"), findsNothing);
      await panel.fieldAt(0).type("0, 255, 0");
      expect(fixture.value, skir.DataValue.wrapInteger("4278255360"));

      await panel.tapOn(find.tooltip("Open color picker"));
      expect(panel.shows("H"), isTrue);
      expect(panel.shows("L%"), isTrue);
      expect(panel.shows("R"), isFalse);
      expect(panel.shows("RGB"), isFalse);
      expect(
        semanticsLabeled("Offered colors").single.button("Color #FF00FF00"),
        isNotNull,
      );
    },
  );
  testWidgets(
    "date entry rejects a timestamp past its bound and the picker steps time by the authored increment",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.wrapTimestamp(DateTime.utc(2026, 10, 13, 14, 30)),
        skir.ScalarKind.timestamp,
      );
      final minimum = DateTime.utc(2026, 10, 1);
      final maximum = DateTime.utc(2026, 11, 1);
      final input =
          (skir.DateTimeControl.mutable()
                ..control = fixture.control
                ..includeDate = true
                ..includeTime = true
                ..options =
                    (skir.DateTimeInteractionOptions.mutable()
                          ..minimum = literalExpression(
                            skir.DataValue.wrapTimestamp(minimum),
                          )
                          ..maximum = literalExpression(
                            skir.DataValue.wrapTimestamp(maximum),
                          )
                          ..timeIncrement = literalExpression(
                            skir.DataValue.createDuration(
                              value: skir.Duration(milliseconds: 90000),
                            ),
                          )
                          ..presentation = skir.DateTimePickerPresentation.text)
                        .toFrozen())
              .toFrozen();
      final panel = await fixture.show(
        tester,
        skir.PresentationElement.wrapDateTimeInput(input),
      );
      expect(find.tooltip("Open picker"), findsNothing);
      await panel.fieldAt(0).type("2026-11-30 14:30:00");
      expect(
        fixture.value,
        skir.DataValue.wrapTimestamp(DateTime.utc(2026, 10, 13, 14, 30)),
      );
      expect(find.text("The timestamp exceeds the maximum"), findsOneWidget);
      await panel.press(LogicalKeyboardKey.escape);

      final picked =
          (input.toMutable()
                ..options =
                    (input.options!.toMutable()
                          ..presentation =
                              skir.DateTimePickerPresentation.calendar)
                        .toFrozen())
              .toFrozen();
      await fixture.show(
        tester,
        skir.PresentationElement.wrapDateTimeInput(picked),
      );
      await panel.tapOn(find.tooltip("Open picker"));
      await panel.tapOn(find.tooltip("Increase time"));
      expect(
        fixture.value,
        skir.DataValue.wrapTimestamp(DateTime.utc(2026, 10, 13, 14, 31, 30)),
      );
    },
  );
  testWidgets(
    "numeric locale keeps the entered fraction and native keyboard steps use exact increment",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.wrapFloat(1.5),
        skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
      );
      final input =
          (skir.NumericControl.mutable()
                ..control = fixture.control
                ..options =
                    (skir.NumericInteractionOptions.mutable()
                          ..editingLocale = textLiteral("de_DE")
                          ..minimum = numberLiteral(0)
                          ..maximum = numberLiteral(2)
                          ..step = numberLiteral(0.25)
                          ..steppers = skir.NumericSteppers.inline)
                        .toFrozen())
              .toFrozen();
      final panel = await fixture.show(
        tester,
        skir.PresentationElement.wrapNumericInput(input),
      );
      final field = panel.fieldAt(0);
      expect(field.value, "1,5");
      await field.type("1,26");
      await panel.press(LogicalKeyboardKey.escape);
      expect(fixture.value, skir.DataValue.wrapFloat(1.26));
      await field.focus();
      await panel.press(LogicalKeyboardKey.tab);
      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.hasFocusOn("Increase"), isTrue);
      await panel.press(LogicalKeyboardKey.enter);
      expect(fixture.value, skir.DataValue.wrapFloat(1.51));
    },
  );
  testWidgets("toggle options preserve native checkbox keyboard operation", (
    tester,
  ) async {
    final fixture = EditedValue.scalar(
      skir.DataValue.wrapBoolean(true),
      skir.ScalarKind.boolean,
    );
    final input =
        (skir.ToggleControl.mutable()
              ..control = fixture.control
              ..options =
                  (skir.ToggleInteractionOptions.mutable()
                        ..presentation = skir.TogglePresentation.checkbox
                        ..position = skir.TogglePosition.leading
                        ..trueLabel = textLiteral("Visible")
                        ..falseLabel = textLiteral("Hidden"))
                      .toFrozen())
            .toFrozen();
    final panel = await fixture.show(
      tester,
      skir.PresentationElement.wrapToggleInput(input),
    );
    expect(
      tester.getRect(find.byType(Checkbox)).right,
      lessThanOrEqualTo(tester.getRect(find.text("Visible")).left),
    );
    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.space);
    expect(fixture.value, skir.DataValue.wrapBoolean(false));
    expect(find.text("Hidden"), findsOneWidget);
  });
  testWidgets("slider arrow keys step by one division", (tester) async {
    final fixture = EditedValue.scalar(
      skir.DataValue.wrapFloat(40),
      skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
    );
    final input =
        (skir.SliderControl.mutable()
              ..control = fixture.control
              ..minimum = numberLiteral(0)
              ..maximum = numberLiteral(100)
              ..divisions = literalExpression(skir.DataValue.wrapInteger("10"))
              ..options =
                  (skir.SliderInteractionOptions.mutable()
                        ..showValue = skir.SliderValueDisplay.always
                        ..showTicks = false
                        ..interaction = skir.SliderInteraction.dragOnly
                        ..trackHeight = 6)
                      .toFrozen())
            .toFrozen();
    final panel = await fixture.show(
      tester,
      skir.PresentationElement.wrapSliderInput(input),
    );
    expect(panel.shows("40"), isTrue);
    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.arrowRight);
    expect(fixture.value, skir.DataValue.wrapFloat(50));
    expect(panel.shows("50"), isTrue);
  });
  testWidgets(
    "radio choice content and disabled override retain native selection",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.wrapStringValue("first"),
        skir.ScalarKind.text,
      );
      final input =
          (skir.SelectControl.mutable()
                ..control = fixture.control
                ..options = [
                  for (final name in ["first", "second"])
                    (skir.SelectOption.mutable()
                          ..optionId = name
                          ..label = textLiteral(name)
                          ..value = textLiteral(name))
                        .toFrozen(),
                ]
                ..optionsConfig =
                    (skir.SelectInteractionOptions.mutable()
                          ..presentation = skir.ChoicePresentation.radio
                          ..optionOverrides = [
                            (skir.ChoiceOptionAppearance.mutable()
                                  ..optionId = "second"
                                  ..enabledIf = literalExpression(
                                    skir.DataValue.wrapBoolean(false),
                                  )
                                  ..disabledReason = textLiteral(
                                    "Unavailable in this state",
                                  ))
                                .toFrozen(),
                          ])
                        .toFrozen())
              .toFrozen();
      final panel = await fixture.show(
        tester,
        skir.PresentationElement.wrapSelectInput(input),
      );
      expect(semanticsLabeled("first").single.isEnabled, isTrue);
      expect(semanticsLabeled("second").single.isEnabled, isFalse);
      expect(find.tooltip("Unavailable in this state"), findsOneWidget);
      await panel.tapOn(find.text("second"));
      expect(fixture.value, skir.DataValue.wrapStringValue("first"));
    },
  );
  testWidgets(
    "selector with appearance overrides shows the value as a dropdown and selects as segments",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.wrapStringValue("first"),
        skir.ScalarKind.text,
      );
      skir.PresentationColor paint(int value) =>
          skir.PresentationColor.wrapValue(
            literalExpression(skir.DataValue.wrapInteger(value.toString())),
          );
      final appearance =
          (skir.InputAppearance.mutable()
                ..density = skir.ControlDensity.compact
                ..alignment = skir.InputTextAlignment.end
                ..border = skir.BorderOverride.none
                ..radius = skir.PresentationRadius.large
                ..labelStyle =
                    (skir.InputTextStyle.mutable()..color = paint(0xffa00000))
                        .toFrozen()
                ..valueStyle = (skir.InputTextStyle.mutable()..weight = 600)
                    .toFrozen())
              .toFrozen();
      final input = skir.SelectControl.mutable()
        ..control =
            (fixture.control.toMutable()
                  ..label = textLiteral("Configured selector"))
                .toFrozen()
        ..appearance = appearance
        ..options = [
          for (final name in ["first", "second"])
            (skir.SelectOption.mutable()
                  ..optionId = name
                  ..label = textLiteral(name)
                  ..value = textLiteral(name))
                .toFrozen(),
        ]
        ..optionsConfig =
            (skir.SelectInteractionOptions.mutable()
                  ..presentation = skir.ChoicePresentation.dropdown
                  ..selectedTextStyle =
                      (skir.InputTextStyle.mutable()..color = paint(0xff0000a0))
                          .toFrozen())
                .toFrozen();
      final panel = await fixture.show(
        tester,
        skir.PresentationElement.wrapSelectInput(input.toFrozen()),
      );
      expect(panel.fieldAt(0).value, "first");
      input.optionsConfig =
          (input.optionsConfig!.toFrozen().toMutable()
                ..presentation = skir.ChoicePresentation.segmented)
              .toFrozen();
      await fixture.show(
        tester,
        skir.PresentationElement.wrapSelectInput(input.toFrozen()),
      );
      await panel.tapOn(find.text("second"));
      expect(fixture.value, skir.DataValue.wrapStringValue("second"));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    "unfilled slider offers a keyboard action that sets the minimum",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.unfilled,
        skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
      );
      final input =
          (skir.SliderControl.mutable()
                ..control = fixture.control
                ..minimum = numberLiteral(0)
                ..maximum = numberLiteral(10)
                ..appearance =
                    (skir.InputAppearance.mutable()
                          ..density = skir.ControlDensity.compact
                          ..border = skir.BorderOverride.none
                          ..radius = skir.PresentationRadius.large)
                        .toFrozen())
              .toFrozen();
      final panel = await fixture.show(
        tester,
        skir.PresentationElement.wrapSliderInput(input),
      );
      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.hasFocusOn("Set to 0"), isTrue);
      await panel.press(LogicalKeyboardKey.enter);
      expect(fixture.value, skir.DataValue.wrapFloat(0));
      expect(panel.shows("Set to 0"), isFalse);
      expect(
        find.semantics.byPredicate(
          (node) => node.getSemanticsData().flagsCollection.isSlider,
        ),
        findsOne,
      );
    },
  );
  testWidgets(
    "color swatch remains independent of decorative icon and authored leading content",
    (tester) async {
      final fixture = EditedValue.scalar(
        skir.DataValue.wrapInteger("4278255360"),
        skir.ScalarKind.createInteger(
          width: skir.IntegerWidth.unsignedThirtyTwo,
        ),
      );
      final input = skir.ColorControl.mutable()
        ..control = fixture.control
        ..content =
            (skir.InputContent.mutable()..leading = skir.InputAdornment.none)
                .toFrozen();
      await fixture.show(
        tester,
        skir.PresentationElement.wrapColorInput(input.toFrozen()),
      );
      expect(find.byType(Checkerboard), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsNothing);
      final leading =
          (skir.PresentationNode.mutable()
                ..nodeId = "leading"
                ..element = skir.PresentationElement.wrapText(
                  (skir.TextContent.mutable()
                        ..value = textLiteral("Tag decoration"))
                      .toFrozen(),
                ))
              .toFrozen();
      input.content =
          (input.content!.toFrozen().toMutable()
                ..leading = skir.InputAdornment.wrapContent(leading))
              .toFrozen();
      await fixture.show(
        tester,
        skir.PresentationElement.wrapColorInput(input.toFrozen()),
      );
      expect(find.byType(Checkerboard), findsOneWidget);
      expect(find.text("Tag decoration"), findsOneWidget);
      input.options =
          (skir.ColorInteractionOptions.mutable()..showSwatch = false)
              .toFrozen();
      await fixture.show(
        tester,
        skir.PresentationElement.wrapColorInput(input.toFrozen()),
      );
      expect(find.byType(Checkerboard), findsNothing);
      expect(find.text("Tag decoration"), findsOneWidget);
    },
  );
  for (final presentation in [
    skir.TogglePresentation.checkbox,
    skir.TogglePresentation.switch_,
  ]) {
    testWidgets(
      "readonly ${presentation.kind.name} ignores taps while readonly text stays focusable",
      (tester) async {
        final fixture = EditedValue.scalar(
          skir.DataValue.wrapBoolean(true),
          skir.ScalarKind.boolean,
        );
        final toggle =
            (skir.ToggleControl.mutable()
                  ..control = fixture.control
                  ..options =
                      (skir.ToggleInteractionOptions.mutable()
                            ..presentation = presentation)
                          .toFrozen())
                .toFrozen();
        final panel = await fixture.show(
          tester,
          skir.PresentationElement.wrapToggleInput(toggle),
          readOnly: true,
        );
        final control = find.semantics.byPredicate((node) {
          final flags = node.getSemanticsData().flagsCollection;
          return !node.isMergedIntoParent &&
              (flags.isChecked != CheckedState.none ||
                  flags.isToggled != Tristate.none);
        });
        expect(control.evaluate().single.isEnabled, isFalse);
        await tester.tapAt(control.evaluate().single.screenRect.center);
        await panel.settle();
        expect(fixture.value, skir.DataValue.wrapBoolean(true));

        final textFixture = EditedValue.scalar(
          skir.DataValue.wrapStringValue("Inspect"),
          skir.ScalarKind.text,
        );
        await textFixture.show(
          tester,
          skir.PresentationElement.wrapTextInput(
            (skir.TextControl.mutable()..control = textFixture.control)
                .toFrozen(),
          ),
          readOnly: true,
        );
        final field = panel.fieldAt(0);
        expect(field.isReadOnly, isTrue);
        expect(field.isEnabled, isTrue);
        await field.focus();
        expect(field.isFocused, isTrue);
        expect(field.value, "Inspect");
      },
    );
  }
  final noIconContent =
      (skir.InputContent.mutable()..leading = skir.InputAdornment.none)
          .toFrozen();
  for (final family in ["number", "duration", "bytes", "date"]) {
    testWidgets("explicit no icon hides the default $family icon", (
      tester,
    ) async {
      final kind = switch (family) {
        "duration" => skir.ScalarKind.duration,
        "bytes" => skir.ScalarKind.bytes,
        "date" => skir.ScalarKind.timestamp,
        _ => skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
      };
      final value = switch (family) {
        "duration" => skir.DataValue.createDuration(
          value: skir.Duration(milliseconds: 1000),
        ),
        "bytes" => skir.DataValue.wrapBytes(skir.ByteString.fromBase16("01")),
        "date" => skir.DataValue.wrapTimestamp(DateTime.utc(2026, 10, 13)),
        _ => skir.DataValue.wrapFloat(1),
      };
      final icon = switch (family) {
        "duration" => Icons.timer,
        "bytes" => Icons.data_object,
        "date" => Icons.calendar_month,
        _ => Icons.numbers,
      };
      final fixture = EditedValue.scalar(value, kind);
      skir.PresentationElement element(skir.InputContent? content) =>
          switch (family) {
            "duration" => skir.PresentationElement.wrapDurationInput(
              (skir.DurationControl.mutable()
                    ..control = fixture.control
                    ..content = content)
                  .toFrozen(),
            ),
            "bytes" => skir.PresentationElement.wrapBytesInput(
              (skir.BytesControl.mutable()
                    ..control = fixture.control
                    ..content = content)
                  .toFrozen(),
            ),
            "date" => skir.PresentationElement.wrapDateTimeInput(
              (skir.DateTimeControl.mutable()
                    ..control = fixture.control
                    ..content = content)
                  .toFrozen(),
            ),
            _ => skir.PresentationElement.wrapNumericInput(
              (skir.NumericControl.mutable()
                    ..control = fixture.control
                    ..content = content)
                  .toFrozen(),
            ),
          };
      await fixture.show(tester, element(null));
      expect(find.byIcon(icon), findsOneWidget);
      await fixture.show(tester, element(noIconContent));
      expect(find.byIcon(icon), findsNothing);
    });
  }
}
