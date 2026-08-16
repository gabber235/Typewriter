part of "../../simple_input_renderer.dart";

extension DateTimeInputElementRendering on DateTimeInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    if (!includeDate && !includeTime) {
      return _inputDiagnostic(
        "Date and time control must enable at least one part",
      );
    }
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) =>
          binding.type is TimestampType && binding.value is TimestampValue
          ? null
          : "Date and time control requires a timestamp",
      builder: (context, field) {
        return DateTimePickerField(
          value: (field.binding.value as TimestampValue).value,
          includeDate: includeDate,
          includeTime: includeTime,
          enabled: field.enabled,
          readOnly: field.readOnly,
          onChanged: (next) => field.update(TimestampValue(next)),
        );
      },
    );
  }
}
