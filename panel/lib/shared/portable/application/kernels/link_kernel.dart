import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The panel's link operations.
final class PanelLinkKernel implements skir.LinkKernel {
  const PanelLinkKernel();

  @override
  skir.ResourceId target(skir.LinkValue reference) => reference.target.resource;
}
