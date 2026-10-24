import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Configured scalar controls",
  type: PortablePresentationRenderer,
)
Widget configuredScalarControlsUseCase(BuildContext context) =>
    configuredScalarControlsStory(
      readOnly: context.knobs.boolean(
        label: "Scalar read only",
        initialValue: false,
      ),
      compact: context.knobs.boolean(
        label: "Scalar compact",
        initialValue: false,
      ),
      noIcon: context.knobs.boolean(
        label: "Scalar remove icons",
        initialValue: false,
      ),
      width: context.knobs.double.slider(
        label: "Scalar gallery width",
        initialValue: 580,
        min: 340,
        max: 900,
      ),
    );

Widget configuredScalarControlsStory({
  bool readOnly = false,
  bool compact = false,
  bool noIcon = false,
  double width = 580,
}) => FakeApp(
  child: Material(
    child: Center(
      child: SizedBox(
        width: width,
        height: 700,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConfiguredScalarGallery(
              readOnly: readOnly,
              compact: compact,
              noIcon: noIcon,
            ),
          ),
        ),
      ),
    ),
  ),
);

class ConfiguredScalarGallery extends HookWidget {
  const ConfiguredScalarGallery({
    required this.readOnly,
    required this.compact,
    required this.noIcon,
    super.key,
  });
  final bool readOnly;
  final bool compact;
  final bool noIcon;
  @override
  Widget build(BuildContext context) {
    final host = useMemoized(
      () => _scalarHost(readOnly: readOnly, compact: compact, noIcon: noIcon),
      [readOnly, compact, noIcon],
    );
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

BoundPresentationHost _scalarHost({
  required bool readOnly,
  required bool compact,
  required bool noIcon,
}) {
  final values = <String, skir.DataValue>{
    "text": skir.DataValue.wrapStringValue("Quest checkpoint"),
    "number": skir.DataValue.wrapFloat(12.25),
    "duration": skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: 90500),
    ),
    "bytes": skir.DataValue.wrapBytes(skir.ByteString.fromBase16("0a12ff")),
    "date": skir.DataValue.wrapTimestamp(DateTime.utc(2026, 10, 13, 14, 30)),
    "color": skir.DataValue.wrapInteger("4285756607"),
    "toggle": skir.DataValue.wrapBoolean(true),
    "slider": skir.DataValue.wrapFloat(40),
    "choice": skir.DataValue.wrapStringValue("center"),
  };
  final kinds = <String, skir.ScalarKind>{
    "text": skir.ScalarKind.text,
    "number": skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
    "duration": skir.ScalarKind.duration,
    "bytes": skir.ScalarKind.bytes,
    "date": skir.ScalarKind.timestamp,
    "color": skir.ScalarKind.createInteger(
      width: skir.IntegerWidth.unsignedThirtyTwo,
    ),
    "toggle": skir.ScalarKind.boolean,
    "slider": skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
    "choice": skir.ScalarKind.text,
  };
  skir.BoundControl control(String name, String label) =>
      (skir.BoundControl.mutable()
            ..binding = skir.BindingRef(
              bindingId: skir.ExpressionBindingId(value: name),
              path: editorRootPath,
            )
            ..label = textLiteral(label)
            ..semanticLabel = textLiteral(label))
          .toFrozen();
  final content =
      (skir.InputContent.mutable()
            ..leading = noIcon ? skir.InputAdornment.none : null
            ..placeholder = textLiteral("Enter a value"))
          .toFrozen();
  final candidate = skir.ExpressionBindingId(value: "candidate");
  final read = skir.ExpressionNode.createInput(
    binding: candidate,
    path: editorRootPath,
  );
  final mappings = skir.ValueMappings(
    completion: skir.ExpressionMapping(
      inputBinding: candidate,
      body: skir.ExpressionNode.createNumberRound(
        source: read,
        increment: numberLiteral(0.5),
        rounding: textLiteral("NearestTiesToEven"),
      ),
    ),
    display: null,
  );
  final nodes = <skir.PresentationNode>[
    presentationNode(
      "scalar.text",
      skir.PresentationElement.wrapTextInput(
        (skir.TextControl.mutable()
              ..control = control("text", "Checkpoint name")
              ..content = content
              ..options =
                  (skir.TextEditingOptions.mutable()
                        ..capitalization = skir.TextCapitalization.words
                        ..length = skir.TextLengthPolicy(
                          maximumGraphemes: 48,
                          enforceAfterComposition: true,
                        ))
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.number",
      skir.PresentationElement.wrapNumericInput(
        (skir.NumericControl.mutable()
              ..control = control("number", "Placement offset")
              ..content = content
              ..mappings = mappings
              ..options =
                  (skir.NumericInteractionOptions.mutable()
                        ..minimum = numberLiteral(0)
                        ..maximum = numberLiteral(100)
                        ..step = numberLiteral(0.5)
                        ..steppers = skir.NumericSteppers.inline)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.duration",
      skir.PresentationElement.wrapDurationInput(
        (skir.DurationControl.mutable()
              ..control = control("duration", "Delay")
              ..content = content
              ..options =
                  (skir.DurationInteractionOptions.mutable()
                        ..step = literalExpression(
                          skir.DataValue.createDuration(
                            value: skir.Duration(milliseconds: 1000),
                          ),
                        ))
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.bytes",
      skir.PresentationElement.wrapBytesInput(
        (skir.BytesControl.mutable()
              ..control = control("bytes", "Payload")
              ..content = content
              ..options =
                  (skir.BytesInteractionOptions.mutable()
                        ..groupSize = 2
                        ..showCount = true)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.date",
      skir.PresentationElement.wrapDateTimeInput(
        (skir.DateTimeControl.mutable()
              ..control = control("date", "Starts at")
              ..content = content
              ..includeDate = true
              ..includeTime = true)
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.color",
      skir.PresentationElement.wrapColorInput(
        (skir.ColorControl.mutable()
              ..control = control("color", "Tag color")
              ..content = content
              ..includeAlpha = true
              ..options =
                  (skir.ColorInteractionOptions.mutable()
                        ..editingRepresentation =
                            skir.ColorEditingRepresentation.rgb
                        ..showCopyAction = false)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.toggle",
      skir.PresentationElement.wrapToggleInput(
        (skir.ToggleControl.mutable()
              ..control = control("toggle", "Visible")
              ..options =
                  (skir.ToggleInteractionOptions.mutable()
                        ..presentation = skir.TogglePresentation.checkbox
                        ..trueLabel = textLiteral("Shown")
                        ..falseLabel = textLiteral("Hidden"))
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.slider",
      skir.PresentationElement.wrapSliderInput(
        (skir.SliderControl.mutable()
              ..control = control("slider", "Opacity")
              ..minimum = numberLiteral(0)
              ..maximum = numberLiteral(100)
              ..divisions = literalExpression(skir.DataValue.wrapInteger("10"))
              ..options =
                  (skir.SliderInteractionOptions.mutable()
                        ..showValue = skir.SliderValueDisplay.always
                        ..showTicks = true)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "scalar.choice",
      skir.PresentationElement.wrapSelectInput(
        (skir.SelectControl.mutable()
              ..control = control("choice", "Alignment")
              ..optionsConfig =
                  (skir.SelectInteractionOptions.mutable()
                        ..presentation = skir.ChoicePresentation.segmented)
                      .toFrozen()
              ..options = [
                for (final value in ["left", "center", "right"])
                  (skir.SelectOption.mutable()
                        ..optionId = value
                        ..label = textLiteral(value)
                        ..value = textLiteral(value))
                      .toFrozen(),
              ])
            .toFrozen(),
      ),
    ),
  ];
  final body = presentationNode(
    "scalar.column",
    skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        layout: skir.AxisChildrenLayout(
          clipOverflow: false,

          spacing: 16,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.stretch,
        ),
        children: nodes.map(skir.AxisChild.wrapFixed).toList(),
      ),
    ),
  );
  final root = presentationNode(
    "scalar.appearance",
    skir.PresentationElement.wrapAppearanceDefaults(
      skir.AppearanceDefaultsElement(
        appearance:
            (skir.InputAppearance.mutable()
                  ..density = compact
                      ? skir.ControlDensity.compact
                      : skir.ControlDensity.comfortable
                  ..radius = skir.PresentationRadius.medium
                  ..border = skir.BorderOverride.none
                  ..iconColor = skir.PresentationColor.wrapValue(
                    literalExpression(skir.DataValue.wrapInteger("4285756607")),
                  ))
                .toFrozen(),
        child: body,
      ),
    ),
  );
  return BoundPresentationHost(
    catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
    root: () => root,
    bindings: [
      for (final entry in values.entries)
        BoundPresentationBinding(
          id: skir.ExpressionBindingId(value: entry.key),
          use: skir.TypeUse.wrapScalar(kinds[entry.key]!),
          read: (_) => values[entry.key],
          write: (_, value) {
            values[entry.key] = value;
            return const PortablePresentationWriteApplied();
          },
        ),
    ],
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    readOnly: readOnly,
  );
}
