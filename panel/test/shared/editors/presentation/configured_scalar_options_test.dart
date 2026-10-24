import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  for (final configured in [false, true]) {
    testWidgets(
      "dropdown retains panel chrome with sparse overrides $configured",
      (tester) async {
        final fixture = _Fixture(
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
        await fixture.pump(
          tester,
          skir.PresentationElement.wrapSelectInput(input),
        );
        final context = tester.element(find.byType(Dropdown<String>));
        final theme = Theme.of(context).dropdownMenuTheme;
        final decoration = tester
            .widget<InputDecorator>(find.byType(InputDecorator))
            .decoration;
        expect(decoration.filled, isTrue);
        expect(decoration.fillColor, theme.inputDecorationTheme!.fillColor);
        expect(decoration.border, theme.inputDecorationTheme!.border);
        expect(
          decoration.contentPadding,
          theme.inputDecorationTheme!.contentPadding,
        );
        expect(
          decoration.isDense,
          configured || theme.inputDecorationTheme!.isDense,
        );
        expect(decoration.prefixIcon, isNull);
        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
        expect(fixture.value, skir.DataValue.wrapStringValue(""));

        if (configured) {
          tester
              .widget<InputFieldContainer>(find.byType(InputFieldContainer))
              .controller
              .requestSurroundingFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(
            tester
                .widget<TextField>(find.byType(TextField))
                .focusNode!
                .hasFocus,
            isTrue,
          );
          await tester.enterText(find.byType(TextField), "paper");
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        } else {
          await tester.tap(find.byType(TextField));
        }
        await tester.pumpAndSettle();
        final menu = tester.widget<MenuAnchor>(find.byType(MenuAnchor));
        expect(menu.style!.padding, theme.menuStyle!.padding);
        expect(menu.style!.shape, theme.menuStyle!.shape);
        expect(
          menu.style!.backgroundColor!.resolve({}),
          configured
              ? const Color(0xff0000ff)
              : theme.menuStyle!.backgroundColor!.resolve({}),
        );
        expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
        expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
        if (configured) {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else {
          await tester.tap(find.text("typewritermc:paper").last);
        }
        await tester.pumpAndSettle();
        expect(fixture.value, skir.DataValue.wrapStringValue("paper"));
        expect(menu.controller!.isOpen, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final wrapped in [false, true]) {
    testWidgets(
      "leading glyph is centered and inherits icon defaults with column $wrapped",
      (tester) async {
        final fixture = _Fixture(
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
        await fixture.pump(
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
        await fixture.pump(
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
    "text options reach the native editing widget and composition aware filtering",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(tester, skir.PresentationElement.wrapTextInput(input));
      final native = tester.widget<TextField>(find.byType(TextField));
      expect(native.obscureText, isTrue);
      expect(native.enableSuggestions, isFalse);
      expect(native.textCapitalization, TextCapitalization.characters);
      expect(native.maxLength, 4);
      expect(
        native.maxLengthEnforcement,
        MaxLengthEnforcement.truncateAfterCompositionEnds,
      );
      expect(native.decoration!.hintText, "Checkpoint");
      expect(native.decoration!.prefixIcon, isNull);
      await tester.enterText(find.byType(TextFormField), "AB1CDE");
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapStringValue("ABCD"));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets("byte encoding grouping and count retain exact authored bytes", (
    tester,
  ) async {
    final fixture = _Fixture(
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
    await fixture.pump(tester, skir.PresentationElement.wrapBytesInput(input));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      "AQ I=",
    );
    expect(find.text("2 bytes"), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), "AQ ID");
    await tester.pumpAndSettle();
    expect(
      fixture.value,
      skir.DataValue.wrapBytes(skir.ByteString.fromBase16("010203")),
    );
    expect(find.text("3 bytes"), findsOneWidget);
  });
  testWidgets(
    "color codec and picker options reach the existing native owner",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapColorInput(input),
      );
      final picker = tester.widget<ColorPickerField>(
        find.byType(ColorPickerField),
      );
      expect(picker.editingFormat, ColorFieldFormat.rgb);
      expect(picker.pickerFormat, ColorFieldFormat.hsl);
      expect(picker.showSwatch, isFalse);
      expect(picker.showCopyAction, isFalse);
      expect(picker.showFormatSelector, isFalse);
      expect(picker.offeredSwatches, [4278255360]);
      expect(picker.popupConstraints!.minWidth, 250);
      expect(picker.popupConstraints!.maxWidth, 400);
      expect(picker.popupConstraints!.maxHeight, 500);
      expect(picker.popupPadding, const EdgeInsets.all(12));
      await tester.enterText(find.byType(TextFormField), "0, 255, 0");
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapInteger("4278255360"));
    },
  );
  testWidgets(
    "date options retain timestamp bounds and millisecond increment",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapDateTimeInput(input),
      );
      final picker = tester.widget<DateTimePickerField>(
        find.byType(DateTimePickerField),
      );
      expect(picker.minimum, minimum);
      expect(picker.maximum, maximum);
      expect(picker.timeIncrementMilliseconds, 90000);
      expect(picker.showPicker, isFalse);
      await tester.enterText(find.byType(TextFormField), "2026-11-30 14:30:00");
      await tester.pumpAndSettle();
      expect(
        fixture.value,
        skir.DataValue.wrapTimestamp(DateTime.utc(2026, 10, 13, 14, 30)),
      );
      expect(find.text("The timestamp exceeds the maximum"), findsOneWidget);
    },
  );
  testWidgets(
    "numeric locale keeps the entered fraction and native keyboard steps use exact increment",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapNumericInput(input),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        "1,5",
      );
      await tester.enterText(find.byType(TextFormField), "1,26");
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapFloat(1.26));
      Focus.of(tester.element(find.byIcon(Icons.add))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapFloat(1.51));
    },
  );
  testWidgets("toggle options preserve native checkbox keyboard operation", (
    tester,
  ) async {
    final fixture = _Fixture(
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
    await fixture.pump(tester, skir.PresentationElement.wrapToggleInput(input));
    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.controlAffinity, ListTileControlAffinity.leading);
    expect(find.text("Visible"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(fixture.value, skir.DataValue.wrapBoolean(false));
    expect(find.text("Hidden"), findsOneWidget);
  });
  testWidgets(
    "slider native keyboard retains divisions and appearance options",
    (tester) async {
      final fixture = _Fixture(
        skir.DataValue.wrapFloat(40),
        skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
      );
      final input =
          (skir.SliderControl.mutable()
                ..control = fixture.control
                ..minimum = numberLiteral(0)
                ..maximum = numberLiteral(100)
                ..divisions = literalExpression(
                  skir.DataValue.wrapInteger("10"),
                )
                ..options =
                    (skir.SliderInteractionOptions.mutable()
                          ..showValue = skir.SliderValueDisplay.always
                          ..showTicks = false
                          ..interaction = skir.SliderInteraction.dragOnly
                          ..trackHeight = 6)
                        .toFrozen())
              .toFrozen();
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapSliderInput(input),
      );
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 10);
      expect(slider.allowedInteraction, SliderInteraction.slideOnly);
      expect(find.text("40"), findsOneWidget);
      tester
          .widget<FocusableActionDetector>(
            find.descendant(
              of: find.byType(Slider),
              matching: find.byType(FocusableActionDetector),
            ),
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapFloat(50));
      expect(find.text("50"), findsOneWidget);
    },
  );
  testWidgets(
    "radio choice content and disabled override retain native selection",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapSelectInput(input),
      );
      final tiles = tester
          .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
          .toList();
      expect(tiles[0].enabled, isTrue);
      expect(tiles[1].enabled, isFalse);
      expect(find.byTooltip("Unavailable in this state"), findsOneWidget);
      await tester.tap(find.text("second"));
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapStringValue("first"));
    },
  );
  testWidgets(
    "selector appearance retains native density alignment and sparse text inheritance",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapSelectInput(input.toFrozen()),
      );
      final dropdown = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(dropdown.textAlign, TextAlign.end);
      expect(dropdown.textStyle!.color, const Color(0xff0000a0));
      expect(
        dropdown.textStyle!.fontVariations!
            .singleWhere((variation) => variation.axis == "wght")
            .value,
        600,
      );
      expect(
        tester
            .widget<LabeledMessage>(find.byType(LabeledMessage))
            .labelStyle!
            .color,
        const Color(0xffa00000),
      );
      input.optionsConfig =
          (input.optionsConfig!.toFrozen().toMutable()
                ..presentation = skir.ChoicePresentation.segmented)
              .toFrozen();
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapSelectInput(input.toFrozen()),
      );
      final segmented = tester.widget<SlidingChoiceControl<String>>(
        find.byType(SlidingChoiceControl<String>),
      );
      expect(segmented.padding!.resolve(TextDirection.ltr).vertical, 8);
      expect(
        find.byType(CupertinoSlidingSegmentedControl<String>),
        findsOneWidget,
      );
      await tester.tap(find.text("second"));
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapStringValue("second"));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    "unfilled slider affordance uses the shared native action appearance",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapSliderInput(input),
      );
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.style!.visualDensity, VisualDensity.compact);
      expect(button.style!.side!.resolve({}), BorderSide.none);
      expect(
        (button.style!.shape!.resolve({})! as RoundedRectangleBorder)
            .borderRadius,
        isNot(BorderRadius.zero),
      );
      Focus.of(tester.element(find.text("Set to 0"))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fixture.value, skir.DataValue.wrapFloat(0));
      expect(find.byType(Slider), findsOneWidget);
    },
  );
  testWidgets(
    "color swatch remains independent of decorative icon and authored leading content",
    (tester) async {
      final fixture = _Fixture(
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
      await fixture.pump(
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
      await fixture.pump(
        tester,
        skir.PresentationElement.wrapColorInput(input.toFrozen()),
      );
      expect(find.byType(Checkerboard), findsOneWidget);
      expect(find.text("Tag decoration"), findsOneWidget);
      input.options =
          (skir.ColorInteractionOptions.mutable()..showSwatch = false)
              .toFrozen();
      await fixture.pump(
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
      "readonly ${presentation.kind.name} observes native disabled separately from readonly text",
      (tester) async {
        skir.PresentationColor paint(int value) =>
            skir.PresentationColor.wrapValue(
              literalExpression(skir.DataValue.wrapInteger(value.toString())),
            );
        final policy = skir.PresentationColor.wrapStates(
          skir.PresentationStateColor(
            rules: [
              skir.PresentationStateColorRule(
                match: skir.PresentationStateMatch(
                  required_: [skir.PresentationInteractionState.disabled],
                  excluded: const [],
                ),
                color: paint(0xffa00000),
              ),
              skir.PresentationStateColorRule(
                match: skir.PresentationStateMatch(
                  required_: [skir.PresentationInteractionState.readOnly],
                  excluded: const [],
                ),
                color: paint(0xff0000a0),
              ),
            ],
            fallback: paint(0xff008000),
          ),
        );
        final appearance = (skir.InputAppearance.mutable()..fill = policy)
            .toFrozen();
        final fixture = _Fixture(
          skir.DataValue.wrapBoolean(true),
          skir.ScalarKind.boolean,
        );
        final toggle =
            (skir.ToggleControl.mutable()
                  ..control = fixture.control
                  ..appearance = appearance
                  ..options =
                      (skir.ToggleInteractionOptions.mutable()
                            ..presentation = presentation)
                          .toFrozen())
                .toFrozen();
        await fixture.pump(
          tester,
          skir.PresentationElement.wrapToggleInput(toggle),
          readOnly: true,
        );
        await tester.pumpAndSettle();
        final controller = presentation == skir.TogglePresentation.checkbox
            ? tester
                  .widget<CheckboxListTile>(find.byType(CheckboxListTile))
                  .statesController!
            : tester
                  .widget<SwitchListTile>(find.byType(SwitchListTile))
                  .statesController!;
        expect(controller.value, contains(WidgetState.disabled));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Material && widget.color == const Color(0xffa00000),
          ),
          findsWidgets,
        );
        final textFixture = _Fixture(
          skir.DataValue.wrapStringValue("Inspect"),
          skir.ScalarKind.text,
        );
        final text =
            (skir.TextControl.mutable()
                  ..control = textFixture.control
                  ..appearance = appearance)
                .toFrozen();
        await textFixture.pump(
          tester,
          skir.PresentationElement.wrapTextInput(text),
          readOnly: true,
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.readOnly, isTrue);
        expect(
          field.statesController!.value,
          isNot(contains(WidgetState.disabled)),
        );
        expect(field.decoration!.fillColor, const Color(0xff0000a0));
      },
    );
  }
  final noIconContent =
      (skir.InputContent.mutable()..leading = skir.InputAdornment.none)
          .toFrozen();
  for (final family in ["number", "duration", "bytes", "date", "color"]) {
    testWidgets(
      "explicit no icon removes the native decoration slot for $family",
      (tester) async {
        final kind = switch (family) {
          "duration" => skir.ScalarKind.duration,
          "bytes" => skir.ScalarKind.bytes,
          "date" => skir.ScalarKind.timestamp,
          "color" => skir.ScalarKind.createInteger(
            width: skir.IntegerWidth.unsignedThirtyTwo,
          ),
          _ => skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
        };
        final value = switch (family) {
          "duration" => skir.DataValue.createDuration(
            value: skir.Duration(milliseconds: 1000),
          ),
          "bytes" => skir.DataValue.wrapBytes(skir.ByteString.fromBase16("01")),
          "date" => skir.DataValue.wrapTimestamp(DateTime.utc(2026, 10, 13)),
          "color" => skir.DataValue.wrapInteger("4278255360"),
          _ => skir.DataValue.wrapFloat(1),
        };
        final fixture = _Fixture(value, kind);
        final element = switch (family) {
          "duration" => skir.PresentationElement.wrapDurationInput(
            (skir.DurationControl.mutable()
                  ..control = fixture.control
                  ..content = noIconContent)
                .toFrozen(),
          ),
          "bytes" => skir.PresentationElement.wrapBytesInput(
            (skir.BytesControl.mutable()
                  ..control = fixture.control
                  ..content = noIconContent)
                .toFrozen(),
          ),
          "date" => skir.PresentationElement.wrapDateTimeInput(
            (skir.DateTimeControl.mutable()
                  ..control = fixture.control
                  ..content = noIconContent)
                .toFrozen(),
          ),
          "color" => skir.PresentationElement.wrapColorInput(
            (skir.ColorControl.mutable()
                  ..control = fixture.control
                  ..content = noIconContent
                  ..options =
                      (skir.ColorInteractionOptions.mutable()
                            ..showSwatch = false)
                          .toFrozen())
                .toFrozen(),
          ),
          _ => skir.PresentationElement.wrapNumericInput(
            (skir.NumericControl.mutable()
                  ..control = fixture.control
                  ..content = noIconContent)
                .toFrozen(),
          ),
        };
        await fixture.pump(tester, element);
        expect(
          tester
              .widget<TextField>(find.byType(TextField))
              .decoration!
              .prefixIcon,
          isNull,
        );
      },
    );
  }
}

class _Fixture {
  _Fixture(this.value, this.kind);
  skir.DataValue value;
  final skir.ScalarKind kind;
  final id = skir.ExpressionBindingId(value: "fixture");
  skir.BoundControl get control =>
      (skir.BoundControl.mutable()
            ..binding = skir.BindingRef(bindingId: id, path: editorRootPath))
          .toFrozen();
  Future<void> pump(
    WidgetTester tester,
    skir.PresentationElement element, {
    bool readOnly = false,
  }) async {
    final host = BoundPresentationHost(
      readOnly: readOnly,
      catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
      root: () =>
          (skir.PresentationNode.mutable()
                ..nodeId = "fixture"
                ..element = element)
              .toFrozen(),
      bindings: [
        BoundPresentationBinding(
          id: id,
          use: skir.TypeUse.wrapScalar(kind),
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
  }
}
