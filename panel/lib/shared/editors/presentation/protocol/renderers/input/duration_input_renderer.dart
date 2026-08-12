part of "../../simple_input_renderer.dart";

extension DurationInputElementRendering on DurationInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    if (binding.value is! DurationValue || binding.type is! DurationType) {
      return _inputDiagnostic("Duration control requires a duration binding");
    }
    final duration = (binding.value as DurationValue).value;
    final child = ValidatedTextField<Duration>(
      value: duration,
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
        final diagnostics = DurationValue(value).validateAgainst(binding.type);
        return diagnostics.isEmpty ? null : diagnostics.first.message;
      },
      readOnly: _bindingLocked(binding, scope),
      onChanged: (value) =>
          scope.update(binding.reference, DurationValue(value)),
    );
    return LabeledControl(control: control, scope: scope, child: child);
  }
}
