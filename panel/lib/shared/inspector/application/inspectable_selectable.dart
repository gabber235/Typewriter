import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// One inspection a selected item offers to share with other selected items:
/// when every selected item offers a compatible surface with the same [id],
/// the inspector shows one inspection for all of them, such as the roles
/// several members hold or the fields several resources of one type agree on.
abstract interface class SharedInspectionSurface {
  Object get id;

  bool isCompatibleWith(SharedInspectionSurface other);

  /// Builds the one inspection [members] share. [members] holds the
  /// compatible surface of every selected item in selection order, this
  /// surface first; editors made while building register with [context].
  InspectionContent buildShared(
    List<SharedInspectionSurface> members,
    InspectionBuildContext context,
  );
}

/// A shared surface presented by a portable editor. Surfaces share only when
/// they agree on [rootType] and the [catalog] snapshot, so admission and
/// presentation check one type; [sharesEditorWith] adds what else they must
/// agree on.
abstract class PortableInspectionSurface implements SharedInspectionSurface {
  const PortableInspectionSurface();

  skir.TypeUse get rootType;

  CheckedEditorCatalog get catalog;

  /// Whether [other], already of the same root type and catalog snapshot,
  /// edits together with this surface.
  bool sharesEditorWith(PortableInspectionSurface other);

  @override
  @nonVirtual
  bool isCompatibleWith(SharedInspectionSurface other) =>
      other is PortableInspectionSurface &&
      other.rootType == rootType &&
      other.catalog.snapshot == catalog.snapshot &&
      sharesEditorWith(other);
}

/// A surface over a local value draft. The selected drafts combine into one
/// owner that reads what they agree on and writes every one of them, and
/// [buildHost] presents that owner.
abstract class ValueEditingInspectionSurface extends PortableInspectionSurface {
  const ValueEditingInspectionSurface();

  ValueEditingRegistration get target;

  PortablePresentationHost buildHost(
    List<SharedInspectionSurface> members,
    EditOwner combinedOwner,
  );

  @override
  InspectionContent buildShared(
    List<SharedInspectionSurface> members,
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

  /// Inspections this item shares with other selected items, each under a
  /// distinct id.
  List<SharedInspectionSurface> get sharedInspectionSurfaces => const [];

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
