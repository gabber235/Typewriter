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
  const truth = TypedExpression(
    resultType: BooleanType(),
    expression: LiteralExpression(BooleanValue(true)),
  );
  final number = TypedExpression(
    resultType: const IntegerType(width: IntegerWidth.signed64),
    expression: LiteralExpression(IntegerValue(BigInt.one)),
  );
  const leaf = PresentationNode(id: "leaf", element: DividerElement());

  test("round trips every layout presentation variant", () {
    final elements = <PresentationElement>[
      ColumnElement(
        children: const [leaf],
        spacing: 2,
        mainAxisAlignment: PresentationMainAxisAlignment.spaceBetween,
        crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
      ),
      RowElement(children: const [leaf], spacing: 3),
      WrapElement(children: const [leaf], spacing: 4),
      StackElement(children: const [leaf], spacing: 5),
      GridElement(
        children: const [leaf],
        columns: 2,
        horizontalSpacing: 3,
        verticalSpacing: 4,
      ),
      const CardElement(leaf, initiallyExpanded: true),
      const SectionElement(
        title: text,
        description: text,
        child: leaf,
        initiallyExpanded: false,
      ),
      const CollapsibleElement(
        title: text,
        child: leaf,
        initiallyExpanded: true,
      ),
      TabsElement(
        tabs: const [TabItem(id: "main", label: text, child: leaf)],
        initiallySelectedTabId: "main",
      ),
      const DividerElement(),
      SpacerElement(width: number, height: number),
    ];

    for (final element in elements) {
      codecs.expectRoundTrip(element);
    }
  });

  test("round trips every semantic header item", () {
    final header = PresentationHeader(
      binding: binding,
      title: text,
      description: text,
      initiallyExpanded: false,
      items: [
        HeaderReorderHandleItem(
          id: listItemReorderHeaderItemId,
          label: text,
          tooltip: text,
          source: binding,
          visibleIf: truth,
          enabledIf: truth,
        ),
        HeaderBooleanToggleItem(
          id: booleanToggleHeaderItemId,
          label: text,
          checked: truth,
          action: LocalEditorAction(
            SetValueAction(target: binding, value: truth),
          ),
          tooltip: text,
          priority: number,
          visibleIf: truth,
          enabledIf: truth,
          placement: HeaderActionPlacement.beforeTitle,
          confirmation: const HeaderActionConfirmation(
            title: text,
            message: text,
            confirmationLabel: text,
          ),
        ),
        HeaderButtonItem(
          id: mapEntryRemoveHeaderItemId,
          icon: TypedExpression(
            resultType: NamedType(standardTypeRefs.icon),
            expression: LiteralExpression(
              const IconValue.svg("<svg></svg>").typedValue,
            ),
          ),
          label: text,
          action: LocalEditorAction(
            SetValueAction(target: binding, value: text),
          ),
          placement: HeaderActionPlacement.afterTitle,
          tone: HeaderActionTone.destructive,
        ),
      ],
    );
    final node = PresentationNode(
      id: "header",
      element: const DividerElement(),
      header: header,
    );

    final encoded = codecs.encoder.encodeNode(node).valueOrNull!;
    final bytes = wire.PresentationNode.serializer.toBytes(encoded);
    final decoded = codecs.decoder.decodeNode(
      wire.PresentationNode.serializer.fromBytes(bytes),
    );

    expect(decoded, node);
  });

  test("localizes an unknown header item", () {
    final node = PresentationNode(
      id: "unknown.header.item",
      element: const DividerElement(),
      header: PresentationHeader(
        items: [
          HeaderButtonItem(
            id: mapAddHeaderItemId,
            icon: text,
            label: text,
            action: const RealmEditorAction(ReloadRealmAction()),
          ),
        ],
      ),
    );
    final encoded = codecs.encoder.encodeNode(node).valueOrNull!;
    final mutable = encoded.toMutable()
      ..header = (encoded.header!.toMutable()
        ..items = const [wire.HeaderItem.unknown]);

    final decoded = codecs.decoder.decodeNode(mutable.toFrozen());
    final item = decoded.header!.items.single as HeaderButtonItem;

    expect(item.label, "Invalid item".asStringLiteral);
    expect(item.icon.resultType, const StringType());
  });

  test("round trips every content presentation variant", () {
    final elements = <PresentationElement>[
      const TextElement(text),
      const MarkdownElement(text),
      const IconElement(name: text, semanticLabel: text),
      const ImageElement(source: text, semanticLabel: text),
      const BadgeElement(label: text, tone: "positive"),
      ProgressElement(value: number, maximum: number, label: text),
    ];

    for (final element in elements) {
      codecs.expectRoundTrip(element);
    }
  });

  test("round trips every data presentation variant", () {
    final elements = <PresentationElement>[
      const DefaultPresentationElement(
        binding: binding,
        presentationId: PresentationId(namespace: "example", name: "main"),
      ),
      DiagnosticElement([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPresentation,
          message: "invalid",
        ),
      ]),
      const TypedFieldElement(
        binding: binding,
        expectedType: StringType(),
        presentation: leaf,
      ),
      const ConditionalElement(
        condition: truth,
        whenTrue: leaf,
        whenFalse: leaf,
      ),
      TypedExpression(
        resultType: const ListType(element: StringType()),
        expression: LiteralExpression(ListValue(const [StringValue("a")])),
      ).let(
        (source) => RepeatedElement(
          source: source,
          itemBindingId: const BindingId(2),
          template: leaf,
          empty: leaf,
        ),
      ),
      const ScopedBindingElement(
        binding: binding,
        scopeBindingId: BindingId(3),
        child: leaf,
      ),
    ];

    for (final element in elements) {
      codecs.expectRoundTrip(element);
    }
  });

  test("localizes a missing presentation element", () {
    final decoded = codecs.decoder.decodeNode(
      wire.PresentationNode(
        nodeId: "missing",
        properties: wire.PresentationProperties(
          enabledIf: null,
          readOnly: false,
        ),
        element: null,
        header: null,
      ),
    );

    expect(decoded.element, isA<DiagnosticElement>());
    final diagnostic = decoded.element as DiagnosticElement;
    expect(diagnostic.diagnostics, hasLength(1));
    expect(diagnostic.diagnostics.single.code, TypeDiagnosticCode.invalidValue);
  });
}

