import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Millisecond counts accepted by every shared duration consumer without saturation.
extension PortableDurationMilliseconds on int {
  static const maximum = 9007199254740991;
  bool get isPortableDurationMilliseconds =>
      this >= -maximum && this <= maximum;
}

extension PortableDurationValue on skir.Duration {
  bool get isPortable => milliseconds.isPortableDurationMilliseconds;
}
