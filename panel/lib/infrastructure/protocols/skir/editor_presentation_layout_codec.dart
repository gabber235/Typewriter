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

  TypeResult<PresentationElement> _section(wire.SectionLayout value) {
    final title = expressions.decode(value.title);
    final description = _optionalExpression(value.description);
    return combineResults(title, description, (title, description) {
      return SectionElement(
        title: title,
        description: description,
        child: decodeNode(value.child),
        initiallyExpanded: value.initiallyExpanded,
      );
    });
  }

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

  TypeResult<PresentationElement> _collapsible(wire.CollapsibleLayout value) =>
      expressions
          .decode(value.title)
          .mapValue(
            (title) => CollapsibleElement(
              title: title,
              child: decodeNode(value.child),
              initiallyExpanded: value.initiallyExpanded,
            ),
          );
}
