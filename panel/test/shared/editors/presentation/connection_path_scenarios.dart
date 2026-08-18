part of "connection_renderer_test.dart";

void registerConnectionPathScenarios() {
  testWidgets("mirrors curved control offsets in right to left layouts", (
    tester,
  ) async {
    final presentation = _curvedConnectionPresentation();
    await tester.pumpTestApp(
      child: SizedBox(width: 240, child: _renderer(presentation)),
    );
    await tester.pump();
    await tester.pump();
    final dynamic leftToRight = _connectionResolution(tester);
    final Rect leftBounds = leftToRight.strokes.single.path.getBounds();
    expect(leftToRight.markers.single.angle.abs(), greaterThan(0.1));

    await tester.pumpTestApp(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(width: 240, child: _renderer(presentation)),
      ),
    );
    await tester.pump();
    await tester.pump();
    final dynamic rightToLeft = _connectionResolution(tester);
    final Rect rightBounds = rightToLeft.strokes.single.path.getBounds();

    expect(leftBounds.left, closeTo(240 - rightBounds.right, 0.01));
    expect(leftBounds.right, closeTo(240 - rightBounds.left, 0.01));
    expect(rightToLeft.markers.single.angle.abs(), greaterThan(0.1));
  });

  testWidgets("routes vertical bundles with one trunk and short branches", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "bundle.layer",
            element: ConnectionLayerElement(
              connections: [
                PresentationConnection.bundle(
                  source: const PresentationAnchorSelector.local("source"),
                  targets: const PresentationAnchorSelector.exportedGroup(
                    "targets",
                  ),
                  path: ConnectionBundlePath.orthogonal(
                    OrthogonalConnectionBundlePath(
                      axis: ConnectionAxis.vertical,
                      bendPosition: 0.35.asFloatLiteral,
                    ),
                  ),
                  trunkStyle: _connectorStyle(
                    _colorExpression(const Color(0xFF967BFA)),
                    2,
                    cornerRadius: 6,
                  ),
                  branchStyle: _connectorStyle(
                    _colorExpression(const Color(0xFF4CAF50)),
                    2,
                    cornerRadius: 6,
                  ),
                ),
              ],
              child: PresentationNode(
                id: "bundle.content",
                element: ColumnElement(
                  spacing: 24,
                  crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
                  children: [
                    _anchor("source", PresentationAnchorAlignment.bottomStart),
                    PresentationNode(
                      id: "bundle.targets",
                      element: ConnectionLayerElement(
                        connections: [_inactiveConnection()],
                        child: PresentationNode(
                          id: "bundle.target.column",
                          element: ColumnElement(
                            spacing: 48,
                            crossAxisAlignment:
                                PresentationCrossAxisAlignment.stretch,
                            children: [
                              _exportedAnchor("first.target"),
                              _exportedAnchor("second.target"),
                            ],
                          ),
                        ),
                      ),
                    ),
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

    final dynamic resolution = _connectionResolution(tester);
    expect(resolution.strokes, hasLength(3));
    final Rect trunkBounds = resolution.strokes.first.path.getBounds();
    expect(trunkBounds.height, greaterThan(80));
    for (final dynamic branch in resolution.strokes.skip(1)) {
      final Rect bounds = branch.path.getBounds();
      expect(bounds.height, lessThanOrEqualTo(6.01));
    }
  });
}
