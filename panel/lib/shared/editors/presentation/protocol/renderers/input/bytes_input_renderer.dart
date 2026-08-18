part of "../../simple_input_renderer.dart";

extension BytesInputElementRendering on BytesInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) => binding.value is BytesValue
          ? null
          : "Bytes control requires base64 content",
      builder: (context, field) => _renderParsedTextValue(
        field: field,
        text: base64Encode((field.binding.value as BytesValue).value),
        parse: (text) {
          try {
            return BytesValue(Uint8List.fromList(base64Decode(text)));
          } on FormatException {
            return null;
          }
        },
      ),
    );
  }
}
