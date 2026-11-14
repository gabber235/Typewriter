import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// One projection a selected item offers for a shared inspection: when every
/// selected item offers a compatible surface with the same root type and
/// catalog snapshot, the inspector shows one inspection for all of them.
///
/// The checked type information is shared by admission and presentation.
abstract interface class PortableMultiInspectionSurface {
  Object get id;

  skir.TypeUse get rootType;

  CheckedEditorCatalog get catalog;

  bool isCompatibleWith(PortableMultiInspectionSurface other);

  /// Builds the one inspection [members] share. [members] holds the
  /// compatible surface of every selected item in selection order, this
  /// surface first; editors made while building register with [context].
  InspectionContent buildShared(
    List<PortableMultiInspectionSurface> members,
    InspectionBuildContext context,
  );
}

/// A surface over a local value draft. The selected drafts combine into one
/// owner that reads what they agree on and writes every one of them, and
/// [buildHost] presents that owner.
abstract class ValueEditingInspectionSurface
    implements PortableMultiInspectionSurface {
  const ValueEditingInspectionSurface();

  ValueEditingRegistration get target;

  PortablePresentationHost buildHost(
    List<PortableMultiInspectionSurface> members,
    EditOwner combinedOwner,
  );

  @override
  InspectionContent buildShared(
    List<PortableMultiInspectionSurface> members,
    InspectionBuildContext context,
  ) {
    final owners =
        (Set<ValueEditing>.identity()..addAll(
              members.cast<ValueEditingInspectionSurface>().map(
                (surface) => context.owners.editor(surface.target),
              ),
            ))
            .toList();
    final combined = context.multiEditorForOwners(
      owners,
      rootType: rootType,
      catalog: catalog,
    );
    return InspectionContent(host: buildHost(members, combined));
  }
}

/// A selectable resource that can be represented in the inspector.
///
/// This is the read only inspection boundary. Implementations create a
/// presentation from the supplied owner scope. [buildInspection] may add a
/// header. The local work session owns resource drafts; the supplied binding
/// scope leases those owners for the inspection graph.
abstract class InspectableSelectable<I extends SelectableIdentifier>
    extends Selectable<I> {
  const InspectableSelectable();

  List<PortableMultiInspectionSurface> get portableMultiInspectionSurfaces =>
      const [];

  /// Builds the graph and optional resource header for this resource.
  InspectionContent buildInspection(InspectionBindingScope owners);
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
  }) : assert(host != null || additionalHosts.length > 0 || body != null);

  final PortablePresentationHost? host;
  final List<PortablePresentationHost> additionalHosts;
  final Widget? body;
}
