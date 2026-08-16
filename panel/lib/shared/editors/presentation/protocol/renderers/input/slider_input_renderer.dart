part of "../../scalar_input_renderer.dart";

extension SliderInputElementRendering on SliderInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      builder: (context, field) {
        final resolvedValue = field.binding.value._sliderNumber;
        final resolvedMinimum = scope
            .evaluate(minimum)
            .valueOrNull
            ._sliderNumber;
        final resolvedMaximum = scope
            .evaluate(maximum)
            .valueOrNull
            ._sliderNumber;
        final resolvedDivisions = divisions._sliderDivisions(scope);
        if (resolvedValue == null ||
            resolvedMinimum == null ||
            resolvedMaximum == null ||
            resolvedMinimum >= resolvedMaximum) {
          return presentationDiagnostic(context, [
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: "Slider values are invalid",
            ),
          ]);
        }
        return Slider(
          value: resolvedValue.clamp(resolvedMinimum, resolvedMaximum),
          min: resolvedMinimum,
          max: resolvedMaximum,
          divisions: resolvedDivisions,
          onChanged: !field.editable
              ? null
              : (next) {
                  final typed = switch (field.binding.type) {
                    IntegerType() => IntegerValue(BigInt.from(next.round())),
                    FloatType() => FloatValue(next),
                    DecimalType() => DecimalValue(next.toString()),
                    _ => null,
                  };
                  if (typed != null) field.update(typed);
                },
        );
      },
    );
  }
}

extension on TypedExpression? {
  int? _sliderDivisions(PresentationRenderScope scope) {
    if (this == null) return null;
    final value = scope.evaluate(this!).valueOrNull;
    if (value case IntegerValue(:final value)) {
      final divisions = value.toInt();
      return divisions > 0 ? divisions : null;
    }
    return null;
  }
}

extension on DataValue? {
  double? get _sliderNumber => switch (this) {
    IntegerValue(:final value) => value.toDouble(),
    FloatValue(:final value) => value,
    DecimalValue(:final value) => double.tryParse(value),
    _ => null,
  };
}
