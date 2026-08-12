part of "editor_presentation_encoder.dart";

extension SkirPresentationLayoutEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _children(
    ChildrenLayoutElement value,
    wire.PresentationElement Function(wire.ChildrenLayout) wrap,
  ) {
    final children = _nodes(value.children);
    return children.mapValue(
      (children) => wrap(
        wire.ChildrenLayout(
          children: children,
          spacing: value.spacing,
          mainAxisAlignment: value.mainAxisAlignment._encodeWire,
          crossAxisAlignment: value.crossAxisAlignment._encodeWire,
        ),
      ),
    );
  }

  TypeResult<wire.PresentationElement> _grid(GridElement value) =>
      _nodes(value.children).mapValue(
        (children) => wire.PresentationElement.createGrid(
          children: children,
          columns: value.columns,
          horizontalSpacing: value.horizontalSpacing,
          verticalSpacing: value.verticalSpacing,
        ),
      );

  TypeResult<wire.PresentationElement> _single(
    PresentationNode value,
    wire.PresentationElement Function(wire.SingleChildLayout) wrap,
  ) => encodeNode(
    value,
  ).mapValue((child) => wrap(wire.SingleChildLayout(child: child)));

  TypeResult<wire.PresentationElement> _section(SectionElement value) {
    final title = expressions.encode(value.title);
    final description = _optional(value.description);
    final child = encodeNode(value.child);
    final diagnostics = [
      ...title.diagnostics,
      ...description.diagnostics,
      ...child.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createSection(
              title: title.valueOrNull!,
              description: description.valueOrNull,
              child: child.valueOrNull!,
              initiallyExpanded: value.initiallyExpanded,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _tabs(TabsElement value) {
    final tabs = <wire.TabItem>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final item in value.tabs) {
      final label = expressions.encode(item.label);
      final child = encodeNode(item.child);
      diagnostics
        ..addAll(label.diagnostics)
        ..addAll(child.diagnostics);
      if (label.valueOrNull case final encodedLabel?) {
        if (child.valueOrNull case final encodedChild?) {
          tabs.add(
            wire.TabItem(
              tabId: item.id,
              label: encodedLabel,
              child: encodedChild,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createTabs(
              tabs: tabs,
              initiallySelectedTabId: value.initiallySelectedTabId,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _spacer(SpacerElement value) =>
      combineResults(
        _optional(value.width),
        _optional(value.height),
        (width, height) =>
            wire.PresentationElement.createSpacer(width: width, height: height),
      );

  TypeResult<wire.PresentationElement> _collapsible(CollapsibleElement value) =>
      combineResults(
        expressions.encode(value.title),
        encodeNode(value.child),
        (title, child) => wire.PresentationElement.createCollapsible(
          title: title,
          child: child,
          initiallyExpanded: value.initiallyExpanded,
        ),
      );

  TypeResult<List<wire.PresentationNode>> _nodes(
    Iterable<PresentationNode> values,
  ) {
    final nodes = <wire.PresentationNode>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final encoded = encodeNode(value);
      diagnostics.addAll(encoded.diagnostics);
      if (encoded.valueOrNull case final node?) nodes.add(node);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(nodes)
        : TypeResult.failure(diagnostics);
  }
}

extension on PresentationMainAxisAlignment {
  wire.MainAxisAlignment get _encodeWire => switch (this) {
    PresentationMainAxisAlignment.start => wire.MainAxisAlignment.start,
    PresentationMainAxisAlignment.center => wire.MainAxisAlignment.center,
    PresentationMainAxisAlignment.end => wire.MainAxisAlignment.end,
    PresentationMainAxisAlignment.spaceBetween =>
      wire.MainAxisAlignment.spaceBetween,
    PresentationMainAxisAlignment.spaceAround =>
      wire.MainAxisAlignment.spaceAround,
    PresentationMainAxisAlignment.spaceEvenly =>
      wire.MainAxisAlignment.spaceEvenly,
  };
}

extension on PresentationCrossAxisAlignment {
  wire.CrossAxisAlignment get _encodeWire => switch (this) {
    PresentationCrossAxisAlignment.start => wire.CrossAxisAlignment.start,
    PresentationCrossAxisAlignment.center => wire.CrossAxisAlignment.center,
    PresentationCrossAxisAlignment.end => wire.CrossAxisAlignment.end,
    PresentationCrossAxisAlignment.stretch => wire.CrossAxisAlignment.stretch,
  };
}
