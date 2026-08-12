part of "../../scalar_input_renderer.dart";

extension SelectInputElementRendering on SelectInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final resolved = scope.resolve(control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    final resolvedOptions = [
      for (final option in options)
        if (scope.evaluate(option.value).valueOrNull case final value?)
          (option, value),
    ];
    return LabeledControl(
      control: control,
      scope: scope,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Dropdown<DataValue>(
            selected:
                resolvedOptions.any((option) => option.$2 == binding.value)
                ? binding.value
                : null,
            dropdownMenuEntries: [
              for (final option in resolvedOptions)
                DropdownMenuEntry(
                  value: option.$2,
                  label: scope.expressionText(option.$1.label),
                ),
            ],
            enabled: !scope.readOnly && scope.enabled && binding.writable,
            onSelected: (value) {
              if (value != null) scope.update(control.binding, value);
            },
          ),
          if (allowCustomValue) ...[
            const SizedBox(height: 8),
            ProtocolBoundValueEditor(
              control: BoundControl(binding: control.binding),
              scope: scope,
            ),
          ],
        ],
      ),
    );
  }
}
