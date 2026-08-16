part of "../../simple_input_renderer.dart";

Widget _inputDiagnostic(String message) {
  return Builder(
    builder: (context) => presentationDiagnostic(context, [
      TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
    ]),
  );
}

Widget _renderParsedTextValue({
  required BoundControlField field,
  required String text,
  required DataValue? Function(String) parse,
}) {
  return EditorTextField(
    key: ValueKey(field.binding.reference),
    text: text,
    enabled: field.editable,
    onInputFocus: field.interaction.begin,
    onDone: (_) => field.interaction.commit(),
    onCancel: field.interaction.cancel,
    onChanged: (next) {
      final parsed = parse(next);
      if (parsed != null &&
          parsed.validateAgainst(field.binding.type).isEmpty) {
        field.update(parsed);
      }
    },
  );
}
