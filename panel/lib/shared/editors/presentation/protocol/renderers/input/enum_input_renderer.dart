part of "../../simple_input_renderer.dart";

extension EnumInputElementRendering on EnumInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    if (binding.type case EnumType(:final values)) {
      final child = Dropdown<DataValue>(
        selected: values.contains(binding.value) ? binding.value : null,
        dropdownMenuEntries: [
          for (final option in values)
            DropdownMenuEntry(
              value: option,
              label: option.expressionDisplayText,
            ),
        ],
        enabled: !_bindingLocked(binding, scope),
        onSelected: (next) {
          if (next != null) scope.update(binding.reference, next);
        },
      );
      return LabeledControl(control: control, scope: scope, child: child);
    }
    return _inputDiagnostic("Enum control requires an enum binding");
  }
}
