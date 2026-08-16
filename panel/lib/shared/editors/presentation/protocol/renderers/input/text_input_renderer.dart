part of "../../scalar_input_renderer.dart";

extension TextInputElementRendering on TextInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) =>
          binding.type is StringType && binding.value is StringValue
          ? null
          : "Text control requires a string binding",
      builder: (context, field) {
        final prefix = renderControlPrefix(context, control, scope);
        return EditorTextField(
          key: ValueKey(field.binding.reference),
          text: (field.binding.value as StringValue).value,
          prefix: prefix ?? const Icones(HeroiconsSolid.pencil),
          hintText: placeholder == null
              ? "Enter text"
              : scope.expressionText(placeholder!),
          singleLine: !multiline,
          minLines: 1,
          maxLines: multiline ? 8 : 1,
          readOnly: field.locked,
          onInputFocus: field.interaction.begin,
          onDone: (_) => field.interaction.commit(),
          onCancel: field.interaction.cancel,
          onChanged: (next) {
            final value = StringValue(next);
            if (value.validateAgainst(field.binding.type).isEmpty) {
              field.update(value);
            }
          },
        );
      },
    );
  }
}
