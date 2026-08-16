part of "../../simple_input_renderer.dart";

extension NumericInputElementRendering on NumericInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      _NumericInputRenderer(element: this, scope: scope);
}

class _NumericInputRenderer extends HookWidget {
  const _NumericInputRenderer({required this.element, required this.scope});

  final NumericInputElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final result = scope.resolve(element.control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    final interaction = useEditorFieldInteraction(scope, binding.reference);
    final prefix = renderControlPrefix(context, element.control, scope);
    final child = ValidatedTextField<DataValue>(
      key: ValueKey(binding.reference),
      value: binding.value,
      name: "number",
      icon: HeroiconsSolid.hashtag,
      decoration: prefix == null ? null : InputDecoration(prefixIcon: prefix),
      deserialize: (value) => value.expressionDisplayText,
      serialize: (text) => binding.type._parseNumber(text),
      validator: (value) {
        final diagnostics = value.validateAgainst(binding.type);
        return diagnostics.isEmpty ? null : diagnostics.first.message;
      },
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      readOnly: _bindingLocked(binding, scope),
      onInputFocus: interaction.begin,
      onInputBlur: interaction.commit,
      onCancel: interaction.cancel,
      onChanged: (value) => scope.update(binding.reference, value),
    );
    return LabeledControl(control: element.control, scope: scope, child: child);
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
