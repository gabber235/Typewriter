part of "connection_renderer_test.dart";

void registerConnectionMarkerScenarios() {
  testWidgets("connects arbitrary local anchors and renders marker content", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "layer",
            element: ConnectionLayerElement(
              connections: [
                PresentationConnection.connection(
                  source: const PresentationAnchorSelector.local("source"),
                  target: const PresentationAnchorSelector.local("target"),
                  path: const ConnectionPath.straight(),
                  style: _connectorStyle(
                    _colorExpression(const Color(0xFF967BFA)),
                    2,
                  ),
                  markers: [
                    ConnectionMarker(
                      node: PresentationNode(
                        id: "marker",
                        element: TextElement("Marker".asStringLiteral),
                      ),
                      position: 0.5.asFloatLiteral,
                      alignToPath: false.asBooleanLiteral,
                    ),
                  ],
                ),
              ],
              child: PresentationNode(
                id: "anchors",
                element: ColumnElement(
                  spacing: 48,
                  children: [
                    _anchor("source", PresentationAnchorAlignment.bottomCenter),
                    _anchor("target", PresentationAnchorAlignment.topCenter),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text("Marker"), findsOneWidget);
    final dynamic resolution = _connectionResolution(tester);
    expect(resolution.strokes, hasLength(1));
    expect(resolution.strokes.single.color, const Color(0xFF967BFA));
    expect(resolution.strokes.single.width, 2);
    expect(
      find.ancestor(
        of: find.text("Marker"),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });

  testWidgets("resolves typed endpoint markers with the connector style", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "endpoint.layer",
            element: ConnectionLayerElement(
              connections: [
                PresentationConnection.connection(
                  source: const PresentationAnchorSelector.local("source"),
                  target: const PresentationAnchorSelector.local("target"),
                  path: ConnectionPath.orthogonal(
                    OrthogonalConnectionPath(bendPosition: 0.5.asFloatLiteral),
                  ),
                  style: _connectorStyle(
                    _colorExpression(const Color(0xFF967BFA)),
                    2,
                    cornerRadius: 7,
                    startMarker: ConnectorEndpointMarker.arrow(
                      size: 8.asFloatLiteral,
                    ),
                    endMarker: ConnectorEndpointMarker.circle(
                      diameter: 6.asFloatLiteral,
                    ),
                  ),
                ),
              ],
              child: PresentationNode(
                id: "endpoint.anchors",
                element: ColumnElement(
                  spacing: 48,
                  children: [
                    _anchor("source", PresentationAnchorAlignment.bottomStart),
                    _anchor("target", PresentationAnchorAlignment.topEnd),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final dynamic stroke = _connectionResolution(tester).strokes.single;
    expect(stroke.style.cornerRadius, 7);
    expect(stroke.style.startMarker.extent, 8);
    expect(stroke.style.endMarker.extent, 6);
  });

  testWidgets("keeps markers distinct for equal connection configurations", (
    tester,
  ) async {
    final connection = PresentationConnection.connection(
      source: const PresentationAnchorSelector.local("source"),
      target: const PresentationAnchorSelector.local("target"),
      path: const ConnectionPath.straight(),
      style: _connectorStyle(_colorExpression(const Color(0xFF967BFA)), 2),
      markers: [
        ConnectionMarker(
          node: PresentationNode(
            id: "equal.marker",
            element: TextElement("Equal marker".asStringLiteral),
          ),
          position: 0.5.asFloatLiteral,
          alignToPath: false.asBooleanLiteral,
        ),
      ],
    );
    await tester.pumpTestApp(
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "layer",
            element: ConnectionLayerElement(
              connections: [connection, connection],
              child: PresentationNode(
                id: "anchors",
                element: ColumnElement(
                  spacing: 48,
                  children: [
                    _anchor("source", PresentationAnchorAlignment.bottomCenter),
                    _anchor("target", PresentationAnchorAlignment.topCenter),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text("Equal marker"), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
