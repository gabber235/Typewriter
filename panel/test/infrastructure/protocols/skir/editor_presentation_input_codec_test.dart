import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
  const prefix = PresentationNode(
    id: "prefix",
    element: TextElement(text, paragraph: TextParagraph()),
  );
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
    final elements = <(PresentationElement, skir.PresentationElement_kind)>[
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
        skir.PresentationElement_kind.textInputWrapper,
      ),
      (
        const NumericInputElement(control),
        skir.PresentationElement_kind.numericInputWrapper,
      ),
      (
        const ToggleInputElement(control),
        skir.PresentationElement_kind.toggleInputWrapper,
      ),
      (
        SelectInputElement(
          control: control,
          options: const [SelectOption(id: "one", label: text, value: text)],
          allowCustomValue: true,
          defaultValue: text,
        ),
        skir.PresentationElement_kind.selectInputWrapper,
      ),
      (
        SliderInputElement(
          control: control,
          minimum: number,
          maximum: number,
          divisions: number,
        ),
        skir.PresentationElement_kind.sliderInputWrapper,
      ),
      (
        const DateTimeInputElement(control: control),
        skir.PresentationElement_kind.dateTimeInputWrapper,
      ),
      (
        const DurationInputElement(control),
        skir.PresentationElement_kind.durationInputWrapper,
      ),
      (
        const ColorInputElement(control: control),
        skir.PresentationElement_kind.colorInputWrapper,
      ),
      (
        const ColorInputElement(control: control, includeAlpha: true),
        skir.PresentationElement_kind.colorInputWrapper,
      ),
      (
        const BytesInputElement(control),
        skir.PresentationElement_kind.bytesInputWrapper,
      ),
      (
        const EnumInputElement(control),
        skir.PresentationElement_kind.enumInputWrapper,
      ),
      (
        const NamedInputElement(control),
        skir.PresentationElement_kind.namedInputWrapper,
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
        skir.PresentationElement_kind.searchInputWrapper,
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
        skir.PresentationElement_kind.listInputWrapper,
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
        skir.PresentationElement_kind.mapInputWrapper,
      ),
      (
        const RecordInputElement(control: control, fieldPresentation: leaf),
        skir.PresentationElement_kind.recordInputWrapper,
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
        skir.PresentationElement_kind.polymorphicInputWrapper,
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
      expect(element, isA<skir.PresentationElement_colorInputWrapper>());
      final color =
          (element! as skir.PresentationElement_colorInputWrapper).value;
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
        (encoded.element! as skir.PresentationElement_textInputWrapper).value;
    final malformed = skir.PresentationNode(
      nodeId: "text",
      properties: encoded.properties,
      element: skir.PresentationElement.createTextInput(
        control: text.control,
        multiline: false,
        placeholder: null,
        inputFormatters: [skir.TextInputFormat.wrapAllow("[")],
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
          skir.PresentationElement_kind.dateTimeInputWrapper,
        );

        final encoded = codecs.encoder
            .encodeNode(PresentationNode(id: "dateTime", element: element))
            .valueOrNull!;
        final wrapper =
            encoded.element! as skir.PresentationElement_dateTimeInputWrapper;
        expect(wrapper.value.includeDate, includeDate);
        expect(wrapper.value.includeTime, includeTime);
      }
    }
  });

  test("maps every interaction presentation variant and its fields", () {
    const action = EditorAction.realm(ReloadRealmAction());
    final elements = <(PresentationElement, skir.PresentationElement_kind)>[
      (
        const ButtonElement(label: text, action: action),
        skir.PresentationElement_kind.buttonWrapper,
      ),
      (
        const IconButtonElement(
          icon: text,
          semanticLabel: text,
          action: action,
        ),
        skir.PresentationElement_kind.iconButtonWrapper,
      ),
      (
        MenuElement(
          label: text,
          items: const [
            PresentationMenuItem(id: "reload", label: text, action: action),
          ],
        ),
        skir.PresentationElement_kind.menuWrapper,
      ),
      (
        const TooltipElement(message: text, child: leaf),
        skir.PresentationElement_kind.tooltipWrapper,
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
    skir.PresentationElement_kind expectedKind,
  ) {
    final node = PresentationNode(id: "root", element: element);
    final encoded = encoder.encodeNode(node).valueOrNull!;

    expect(encoded.nodeId, "root");
    expect(encoded.element?.kind, expectedKind);
    expect(decoder.decodeNode(encoded), node);
  }
}
