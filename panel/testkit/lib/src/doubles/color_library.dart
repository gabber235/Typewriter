import "package:typewriter_panel/typewriter_panel.dart";

/// Color library storage the platform refuses: every read and write throws.
final class UnavailableColorLibraryStorage implements ColorLibraryStorage {
  const UnavailableColorLibraryStorage();

  @override
  String? read() => throw StateError("Unavailable");

  @override
  void write(String value) => throw StateError("Unavailable");
}
