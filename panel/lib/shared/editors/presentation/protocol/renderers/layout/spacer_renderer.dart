part of "../../layout_renderer.dart";

extension SpacerElementRendering on SpacerElement {
  Widget render(PresentationRenderScope scope) => SizedBox(
    width: width.resolveLayoutSize(scope),
    height: height.resolveLayoutSize(scope),
  );
}
