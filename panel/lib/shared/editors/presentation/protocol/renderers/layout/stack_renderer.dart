part of "../../layout_renderer.dart";

extension StackElementRendering on StackElement {
  Widget render(PresentationRenderScope scope) =>
      Stack(children: children.renderChildren(scope));
}
