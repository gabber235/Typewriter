import "package:typewriter_panel/typewriter_panel.dart";

/// One backend owned projection that can participate in a shared inspection.
///
/// The legacy type information remains the admission boundary for the existing
/// editor owners. The portable host builder supplies the independently checked
/// presentation schema and never derives it from this catalog.
abstract interface class PortableMultiInspectionSurface {
  Object get id;

  EditorTarget get target;

  TypeExpression get rootType;

  TypeCatalog get typeCatalog;

  bool isCompatibleWith(PortableMultiInspectionSurface other);

  PortablePresentationHost buildHost(
    List<PortableMultiInspectionSurface> members,
    EditOwner combinedOwner,
    Future<void> Function() commit,
  );
}

/// A selectable resource that can be represented in the inspector.
///
/// This is the read only inspection boundary. Implementations create a
/// presentation from the supplied owner scope. [buildInspection] may add a
/// header, but it does not own resource editors; the inspection session does.
abstract class InspectableSelectable<I extends SelectableIdentifier>
    extends Selectable<I> {
  const InspectableSelectable();

  List<PortableMultiInspectionSurface> get portableMultiInspectionSurfaces =>
      const [];

  /// Builds the graph and optional resource header for this resource.
  InspectionContent buildInspection(EditorOwnerScope owners);
}

/// The presentation graph and optional header produced for one inspection.
///
/// The graph is consumed by [InspectionSession]. Any composite editor created
/// while building it must be registered through [InspectionBuildContext] so
/// the session can dispose it when the graph is replaced.
final class InspectionContent {
  const InspectionContent({
    this.host,
    this.additionalHosts = const [],
    this.body,
    this.header,
  }) : assert(host != null || additionalHosts.length > 0 || body != null);

  final PortablePresentationHost? host;
  final List<PortablePresentationHost> additionalHosts;
  final Widget? body;
  final Widget? header;
}
