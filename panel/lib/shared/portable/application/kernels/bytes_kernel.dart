import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The panel's byte string operations.
final class PanelBytesKernel implements skir.BytesKernel {
  const PanelBytesKernel();

  @override
  skir.ByteString fromList(List<int> values) {
    for (final value in values) {
      if (value < 0 || value > 255) {
        throw skir.PortableOperationFailure(
          skir.PortableFailures.invalidByte,
          "The value $value is outside 0 to 255.",
        );
      }
    }
    return skir.ByteString.copy(values);
  }

  @override
  List<int> toList(skir.ByteString value) => value.asUnmodifiableList;
}
