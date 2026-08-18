part of "../../content_renderer.dart";

extension ImageElementRendering on ImageElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final resolvedSource = scope.expressionText(source);
    final uri = Uri.tryParse(resolvedSource);
    if (uri == null || uri.scheme != "https") {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Image source must use HTTPS",
        ),
      ]);
    }
    final label = semanticLabel == null
        ? null
        : scope.expressionText(semanticLabel!);
    return ClipRRect(
      borderRadius: context.shapes.mediumBorderRadius,
      child: Image.network(
        resolvedSource,
        semanticLabel: label,
        frameBuilder: (_, child, frame, _) {
          if (frame != null) return child;

          return ShimmerBox.rectangle(
            borderRadius: context.shapes.mediumBorderRadius,
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            presentationDiagnostic(context, [
              const TypeDiagnostic(
                code: TypeDiagnosticCode.invalidValue,
                message: "Image could not be loaded",
              ),
            ]),
      ),
    );
  }
}
