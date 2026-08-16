part of "../../scalar_input_renderer.dart";

extension SelectInputElementRendering on SelectInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      builder: (context, field) {
        final resolvedOptions = [
          for (final option in options)
            if (scope.evaluate(option.value).valueOrNull case final value?)
              (option, value),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdaptiveChoiceControl<DataValue>(
              selected:
                  resolvedOptions.any(
                    (option) => option.$2 == field.binding.value,
                  )
                  ? field.binding.value
                  : null,
              choices: {
                for (final option in resolvedOptions)
                  option.$2: scope.expressionText(option.$1.label),
              },
              enabled: field.editable,
              onSelected: (value) {
                if (value != null) field.update(value);
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
        );
      },
    );
  }
}
