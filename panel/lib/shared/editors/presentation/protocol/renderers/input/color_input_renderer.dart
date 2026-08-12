part of "../../simple_input_renderer.dart";

extension ColorInputElementRendering on ColorInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      _renderNamedInput(control: control, context: context, scope: scope);
}
