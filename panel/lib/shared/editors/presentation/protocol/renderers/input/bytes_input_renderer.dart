part of "../../simple_input_renderer.dart";

extension BytesInputElementRendering on BytesInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    final child = _renderParsedTextValue(
      binding: binding,
      scope: scope,
      text: binding.value is BytesValue
          ? base64Encode((binding.value as BytesValue).value)
          : null,
      parse: (text) {
        try {
          return BytesValue(Uint8List.fromList(base64Decode(text)));
        } on FormatException {
          return null;
        }
      },
      diagnostic: "Bytes control requires base64 content",
    );
    return LabeledControl(control: control, scope: scope, child: child);
  }
}
