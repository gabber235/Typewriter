part of "../../simple_input_renderer.dart";

extension IconInputElementRendering on IconInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      ScalarInputRendering(
        TextInputElement(control: control, multiline: false),
      ).render(context, scope);
}
