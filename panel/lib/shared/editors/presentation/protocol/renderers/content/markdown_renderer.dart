part of "../../content_renderer.dart";

extension MarkdownElementRendering on MarkdownElement {
  Widget render(PresentationRenderScope scope) =>
      MarkdownBody(data: scope.expressionText(value), selectable: true);
}
