part of "../../simple_input_renderer.dart";

extension NamedInputElementRendering on NamedInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      _renderNamedInput(control: control, context: context, scope: scope);
}
