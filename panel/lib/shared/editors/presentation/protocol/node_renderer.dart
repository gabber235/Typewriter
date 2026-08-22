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
    if (node.element case final DiagnosticElement element) {
      return element.render(context);
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
            expansionKey: renderScope.expansionIdentity == null
                ? HeaderExpansionKey.node(
                    nodeId: node.id,
                    binding: headerBinding,
                  )
                : HeaderExpansionKey.instance((
                    renderScope.expansionIdentity,
                    node.id,
                    headerBinding,
                  )),
            header: header,
            scope: renderScope,
            contained: node.element is SectionElement,
            child: child,
          );
    final decoratedSurface = switch (node.element) {
      final SectionElement element => element.decorate(
        context,
        renderScope,
        surface,
      ),
      _ => surface,
    };
    return Semantics(
      container: true,
      enabled: nodeEnabled,
      child: IgnorePointer(
        ignoring: !nodeEnabled,
        child: AnimatedOpacity(
          opacity: nodeEnabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 120),
          child: KeyedSubtree(key: ValueKey(node.id), child: decoratedSurface),
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
  Widget _render(BuildContext context, PresentationRenderScope scope) {
    return switch (this) {
      final DefaultPresentationElement element => element.render(
        context,
        scope,
      ),
      final TextElement element => element.render(scope),
      final MarkdownElement element => element.render(scope),
      final IconElement element => element.render(context, scope),
      final ImageElement element => element.render(context, scope),
      final BadgeElement element => element.render(context, scope),
      final ChipElement element => element.render(context, scope),
      final ProgressElement element => element.render(context, scope),
      final StatusElement element => element.render(context, scope),
      final DateTimeElement element => element.render(context, scope),
      final RelativeTimeElement element => element.render(context, scope),
      final DiagnosticElement element => element.render(context),
      final TypedFieldElement element => element.render(scope),
      final ConditionalElement element => element.render(context, scope),
      final RepeatedElement element => element.render(context, scope),
      final ScopedBindingElement element => element.render(context, scope),
      final CollectionLookupElement element => element.render(context, scope),
      final CollectionGraphElement element => element.render(context, scope),
      final PolymorphicMatchElement element => element.render(context, scope),
      final TextInputElement element => element.render(context, scope),
      final SelectInputElement element => element.render(context, scope),
      final SliderInputElement element => element.render(context, scope),
      final NumericInputElement element => element.render(context, scope),
      final ToggleInputElement element => element.render(context, scope),
      final DateTimeInputElement element => element.render(context, scope),
      final DurationInputElement element => element.render(context, scope),
      final BytesInputElement element => element.render(context, scope),
      final EnumInputElement element => element.render(context, scope),
      final ColorInputElement element => element.render(context, scope),
      final NamedInputElement element => element.render(context, scope),
      final SearchInputElement element => element.render(context, scope),
      final PolymorphicInputElement element => element.render(context, scope),
      final ListInputElement element => element.renderInput(context, scope),
      final MapInputElement element => element.renderInput(context, scope),
      final RecordInputElement element => element.renderInput(context, scope),
      final ButtonElement element => element.render(scope),
      final IconButtonElement element => element.render(context, scope),
      final MenuElement element => element.render(scope),
      final TooltipElement element => element.render(scope),
      final ColumnElement element => element.render(scope),
      final RowElement element => element.render(scope),
      final WrapElement element => element.render(scope),
      final StackElement element => element.render(scope),
      final GridElement element => element.render(scope),
      final SectionElement element => element.render(scope),
      final ContainerElement element => element.render(context, scope),
      final PresentationAnchorElement element => element.render(context, scope),
      final ConnectionLayerElement element => element.render(context, scope),
      final PaddingElement element => element.render(scope),
      final PresentationSlotElement element => element.render(context, scope),
      final TabsElement element => element.render(scope),
      final DividerElement element => element.render(),
      final SpacerElement element => element.render(scope),
    };
  }
}
