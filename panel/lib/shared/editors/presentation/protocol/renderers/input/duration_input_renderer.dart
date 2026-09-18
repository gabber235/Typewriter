part of "../../simple_input_renderer.dart";

/// Renders a duration as human readable text while keeping the binding value
/// typed as a [DurationValue]. Serialization is only a display concern;
/// validation against the bound type decides whether an edit can be routed to
/// the scope owner.
extension DurationInputElementRendering on DurationInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) =>
          binding.type is DurationType &&
              (binding.value is MixedEditorValue ||
                  binding.value is MissingEditorValue ||
                  binding.value.valueOrNull is DurationValue)
          ? null
          : "Duration control requires a duration binding",
      builder: (context, field) => ValidatedTextField<Duration>(
        key: ValueKey(field.binding.reference),
        value: (field.value as DurationValue?)?.value,
        name: "duration",
        icon: Bi.stopwatch_fill,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[\dwdhminsu +\-]")),
        ],
        deserialize: (value) => prettyDuration(
          value,
          abbreviated: true,
          delimiter: " ",
          spacer: "",
          tersity: DurationTersity.millisecond,
        ),
        serialize: (value) => parseDuration(value, separator: " "),
        formatted: (value) {
          final formatted = prettyDuration(
            value,
            abbreviated: false,
            tersity: DurationTersity.millisecond,
          );
          return "Valid Duration: $formatted";
        },
        validator: (value) {
          final diagnostics = DurationValue(value)
              .validateAgainst(field.binding.type);
          return diagnostics.isEmpty ? null : diagnostics.first.message;
        },
        mixed: field.mixed,
        readOnly: field.locked,
        onInputFocus: field.interaction.begin,
        onInputBlur: field.interaction.commit,
        onCancel: field.interaction.cancel,
        onChanged: (value) => field.update(DurationValue(value)),
      ),
    );
  }
}
