part of "../../content_renderer.dart";

extension IconElementRendering on IconElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.evaluate(name);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final value = result.valueOrNull;
    final icon =
        value?.iconValueOrNull ??
        switch ((name.resultType, value)) {
          (NamedType(reference: final type), StringValue(value: final source))
              when type == standardTypeRefs.iconifyIcon =>
            IconValue.iconify(source),
          (NamedType(reference: final type), StringValue(value: final source))
              when type == standardTypeRefs.svgIcon =>
            IconValue.svg(source),
          _ => null,
        };
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
