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
  const control = BoundControl(
    binding: binding,
    label: text,
    description: text,
  );
  const leaf = PresentationNode(id: "leaf", element: DividerElement());
  final concreteType = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "entry"),
    revision: 1,
  );

  test("round trips every input presentation variant", () {
    final elements = <PresentationElement>[
      const TextInputElement(
        control: control,
        multiline: false,
        placeholder: text,
      ),
      const NumericInputElement(control),
      const ToggleInputElement(control),
      SelectInputElement(
        control: control,
        options: const [SelectOption(id: "one", label: text, value: text)],
        allowCustomValue: true,
      ),
      SliderInputElement(
        control: control,
        minimum: number,
        maximum: number,
        divisions: number,
      ),
      const DateTimeInputElement(control: control),
      const DurationInputElement(control),
      const ColorInputElement(control: control),
      const ColorInputElement(control: control, includeAlpha: true),
      const BytesInputElement(control),
      const EnumInputElement(control),
      const NamedInputElement(control),
      SearchInputElement(
        control: control,
        selectionMode: SearchSelectionMode.single,
        queryBindingId: const BindingId(10),
        summaryBindingId: const BindingId(11),
        maximumExtent: 280.asFloatLiteral,
        provider: SearchProvider.staticValues(
          values: const ListValue([
            StringValue("mdi:home"),
          ]).asLiteral(
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
      const ListInputElement(
        control: control,
        itemPresentation: leaf,
        allowAdd: false,
        allowRemove: false,
        allowReorder: false,
        itemBindingId: BindingId(2),
        indexBindingId: BindingId(5),
      ),
      const MapInputElement(
        control: control,
        keyPresentation: leaf,
        valuePresentation: leaf,
        allowAdd: false,
        allowRemove: false,
        keyBindingId: BindingId(3),
        valueBindingId: BindingId(4),
      ),
      const RecordInputElement(control: control, fieldPresentation: leaf),
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
    ];

    for (final element in elements) {
      codecs.expectRoundTrip(element);
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

  test("round trips every date and time visibility combination", () {
    for (final includeDate in [false, true]) {
      for (final includeTime in [false, true]) {
        final element = DateTimeInputElement(
          control: control,
          includeDate: includeDate,
          includeTime: includeTime,
        );
        codecs.expectRoundTrip(element);

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

  test("round trips every interaction presentation variant", () {
    const action = EditorAction.realm(ReloadRealmAction());
    final elements = <PresentationElement>[
      const ButtonElement(label: text, action: action),
      const IconButtonElement(icon: text, semanticLabel: text, action: action),
      MenuElement(
        label: text,
        items: const [
          PresentationMenuItem(id: "reload", label: text, action: action),
        ],
      ),
      const TooltipElement(message: text, child: leaf),
    ];

    for (final element in elements) {
      codecs.expectRoundTrip(element);
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

  void expectRoundTrip(PresentationElement element) {
    final encoded = encoder
        .encodeNode(PresentationNode(id: "root", element: element))
        .valueOrNull!;
    final bytes = wire.PresentationNode.serializer.toBytes(encoded);
    final decodedWire = wire.PresentationNode.serializer.fromBytes(bytes);
    final decoded = decoder.decodeNode(decodedWire);
    final reencoded = encoder.encodeNode(decoded).valueOrNull!;
    expect(wire.PresentationNode.serializer.toBytes(reencoded), bytes);
  }
}
