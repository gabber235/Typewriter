import "package:typewriter_panel/typewriter_panel.dart";

/// Replaces an invalid presentation subtree with a diagnostic element.
///
/// Renderers call this at the point where a nested node is about to be shown.
/// A node with validation failures becomes one visible diagnostic boundary;
/// otherwise localization recurses through renderable child nodes and preserves
/// the original immutable tree and all valid siblings.
extension PresentationNodeFailureLocalization on PresentationNode {
  PresentationNode localizeFailures(
    ExpressionContext context, {
    required TypeRegistry? registry,
    ExpressionBudget budget = const ExpressionBudget(),
  }) {
    final diagnostics = validatePresentation(
      context,
      registry: registry,
      budget: budget,
    );
    if (diagnostics.isNotEmpty) {
      return PresentationNode(
        id: id,
        properties: properties,
        header: header,
        element: DiagnosticElement(diagnostics),
      );
    }
    return PresentationNode(
      id: id,
      properties: properties,
      header: header?._localizeFailures(context, budget, registry),
      element: element._localizeFailures(context, budget, registry),
    );
  }
}

extension on PresentationHeader {
  PresentationHeader _localizeFailures(
    ExpressionContext context,
    ExpressionBudget budget,
    TypeRegistry? registry,
  ) => PresentationHeader(
    binding: binding,
    title: switch (title) {
      PresentationHeaderNodeTitle(:final node) =>
        PresentationHeaderTitle.presentation(
          node.localizeFailures(context, registry: registry, budget: budget),
        ),
      final value => value,
    },
    description: description,
    initiallyExpanded: initiallyExpanded,
    items: items,
    headerPadding: headerPadding,
    contentPadding: contentPadding,
  );
}

extension on PresentationElement {
  PresentationElement _localizeFailures(
    ExpressionContext context,
    ExpressionBudget budget,
    TypeRegistry? registry,
  ) {
    final element = this;
    return switch (element) {
      ColumnElement() => ColumnElement(
        children: element.children._localizeFailures(context, budget, registry),
        spacing: element.spacing,
        mainAxisAlignment: element.mainAxisAlignment,
        crossAxisAlignment: element.crossAxisAlignment,
      ),
      RowElement() => RowElement(
        children: element.children._localizeFailures(context, budget, registry),
        spacing: element.spacing,
        mainAxisAlignment: element.mainAxisAlignment,
        crossAxisAlignment: element.crossAxisAlignment,
      ),
      WrapElement() => WrapElement(
        children: element.children._localizeFailures(context, budget, registry),
        spacing: element.spacing,
        runSpacing: element.runSpacing,
        mainAxisAlignment: element.mainAxisAlignment,
        crossAxisAlignment: element.crossAxisAlignment,
      ),
      StackElement() => StackElement(
        children: element.children._localizeFailures(context, budget, registry),
      ),
      GridElement() => GridElement(
        children: element.children._localizeFailures(context, budget, registry),
        columns: element.columns,
        horizontalSpacing: element.horizontalSpacing,
        verticalSpacing: element.verticalSpacing,
      ),
      SectionElement(:final child, :final border) => SectionElement(
        border: border,
        child: child.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
      ),
      PaddingElement() => PaddingElement(
        child: element.child.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
        top: element.top,
        start: element.start,
        end: element.end,
        bottom: element.bottom,
      ),
      ContainerElement() => element.copyWith(
        child: element.child.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
      ),
      PresentationAnchorElement() => element.copyWith(
        child: element.child.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
      ),
      ConnectionLayerElement() => element.copyWith(
        child: element.child.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
      ),
      CommitControlsElement() => element,
      PresentationSlotElement() => element,
      TabsElement() => TabsElement(
        tabs: [
          for (final tab in element.tabs)
            TabItem(
              id: tab.id,
              label: tab.label,
              child: tab.child.localizeFailures(
                context,
                registry: registry,
                budget: budget,
              ),
            ),
        ],
        initiallySelectedTabId: element.initiallySelectedTabId,
      ),
      AdaptiveLeadingElement() => AdaptiveLeadingElement(
        leading: element.leading.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
        center: element.center?.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
        suffix: element.suffix?.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
        padding: element.padding,
        compactPadding: element.compactPadding,
        gap: element.gap,
        minimumCenterWidth: element.minimumCenterWidth,
      ),
      TypedFieldElement() => TypedFieldElement(
        binding: element.binding,
        expectedType: element.expectedType,
        presentation: element.presentation == null
            ? null
            : (element.presentation!).localizeFailures(
                context,
                registry: registry,
                budget: budget,
              ),
      ),
      ConditionalElement() => ConditionalElement(
        condition: element.condition,
        whenTrue: element.whenTrue.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
        whenFalse: element.whenFalse == null
            ? null
            : (element.whenFalse!).localizeFailures(
                context,
                registry: registry,
                budget: budget,
              ),
      ),
      RepeatedElement() ||
      ScopedBindingElement() ||
      CollectionLookupElement() ||
      CollectionGraphElement() ||
      ListInputElement() ||
      MapInputElement() ||
      RecordInputElement() ||
      PolymorphicInputElement() ||
      PolymorphicMatchElement() => element,
      TooltipElement() => TooltipElement(
        message: element.message,
        child: element.child.localizeFailures(
          context,
          registry: registry,
          budget: budget,
        ),
      ),
      _ => element,
    };
  }
}

extension on List<PresentationNode> {
  List<PresentationNode> _localizeFailures(
    ExpressionContext context,
    ExpressionBudget budget,
    TypeRegistry? registry,
  ) => [
    for (final child in this)
      child.localizeFailures(context, registry: registry, budget: budget),
  ];
}

extension on List<PresentationAxisChild> {
  List<PresentationAxisChild> _localizeFailures(
    ExpressionContext context,
    ExpressionBudget budget,
    TypeRegistry? registry,
  ) => [
    for (final value in this)
      switch (value) {
        FixedPresentationAxisChild(:final child) => PresentationAxisChild.fixed(
          child.localizeFailures(context, registry: registry, budget: budget),
        ),
        FlexiblePresentationAxisChild(:final child, :final flex, :final fit) =>
          PresentationAxisChild.flexible(
            child: child.localizeFailures(
              context,
              registry: registry,
              budget: budget,
            ),
            flex: flex,
            fit: fit,
          ),
      },
  ];
}
