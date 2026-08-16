part of "editor_presentation_codec.dart";

extension SkirPresentationLayoutDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _children(wire.ChildrenElement value) =>
      _childrenLayout(value.layout).mapValue(
        (layout) => layout.element(
          value.children.map(decodeNode).toList(growable: false),
        ),
      );

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
