part of "../../scalar_input_renderer.dart";

extension TextInputElementRendering on TextInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      _TextInputRenderer(element: this, scope: scope);
}

class _TextInputRenderer extends HookWidget {
  const _TextInputRenderer({required this.element, required this.scope});

  final TextInputElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final resolved = scope.resolve(element.control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    final interaction = useEditorFieldInteraction(scope, binding.reference);
    final text = switch (binding.value) {
      StringValue(:final value) => value,
      _ => null,
    };
    if (text == null || binding.type is! StringType) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Text control requires a string binding",
        ),
      ]);
    }
    final prefix = renderControlPrefix(context, element.control, scope);
    return LabeledControl(
      control: element.control,
      scope: scope,
      child: FormattedTextField(
        key: ValueKey(binding.reference),
        focusNode: focusNode,
        text: text,
        prefix: prefix ?? const Icones(HeroiconsSolid.pencil),
        hintText: element.placeholder == null
            ? "Enter text"
            : scope.expressionText(element.placeholder!),
        singleLine: !element.multiline,
        minLines: 1,
        maxLines: element.multiline ? 8 : 1,
        readOnly: !scope.enabled || scope.readOnly || !binding.writable,
        onInputFocus: interaction.begin,
        onDone: (_) => interaction.commit(),
        onCancel: interaction.cancel,
        onChanged: (next) {
          final value = StringValue(next);
          if (value.validateAgainst(binding.type).isEmpty) {
            scope.update(element.control.binding, value);
          }
        },
      ),
    );
  }
}
