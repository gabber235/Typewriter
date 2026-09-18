part of "../../simple_input_renderer.dart";

/// Renders a boolean control only for mixed bindings, where the ordinary
/// labeled control is supplied by the surrounding presentation path.
///
/// A checked value replaces the mixed state through the field owner. A
/// uniform value needs no local widget because its header or parent chrome
/// already represents that state.
extension ToggleInputElementRendering on ToggleInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      labeled: false,
      shapeMismatch: (binding) =>
          binding.type is BooleanType &&
              (binding.value is MixedEditorValue ||
                  binding.value is MissingEditorValue ||
                  binding.value.valueOrNull is BooleanValue)
          ? null
          : "Toggle control requires a boolean binding",
      builder: (context, field) {
        if (!field.mixed && !field.missing) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              value: null,
              tristate: true,
              contentPadding: EdgeInsets.zero,
              title: control.label == null
                  ? null
                  : Text(scope.expressionText(control.label!)),
              subtitle: control.description == null
                  ? null
                  : Text(scope.expressionText(control.description!)),
              onChanged: field.editable
                  ? (next) {
                      if (next != null) field.update(BooleanValue(next));
                    }
                  : null,
            ),
            if (field.mixed) const MixedValueMessage(),
          ],
        );
      },
    );
  }
}
