part of "../../simple_input_renderer.dart";

/// Renders a timestamp with the date and time portions selected by the
/// presentation. A mixed binding remains a mixed picker until the user makes
/// one replacement value, while malformed configuration is shown as a
/// presentation diagnostic.
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
          binding.type is TimestampType &&
              (binding.value is MixedEditorValue ||
                  binding.value is MissingEditorValue ||
                  binding.value.valueOrNull is TimestampValue)
          ? null
          : "Date and time control requires a timestamp",
      builder: (context, field) {
        if (field.mixed) {
          return DateTimePickerField.mixed(
            includeDate: includeDate,
            includeTime: includeTime,
            enabled: field.enabled,
            readOnly: field.readOnly,
            onInteractionStart: field.interaction.begin,
            onInteractionCommit: field.interaction.commit,
            onInteractionCancel: field.interaction.cancel,
            onChanged: (next) => field.update(TimestampValue(next)),
          );
        }
        final value = field.value;
        if (value is! TimestampValue) {
          return _inputDiagnostic("Date and time control requires a timestamp");
        }
        return DateTimePickerField(
          value: value.value,
          includeDate: includeDate,
          includeTime: includeTime,
          enabled: field.enabled,
          readOnly: field.readOnly,
          onInteractionStart: field.interaction.begin,
          onInteractionCommit: field.interaction.commit,
          onInteractionCancel: field.interaction.cancel,
          onChanged: (next) => field.update(TimestampValue(next)),
        );
      },
    );
  }
}
