import "package:typewriter_panel/typewriter_panel.dart";

part "services_packed_models.freezed.dart";

/// A graph node before grid coordinates are assigned.
///
/// Width and height use graph cells. [priority] affects neither topology nor
/// selection; it is carried through so the shared graph renderer can preserve
/// its draw ordering contract.
@freezed
abstract class ServicesPackedNode with _$ServicesPackedNode {
  const factory ServicesPackedNode({
    required GraphIdentifier id,
    required int width,
    required int height,
    required WidgetBuilder builder,
    @Default(0) int priority,
  }) = _ServicesPackedNode;
}

/// A directed relationship between two packed node identities.
///
/// The packer uses endpoints to group and rank connected nodes. The color is
/// retained for the final shared graph edge; unresolved endpoints are filtered
/// by [ServicesPackedLayout] before placement.
@freezed
abstract class ServicesPackedConnection with _$ServicesPackedConnection {
  const factory ServicesPackedConnection({
    required String id,
    required GraphIdentifier source,
    required GraphIdentifier target,
    required Color color,
  }) = _ServicesPackedConnection;
}

/// Local placement of one connected component before global packing.
///
/// Coordinates are relative to the component origin. The map contains every
/// node in the component and is translated once when the component is placed.
@freezed
abstract class ServicesPackedComponentPlacement
    with _$ServicesPackedComponentPlacement {
  const factory ServicesPackedComponentPlacement({
    required String id,
    required int width,
    required int height,
    required Map<GraphIdentifier, ServicesPackedGridPlacement> placements,
  }) = _ServicesPackedComponentPlacement;
}

/// Grid rectangle assigned to one node or component member.
///
/// Translation returns a new value, keeping layout calculations independent of
/// the mutable collection used to pack components.
@freezed
abstract class ServicesPackedGridPlacement with _$ServicesPackedGridPlacement {
  const factory ServicesPackedGridPlacement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _ServicesPackedGridPlacement;

  const ServicesPackedGridPlacement._();

  /// Returns this rectangle shifted by the supplied grid delta.
  ServicesPackedGridPlacement translate(int dx, int dy) =>
      copyWith(x: x + dx, y: y + dy);
}
