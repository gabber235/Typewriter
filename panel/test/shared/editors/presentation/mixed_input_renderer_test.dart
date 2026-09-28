import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("mixed text stays unset until typing replaces every value", (
    tester,
  ) async {
    final selection = _selection(
      type: const StringType(),
      values: const [StringValue("First"), StringValue("Second")],
    );
    addTearDown(selection.dispose);

    await tester.pumpTestApp(
      child: _editor(
        selection.owner,
        const TextInputElement(
          control: BoundControl(binding: _rootBinding),
          multiline: false,
        ),
      ),
    );

    expect(find.text("Multiple values"), findsOneWidget);
    expect(find.text(mixedValueReplacementMessage), findsOneWidget);
    expect(selection.values, const [
      StringValue("First"),
      StringValue("Second"),
    ]);

    await tester.enterText(find.byType(TextFormField), "Shared");
    await tester.pump();

    expect(selection.values, const [
      StringValue("Shared"),
      StringValue("Shared"),
    ]);
  });

  testWidgets("mixed toggle is indeterminate until an explicit choice", (
    tester,
  ) async {
    final selection = _selection(
      type: const BooleanType(),
      values: const [BooleanValue(false), BooleanValue(true)],
    );
    addTearDown(selection.dispose);

    await tester.pumpTestApp(
      child: _editor(
        selection.owner,
        const ToggleInputElement(BoundControl(binding: _rootBinding)),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isNull);
    expect(find.text(mixedValueReplacementMessage), findsOneWidget);
    expect(selection.values, const [BooleanValue(false), BooleanValue(true)]);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(selection.values, const [BooleanValue(false), BooleanValue(false)]);
  });

  testWidgets("mixed color keeps the color picker until replacement", (
    tester,
  ) async {
    final selection = _selection(
      type: NamedType(standardTypeRefs.color),
      values: [
        IntegerValue(BigInt.from(0xFF008080)),
        IntegerValue(BigInt.from(0xFFFFA500)),
      ],
    );
    addTearDown(selection.dispose);

    await tester.pumpTestApp(
      child: _editor(
        selection.owner,
        const ColorInputElement(
          control: BoundControl(binding: _rootBinding),
          includeAlpha: true,
        ),
      ),
    );

    final picker = tester.widget<ColorPickerField>(
      find.byType(ColorPickerField),
    );
    expect(picker.color, isNull);
    expect(find.byType(MixedColorSwatch), findsOneWidget);
    expect(find.text(mixedValueReplacementMessage), findsOneWidget);

    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();
    expect(find.text("Choose one replacement color."), findsOneWidget);
    expect(selection.values, [
      IntegerValue(BigInt.from(0xFF008080)),
      IntegerValue(BigInt.from(0xFFFFA500)),
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), "#FF112233");
    await tester.pumpAndSettle();

    expect(selection.values, [
      IntegerValue(BigInt.from(0xFF112233)),
      IntegerValue(BigInt.from(0xFF112233)),
    ]);
  });

  testWidgets("mixed date keeps the date picker until replacement", (
    tester,
  ) async {
    final selection = _selection(
      type: const TimestampType(),
      values: [
        TimestampValue(DateTime(2026, 1, 2)),
        TimestampValue(DateTime(2027, 3, 4)),
      ],
    );
    addTearDown(selection.dispose);

    await tester.pumpTestApp(
      child: _editor(
        selection.owner,
        const DateTimeInputElement(
          control: BoundControl(binding: _rootBinding),
          includeDate: true,
          includeTime: false,
        ),
      ),
    );

    final picker = tester.widget<DateTimePickerField>(
      find.byType(DateTimePickerField),
    );
    expect(picker.value, isNull);
    expect(find.text(mixedValueReplacementMessage), findsOneWidget);

    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    expect(find.text("Choose one replacement value."), findsOneWidget);
    expect(selection.values, [
      TimestampValue(DateTime(2026, 1, 2)),
      TimestampValue(DateTime(2027, 3, 4)),
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), "2030-01-02");
    await tester.pumpAndSettle();

    expect(selection.values, [
      TimestampValue(DateTime.utc(2030, 1, 2)),
      TimestampValue(DateTime.utc(2030, 1, 2)),
    ]);
  });

  testWidgets("mixed slider keeps its track until explicit input", (
    tester,
  ) async {
    final selection = _selection(
      type: const FloatType(width: FloatWidth.float64),
      values: const [FloatValue(0.2), FloatValue(0.8)],
    );
    addTearDown(selection.dispose);

    await tester.pumpTestApp(
      child: _editor(
        selection.owner,
        SliderInputElement(
          control: const BoundControl(binding: _rootBinding),
          minimum: 0.0.asFloatLiteral,
          maximum: 1.0.asFloatLiteral,
          divisions: 10.asIntegerLiteral,
        ),
      ),
    );

    expect(find.byType(MixedSlider), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text(mixedValueReplacementMessage), findsOneWidget);
    expect(selection.values, const [FloatValue(0.2), FloatValue(0.8)]);

    final center = tester.getCenter(find.byType(Slider));
    await tester.tapAt(center + const Offset(40, 0));
    await tester.pump();

    expect(selection.values.first, selection.values.last);
    expect(selection.values.first, isNot(const FloatValue(0.2)));
    expect(find.byType(MixedSlider), findsNothing);
  });

  for (final fixture in [
    (
      type: const ListType(element: StringType()),
      values: const <DataValue>[
        ListValue([StringValue("First")]),
        ListValue([StringValue("Second")]),
      ],
      element: const ListInputElement(
        control: BoundControl(binding: _rootBinding),
      ) as PresentationElement,
      replacement: const ListValue([]) as DataValue,
    ),
    (
      type: const MapType(key: StringType(), value: StringType()),
      values: const <DataValue>[
        MapValue([
          DataMapEntry(key: StringValue("first"), value: StringValue("one")),
        ]),
        MapValue([
          DataMapEntry(key: StringValue("second"), value: StringValue("two")),
        ]),
      ],
      element: const MapInputElement(
        control: BoundControl(binding: _rootBinding),
      ) as PresentationElement,
      replacement: const MapValue([]) as DataValue,
    ),
  ]) {
    testWidgets("mixed ${fixture.type.runtimeType} requires replacement", (
      tester,
    ) async {
      final selection = _selection(type: fixture.type, values: fixture.values);
      addTearDown(selection.dispose);

      await tester.pumpTestApp(
        child: _editor(selection.owner, fixture.element),
      );

      expect(find.text("Different collections"), findsOneWidget);
      expect(find.text(mixedValueReplacementMessage), findsOneWidget);
      expect(selection.values, fixture.values);

      await tester.tap(find.text("Replace all"));
      await tester.pumpAndSettle();

      expect(selection.values, [fixture.replacement, fixture.replacement]);
    });
  }
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

Widget _editor(MultiEditOwner owner, PresentationElement element) =>
    ComposedEditor(
      model: PresentationModel.editor(
        owner: owner,
        presentation: PresentationNode(id: "mixed", element: element),
      ),
    );

_Selection _selection({
  required TypeExpression type,
  required List<DataValue> values,
}) {
  final owners = [
    for (final value in values)
      LocalEditor(
        rootType: type,
        typeCatalog: receivedRealmCatalog(),
        value: value,
      ),
  ];
  return _Selection(
    owners,
    MultiEditOwner(
      owners: owners,
      rootType: type,
      typeCatalog: receivedRealmCatalog(),
      commitInteractions: (interactions) => interactions.commitIndependently(),
    ),
  );
}

final class _Selection {
  const _Selection(this.owners, this.owner);

  final List<LocalEditor> owners;
  final MultiEditOwner owner;

  List<DataValue?> get values =>
      owners.map((owner) => owner.value(DataPath.root).valueOrNull).toList();

  void dispose() {
    owner.dispose();
    for (final editor in owners) {
      editor.dispose();
    }
  }
}
