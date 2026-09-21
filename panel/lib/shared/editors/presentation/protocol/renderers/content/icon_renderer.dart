part of "../../content_renderer.dart";

/// Renders a protocol icon while preserving typed expression diagnostics.
///
/// The rendered icon is hidden from the semantics tree because the optional
/// semantic label is the accessible representation.
extension IconElementRendering on IconElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.evaluate(name);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final icon = result.valueOrNull?.iconValueOrNull;
    if (icon == null) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Icon content must evaluate to the nominal Icon type",
        ),
      ]);
    }
    final label = semanticLabel == null
        ? null
        : scope.expressionText(semanticLabel!);

    final resolvedColor = resolvePresentationColor(color, scope);

    final resolvedSize = resolvePresentationSize(size, scope);
    final diagnostics = [
      ...resolvedColor.diagnostics,
      ...resolvedSize.diagnostics,
    ];
    if (diagnostics.isNotEmpty) {
      return presentationDiagnostic(context, diagnostics);
    }
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: Icones.value(
          icon,
          color: resolvedColor.valueOrNull,
          size: resolvedSize.valueOrNull,
        ),
      ),
    );
  }
}
