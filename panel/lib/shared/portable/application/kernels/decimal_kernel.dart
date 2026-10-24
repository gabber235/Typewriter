import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The panel's decimal operations.
final class PanelDecimalKernel implements skir.DecimalKernel {
  const PanelDecimalKernel();

  @override
  int scale(skir.PortableDecimal value) => value.normalized().scale;
}
