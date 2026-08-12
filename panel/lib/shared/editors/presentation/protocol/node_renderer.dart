import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class PresentationNodeRenderer extends StatelessWidget {
  const PresentationNodeRenderer({
    required this.node,
    required this.scope,
    super.key,
  });

  final PresentationNode node;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    if (node.element case DiagnosticElement(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final enabled = _condition(node.properties.enabledIf, true);
    if (enabled case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final nodeEnabled = scope.enabled && (enabled.valueOrNull ?? true);
    final childScope = scope.copyWith(
      enabled: nodeEnabled,
      readOnly: scope.readOnly || node.properties.readOnly,
    );
    final chain = node.resolveHeaderChain(childScope);
    final headerBinding = chain.header?.binding == null
        ? null
        : childScope.canonical(chain.header!.binding!);
    final headerKey = (node.id, headerBinding);
    final header = childScope.suppressedHeaders.contains(headerKey)
        ? null
        : chain.header;
    final renderScope = childScope.copyWith(
      suppressedHeaders: {...childScope.suppressedHeaders, ...chain.suppressed},
    );
    final child = node.element._render(context, renderScope);
    final surface = header == null
        ? child
        : PresentationHeaderChrome(
            nodeId: node.id,
            header: header,
            scope: renderScope,
            child: child,
          );
    return Semantics(
      container: true,
      enabled: nodeEnabled,
      child: IgnorePointer(
        ignoring: !nodeEnabled,
        child: AnimatedOpacity(
          opacity: nodeEnabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 120),
          child: KeyedSubtree(key: ValueKey(node.id), child: surface),
        ),
      ),
    );
  }

  TypeResult<bool> _condition(TypedExpression? expression, bool fallback) {
    if (expression == null) return TypeResult.success(fallback);
    final result = scope.evaluate(expression);
    if (result case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final value = result.valueOrNull;
    if (value is BooleanValue) return TypeResult.success(value.value);
    return TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Presentation condition must evaluate to boolean",
      ),
    ]);
  }
}

extension on PresentationElement {
  Widget _render(
    BuildContext context,
    PresentationRenderScope scope,
  ) => switch (this) {
    ChildrenLayoutElement() ||
    GridElement() ||
    SingleChildLayoutElement() ||
    CollapsibleElement() ||
    TabsElement() ||
    DividerElement() ||
    SpacerElement() => LayoutElementRendering(this).render(context, scope),
    TextualContentElement() ||
    IconElement() ||
    ImageElement() ||
    BadgeElement() ||
    ProgressElement() => ContentElementRendering(this).render(context, scope),
    TypedFieldElement() ||
    ConditionalElement() ||
    RepeatedElement() ||
    ScopedBindingElement() => DataElementRendering(this).render(context, scope),
    TextInputElement() ||
    NumericInputElement() ||
    ToggleInputElement() ||
    SelectInputElement() ||
    SliderInputElement() ||
    SimpleInputElement() ||
    ListInputElement() ||
    MapInputElement() ||
    RecordInputElement() ||
    PolymorphicInputElement() => InputElementRendering(
      this,
    ).render(context, scope),
    ButtonElement() ||
    IconButtonElement() ||
    MenuElement() ||
    TooltipElement() => InteractionElementRendering(
      this,
    ).render(context, scope),
    DiagnosticElement(:final diagnostics) => presentationDiagnostic(
      context,
      diagnostics,
    ),
    DefaultPresentationElement() => (this as DefaultPresentationElement).render(
      context,
      scope,
    ),
  };
}
