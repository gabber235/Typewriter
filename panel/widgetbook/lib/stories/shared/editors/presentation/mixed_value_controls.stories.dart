import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Mixed values", type: ComposedEditor)
Widget mixedValueControlsUseCase(BuildContext context) =>
    const MixedValueControls(mixed: true);

@widgetbook.UseCase(name: "Shared values", type: ComposedEditor)
Widget sharedValueControlsUseCase(BuildContext context) =>
    const MixedValueControls(mixed: false);

class MixedValueControls extends StatefulWidget {
  const MixedValueControls({required this.mixed, super.key});

  final bool mixed;

  @override
  State<MixedValueControls> createState() => _MixedValueControlsState();
}

class _MixedValueControlsState extends State<MixedValueControls> {
  late final List<LocalEditor> _editors = [
    LocalEditor(
      rootType: _type,
      typeCatalog: receivedRealmCatalog(),
      value: _firstValue,
    ),
    LocalEditor(
      rootType: _type,
      typeCatalog: receivedRealmCatalog(),
      value: widget.mixed ? _secondValue : _firstValue,
    ),
  ];

  late final MultiEditOwner _owner = MultiEditOwner(
    owners: _editors,
    rootType: _type,
    typeCatalog: receivedRealmCatalog(),
    commitInteractions: (interactions) => interactions.commitIndependently(),
  );

  @override
  Widget build(BuildContext context) => FakeApp(
    child: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Section(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ComposedEditor(
                  model: PresentationModel.editor(
                    owner: _owner,
                    presentation: _presentation,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _owner.dispose();
    for (final editor in _editors) {
      editor.dispose();
    }
    super.dispose();
  }
}

final _type = RecordType(
  fields: {
    "name": const TypeField(name: "name", type: StringType()),
    "color": TypeField(name: "color", type: NamedType(standardTypeRefs.color)),
    "startsAt": const TypeField(name: "startsAt", type: TimestampType()),
    "intensity": const TypeField(
      name: "intensity",
      type: FloatType(width: FloatWidth.float64),
    ),
    "duration": const TypeField(name: "duration", type: DurationType()),
  },
);

final _firstValue = RecordValue({
  "name": const StringValue("Earth"),
  "color": IntegerValue(BigInt.from(0xFF008080)),
  "startsAt": TimestampValue(DateTime.utc(2026, 1, 2, 10, 30)),
  "intensity": const FloatValue(0.25),
  "duration": const DurationValue(Duration(minutes: 5)),
});

final _secondValue = RecordValue({
  "name": const StringValue("Europe"),
  "color": IntegerValue(BigInt.from(0xFFFFA500)),
  "startsAt": TimestampValue(DateTime.utc(2027, 3, 4, 14, 45)),
  "intensity": const FloatValue(0.75),
  "duration": const DurationValue(Duration(minutes: 12)),
});

final _presentation = PresentationNode(
  id: "mixedValues",
  element: ColumnElement(
    spacing: 16,
    crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
    children: [
      PresentationAxisChild.fixed(
        PresentationNode(
          id: "name",
          element: TextInputElement(
            control: "name"._control("Name"),
            multiline: false,
          ),
        ),
      ),
      PresentationAxisChild.fixed(
        PresentationNode(
          id: "color",
          element: ColorInputElement(control: "color"._control("Color")),
        ),
      ),
      PresentationAxisChild.fixed(
        PresentationNode(
          id: "startsAt",
          element: DateTimeInputElement(
            control: "startsAt"._control("Starts at"),
          ),
        ),
      ),
      PresentationAxisChild.fixed(
        PresentationNode(
          id: "intensity",
          element: SliderInputElement(
            control: "intensity"._control("Intensity"),
            minimum: 0.0.asFloatLiteral,
            maximum: 1.0.asFloatLiteral,
            divisions: 20.asIntegerLiteral,
          ),
        ),
      ),
      PresentationAxisChild.fixed(
        PresentationNode(
          id: "duration",
          element: DurationInputElement("duration"._control("Duration")),
        ),
      ),
    ],
  ),
);

extension on String {
  BoundControl _control(String label) => BoundControl(
    binding: BindingReference(
      bindingId: const BindingId(0),
      path: DataPath.root.field(this),
    ),
    label: label.asStringLiteral,
  );
}
