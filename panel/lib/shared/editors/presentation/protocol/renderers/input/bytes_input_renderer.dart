part of "../../simple_input_renderer.dart";

/// Renders a byte sequence as editable base64 text.
///
/// Parsing and type validation happen before the value is sent through the
/// bound control field. Invalid text therefore leaves the authoritative value
/// unchanged and lets the caller continue editing.
extension BytesInputElementRendering on BytesInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      control: control,
      scope: scope,
      shapeMismatch: (binding) =>
          binding.value is MixedEditorValue ||
              binding.value is MissingEditorValue ||
              binding.value.valueOrNull is BytesValue
          ? null
          : "Bytes control requires base64 content",
      builder: (context, field) => _renderParsedTextValue(
        field: field,
        text: switch (field.value) {
          BytesValue(:final value) => base64Encode(value),
          _ => null,
        },
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
