part of "../../simple_input_renderer.dart";

extension ToggleInputElementRendering on ToggleInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      labeled: false,
      shapeMismatch: (binding) =>
          binding.type is BooleanType && binding.value is BooleanValue
          ? null
          : "Toggle control requires a boolean binding",
      builder: (context, field) => const SizedBox.shrink(),
    );
  }
}
