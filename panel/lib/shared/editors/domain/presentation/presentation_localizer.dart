import "package:typewriter_panel/typewriter_panel.dart";

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
      header: header,
      element: element._localizeFailures(context, budget, registry),
    );
  }
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
      CardElement(:final child, :final initiallyExpanded) => CardElement(
        child.localizeFailures(context, registry: registry, budget: budget),
        initiallyExpanded: initiallyExpanded,
      ),
      SectionElement(
        :final title,
        :final description,
        :final child,
        :final initiallyExpanded,
      ) =>
        SectionElement(
          title: title,
          description: description,
          initiallyExpanded: initiallyExpanded,
          child: child.localizeFailures(
            context,
            registry: registry,
            budget: budget,
          ),
        ),
      CollapsibleElement(
        :final title,
        :final child,
        :final initiallyExpanded,
      ) =>
        CollapsibleElement(
          title: title,
          initiallyExpanded: initiallyExpanded,
          child: child.localizeFailures(
            context,
            registry: registry,
            budget: budget,
          ),
        ),
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
      PolymorphicInputElement() => element,
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
