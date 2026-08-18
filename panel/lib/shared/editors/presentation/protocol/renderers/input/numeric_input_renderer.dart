part of "../../simple_input_renderer.dart";

extension NumericInputElementRendering on NumericInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      builder: (context, field) {
        final prefix = renderControlPrefix(context, control, scope);
        return ValidatedTextField<DataValue>(
          key: ValueKey(field.binding.reference),
          value: field.binding.value,
          name: "number",
          icon: HeroiconsSolid.hashtag,
          decoration: prefix == null
              ? null
              : InputDecoration(prefixIcon: prefix),
          deserialize: (value) => value.expressionDisplayText,
          serialize: (text) => field.binding.type._parseNumber(text),
          validator: (value) {
            final diagnostics = value.validateAgainst(field.binding.type);
            return diagnostics.isEmpty ? null : diagnostics.first.message;
          },
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          readOnly: field.locked,
          onInputFocus: field.interaction.begin,
          onInputBlur: field.interaction.commit,
          onCancel: field.interaction.cancel,
          onChanged: field.update,
        );
      },
    );
  }
}

extension on TypeExpression {
  DataValue _parseNumber(String text) => switch (this) {
    IntegerType() => switch (BigInt.tryParse(text)) {
      final value? => IntegerValue(value),
      null => throw const FormatException("Invalid integer"),
    },
    FloatType() => switch (double.tryParse(text)) {
      final value? => FloatValue(value),
      null => throw const FormatException("Invalid number"),
    },
    DecimalType()
        when RegExp(r"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$").hasMatch(text) =>
      DecimalValue(text),
    DecimalType() => throw const FormatException("Invalid decimal"),
    _ => throw const FormatException("Input is not numeric"),
  };
}
