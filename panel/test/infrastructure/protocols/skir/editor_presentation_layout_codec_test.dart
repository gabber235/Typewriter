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
  final color = TypedExpression(
    resultType: NamedType(standardTypeRefs.color),
    expression: LiteralExpression(IntegerValue(BigInt.from(0xFF967BFA))),
  );
  final concreteType = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "entry"),
    revision: 1,
  );
  const leaf = PresentationNode(id: "leaf", element: DividerElement());

  test("maps every layout presentation variant and its fields", () {
    final elements = <(PresentationElement, wire.PresentationElement_kind)>[
      (
        ColumnElement(
          children: const [leaf],
          spacing: 2,
          mainAxisAlignment: PresentationMainAxisAlignment.spaceBetween,
          crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
        ),
        wire.PresentationElement_kind.childrenWrapper,
      ),
      (
        RowElement(children: const [leaf], spacing: 3),
        wire.PresentationElement_kind.childrenWrapper,
      ),
      (
        WrapElement(children: const [leaf], spacing: 4, runSpacing: 6),
        wire.PresentationElement_kind.childrenWrapper,
      ),
      (
        StackElement(children: const [leaf]),
        wire.PresentationElement_kind.childrenWrapper,
      ),
      (
        GridElement(
          children: const [leaf],
          columns: 2,
          horizontalSpacing: 3,
          verticalSpacing: 4,
        ),
        wire.PresentationElement_kind.childrenWrapper,
      ),
      (
        SectionElement(
          child: leaf,
          border: PresentationBorder.sides(
            top: const PresentationBorderSide(width: 1),
            start: PresentationBorderSide(color: color, width: 4),
            bottom: const PresentationBorderSide(width: 2),
          ),
        ),
        wire.PresentationElement_kind.sectionWrapper,
      ),
      (
        ContainerElement(
          child: leaf,
          border: PresentationBorder.all(
            PresentationBorderSide(color: color, width: 2),
          ),
          backgroundColor: color,
          radius: PresentationRadius.custom(number),
        ),
        wire.PresentationElement_kind.containerWrapper,
      ),
      (
        PresentationAnchorElement(
          child: leaf,
          anchors: [
            PresentationAnchorPoint(
              id: "origin",
              groupIds: const ["items"],
              alignment: PresentationAnchorAlignment.bottomStart,
              offset: PresentationOffset(x: number, y: number),
              visibleIf: truth,
              exportToParent: true,
            ),
          ],
        ),
        wire.PresentationElement_kind.anchorWrapper,
      ),
      (
        ConnectionLayerElement(
          child: leaf,
          connections: [
            PresentationConnection.connection(
              source: const PresentationAnchorSelector.local("origin"),
              target: const PresentationAnchorSelector.exportedGroup("items"),
              path: ConnectionPath.orthogonal(
                OrthogonalConnectionPath(bendPosition: number),
              ),
              style: ConnectorStyle(
                stroke: ConnectorStroke(color: color, width: number),
                cornerRadius: number,
                startMarker: ConnectorEndpointMarker.arrow(size: number),
                endMarker: ConnectorEndpointMarker.circle(diameter: number),
              ),
              markers: [
                ConnectionMarker(
                  node: leaf,
                  position: number,
                  alignToPath: truth,
                  scope: ConnectionExpressionScope.target,
                ),
              ],
              visibleIf: truth,
            ),
          ],
        ),
        wire.PresentationElement_kind.connectionLayerWrapper,
      ),
      (
        const PaddingElement(child: leaf, top: 1, start: 2, end: 3, bottom: 4),
        wire.PresentationElement_kind.paddingWrapper,
      ),
      (
        const PresentationSlotElement(slotId: "children"),
        wire.PresentationElement_kind.slotWrapper,
      ),
      (
        SectionElement(
          child: leaf,
          border: PresentationBorder.all(
            PresentationBorderSide(color: color, width: 3),
          ),
        ),
        wire.PresentationElement_kind.sectionWrapper,
      ),
      (
        TabsElement(
          tabs: const [TabItem(id: "main", label: text, child: leaf)],
          initiallySelectedTabId: "main",
        ),
        wire.PresentationElement_kind.tabsWrapper,
      ),
      (const DividerElement(), wire.PresentationElement_kind.dividerConst),
      (
        SpacerElement(width: number, height: number),
        wire.PresentationElement_kind.spacerWrapper,
      ),
    ];

    for (final (element, kind) in elements) {
      codecs.expectMapping(element, kind);
    }
  });

  test("maps every semantic header item and its metadata", () {
    final header = PresentationHeader(
      binding: binding,
      title: const PresentationHeaderTitle.text(text),
      description: text,
      initiallyExpanded: false,
      headerPadding: const PresentationInsets.only(
        top: 1,
        left: 2,
        right: 3,
        bottom: 4,
      ),
      contentPadding: const PresentationInsets.symmetric(
        horizontal: 5,
        vertical: 6,
      ),
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
    final encodedHeader = encoded.header!;

    expect(encoded.nodeId, "header");
    expect(encoded.element?.kind, wire.PresentationElement_kind.dividerConst);
    expect(encodedHeader.items, hasLength(3));
    expect(encodedHeader.items.map((item) => item.kind), [
      wire.HeaderItem_kind.reorderHandleWrapper,
      wire.HeaderItem_kind.booleanToggleWrapper,
      wire.HeaderItem_kind.buttonWrapper,
    ]);
    expect(
      encodedHeader.headerPadding?.kind,
      wire.PresentationInsets_kind.onlyWrapper,
    );
    final encodedHeaderPadding =
        (encodedHeader.headerPadding! as wire.PresentationInsets_onlyWrapper)
            .value;
    expect(encodedHeaderPadding.top, 1);
    expect(encodedHeaderPadding.left, 2);
    expect(encodedHeaderPadding.right, 3);
    expect(encodedHeaderPadding.bottom, 4);
    expect(
      encodedHeader.contentPadding?.kind,
      wire.PresentationInsets_kind.symmetricWrapper,
    );
    final decoded = codecs.decoder.decodeNode(encoded);

    expect(decoded, node);
  });

  test("maps a presentation node header title", () {
    const node = PresentationNode(
      id: "richHeader",
      header: PresentationHeader(
        title: PresentationHeaderTitle.presentation(
          PresentationNode(id: "title", element: TextElement(text)),
        ),
      ),
      element: DividerElement(),
    );

    final encoded = codecs.encoder.encodeNode(node).valueOrNull!;
    final decoded = codecs.decoder.decodeNode(encoded);

    expect(decoded, node);
  });

  test("maps every presentation inset shape", () {
    const cases = [
      PresentationInsets.all(8),
      PresentationInsets.symmetric(horizontal: 6, vertical: 3),
      PresentationInsets.only(top: 1, left: 2, right: 3, bottom: 4),
    ];

    for (final padding in cases) {
      final node = PresentationNode(
        id: "insets.${padding.runtimeType}",
        header: PresentationHeader(headerPadding: padding),
        element: const DividerElement(),
      );
      final encoded = codecs.encoder.encodeNode(node).valueOrNull!;
      final decoded = codecs.decoder.decodeNode(encoded);

      expect(decoded, node);
    }
  });

  test("rejects invalid section border widths", () {
    final decoded = codecs.decoder.decodeNode(
      wire.PresentationNode(
        nodeId: "invalid.border.width",
        properties: wire.PresentationProperties(
          enabledIf: null,
          readOnly: false,
        ),
        element: wire.PresentationElement.createSection(
          child: codecs.encoder.encodeNode(leaf).valueOrNull!,
          border: wire.PresentationBorder.createAll(color: null, width: 0),
        ),
        header: null,
      ),
    );

    expect(decoded.element, isA<DiagnosticElement>());
  });

  test("rejects section borders without sides", () {
    final decoded = codecs.decoder.decodeNode(
      wire.PresentationNode(
        nodeId: "invalid.border.sides",
        properties: wire.PresentationProperties(
          enabledIf: null,
          readOnly: false,
        ),
        element: wire.PresentationElement.createSection(
          child: codecs.encoder.encodeNode(leaf).valueOrNull!,
          border: wire.PresentationBorder.createSides(
            top: null,
            start: null,
            end: null,
            bottom: null,
          ),
        ),
        header: null,
      ),
    );

    expect(decoded.element, isA<DiagnosticElement>());
  });

  test("rejects invalid directional padding", () {
    final decoded = codecs.decoder.decodeNode(
      wire.PresentationNode(
        nodeId: "invalid.padding",
        properties: wire.PresentationProperties(
          enabledIf: null,
          readOnly: false,
        ),
        element: wire.PresentationElement.createPadding(
          child: codecs.encoder.encodeNode(leaf).valueOrNull!,
          top: 0,
          start: -1,
          end: 0,
          bottom: 0,
        ),
        header: null,
      ),
    );

    expect(decoded.element, isA<DiagnosticElement>());
  });

  final invalidHeaderInsets = {
    "negative all": wire.PresentationInsets.wrapAll(-1),
    "nonfinite all": wire.PresentationInsets.wrapAll(double.nan),
    "negative symmetric": wire.PresentationInsets.createSymmetric(
      horizontal: -1,
      vertical: 0,
    ),
    "nonfinite symmetric": wire.PresentationInsets.createSymmetric(
      horizontal: 0,
      vertical: double.infinity,
    ),
    "negative only": wire.PresentationInsets.createOnly(
      top: 0,
      left: -1,
      right: 0,
      bottom: 0,
    ),
    "nonfinite only": wire.PresentationInsets.createOnly(
      top: 0,
      left: 0,
      right: double.negativeInfinity,
      bottom: 0,
    ),
  };

  for (final invalidInsets in invalidHeaderInsets.entries) {
    test("rejects ${invalidInsets.key} header padding", () {
      final encoded = codecs.encoder
          .encodeNode(
            const PresentationNode(
              id: "invalid.header.padding",
              header: PresentationHeader(),
              element: DividerElement(),
            ),
          )
          .valueOrNull!;
      final invalidHeader = encoded.header!.toMutable()
        ..headerPadding = invalidInsets.value;
      final decoded = codecs.decoder.decodeNode(
        (encoded.toMutable()..header = invalidHeader).toFrozen(),
      );

      expect(decoded.element, isA<DiagnosticElement>());
    });
  }

  test("rejects an empty presentation slot identifier", () {
    final decoded = codecs.decoder.decodeNode(
      wire.PresentationNode(
        nodeId: "invalid.slot",
        properties: wire.PresentationProperties(
          enabledIf: null,
          readOnly: false,
        ),
        element: wire.PresentationElement.createSlot(slotId: ""),
        header: null,
      ),
    );

    expect(decoded.element, isA<DiagnosticElement>());
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

  test("maps every content presentation variant and its fields", () {
    final elements = <(PresentationElement, wire.PresentationElement_kind)>[
      (
        TextElement(
          text,
          color: color,
          fontSize: number,
          fontWeight: number,
          fontItalic: number,
          fontOpticalSize: number,
          fontSlant: number,
          fontWidth: number,
          textAlignment: text,
          lineHeight: number,
          letterSpacing: number,
          decoration: text,
          semanticLabel: text,
        ),
        wire.PresentationElement_kind.textWrapper,
      ),
      (
        MarkdownElement(text, color: color),
        wire.PresentationElement_kind.markdownWrapper,
      ),
      (
        IconElement(
          name: text,
          semanticLabel: text,
          color: color,
          size: number,
        ),
        wire.PresentationElement_kind.iconWrapper,
      ),
      (
        const ImageElement(source: text, semanticLabel: text),
        wire.PresentationElement_kind.imageWrapper,
      ),
      (
        const BadgeElement(label: text, tone: "positive"),
        wire.PresentationElement_kind.badgeWrapper,
      ),
      (
        ChipElement(label: text, color: color),
        wire.PresentationElement_kind.chipWrapper,
      ),
      (
        ProgressElement(value: number, maximum: number, label: text),
        wire.PresentationElement_kind.progressWrapper,
      ),
    ];

    for (final (element, kind) in elements) {
      codecs.expectMapping(element, kind);
    }
  });

  test("maps every data presentation variant and its fields", () {
    final elements = <(PresentationElement, wire.PresentationElement_kind)>[
      (
        const DefaultPresentationElement(
          binding: binding,
          presentationId: PresentationId(namespace: "example", name: "main"),
        ),
        wire.PresentationElement_kind.defaultPresentationWrapper,
      ),
      (
        DiagnosticElement([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidPresentation,
            message: "invalid",
          ),
        ]),
        wire.PresentationElement_kind.textWrapper,
      ),
      (
        const TypedFieldElement(
          binding: binding,
          expectedType: StringType(),
          presentation: leaf,
        ),
        wire.PresentationElement_kind.typedFieldWrapper,
      ),
      (
        const ConditionalElement(
          condition: truth,
          whenTrue: leaf,
          whenFalse: leaf,
        ),
        wire.PresentationElement_kind.conditionalWrapper,
      ),
      (
        TypedExpression(
          resultType: const ListType(element: StringType()),
          expression: LiteralExpression(ListValue(const [StringValue("a")])),
        ).let(
          (source) => RepeatedElement(
            source: source,
            itemBindingId: const BindingId(2),
            presentation: const SequencePresentation(
              item: leaf,
              empty: leaf,
              separator: leaf,
              layout: PresentationSequenceLayout.children(
                PresentationChildrenLayout.wrap(spacing: 4, runSpacing: 6),
              ),
            ),
          ),
        ),
        wire.PresentationElement_kind.repeatedWrapper,
      ),
      (
        RepeatedElement(
          source: TypedExpression(
            resultType: const ListType(element: StringType()),
            expression: LiteralExpression(ListValue(const [StringValue("a")])),
          ),
          itemBindingId: const BindingId(9),
          presentation: SequencePresentation(
            item: leaf,
            layout: PresentationSequenceLayout.hierarchy(
              HierarchySequenceLayout(
                unaryConnector: ConnectorStyle(
                  stroke: ConnectorStroke(color: color, width: number),
                  cornerRadius: number,
                  startMarker: ConnectorEndpointMarker.arrow(size: number),
                ),
                trunkConnector: ConnectorStyle(
                  stroke: ConnectorStroke(color: color, width: number),
                  cornerRadius: number,
                ),
                branchConnector: ConnectorStyle(
                  stroke: ConnectorStroke(color: color, width: number),
                  cornerRadius: number,
                  endMarker: ConnectorEndpointMarker.circle(diameter: number),
                ),
                itemSpacing: number,
                indentation: number,
                leadingSpacing: number,
                itemAnchor: ConnectorAnchor.offset(number),
                flattenSingleItem: truth,
                crossAxisAlignment: PresentationCrossAxisAlignment.end,
              ),
            ),
          ),
        ),
        wire.PresentationElement_kind.repeatedWrapper,
      ),
      (
        const ScopedBindingElement(
          binding: binding,
          scopeBindingId: BindingId(3),
          child: leaf,
        ),
        wire.PresentationElement_kind.scopedBindingWrapper,
      ),
      (
        PolymorphicMatchElement(
          binding: binding,
          scopeBindingId: const BindingId(4),
          cases: [PolymorphicMatchCase(type: concreteType, child: leaf)],
          fallback: leaf,
        ),
        wire.PresentationElement_kind.polymorphicMatchWrapper,
      ),
      (
        const CollectionGraphElement(
          sourceId: PresentationCollectionSourceId("nodes"),
          roots: binding,
          rootSequence: SequencePresentation(
            item: PresentationNode(
              id: "graphRoot",
              element: PresentationSlotElement(slotId: "root"),
            ),
          ),
          relation: PresentationCollectionRelationId("links"),
          direction: CollectionGraphDirection.forward,
          maximumDepth: 8,
          node: PresentationNode(
            id: "graphNode",
            element: PresentationSlotElement(slotId: "children"),
          ),
          childrenBindingId: BindingId(7),
          childBindingId: BindingId(8),
          children: SequencePresentation(
            item: PresentationNode(
              id: "graphChild",
              element: PresentationSlotElement(slotId: "children"),
            ),
          ),
        ),
        wire.PresentationElement_kind.collectionGraphWrapper,
      ),
    ];

    for (final (element, kind) in elements) {
      if (element is DiagnosticElement) {
        final encoded = codecs.encoder
            .encodeNode(PresentationNode(id: "root", element: element))
            .valueOrNull!;
        expect(encoded.element?.kind, kind);
        final decoded = codecs.decoder.decodeNode(encoded).element;
        expect(decoded, isA<TextElement>());
        expect((decoded as TextElement).value, "invalid".asStringLiteral);
        continue;
      }
      codecs.expectMapping(element, kind);
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

  void expectMapping(
    PresentationElement element,
    wire.PresentationElement_kind expectedKind,
  ) {
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

    expect(encoded.nodeId, "root");
    expect(encoded.properties.readOnly, isTrue);
    expect(encoded.properties.enabledIf, isNotNull);
    expect(encoded.element?.kind, expectedKind);
    expect(decoder.decodeNode(encoded), node);
  }
}

extension on TypedExpression {
  T let<T>(T Function(TypedExpression value) transform) => transform(this);
}
