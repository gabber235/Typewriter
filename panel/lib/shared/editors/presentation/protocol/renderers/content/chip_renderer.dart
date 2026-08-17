part of "../../content_renderer.dart";

extension ChipElementRendering on ChipElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final resolvedLabel = scope.evaluate(label);
    if (resolvedLabel case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final labelValue = resolvedLabel.valueOrNull;
    if (labelValue is! StringValue) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Chip label must evaluate to a string",
        ),
      ]);
    }
    final resolvedColor = color == null ? null : scope.evaluate(color!);
    if (resolvedColor case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final colorValue = resolvedColor?.valueOrNull;
    if (colorValue != null && colorValue is! IntegerValue) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Chip color must evaluate to an unsigned 32 bit value",
        ),
      ]);
    }
    final entityColor = colorValue == null
        ? Theme.of(context).colorScheme.primary
        : (colorValue as IntegerValue).colorOrNull;
    if (entityColor == null) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Chip color is outside the unsigned 32 bit range",
        ),
      ]);
    }
    final foreground = entityColor._readableEntityColor(context);
    return Chip(
      label: Text(labelValue.value, style: TextStyle(color: foreground)),
      backgroundColor: entityColor.withValues(alpha: 0.18),
      side: BorderSide(color: entityColor),
    );
  }
}

extension on Color {
  Color _readableEntityColor(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return this;
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness(hsl.lightness.clamp(0.2, 0.4)).toColor();
  }
}
