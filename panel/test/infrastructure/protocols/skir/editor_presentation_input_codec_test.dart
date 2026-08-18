import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final codecs = _PresentationCodecs();
  const binding = BindingReference(bindingId: BindingId(1));
  const text = TypedExpression(
    resultType: StringType(),
    expression: LiteralExpression(StringValue("label")),
  );
  final number = TypedExpression(
    resultType: const IntegerType(width: IntegerWidth.signed64),
    expression: LiteralExpression(IntegerValue(BigInt.one)),
  );
  const prefix = PresentationNode(id: "prefix", element: TextElement(text));
  const control = BoundControl(
    binding: binding,
    label: text,
    description: text,
    prefix: prefix,
    semanticLabel: text,
  );
  const leaf = PresentationNode(id: "leaf", element: DividerElement());
  final concreteType = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "entry"),
    revision: 1,
  );

  test("maps every input presentation variant and its fields", () {
    final elements = <(PresentationElement, wire.PresentationElement_kind)>[
      (
        const TextInputElement(
          control: control,
          multiline: false,
          placeholder: text,
          inputFormatters: [
            TextInputFormat.lowercase(),
            TextInputFormat.uppercase(),
            TextInputFormat.replace(pattern: r"\s+", replacement: "_"),
            TextInputFormat.allow("[a-z_]"),
            TextInputFormat.deny("[^a-z_]"),
          ],
        ),
        wire.PresentationElement_kind.textInputWrapper,
      ),
      (
        const NumericInputElement(control),
        wire.PresentationElement_kind.numericInputWrapper,
      ),
      (
        const ToggleInputElement(control),
        wire.PresentationElement_kind.toggleInputWrapper,
      ),
      (
        SelectInputElement(
          control: control,
          options: const [SelectOption(id: "one", label: text, value: text)],
          allowCustomValue: true,
        ),
        wire.PresentationElement_kind.selectInputWrapper,
      ),
      (
        SliderInputElement(
          control: control,
          minimum: number,
          maximum: number,
          divisions: number,
        ),
        wire.PresentationElement_kind.sliderInputWrapper,
      ),
      (
        const DateTimeInputElement(control: control),
        wire.PresentationElement_kind.dateTimeInputWrapper,
      ),
      (
        const DurationInputElement(control),
        wire.PresentationElement_kind.durationInputWrapper,
      ),
      (
        const ColorInputElement(control: control),
        wire.PresentationElement_kind.colorInputWrapper,
      ),
      (
        const ColorInputElement(control: control, includeAlpha: true),
        wire.PresentationElement_kind.colorInputWrapper,
      ),
      (
        const BytesInputElement(control),
        wire.PresentationElement_kind.bytesInputWrapper,
      ),
      (
        const EnumInputElement(control),
        wire.PresentationElement_kind.enumInputWrapper,
      ),
      (
        const NamedInputElement(control),
        wire.PresentationElement_kind.namedInputWrapper,
      ),
      (
        SearchInputElement(
          control: control,
          selectionMode: SearchSelectionMode.single,
          queryBindingId: const BindingId(10),
          summaryBindingId: const BindingId(11),
          maximumExtent: 280.asFloatLiteral,
          initialQuery: "".asStringLiteral,
          provider: SearchProvider.staticValues(
            values: const ListValue([StringValue("mdi:home")]).asLiteral(
              ListType(element: NamedType(standardTypeRefs.iconifyIcon)),
            ),
            result: SearchResultMapping(
              bindingId: const BindingId(12),
              key: text,
              selectedValue: text,
              presentation: leaf,
            ),
          ),
        ),
        wire.PresentationElement_kind.searchInputWrapper,
      ),
      (
        const ListInputElement(
          control: control,
          itemPresentation: leaf,
          allowAdd: false,
          allowRemove: false,
          allowReorder: false,
          itemBindingId: BindingId(2),
          indexBindingId: BindingId(5),
        ),
        wire.PresentationElement_kind.listInputWrapper,
      ),
      (
        const MapInputElement(
          control: control,
          keyPresentation: leaf,
          valuePresentation: leaf,
          allowAdd: false,
          allowRemove: false,
          keyBindingId: BindingId(3),
          valueBindingId: BindingId(4),
        ),
        wire.PresentationElement_kind.mapInputWrapper,
      ),
      (
        const RecordInputElement(control: control, fieldPresentation: leaf),
        wire.PresentationElement_kind.recordInputWrapper,
      ),
      (
        PolymorphicInputElement(
          control: control,
          concreteTypes: [
            ConcreteTypePresentation(
              type: concreteType,
              label: text,
              presentation: leaf,
            ),
          ],
        ),
        wire.PresentationElement_kind.polymorphicInputWrapper,
      ),
    ];

    for (final (element, kind) in elements) {
      codecs.expectMapping(element, kind);
    }
  });

  test("encodes both color modes through one color control", () {
    for (final includeAlpha in [false, true]) {
      final encoded = codecs.encoder
          .encodeNode(
            PresentationNode(
              id: "color",
              element: ColorInputElement(
                control: control,
                includeAlpha: includeAlpha,
              ),
            ),
          )
          .valueOrNull!;

      final element = encoded.element;
      expect(element, isA<wire.PresentationElement_colorInputWrapper>());
      final color =
          (element! as wire.PresentationElement_colorInputWrapper).value;
      expect(color.includeAlpha, includeAlpha);
    }
  });

  test("decodes malformed formatter patterns as diagnostics", () {
    final encoded = codecs.encoder
        .encodeNode(
          const PresentationNode(
            id: "text",
            element: TextInputElement(control: control),
          ),
        )
        .valueOrNull!;
    final text =
        (encoded.element! as wire.PresentationElement_textInputWrapper).value;
    final malformed = wire.PresentationNode(
      nodeId: "text",
      properties: encoded.properties,
      element: wire.PresentationElement.createTextInput(
        control: text.control,
        multiline: false,
        placeholder: null,
        inputFormatters: [wire.TextInputFormat.wrapAllow("[")],
      ),
      header: null,
    );

    final decoded = codecs.decoder.decodeNode(malformed);

    expect(decoded.element, isA<DiagnosticElement>());
    expect(
      (decoded.element as DiagnosticElement).diagnostics.single.message,
      "Text input formatter pattern is malformed",
    );
  });

  test("maps every date and time visibility combination", () {
    for (final includeDate in [false, true]) {
      for (final includeTime in [false, true]) {
        final element = DateTimeInputElement(
          control: control,
          includeDate: includeDate,
          includeTime: includeTime,
        );
        codecs.expectMapping(
          element,
          wire.PresentationElement_kind.dateTimeInputWrapper,
        );

        final encoded = codecs.encoder
            .encodeNode(PresentationNode(id: "dateTime", element: element))
            .valueOrNull!;
        final wrapper =
            encoded.element! as wire.PresentationElement_dateTimeInputWrapper;
        expect(wrapper.value.includeDate, includeDate);
        expect(wrapper.value.includeTime, includeTime);
      }
    }
  });

  test("maps every interaction presentation variant and its fields", () {
    const action = EditorAction.realm(ReloadRealmAction());
    final elements = <(PresentationElement, wire.PresentationElement_kind)>[
      (
        const ButtonElement(label: text, action: action),
        wire.PresentationElement_kind.buttonWrapper,
      ),
      (
        const IconButtonElement(
          icon: text,
          semanticLabel: text,
          action: action,
        ),
        wire.PresentationElement_kind.iconButtonWrapper,
      ),
      (
        MenuElement(
          label: text,
          items: const [
            PresentationMenuItem(id: "reload", label: text, action: action),
          ],
        ),
        wire.PresentationElement_kind.menuWrapper,
      ),
      (
        const TooltipElement(message: text, child: leaf),
        wire.PresentationElement_kind.tooltipWrapper,
      ),
    ];

    for (final (element, kind) in elements) {
      codecs.expectMapping(element, kind);
    }
  });
}

final class _PresentationCodecs {
  _PresentationCodecs()
    : types = SkirTypeCodec(TypeRegistry(TypeCatalog(const []))) {
    final values = SkirDataValueCodec(types);
    final expressionEncoder = SkirExpressionEncoder(types, values);
    final expressionDecoder = SkirExpressionDecoder(types, values);
    encoder = SkirPresentationEncoder(
      expressionEncoder,
      SkirActionEncoder(expressionEncoder, values),
      types,
    );
    decoder = SkirPresentationDecoder(
      expressionDecoder,
      SkirActionDecoder(expressionDecoder, values),
      types,
    );
  }

  final SkirTypeCodec types;
  late final SkirPresentationEncoder encoder;
  late final SkirPresentationDecoder decoder;

  void expectMapping(
    PresentationElement element,
    wire.PresentationElement_kind expectedKind,
  ) {
    final node = PresentationNode(id: "root", element: element);
    final encoded = encoder.encodeNode(node).valueOrNull!;

    expect(encoded.nodeId, "root");
    expect(encoded.element?.kind, expectedKind);
    expect(decoder.decodeNode(encoded), node);
  }
}
