part of "../../simple_input_renderer.dart";

extension ColorInputElementRendering on ColorInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      _ColorInputRenderer(element: this, scope: scope);
}

class _ColorInputRenderer extends HookWidget {
  const _ColorInputRenderer({required this.element, required this.scope});

  final ColorInputElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final result = scope.resolve(element.control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    final interaction = useEditorFieldInteraction(scope, binding.reference);
    if (binding.type is! NamedType) {
      return _inputDiagnostic("Color control requires a nominal binding");
    }
    final namedType = binding.type as NamedType;
    final resolved = scope.registry.resolve(namedType);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    const expected = IntegerType(width: IntegerWidth.unsigned32);
    if (!resolved.valueOrNull!.isConcrete ||
        resolved.valueOrNull!.representation != expected ||
        binding.value is! IntegerValue) {
      return _inputDiagnostic(
        "Color control requires a concrete unsigned 32 bit value",
      );
    }
    final value = binding.value as IntegerValue;
    final child = ColorPickerField(
      color: Color(value.value.toInt()),
      includeAlpha: element.includeAlpha,
      enabled: scope.enabled && binding.writable,
      readOnly: scope.readOnly,
      onInteractionStart: interaction.begin,
      onInteractionCommit: interaction.commit,
      onInteractionCancel: interaction.cancel,
      onChanged: (next) {
        scope.update(binding.reference, next.integerValue);
      },
    );
    return LabeledControl(control: element.control, scope: scope, child: child);
  }
}
