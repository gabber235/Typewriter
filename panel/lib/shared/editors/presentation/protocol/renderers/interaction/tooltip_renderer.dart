part of "../../interaction_renderer.dart";

extension TooltipElementRendering on TooltipElement {
  Widget render(PresentationRenderScope scope) => Tooltip(
    message: scope.expressionText(message),
    child: PresentationNodeRenderer(node: child, scope: scope),
  );
}
