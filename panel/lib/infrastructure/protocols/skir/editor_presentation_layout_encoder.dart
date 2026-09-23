part of "editor_presentation_encoder.dart";

/// Encodes layout structure while preserving the catalog's node identity model.
///
/// This boundary translates domain layout choices to wire variants. It does not
/// resolve layout or mutate the child presentation tree.
extension SkirPresentationLayoutEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _children(PresentationElement value) {
    final children = switch (value) {
      WrapElement(:final children) ||
      GridElement(:final children) ||
      StackElement(:final children) => children,
      _ => throw StateError("Element does not contain children"),
    };
    return _nodes(children).mapValue((children) {
      final encoded = switch (value) {
        WrapElement(
          :final spacing,
          :final runSpacing,
          :final mainAxisAlignment,
          :final crossAxisAlignment,
        ) =>
          wire.ChildrenElement.createWrap(
            children: children,
            layout: wire.WrapChildrenLayout(
              spacing: spacing,
              runSpacing: runSpacing,
              mainAxisAlignment: mainAxisAlignment._encodeWire,
              crossAxisAlignment: crossAxisAlignment._encodeWire,
            ),
          ),
        GridElement(
          :final columns,
          :final horizontalSpacing,
          :final verticalSpacing,
        ) =>
          wire.ChildrenElement.createGrid(
            children: children,
            layout: wire.GridChildrenLayout(
              columns: columns,
              horizontalSpacing: horizontalSpacing,
              verticalSpacing: verticalSpacing,
            ),
          ),
        StackElement() => wire.ChildrenElement.createStack(children: children),
        _ => throw StateError("Element does not contain ordinary children"),
      };
      return wire.PresentationElement.wrapChildren(encoded);
    });
  }

  TypeResult<wire.PresentationElement> _axisChildren(
    ChildrenLayoutElement value,
  ) {
    final encoded = <wire.AxisChild>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final child in switch (value) {
      ColumnElement(:final children) || RowElement(:final children) => children,
      _ => throw StateError("Element does not contain axis children"),
    }) {
      final node = encodeNode(child.child);
      diagnostics.addAll(node.diagnostics);
      if (node.valueOrNull case final value?) {
        encoded.add(switch (child) {
          FixedPresentationAxisChild() => wire.AxisChild.wrapFixed(value),
          FlexiblePresentationAxisChild(:final flex, :final fit) =>
            wire.AxisChild.createFlexible(
              child: value,
              flex: flex,
              fit: switch (fit) {
                PresentationFlexFit.tight => wire.FlexFit.tight,
                PresentationFlexFit.loose => wire.FlexFit.loose,
              },
            ),
        });
      }
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    final layout = wire.AxisChildrenLayout(
      spacing: value.spacing,
      mainAxisAlignment: value.mainAxisAlignment._encodeWire,
      crossAxisAlignment: value.crossAxisAlignment._encodeWire,
    );
    final children = switch (value) {
      ColumnElement() => wire.ChildrenElement.createColumn(
        children: encoded,
        layout: layout,
      ),
      RowElement() => wire.ChildrenElement.createRow(
        children: encoded,
        layout: layout,
      ),
      _ => throw StateError("Element does not contain axis children"),
    };
    return TypeResult.success(wire.PresentationElement.wrapChildren(children));
  }

  TypeResult<wire.PresentationElement> _adaptiveLeading(
    AdaptiveLeadingElement value,
  ) {
    final leading = encodeNode(value.leading);
    final center = value.center == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.center!).mapValue((value) => value);
    final suffix = value.suffix == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.suffix!).mapValue((value) => value);
    final diagnostics = [
      ...leading.diagnostics,
      ...center.diagnostics,
      ...suffix.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createAdaptiveLeading(
              leading: leading.valueOrNull!,
              center: center.valueOrNull,
              suffix: suffix.valueOrNull,
              padding: value.padding._encode,
              compactPadding: value.compactPadding._encode,
              gap: value.gap,
              minimumCenterWidth: value.minimumCenterWidth,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _section(SectionElement value) {
    final child = encodeNode(value.child);
    final border = _border(value.border);
    final diagnostics = [...child.diagnostics, ...border.diagnostics];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createSection(
              child: child.valueOrNull!,
              border: border.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _padding(PaddingElement value) =>
      encodeNode(value.child).mapValue(
        (child) => wire.PresentationElement.createPadding(
          child: child,
          top: value.top,
          start: value.start,
          end: value.end,
          bottom: value.bottom,
        ),
      );

  TypeResult<wire.PresentationElement> _slot(PresentationSlotElement value) =>
      TypeResult.success(
        wire.PresentationElement.createSlot(slotId: value.slotId),
      );

  TypeResult<wire.PresentationBorder?> _border(PresentationBorder? value) {
    if (value == null) return const TypeResult.success(null);
    return switch (value) {
      PresentationBorderAll(:final side) => _borderSide(
        side,
      ).mapValue(wire.PresentationBorder.wrapAll),
      PresentationBorderSides(
        :final top,
        :final start,
        :final end,
        :final bottom,
      ) =>
        _borderSides(top: top, start: start, end: end, bottom: bottom),
    };
  }

  TypeResult<wire.PresentationBorderSide> _borderSide(
    PresentationBorderSide value,
  ) => _optional(value.color).mapValue(
    (color) => wire.PresentationBorderSide(color: color, width: value.width),
  );

  TypeResult<wire.PresentationBorder> _borderSides({
    PresentationBorderSide? top,
    PresentationBorderSide? start,
    PresentationBorderSide? end,
    PresentationBorderSide? bottom,
  }) {
    final encodedTop = _optionalBorderSide(top);
    final encodedStart = _optionalBorderSide(start);
    final encodedEnd = _optionalBorderSide(end);
    final encodedBottom = _optionalBorderSide(bottom);
    final diagnostics = [
      ...encodedTop.diagnostics,
      ...encodedStart.diagnostics,
      ...encodedEnd.diagnostics,
      ...encodedBottom.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationBorder.createSides(
              top: encodedTop.valueOrNull,
              start: encodedStart.valueOrNull,
              end: encodedEnd.valueOrNull,
              bottom: encodedBottom.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationBorderSide?> _optionalBorderSide(
    PresentationBorderSide? value,
  ) => value == null
      ? const TypeResult.success(null)
      : _borderSide(value).mapValue((value) => value);

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

  TypeResult<wire.SequenceLayout> _sequenceLayout(
    PresentationSequenceLayout value,
  ) => switch (value) {
    PresentationStandardSequenceLayout(:final layout) => TypeResult.success(
      wire.SequenceLayout.wrapChildren(layout._encodeWire),
    ),
    PresentationHierarchySequenceLayout(:final layout) =>
      _hierarchySequenceLayout(layout),
  };

  TypeResult<wire.SequenceLayout> _hierarchySequenceLayout(
    HierarchySequenceLayout value,
  ) {
    final unary = _connectorStyle(value.unaryConnector);
    final trunk = _connectorStyle(value.trunkConnector);
    final branch = _connectorStyle(value.branchConnector);
    final itemSpacing = expressions.encode(value.itemSpacing);
    final indentation = expressions.encode(value.indentation);
    final leadingSpacing = expressions.encode(value.leadingSpacing);

    final anchor = _connectorAnchor(value.itemAnchor);
    final flatten = expressions.encode(value.flattenSingleItem);
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
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.SequenceLayout.createHierarchy(
              unaryConnector: unary.valueOrNull!,
              trunkConnector: trunk.valueOrNull!,
              branchConnector: branch.valueOrNull!,
              itemSpacing: itemSpacing.valueOrNull!,
              indentation: indentation.valueOrNull!,
              leadingSpacing: leadingSpacing.valueOrNull!,
              itemAnchor: anchor.valueOrNull!,
              flattenSingleItem: flatten.valueOrNull!,
              crossAxisAlignment: value.crossAxisAlignment._encodeWire,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.ConnectorAnchor> _connectorAnchor(ConnectorAnchor value) =>
      switch (value) {
        StartConnectorAnchor() => const TypeResult.success(
          wire.ConnectorAnchor.start,
        ),
        CenterConnectorAnchor() => const TypeResult.success(
          wire.ConnectorAnchor.center,
        ),
        OffsetConnectorAnchor(:final value) =>
          expressions.encode(value).mapValue(wire.ConnectorAnchor.wrapOffset),
      };
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
