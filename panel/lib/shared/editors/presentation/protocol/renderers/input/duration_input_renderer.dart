part of "../../simple_input_renderer.dart";

extension DurationInputElementRendering on DurationInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) =>
          binding.type is DurationType && binding.value is DurationValue
          ? null
          : "Duration control requires a duration binding",
      builder: (context, field) => ValidatedTextField<Duration>(
        key: ValueKey(field.binding.reference),
        value: (field.binding.value as DurationValue).value,
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
          final diagnostics = DurationValue(
            value,
          ).validateAgainst(field.binding.type);
          return diagnostics.isEmpty ? null : diagnostics.first.message;
        },
        readOnly: field.locked,
        onInputFocus: field.interaction.begin,
        onInputBlur: field.interaction.commit,
        onCancel: field.interaction.cancel,
        onChanged: (value) => field.update(DurationValue(value)),
      ),
    );
  }
}
