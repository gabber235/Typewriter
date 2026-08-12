part of "../../content_renderer.dart";

extension TextElementRendering on TextElement {
  Widget render(PresentationRenderScope scope) =>
      SelectableText(scope.expressionText(value));
}
