part of "presentation_element.dart";

enum PresentationAnchorAlignment {
  topStart,
  topCenter,
  topEnd,
  centerStart,
  center,
  centerEnd,
  bottomStart,
  bottomCenter,
  bottomEnd,
}

enum ConnectionExpressionScope { layer, source, target }

enum ConnectionAxis { horizontal, vertical }

@freezed
abstract class PresentationOffset with _$PresentationOffset {
  const factory PresentationOffset({
    required TypedExpression x,
    required TypedExpression y,
  }) = _PresentationOffset;
}

@freezed
abstract class PresentationAnchorPoint with _$PresentationAnchorPoint {
  @Assert("id != \"\"", "Anchor ID must not be empty.")
  const factory PresentationAnchorPoint({
    required String id,
    @Default([]) List<String> groupIds,
    @Default(PresentationAnchorAlignment.center)
    PresentationAnchorAlignment alignment,
    PresentationOffset? offset,
    TypedExpression? visibleIf,
    @Default(false) bool exportToParent,
  }) = _PresentationAnchorPoint;
}

@freezed
sealed class PresentationAnchorSelector with _$PresentationAnchorSelector {
  @Assert("id != \"\"", "Anchor ID must not be empty.")
  const factory PresentationAnchorSelector.local(String id) = LocalAnchor;

  @Assert("groupId != \"\"", "Anchor group ID must not be empty.")
  const factory PresentationAnchorSelector.exportedGroup(String groupId) =
      ExportedAnchorGroup;
}

@freezed
abstract class ConnectorStroke with _$ConnectorStroke {
  const factory ConnectorStroke({
    required TypedExpression color,
    required TypedExpression width,
  }) = _ConnectorStroke;
}

@freezed
sealed class ConnectorEndpointMarker with _$ConnectorEndpointMarker {
  const factory ConnectorEndpointMarker.arrow({required TypedExpression size}) =
      ArrowConnectorMarker;

  const factory ConnectorEndpointMarker.circle({
    required TypedExpression diameter,
  }) = CircleConnectorMarker;
}

@freezed
abstract class ConnectorStyle with _$ConnectorStyle {
  const factory ConnectorStyle({
    required ConnectorStroke stroke,
    required TypedExpression cornerRadius,
    ConnectorEndpointMarker? startMarker,
    ConnectorEndpointMarker? endMarker,
  }) = _ConnectorStyle;
}

@freezed
abstract class ConnectionMarker with _$ConnectionMarker {
  const factory ConnectionMarker({
    required PresentationNode node,
    required TypedExpression position,
    required TypedExpression alignToPath,
    @Default(ConnectionExpressionScope.layer) ConnectionExpressionScope scope,
  }) = _ConnectionMarker;
}

@freezed
abstract class OrthogonalConnectionPath with _$OrthogonalConnectionPath {
  const factory OrthogonalConnectionPath({
    required TypedExpression bendPosition,
  }) = _OrthogonalConnectionPath;
}

@freezed
abstract class CurvedConnectionPath with _$CurvedConnectionPath {
  const factory CurvedConnectionPath({
    required PresentationOffset sourceControlOffset,
    required PresentationOffset targetControlOffset,
  }) = _CurvedConnectionPath;
}

@freezed
sealed class ConnectionPath with _$ConnectionPath {
  const factory ConnectionPath.straight() = StraightConnectionPath;
  const factory ConnectionPath.orthogonal(OrthogonalConnectionPath path) =
      OrthogonalPath;
  const factory ConnectionPath.curved(CurvedConnectionPath path) = CurvedPath;
}

@freezed
abstract class OrthogonalConnectionBundlePath
    with _$OrthogonalConnectionBundlePath {
  const factory OrthogonalConnectionBundlePath({
    required ConnectionAxis axis,
    required TypedExpression bendPosition,
  }) = _OrthogonalConnectionBundlePath;
}

@freezed
sealed class ConnectionBundlePath with _$ConnectionBundlePath {
  const factory ConnectionBundlePath.orthogonal(
    OrthogonalConnectionBundlePath path,
  ) = OrthogonalBundlePath;
  const factory ConnectionBundlePath.fan() = FanBundlePath;
}

@freezed
sealed class PresentationConnection with _$PresentationConnection {
  const factory PresentationConnection.connection({
    required PresentationAnchorSelector source,
    required PresentationAnchorSelector target,
    required ConnectionPath path,
    required ConnectorStyle style,
    @Default([]) List<ConnectionMarker> markers,
    TypedExpression? visibleIf,
  }) = AnchoredConnection;

  const factory PresentationConnection.bundle({
    required PresentationAnchorSelector source,
    required PresentationAnchorSelector targets,
    required ConnectionBundlePath path,
    required ConnectorStyle trunkStyle,
    required ConnectorStyle branchStyle,
    @Default([]) List<ConnectionMarker> trunkMarkers,
    @Default([]) List<ConnectionMarker> branchMarkers,
    TypedExpression? visibleIf,
  }) = AnchoredConnectionBundle;
}
