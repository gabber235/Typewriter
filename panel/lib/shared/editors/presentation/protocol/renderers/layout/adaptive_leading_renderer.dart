part of "../../layout_renderer.dart";

extension AdaptiveLeadingElementRendering on AdaptiveLeadingElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
            return presentationDiagnostic(context, [
              const TypeDiagnostic(
                code: TypeDiagnosticCode.invalidPresentation,
                message:
                    "Adaptive leading requires finite maximum width and height",
              ),
            ]);
          }
          return AdaptiveLeadingLayout(
            leading: PresentationNodeRenderer(node: leading, scope: scope),
            center: center == null
                ? null
                : PresentationNodeRenderer(node: center!, scope: scope),
            suffix: suffix == null
                ? null
                : PresentationNodeRenderer(node: suffix!, scope: scope),
            padding: padding.edgeInsets,
            compactPadding: compactPadding.edgeInsets,
            gap: gap,
            minCenterWidth: minimumCenterWidth,
          );
        },
      );
}

extension on PresentationInsets {
  EdgeInsets get edgeInsets => switch (this) {
    PresentationInsetsAll(:final value) => EdgeInsets.all(value),
    PresentationInsetsSymmetric(:final horizontal, :final vertical) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
    PresentationInsetsOnly(
      :final top,
      :final left,
      :final right,
      :final bottom,
    ) =>
      EdgeInsets.fromLTRB(left, top, right, bottom),
  };
}
