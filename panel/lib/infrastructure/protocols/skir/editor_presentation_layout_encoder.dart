part of "editor_presentation_encoder.dart";

extension SkirPresentationLayoutEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _children(PresentationElement value) {
    final children = switch (value) {
      ChildrenLayoutElement(:final children) ||
      GridElement(:final children) ||
      StackElement(:final children) => children,
      _ => throw StateError("Element does not contain children"),
    };
    return _nodes(children).mapValue(
      (children) => wire.PresentationElement.createChildren(
        children: children,
        layout: value._childrenLayout._encodeWire,
      ),
    );
  }

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

extension on PresentationElement {
  PresentationChildrenLayout get _childrenLayout => switch (this) {
    ColumnElement(
      :final spacing,
      :final mainAxisAlignment,
      :final crossAxisAlignment,
    ) =>
      PresentationChildrenLayout.column(
        spacing: spacing,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
      ),
    RowElement(
      :final spacing,
      :final mainAxisAlignment,
      :final crossAxisAlignment,
    ) =>
      PresentationChildrenLayout.row(
        spacing: spacing,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
      ),
    WrapElement(
      :final spacing,
      :final runSpacing,
      :final mainAxisAlignment,
      :final crossAxisAlignment,
    ) =>
      PresentationChildrenLayout.wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
      ),
    GridElement(
      :final columns,
      :final horizontalSpacing,
      :final verticalSpacing,
    ) =>
      PresentationChildrenLayout.grid(
        columns: columns,
        horizontalSpacing: horizontalSpacing,
        verticalSpacing: verticalSpacing,
      ),
    StackElement() => const PresentationChildrenLayout.stack(),
    _ => throw StateError("Element does not contain children"),
  };
}

extension on PresentationChildrenLayout {
  wire.ChildrenLayout get _encodeWire => switch (this) {
    PresentationColumnLayout(
      :final spacing,
      :final mainAxisAlignment,
      :final crossAxisAlignment,
    ) =>
      wire.ChildrenLayout.createColumn(
        spacing: spacing,
        mainAxisAlignment: mainAxisAlignment._encodeWire,
        crossAxisAlignment: crossAxisAlignment._encodeWire,
      ),
    PresentationRowLayout(
      :final spacing,
      :final mainAxisAlignment,
      :final crossAxisAlignment,
    ) =>
      wire.ChildrenLayout.createRow(
        spacing: spacing,
        mainAxisAlignment: mainAxisAlignment._encodeWire,
        crossAxisAlignment: crossAxisAlignment._encodeWire,
      ),
    PresentationWrapLayout(
      :final spacing,
      :final runSpacing,
      :final mainAxisAlignment,
      :final crossAxisAlignment,
    ) =>
      wire.ChildrenLayout.createWrap(
        spacing: spacing,
        runSpacing: runSpacing,
        mainAxisAlignment: mainAxisAlignment._encodeWire,
        crossAxisAlignment: crossAxisAlignment._encodeWire,
      ),
    PresentationGridLayout(
      :final columns,
      :final horizontalSpacing,
      :final verticalSpacing,
    ) =>
      wire.ChildrenLayout.createGrid(
        columns: columns,
        horizontalSpacing: horizontalSpacing,
        verticalSpacing: verticalSpacing,
      ),
    PresentationStackLayout() => wire.ChildrenLayout.stack,
  };
}
