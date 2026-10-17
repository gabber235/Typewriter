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

skir.ExpressionNode _literal(skir.DataValue value) =>
    skir.ExpressionNode.wrapLiteral(value);
skir.ExpressionNode _text(String value) =>
    _literal(skir.DataValue.wrapStringValue(value));
skir.ExpressionNode _number(double value) =>
    _literal(skir.DataValue.wrapFloat(value));
skir.PresentationNode _node(String name, skir.PresentationElement element) =>
    (skir.PresentationNode.mutable()
          ..nodeId = "scalar.$name"
          ..element = element)
        .toFrozen();

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
            ..label = _text(label)
            ..semanticLabel = _text(label))
          .toFrozen();
  final content =
      (skir.InputContent.mutable()
            ..leading = noIcon ? skir.InputAdornment.none : null
            ..placeholder = _text("Enter a value"))
          .toFrozen();
  final candidate = skir.ExpressionBindingId(value: "candidate");
  final read = skir.ExpressionNode.createRead(
    binding: candidate,
    path: editorRootPath,
  );
  final mappings = skir.ValueMappings(
    completion: skir.ExpressionMapping(
      inputBinding: candidate,
      body: skir.ExpressionNode.createCall(
        operation: skir.OperationId(value: "typewriter.number.round_to"),
        arguments: [read, _number(0.5), _text("NearestTiesToEven")],
      ),
    ),
    display: null,
  );
  final nodes = <skir.PresentationNode>[
    _node(
      "text",
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
    _node(
      "number",
      skir.PresentationElement.wrapNumericInput(
        (skir.NumericControl.mutable()
              ..control = control("number", "Placement offset")
              ..content = content
              ..mappings = mappings
              ..options =
                  (skir.NumericInteractionOptions.mutable()
                        ..minimum = _number(0)
                        ..maximum = _number(100)
                        ..step = _number(0.5)
                        ..steppers = skir.NumericSteppers.inline)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    _node(
      "duration",
      skir.PresentationElement.wrapDurationInput(
        (skir.DurationControl.mutable()
              ..control = control("duration", "Delay")
              ..content = content
              ..options =
                  (skir.DurationInteractionOptions.mutable()
                        ..step = _literal(
                          skir.DataValue.createDuration(
                            value: skir.Duration(milliseconds: 1000),
                          ),
                        ))
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    _node(
      "bytes",
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
    _node(
      "date",
      skir.PresentationElement.wrapDateTimeInput(
        (skir.DateTimeControl.mutable()
              ..control = control("date", "Starts at")
              ..content = content
              ..includeDate = true
              ..includeTime = true)
            .toFrozen(),
      ),
    ),
    _node(
      "color",
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
    _node(
      "toggle",
      skir.PresentationElement.wrapToggleInput(
        (skir.ToggleControl.mutable()
              ..control = control("toggle", "Visible")
              ..options =
                  (skir.ToggleInteractionOptions.mutable()
                        ..presentation = skir.TogglePresentation.checkbox
                        ..trueLabel = _text("Shown")
                        ..falseLabel = _text("Hidden"))
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    _node(
      "slider",
      skir.PresentationElement.wrapSliderInput(
        (skir.SliderControl.mutable()
              ..control = control("slider", "Opacity")
              ..minimum = _number(0)
              ..maximum = _number(100)
              ..divisions = _literal(skir.DataValue.wrapInteger("10"))
              ..options =
                  (skir.SliderInteractionOptions.mutable()
                        ..showValue = skir.SliderValueDisplay.always
                        ..showTicks = true)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    _node(
      "choice",
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
                        ..label = _text(value)
                        ..value = _text(value))
                      .toFrozen(),
              ])
            .toFrozen(),
      ),
    ),
  ];
  final body = _node(
    "column",
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
  final root = _node(
    "appearance",
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
                    _literal(skir.DataValue.wrapInteger("4285756607")),
                  ))
                .toFrozen(),
        child: body,
      ),
    ),
  );
  return BoundPresentationHost(
    catalog: CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot.defaultInstance,
    ),
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
