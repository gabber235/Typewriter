part of "../../simple_input_renderer.dart";

extension EnumInputElementRendering on EnumInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) => binding.type is EnumType
          ? null
          : "Enum control requires an enum binding",
      builder: (context, field) {
        final values = (field.binding.type as EnumType).values;
        return Dropdown<DataValue>(
          selected: values.contains(field.binding.value)
              ? field.binding.value
              : null,
          dropdownMenuEntries: [
            for (final option in values)
              DropdownMenuEntry(
                value: option,
                label: option.expressionDisplayText,
              ),
          ],
          enabled: field.editable,
          onSelected: (next) {
            if (next != null) field.update(next);
          },
        );
      },
    );
  }
}
