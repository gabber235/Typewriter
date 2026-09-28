part of "editor_presentation_codec.dart";

/// Decodes layout structure and its renderer independent constraints.
///
/// Layout is separate from content so a node tree can arrange, wrap, anchor,
/// and decorate child nodes without changing the values those nodes consume.
extension SkirPresentationLayoutDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _children(wire.ChildrenElement value) =>
      switch (value) {
        wire.ChildrenElement_columnWrapper(:final value) => _axisChildren(
          value,
          ColumnElement.new,
        ),
        wire.ChildrenElement_rowWrapper(:final value) => _axisChildren(
          value,
          RowElement.new,
        ),
        wire.ChildrenElement_wrapWrapper(:final value) =>
          _wrapLayout(value.layout).mapValue(
            (layout) => layout.element(
              value.children.map(decodeNode).toList(growable: false),
            ),
          ),
        wire.ChildrenElement_gridWrapper(:final value) =>
          _gridLayout(value.layout).mapValue(
            (layout) => layout.element(
              value.children.map(decodeNode).toList(growable: false),
            ),
          ),
        wire.ChildrenElement_stackWrapper(:final value) => TypeResult.success(
          StackElement(
            children: value.children.map(decodeNode).toList(growable: false),
          ),
        ),
        wire.ChildrenElement_unknown() => invalidWire(
          "Unknown children element",
        ),
      };

  TypeResult<PresentationElement> _axisChildren(
    wire.AxisChildrenElement value,
    PresentationElement Function({
      required List<PresentationAxisChild> children,
      double spacing,
      PresentationMainAxisAlignment mainAxisAlignment,
      PresentationCrossAxisAlignment crossAxisAlignment,
    })
    create,
  ) {
    final layout = _axisLayout(value.layout, PresentationColumnLayout.new);
    final children = <PresentationAxisChild>[];
    final diagnostics = [...layout.diagnostics];
    for (final child in value.children) {
      final decoded = switch (child) {
        wire.AxisChild_fixedWrapper(:final value) => TypeResult.success(
          PresentationAxisChild.fixed(decodeNode(value)),
        ),
        wire.AxisChild_flexibleWrapper(:final value) =>
          value.flex <= 0
              ? invalidWire("Axis child flex must be positive")
              : switch (value.fit) {
                  wire.FlexFit.tight => TypeResult.success(
                    PresentationAxisChild.flexible(
                      child: decodeNode(value.child),
                      flex: value.flex,
                      fit: PresentationFlexFit.tight,
                    ),
                  ),
                  wire.FlexFit.loose => TypeResult.success(
                    PresentationAxisChild.flexible(
                      child: decodeNode(value.child),
                      flex: value.flex,
                    ),
                  ),
                  _ => invalidWire("Unknown axis child flex fit"),
                },
        wire.AxisChild_unknown() => invalidWire("Unknown axis child"),
      };
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final value?) children.add(value);
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    final axis = layout.valueOrNull!;
    return TypeResult.success(
      create(
        children: children,
        spacing: axis._axisSpacing,
        mainAxisAlignment: axis._axisMainAlignment,
        crossAxisAlignment: axis._axisCrossAlignment,
      ),
    );
  }

  TypeResult<PresentationChildrenLayout> _childrenLayout(
    wire.ChildrenLayout value,
  ) => switch (value) {
    wire.ChildrenLayout_columnWrapper(:final value) => _axisLayout(
      value,
      PresentationColumnLayout.new,
    ),
    wire.ChildrenLayout_rowWrapper(:final value) => _axisLayout(
      value,
      PresentationRowLayout.new,
    ),
    wire.ChildrenLayout_wrapWrapper(:final value) => _wrapLayout(value),
    wire.ChildrenLayout_gridWrapper(:final value) => _gridLayout(value),
    wire.ChildrenLayout.stack => const TypeResult.success(
      PresentationStackLayout(),
    ),
    wire.ChildrenLayout_unknown() => invalidWire("Unknown children layout"),
  };

  TypeResult<PresentationSequenceLayout> _sequenceLayout(
    wire.SequenceLayout value,
  ) => switch (value) {
    wire.SequenceLayout_childrenWrapper(:final value) => _childrenLayout(
      value,
    ).mapValue(PresentationSequenceLayout.children),
    wire.SequenceLayout_hierarchyWrapper(:final value) =>
      _hierarchySequenceLayout(value)
          .mapValue(PresentationSequenceLayout.hierarchy),
    wire.SequenceLayout_unknown() => invalidWire("Unknown sequence layout"),
  };

  TypeResult<HierarchySequenceLayout> _hierarchySequenceLayout(
    wire.HierarchySequenceLayout value,
  ) {
    final unary = _connectorStyle(value.unaryConnector);
    final trunk = _connectorStyle(value.trunkConnector);
    final branch = _connectorStyle(value.branchConnector);
    final itemSpacing = expressions.decode(value.itemSpacing);
    final indentation = expressions.decode(value.indentation);
    final leadingSpacing = expressions.decode(value.leadingSpacing);

    final anchor = _connectorAnchor(value.itemAnchor);
    final flatten = expressions.decode(value.flattenSingleItem);
    final alignment = value.crossAxisAlignment._decodeCrossAxisAlignment;
    final diagnostics = [
      ...unary.diagnostics,
      ...trunk.diagnostics,
      ...branch.diagnostics,
      ...itemSpacing.diagnostics,
      ...indentation.diagnostics,
      ...leadingSpacing.diagnostics,
      ...anchor.diagnostics,
      ...flatten.diagnostics,
    ];
    if (alignment == null) {
      diagnostics.add(wireDiagnostic("Unknown hierarchy cross axis alignment"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            HierarchySequenceLayout(
              unaryConnector: unary.valueOrNull!,
              trunkConnector: trunk.valueOrNull!,
              branchConnector: branch.valueOrNull!,
              itemSpacing: itemSpacing.valueOrNull!,
              indentation: indentation.valueOrNull!,
              leadingSpacing: leadingSpacing.valueOrNull!,
              itemAnchor: anchor.valueOrNull!,
              flattenSingleItem: flatten.valueOrNull!,
              crossAxisAlignment: alignment!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<ConnectorAnchor> _connectorAnchor(wire.ConnectorAnchor value) =>
      switch (value) {
        wire.ConnectorAnchor.start => const TypeResult.success(
          ConnectorAnchor.start(),
        ),
        wire.ConnectorAnchor.center => const TypeResult.success(
          ConnectorAnchor.center(),
        ),
        wire.ConnectorAnchor_offsetWrapper(:final value) =>
          expressions.decode(value).mapValue(ConnectorAnchor.offset),
        wire.ConnectorAnchor_unknown() => invalidWire(
          "Unknown connector anchor",
        ),
      };

  TypeResult<PresentationChildrenLayout> _axisLayout(
    wire.AxisChildrenLayout value,
    PresentationChildrenLayout Function({
      double spacing,
      PresentationMainAxisAlignment mainAxisAlignment,
      PresentationCrossAxisAlignment crossAxisAlignment,
    })
    create,
  ) {
    final main = switch (value.mainAxisAlignment) {
      wire.MainAxisAlignment.start => PresentationMainAxisAlignment.start,
      wire.MainAxisAlignment.center => PresentationMainAxisAlignment.center,
      wire.MainAxisAlignment.end => PresentationMainAxisAlignment.end,
      wire.MainAxisAlignment.spaceBetween =>
        PresentationMainAxisAlignment.spaceBetween,
      wire.MainAxisAlignment.spaceAround =>
        PresentationMainAxisAlignment.spaceAround,
      wire.MainAxisAlignment.spaceEvenly =>
        PresentationMainAxisAlignment.spaceEvenly,
      _ => null,
    };
    final cross = switch (value.crossAxisAlignment) {
      wire.CrossAxisAlignment.start => PresentationCrossAxisAlignment.start,
      wire.CrossAxisAlignment.center => PresentationCrossAxisAlignment.center,
      wire.CrossAxisAlignment.end => PresentationCrossAxisAlignment.end,
      wire.CrossAxisAlignment.stretch => PresentationCrossAxisAlignment.stretch,
      _ => null,
    };
    if (main == null || cross == null || value.spacing < 0) {
      return invalidWire("Invalid layout alignment or spacing");
    }
    return TypeResult.success(
      create(
        spacing: value.spacing,
        mainAxisAlignment: main,
        crossAxisAlignment: cross,
      ),
    );
  }

  TypeResult<PresentationChildrenLayout> _wrapLayout(
    wire.WrapChildrenLayout value,
  ) {
    final axis = _axisLayout(
      wire.AxisChildrenLayout(
        spacing: value.spacing,
        mainAxisAlignment: value.mainAxisAlignment,
        crossAxisAlignment: value.crossAxisAlignment,
      ),
      PresentationWrapLayout.new,
    );
    if (value.runSpacing < 0) return invalidWire("Invalid wrap run spacing");
    return axis.mapValue(
      (layout) => PresentationWrapLayout(
        spacing: (layout as PresentationWrapLayout).spacing,
        runSpacing: value.runSpacing,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
      ),
    );
  }

  TypeResult<PresentationChildrenLayout> _gridLayout(
    wire.GridChildrenLayout value,
  ) {
    if (value.columns <= 0 ||
        value.horizontalSpacing < 0 ||
        value.verticalSpacing < 0) {
      return invalidWire("Invalid grid dimensions");
    }
    return TypeResult.success(
      PresentationGridLayout(
        columns: value.columns,
        horizontalSpacing: value.horizontalSpacing,
        verticalSpacing: value.verticalSpacing,
      ),
    );
  }

  TypeResult<PresentationElement> _section(wire.SectionLayout value) =>
      _border(value.border).mapValue(
        (border) =>
            SectionElement(child: decodeNode(value.child), border: border),
      );

  TypeResult<PresentationElement> _adaptiveLeading(
    wire.AdaptiveLeadingElement value,
  ) {
    final padding = _insets(value.padding);
    final compactPadding = _insets(value.compactPadding);
    final diagnostics = [...padding.diagnostics, ...compactPadding.diagnostics];
    if (!value.gap.isFinite ||
        value.gap < 0 ||
        !value.minimumCenterWidth.isFinite ||
        value.minimumCenterWidth < 0) {
      diagnostics.add(
        wireDiagnostic(
          "Adaptive leading dimensions must be finite and nonnegative",
        ),
      );
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(
      AdaptiveLeadingElement(
        leading: decodeNode(value.leading),
        center: value.center == null ? null : decodeNode(value.center!),
        suffix: value.suffix == null ? null : decodeNode(value.suffix!),
        padding: padding.valueOrNull!,
        compactPadding: compactPadding.valueOrNull!,
        gap: value.gap,
        minimumCenterWidth: value.minimumCenterWidth,
      ),
    );
  }

  TypeResult<PresentationElement> _padding(wire.PaddingLayout value) {
    final values = [value.top, value.start, value.end, value.bottom];
    if (values.any((value) => !value.isFinite || value < 0)) {
      return invalidWire("Invalid directional padding");
    }
    return TypeResult.success(
      PaddingElement(
        child: decodeNode(value.child),
        top: value.top,
        start: value.start,
        end: value.end,
        bottom: value.bottom,
      ),
    );
  }

  TypeResult<PresentationElement> _slot(wire.PresentationSlotElement value) =>
      value.slotId.isEmpty
      ? invalidWire("Presentation slot ID is empty")
      : TypeResult.success(PresentationSlotElement(slotId: value.slotId));

  TypeResult<PresentationBorder?> _border(wire.PresentationBorder? value) {
    if (value == null) return const TypeResult.success(null);
    return switch (value) {
      wire.PresentationBorder_allWrapper(:final value) => _borderSide(
        value,
      ).mapValue(PresentationBorder.all),
      wire.PresentationBorder_sidesWrapper(:final value) => _borderSides(
        value,
      ).mapValue((value) => value),
      wire.PresentationBorder_unknown() => invalidWire(
        "Unknown presentation border",
      ),
    };
  }

  TypeResult<PresentationBorderSide> _borderSide(
    wire.PresentationBorderSide value,
  ) {
    if (!value.width.isFinite || value.width <= 0) {
      return invalidWire("Invalid presentation border width");
    }
    return _optionalExpression(value.color).mapValue(
      (color) => PresentationBorderSide(color: color, width: value.width),
    );
  }

  TypeResult<PresentationBorder> _borderSides(
    wire.DirectionalPresentationBorder value,
  ) {
    if (value.top == null &&
        value.start == null &&
        value.end == null &&
        value.bottom == null) {
      return invalidWire("Presentation border has no sides");
    }
    final top = _optionalBorderSide(value.top);
    final start = _optionalBorderSide(value.start);
    final end = _optionalBorderSide(value.end);
    final bottom = _optionalBorderSide(value.bottom);
    final diagnostics = [
      ...top.diagnostics,
      ...start.diagnostics,
      ...end.diagnostics,
      ...bottom.diagnostics,
    ];

    return diagnostics.isEmpty
        ? TypeResult.success(
            PresentationBorder.sides(
              top: top.valueOrNull,
              start: start.valueOrNull,
              end: end.valueOrNull,
              bottom: bottom.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationBorderSide?> _optionalBorderSide(
    wire.PresentationBorderSide? value,
  ) => value == null
      ? const TypeResult.success(null)
      : _borderSide(value).mapValue((value) => value);

  TypeResult<PresentationElement> _tabs(wire.TabsLayout value) {
    if (value.tabs.isEmpty) return invalidWire("Tabs are empty");
    final tabs = <TabItem>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final tab in value.tabs) {
      final label = expressions.decode(tab.label);
      diagnostics.addAll(label.diagnostics);
      if (tab.tabId.isEmpty) diagnostics.add(wireDiagnostic("Tab id is empty"));
      if (label.valueOrNull case final decoded? when tab.tabId.isNotEmpty) {
        tabs.add(
          TabItem(id: tab.tabId, label: decoded, child: decodeNode(tab.child)),
        );
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            TabsElement(
              tabs: tabs,
              initiallySelectedTabId: value.initiallySelectedTabId,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _spacer(wire.SpacerLayout value) {
    return combineResults(
      _optionalExpression(value.width),
      _optionalExpression(value.height),
      (width, height) => SpacerElement(width: width, height: height),
    );
  }
}

extension on PresentationChildrenLayout {
  double get _axisSpacing => switch (this) {
    PresentationColumnLayout(:final spacing) ||
    PresentationRowLayout(:final spacing) => spacing,
    _ => throw StateError("Layout is not an axis layout"),
  };

  PresentationMainAxisAlignment get _axisMainAlignment => switch (this) {
    PresentationColumnLayout(:final mainAxisAlignment) ||
    PresentationRowLayout(:final mainAxisAlignment) => mainAxisAlignment,
    _ => throw StateError("Layout is not an axis layout"),
  };

  PresentationCrossAxisAlignment get _axisCrossAlignment => switch (this) {
    PresentationColumnLayout(:final crossAxisAlignment) ||
    PresentationRowLayout(:final crossAxisAlignment) => crossAxisAlignment,
    _ => throw StateError("Layout is not an axis layout"),
  };
}

extension on wire.CrossAxisAlignment {
  PresentationCrossAxisAlignment? get _decodeCrossAxisAlignment =>
      switch (this) {
        wire.CrossAxisAlignment.start => PresentationCrossAxisAlignment.start,
        wire.CrossAxisAlignment.center => PresentationCrossAxisAlignment.center,
        wire.CrossAxisAlignment.end => PresentationCrossAxisAlignment.end,
        wire.CrossAxisAlignment.stretch =>
          PresentationCrossAxisAlignment.stretch,
        _ => null,
      };
}
