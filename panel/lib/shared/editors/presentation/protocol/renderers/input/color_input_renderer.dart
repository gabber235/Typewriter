part of "../../simple_input_renderer.dart";

extension ColorInputElementRendering on ColorInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) => binding.type is NamedType
          ? null
          : "Color control requires a nominal binding",
      builder: (context, field) {
        final resolved = scope.registry.resolve(
          field.binding.type as NamedType,
        );
        if (resolved case TypeFailure(:final diagnostics)) {
          return presentationDiagnostic(context, diagnostics);
        }
        const expected = IntegerType(width: IntegerWidth.unsigned32);
        if (!resolved.valueOrNull!.isConcrete ||
            resolved.valueOrNull!.representation != expected ||
            field.binding.value is! IntegerValue) {
          return _inputDiagnostic(
            "Color control requires a concrete unsigned 32 bit value",
          );
        }
        final value = field.binding.value as IntegerValue;
        return ColorPickerField(
          color: Color(value.value.toInt()),
          includeAlpha: includeAlpha,
          enabled: field.enabled,
          readOnly: field.readOnly,
          onInteractionStart: field.interaction.begin,
          onInteractionCommit: field.interaction.commit,
          onInteractionCancel: field.interaction.cancel,
          onChanged: (next) => field.update(next.integerValue),
        );
      },
    );
  }
}
