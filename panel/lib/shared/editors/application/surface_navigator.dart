import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "surface_navigator.freezed.dart";

/// Where opening a resource lands: the realm home, or the route of a resource
/// with a surface. [selected] is the resource to select inside it when that
/// differs from the routed resource.
@freezed
sealed class SurfaceTarget with _$SurfaceTarget {
  const factory SurfaceTarget.home({skir.ResourceId? selected}) = HomeTarget;
  const factory SurfaceTarget.resource({
    required skir.ResourceId routed,
    skir.ResourceId? selected,
  }) = ResourceTarget;
}

/// One owner walk for every navigation. Every owner chain ends at the realm
/// root, so opening any resource lands on the nearest resource with a surface,
/// or on the realm home when none exists below the root.
extension SurfaceNavigator on AuthoringDocument {
  /// The single instance of the catalog's realm root type, or null while the
  /// realm has not provisioned it.
  skir.ResourceId? get realmRoot =>
      instancesOf(catalog.snapshot.realmRoot).singleOrNull;

  /// The section the realm home shows: the first section of the root.
  skir.ResourceId? get homeSection {
    final root = realmRoot;
    final record = root == null ? null : resource(root);
    if (record == null) return null;
    for (final field in catalog.owningFields(record.configuration)) {
      final items = switch (record.readAt(field.path)) {
        PortablePathValue(:final value) => value.authoredItems,
        PortablePathUnavailable() => null,
      };
      for (final item in items ?? const <skir.ListItem>[]) {
        final target = item.value.authoredLink?.target.resource;
        if (target != null && entry(target) != null) return target;
      }
    }
    return null;
  }

  /// Resources whose selected type is exactly [type].
  Iterable<skir.ResourceId> instancesOf(skir.TypeDefinitionId type) => entries
      .values
      .where((entry) => entry.content.configuration.definition == type)
      .map((entry) => entry.id);

  /// Whether the resource's type declares a workspace or navigator. Role
  /// fallbacks do not count.
  bool hasSurface(skir.ResourceId id) => switch (resource(id)) {
    final record? =>
      catalog.declaresPresentation(
            record.configuration,
            skir.PresentationRole.workspace,
          ) ||
          catalog.declaresPresentation(
            record.configuration,
            skir.PresentationRole.navigator,
          ),
    null => false,
  };

  /// Opens the nearest of the resource and its owners below the root that has
  /// a surface, selecting the resource inside it. The root itself, and any
  /// resource without such an owner, opens the realm home.
  SurfaceTarget open(skir.ResourceId id) {
    final root = realmRoot;
    final routed = [
      id,
      ...relations.ownerPath(id).owners,
    ].where((candidate) => candidate != root).firstWhereOrNull(hasSurface);
    if (routed == null) {
      return SurfaceTarget.home(selected: id == root ? null : id);
    }
    return SurfaceTarget.resource(
      routed: routed,
      selected: routed == id ? null : id,
    );
  }

  /// The owners of [id] below the root, nearest last, followed by [id]
  /// itself: the breadcrumb trail of a routed resource.
  List<skir.ResourceId> surfaceTrail(skir.ResourceId id) {
    final root = realmRoot;
    return [
      ...relations
          .ownerPath(id)
          .owners
          .reversed
          .where((owner) => owner != root),
      id,
    ];
  }

  /// The navigator beside [routed]: the nearest of it and its owners below
  /// the root that declares a navigator.
  skir.ResourceId? railNavigator(skir.ResourceId routed) {
    final root = realmRoot;
    return [routed, ...relations.ownerPath(routed).owners]
        .where((candidate) => candidate != root)
        .firstWhereOrNull(
          (candidate) => switch (resource(candidate)) {
            final record? => catalog.declaresPresentation(
              record.configuration,
              skir.PresentationRole.navigator,
            ),
            null => false,
          },
        );
  }
}
