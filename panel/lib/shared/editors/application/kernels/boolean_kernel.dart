import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The panel's boolean operations.
final class PanelBooleanKernel implements skir.BooleanKernel {
  const PanelBooleanKernel();

  @override
  bool not(bool value) => !value;
}
