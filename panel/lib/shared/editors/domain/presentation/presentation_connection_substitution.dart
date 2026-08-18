part of "presentation_substitution.dart";

PresentationElement _substituteAnchorElement(
  PresentationAnchorElement element,
  Map<String, TypeExpression> substitutions,
) => PresentationAnchorElement(
  child: element.child._substituteTypes(substitutions),
  anchors: [
    for (final anchor in element.anchors)
      PresentationAnchorPoint(
        id: anchor.id,
        groupIds: anchor.groupIds,
        alignment: anchor.alignment,
        offset: anchor.offset?._substituteTypes(substitutions),
        visibleIf: anchor.visibleIf._substituteTypes(substitutions),
        exportToParent: anchor.exportToParent,
      ),
  ],
);

PresentationElement _substituteConnectionElement(
  ConnectionLayerElement element,
  Map<String, TypeExpression> substitutions,
) => ConnectionLayerElement(
  child: element.child._substituteTypes(substitutions),
  connections: [
    for (final connection in element.connections)
      connection._substituteTypes(substitutions),
  ],
);

extension on PresentationAnchorElement {
  PresentationElement _substituteAnchorTypes(
    Map<String, TypeExpression> substitutions,
  ) => _substituteAnchorElement(this, substitutions);
}

extension on ConnectionLayerElement {
  PresentationElement _substituteConnectionTypes(
    Map<String, TypeExpression> substitutions,
  ) => _substituteConnectionElement(this, substitutions);
}

extension on PresentationRadius {
  PresentationRadius _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => switch (this) {
    NoPresentationRadius() => this,
    SmallPresentationRadius() => this,
    MediumPresentationRadius() => this,
    LargePresentationRadius() => this,
    CustomPresentationRadius(:final value) => PresentationRadius.custom(
      value._substituteTypes(substitutions),
    ),
  };
}

extension on PresentationOffset {
  PresentationOffset _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => PresentationOffset(
    x: x._substituteTypes(substitutions),
    y: y._substituteTypes(substitutions),
  );
}

extension on PresentationConnection {
  PresentationConnection _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => switch (this) {
    AnchoredConnection(
      :final source,
      :final target,
      :final path,
      :final style,
      :final markers,
      :final visibleIf,
    ) =>
      AnchoredConnection(
        source: source,
        target: target,
        path: path._substituteTypes(substitutions),
        style: style._substituteTypes(substitutions),
        markers: markers._substituteTypes(substitutions),
        visibleIf: visibleIf._substituteTypes(substitutions),
      ),
    AnchoredConnectionBundle(
      :final source,
      :final targets,
      :final path,
      :final trunkStyle,
      :final branchStyle,
      :final trunkMarkers,
      :final branchMarkers,
      :final visibleIf,
    ) =>
      AnchoredConnectionBundle(
        source: source,
        targets: targets,
        path: path._substituteTypes(substitutions),
        trunkStyle: trunkStyle._substituteTypes(substitutions),
        branchStyle: branchStyle._substituteTypes(substitutions),
        trunkMarkers: trunkMarkers._substituteTypes(substitutions),
        branchMarkers: branchMarkers._substituteTypes(substitutions),
        visibleIf: visibleIf._substituteTypes(substitutions),
      ),
  };
}

extension on ConnectorStroke {
  ConnectorStroke _substituteTypes(Map<String, TypeExpression> substitutions) =>
      ConnectorStroke(
        color: color._substituteTypes(substitutions),
        width: width._substituteTypes(substitutions),
      );
}

extension on ConnectorStyle {
  ConnectorStyle _substituteTypes(Map<String, TypeExpression> substitutions) =>
      ConnectorStyle(
        stroke: stroke._substituteTypes(substitutions),
        cornerRadius: cornerRadius._substituteTypes(substitutions),
        startMarker: startMarker?._substituteTypes(substitutions),
        endMarker: endMarker?._substituteTypes(substitutions),
      );
}

extension on ConnectorEndpointMarker {
  ConnectorEndpointMarker _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => switch (this) {
    ArrowConnectorMarker(:final size) => ConnectorEndpointMarker.arrow(
      size: size._substituteTypes(substitutions),
    ),
    CircleConnectorMarker(:final diameter) => ConnectorEndpointMarker.circle(
      diameter: diameter._substituteTypes(substitutions),
    ),
  };
}

extension on List<ConnectionMarker> {
  List<ConnectionMarker> _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => [
    for (final marker in this)
      ConnectionMarker(
        node: marker.node._substituteTypes(substitutions),
        position: marker.position._substituteTypes(substitutions),
        alignToPath: marker.alignToPath._substituteTypes(substitutions),
        scope: marker.scope,
      ),
  ];
}

extension on ConnectionPath {
  ConnectionPath _substituteTypes(Map<String, TypeExpression> substitutions) =>
      switch (this) {
        StraightConnectionPath() => this,
        OrthogonalPath(:final path) => ConnectionPath.orthogonal(
          OrthogonalConnectionPath(
            bendPosition: path.bendPosition._substituteTypes(substitutions),
          ),
        ),
        CurvedPath(:final path) => ConnectionPath.curved(
          CurvedConnectionPath(
            sourceControlOffset: path.sourceControlOffset._substituteTypes(
              substitutions,
            ),
            targetControlOffset: path.targetControlOffset._substituteTypes(
              substitutions,
            ),
          ),
        ),
      };
}

extension on ConnectionBundlePath {
  ConnectionBundlePath _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => switch (this) {
    FanBundlePath() => this,
    OrthogonalBundlePath(:final path) => ConnectionBundlePath.orthogonal(
      OrthogonalConnectionBundlePath(
        axis: path.axis,
        bendPosition: path.bendPosition._substituteTypes(substitutions),
      ),
    ),
  };
}