final class _PresentationCodecs {
  _PresentationCodecs()
    : types = SkirTypeCodec(TypeRegistry(TypeCatalog(const []))) {
    values = SkirDataValueCodec(types);
    expressionEncoder = SkirExpressionEncoder(types, values);
    expressionDecoder = SkirExpressionDecoder(types, values);
    final actionEncoder = SkirActionEncoder(expressionEncoder, values);
    final actionDecoder = SkirActionDecoder(expressionDecoder, values);
    encoder = SkirPresentationEncoder(expressionEncoder, actionEncoder, types);
    decoder = SkirPresentationDecoder(expressionDecoder, actionDecoder, types);
  }

  final SkirTypeCodec types;
  late final SkirDataValueCodec values;
  late final SkirExpressionEncoder expressionEncoder;
  late final SkirExpressionDecoder expressionDecoder;
  late final SkirPresentationEncoder encoder;
  late final SkirPresentationDecoder decoder;

  void expectRoundTrip(PresentationElement element) {
    final node = PresentationNode(
      id: "root",
      properties: const PresentationProperties(
        enabledIf: TypedExpression(
          resultType: BooleanType(),
          expression: LiteralExpression(BooleanValue(true)),
        ),
        readOnly: true,
      ),
      element: element,
    );
    final encoded = encoder.encodeNode(node).valueOrNull!;
    final bytes = wire.PresentationNode.serializer.toBytes(encoded);
    final decodedWire = wire.PresentationNode.serializer.fromBytes(bytes);
    final decoded = decoder.decodeNode(decodedWire);
    final reencoded = encoder.encodeNode(decoded).valueOrNull!;
    expect(wire.PresentationNode.serializer.toBytes(reencoded), bytes);
  }
}

extension on TypedExpression {
  T let<T>(T Function(TypedExpression value) transform) => transform(this);
}
