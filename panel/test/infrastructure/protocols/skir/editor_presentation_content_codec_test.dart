import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final codecs = _PresentationContentCodecs();

  test("round trips commit controls with a nested binding", () {
    codecs.expectRoundTrip(
      CommitControlsElement(
        binding: BindingReference(
          bindingId: const BindingId(7),
          path: DataPath.root.field("configuration"),
        ),
      ),
      skir.PresentationElement_kind.commitControlsWrapper,
    );
  });

  test("round trips every status tone and optional label", () {
    final tones = StatusTone.values;
    final element = StatusElement(
      value: "active".asStringLiteral,
      cases: [
        for (final (index, tone) in tones.indexed)
          StatusCase(
            match: StringValue("value$index"),
            appearance: StatusAppearance(
              tone: tone,
              label: index.isEven ? "Label $index".asStringLiteral : null,
            ),
          ),
      ],
      fallback: const StatusAppearance(tone: StatusTone.unknown),
    );

    codecs.expectRoundTrip(
      element,
      skir.PresentationElement_kind.statusWrapper,
    );
  });

  test("round trips date time zones and relative time styles", () {
    final timestamp = TypedExpression(
      resultType: const TimestampType(),
      expression: LiteralExpression(TimestampValue(DateTime.utc(2026))),
    );
    final elements = <PresentationElement>[
      DateTimeElement(value: timestamp, format: "yyyy/MM/dd".asStringLiteral),
      DateTimeElement(
        value: timestamp,
        format: "HH:mm:ss".asStringLiteral,
        timeZone: DateTimeZone.utc,
      ),
      RelativeTimeElement(value: timestamp),
      RelativeTimeElement(
        value: timestamp,
        style: RelativeTimeStyle.natural,
        timeZone: DateTimeZone.utc,
      ),
    ];

    for (final element in elements) {
      codecs.expectRoundTrip(
        element,
        element is DateTimeElement
            ? skir.PresentationElement_kind.dateTimeWrapper
            : skir.PresentationElement_kind.relativeTimeWrapper,
      );
    }
  });
}

final class _PresentationContentCodecs {
  _PresentationContentCodecs()
    : types = SkirTypeCodec(TypeRegistry(TypeCatalog(const []))) {
    values = SkirDataValueCodec(types);
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
  late final SkirDataValueCodec values;
  late final SkirPresentationEncoder encoder;
  late final SkirPresentationDecoder decoder;

  void expectRoundTrip(
    PresentationElement element,
    skir.PresentationElement_kind kind,
  ) {
    final node = PresentationNode(id: "root", element: element);
    final encoded = encoder.encodeNode(node).valueOrNull!;

    expect(encoded.element?.kind, kind);
    expect(decoder.decodeNode(encoded), node);
  }
}
