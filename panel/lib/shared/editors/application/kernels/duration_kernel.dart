import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's duration operations.
final class PanelDurationKernel implements skir.DurationKernel {
  const PanelDurationKernel();

  @override
  Duration fromMilliseconds(BigInt milliseconds) =>
      portableDuration(milliseconds);

  @override
  BigInt toMilliseconds(Duration value) => BigInt.from(value.inMilliseconds);
}
