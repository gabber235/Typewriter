import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_header_substitution.dart";

extension PresentationNodeSubstitution on PresentationNode {
  PresentationNode substitute(Map<String, TypeExpression> substitutions) =>
      PresentationNode(
        id: id,
        properties: PresentationProperties(
          enabledIf: properties.enabledIf._substituteTypes(substitutions),
          readOnly: properties.readOnly,
        ),
        header: header?._substituteTypes(substitutions),
        element: element._substituteTypes(substitutions),
      );
}

extension on PresentationElement {
  PresentationElement _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) {
    final value = this;
    return switch (value) {
      DiagnosticElement() => DiagnosticElement(value.diagnostics),
      DefaultPresentationElement() => value,
      ColumnElement() => ColumnElement(
        children: value.children._substituteTypes(substitutions),
        spacing: value.spacing,
        mainAxisAlignment: value.mainAxisAlignment,
        crossAxisAlignment: value.crossAxisAlignment,
      ),
      RowElement() => RowElement(
        children: value.children._substituteTypes(substitutions),
        spacing: value.spacing,
        mainAxisAlignment: value.mainAxisAlignment,
        crossAxisAlignment: value.crossAxisAlignment,
      ),
      WrapElement() => WrapElement(
        children: value.children._substituteTypes(substitutions),
        spacing: value.spacing,
        mainAxisAlignment: value.mainAxisAlignment,
        crossAxisAlignment: value.crossAxisAlignment,
      ),
      StackElement() => StackElement(
        children: value.children._substituteTypes(substitutions),
        spacing: value.spacing,
        mainAxisAlignment: value.mainAxisAlignment,
        crossAxisAlignment: value.crossAxisAlignment,
      ),
      GridElement() => GridElement(
        children: value.children._substituteTypes(substitutions),
        columns: value.columns,
        horizontalSpacing: value.horizontalSpacing,
        verticalSpacing: value.verticalSpacing,
      ),
      CardElement() => CardElement(
        value.child._substituteTypes(substitutions),
        initiallyExpanded: value.initiallyExpanded,
      ),
      SectionElement() => SectionElement(
        title: value.title._substituteTypes(substitutions),
        description: value.description._substituteTypes(substitutions),
        child: value.child._substituteTypes(substitutions),
        initiallyExpanded: value.initiallyExpanded,
      ),
      CollapsibleElement() => CollapsibleElement(
        title: value.title._substituteTypes(substitutions),
        child: value.child._substituteTypes(substitutions),
        initiallyExpanded: value.initiallyExpanded,
      ),
      TabsElement() => TabsElement(
        tabs: value.tabs
            .map(
              (tab) => TabItem(
                id: tab.id,
                label: tab.label._substituteTypes(substitutions),
                child: tab.child._substituteTypes(substitutions),
              ),
            )
            .toList(),
        initiallySelectedTabId: value.initiallySelectedTabId,
      ),
      DividerElement() => value,
      SpacerElement() => SpacerElement(
        width: value.width._substituteTypes(substitutions),
        height: value.height._substituteTypes(substitutions),
      ),
      TextElement() => TextElement(value.value._substituteTypes(substitutions)),
      MarkdownElement() => MarkdownElement(
        value.value._substituteTypes(substitutions),
      ),
      IconElement() => IconElement(
        name: value.name._substituteTypes(substitutions),
        semanticLabel: value.semanticLabel._substituteTypes(substitutions),
      ),
      ImageElement() => ImageElement(
        source: value.source._substituteTypes(substitutions),
        semanticLabel: value.semanticLabel._substituteTypes(substitutions),
      ),
      BadgeElement() => BadgeElement(
        label: value.label._substituteTypes(substitutions),
        tone: value.tone,
      ),
      ProgressElement() => ProgressElement(
        value: value.value._substituteTypes(substitutions),
        maximum: value.maximum._substituteTypes(substitutions),
        label: value.label._substituteTypes(substitutions),
      ),
      TypedFieldElement() => TypedFieldElement(
        binding: value.binding,
        expectedType: value.expectedType.substitute(substitutions),
        presentation: value.presentation._substituteTypes(substitutions),
      ),
      ConditionalElement() => ConditionalElement(
        condition: value.condition._substituteTypes(substitutions),
        whenTrue: value.whenTrue._substituteTypes(substitutions),
        whenFalse: value.whenFalse._substituteTypes(substitutions),
      ),
      RepeatedElement() => RepeatedElement(
        source: value.source._substituteTypes(substitutions),
        itemBindingId: value.itemBindingId,
        template: value.template._substituteTypes(substitutions),
        empty: value.empty._substituteTypes(substitutions),
      ),
      ScopedBindingElement() => ScopedBindingElement(
        binding: value.binding,
        scopeBindingId: value.scopeBindingId,
        child: value.child._substituteTypes(substitutions),
      ),
      TextInputElement() => TextInputElement(
        control: value.control._substituteTypes(substitutions),
        multiline: value.multiline,
        placeholder: value.placeholder._substituteTypes(substitutions),
      ),
      NumericInputElement() => NumericInputElement(
        value.control._substituteTypes(substitutions),
      ),
      ToggleInputElement() => ToggleInputElement(
        value.control._substituteTypes(substitutions),
      ),
      SelectInputElement() => SelectInputElement(
        control: value.control._substituteTypes(substitutions),
        options: value.options
            .map(
              (option) => SelectOption(
                id: option.id,
                label: option.label._substituteTypes(substitutions),
                value: option.value._substituteTypes(substitutions),
              ),
            )
            .toList(),
        allowCustomValue: value.allowCustomValue,
      ),
      SliderInputElement() => SliderInputElement(
        control: value.control._substituteTypes(substitutions),
        minimum: value.minimum._substituteTypes(substitutions),
        maximum: value.maximum._substituteTypes(substitutions),
        divisions: value.divisions._substituteTypes(substitutions),
      ),
      DateTimeInputElement() => DateTimeInputElement(
        control: value.control._substituteTypes(substitutions),
        includeDate: value.includeDate,
        includeTime: value.includeTime,
      ),
      DurationInputElement() => DurationInputElement(
        value.control._substituteTypes(substitutions),
      ),
      ColorInputElement() => ColorInputElement(
        control: value.control._substituteTypes(substitutions),
        includeAlpha: value.includeAlpha,
      ),
      IconInputElement() => IconInputElement(
        value.control._substituteTypes(substitutions),
      ),
      BytesInputElement() => BytesInputElement(
        value.control._substituteTypes(substitutions),
      ),
      EnumInputElement() => EnumInputElement(
        value.control._substituteTypes(substitutions),
      ),
      NamedInputElement() => NamedInputElement(
        value.control._substituteTypes(substitutions),
      ),
      ListInputElement() => ListInputElement(
        control: value.control._substituteTypes(substitutions),
        itemPresentation: value.itemPresentation._substituteTypes(
          substitutions,
        ),
        allowAdd: value.allowAdd,
        allowRemove: value.allowRemove,
        allowReorder: value.allowReorder,
        itemBindingId: value.itemBindingId,
        indexBindingId: value.indexBindingId,
      ),
      MapInputElement() => MapInputElement(
        control: value.control._substituteTypes(substitutions),
        keyPresentation: value.keyPresentation._substituteTypes(substitutions),
        valuePresentation: value.valuePresentation._substituteTypes(
          substitutions,
        ),
        allowAdd: value.allowAdd,
        allowRemove: value.allowRemove,
        keyBindingId: value.keyBindingId,
        valueBindingId: value.valueBindingId,
      ),
      RecordInputElement() => RecordInputElement(
        control: value.control._substituteTypes(substitutions),
        fieldPresentation: value.fieldPresentation._substituteTypes(
          substitutions,
        ),
      ),
      PolymorphicInputElement() => PolymorphicInputElement(
        control: value.control._substituteTypes(substitutions),
        concreteTypes: value.concreteTypes
            .map(
              (item) => ConcreteTypePresentation(
                type: item.type.substitute(substitutions),
                label: item.label._substituteTypes(substitutions),
                presentation: item.presentation._substituteTypes(substitutions),
              ),
            )
            .toList(),
      ),
      ButtonElement() => ButtonElement(
        label: value.label._substituteTypes(substitutions),
        action: value.action.substituteTypes(substitutions),
      ),
      IconButtonElement() => IconButtonElement(
        icon: value.icon._substituteTypes(substitutions),
        semanticLabel: value.semanticLabel._substituteTypes(substitutions),
        action: value.action.substituteTypes(substitutions),
      ),
      MenuElement() => MenuElement(
        label: value.label._substituteTypes(substitutions),
        items: value.items
            .map(
              (item) => PresentationMenuItem(
                id: item.id,
                label: item.label._substituteTypes(substitutions),
                action: item.action.substituteTypes(substitutions),
              ),
            )
            .toList(),
      ),
      TooltipElement() => TooltipElement(
        message: value.message._substituteTypes(substitutions),
        child: value.child._substituteTypes(substitutions),
      ),
    };
  }
}

extension on BoundControl {
  BoundControl _substituteTypes(Map<String, TypeExpression> substitutions) =>
      BoundControl(
        binding: binding,
        label: label._substituteTypes(substitutions),
        description: description._substituteTypes(substitutions),
      );
}

extension on Iterable<PresentationNode> {
  List<PresentationNode> _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => map((value) => value._substituteTypes(substitutions)).toList();
}

extension on PresentationNode {
  PresentationNode _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => substitute(substitutions);
}

extension on PresentationNode? {
  PresentationNode? _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => this?.substitute(substitutions);
}

extension on TypedExpression {
  TypedExpression _substituteTypes(Map<String, TypeExpression> substitutions) =>
      substituteTypes(substitutions);
}

extension on TypedExpression? {
  TypedExpression? _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => this?.substituteTypes(substitutions);
}
