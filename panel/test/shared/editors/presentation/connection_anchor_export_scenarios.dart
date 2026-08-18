part of "connection_renderer_test.dart";

void registerConnectionAnchorExportScenarios() {
  testWidgets("exports anchors one layer and ignores offstage targets", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "outer",
            element: ConnectionLayerElement(
              connections: [
                PresentationConnection.bundle(
                  source: const PresentationAnchorSelector.local("source"),
                  targets: const PresentationAnchorSelector.exportedGroup(
                    "targets",
                  ),
                  path: const ConnectionBundlePath.fan(),
                  trunkStyle: _connectorStyle(
                    _colorExpression(const Color(0xFF967BFA)),
                    2,
                  ),
                  branchStyle: _connectorStyle(
                    _colorExpression(const Color(0xFF4CAF50)),
                    3,
                  ),
                ),
              ],
              child: PresentationNode(
                id: "outer.content",
                element: ColumnElement(
                  spacing: 48,
                  children: [
                    _anchor("source", PresentationAnchorAlignment.bottomCenter),
                    PresentationNode(
                      id: "target.section",
                      header: PresentationHeader(
                        title: "Targets".asStringLiteral.asHeaderTitle,
                        initiallyExpanded: true,
                      ),
                      element: SectionElement(
                        child: PresentationNode(
                          id: "nested",
                          element: ConnectionLayerElement(
                            connections: [_inactiveConnection()],
                            child: _exportedAnchor(),
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
      settle: false,
    );
    await tester.pump();
    await tester.pump();

    dynamic resolution = _connectionResolution(tester);
    expect(resolution.strokes, hasLength(1));
    expect(resolution.strokes.single.color, const Color(0xFF4CAF50));

    await tester.tap(find.text("Targets"));
    await tester.pumpAndSettle();

    resolution = _connectionResolution(tester);
    expect(resolution.strokes, isEmpty);
    expect(resolution.diagnostics, isEmpty);
  });

  testWidgets("does not export anchors through two connection layers", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "outer",
            element: ConnectionLayerElement(
              connections: [_bundleConnection()],
              child: PresentationNode(
                id: "outer.content",
                element: ColumnElement(
                  spacing: 48,
                  children: [
                    _anchor("source", PresentationAnchorAlignment.bottomCenter),
                    PresentationNode(
                      id: "middle",
                      element: ConnectionLayerElement(
                        connections: [_inactiveConnection()],
                        child: PresentationNode(
                          id: "inner",
                          element: ConnectionLayerElement(
                            connections: [_inactiveConnection()],
                            child: _exportedAnchor(),
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
    expect(resolution.strokes, isEmpty);
    expect(resolution.diagnostics, isEmpty);
  });

  testWidgets("evaluates target strokes in the exported anchor scope", (
    tester,
  ) async {
    const targetBinding = BindingId(7);
    const targetColor = Color(0xFF4CAF50);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 240,
        child: _renderer(
          PresentationNode(
            id: "outer",
            element: ConnectionLayerElement(
              connections: [
                PresentationConnection.connection(
                  source: const PresentationAnchorSelector.local("source"),
                  target: const PresentationAnchorSelector.exportedGroup(
                    "targets",
                  ),
                  path: const ConnectionPath.straight(),
                  style: _connectorStyle(
                    _bindingColorExpression(targetBinding),
                    2,
                  ),
                ),
              ],
              child: PresentationNode(
                id: "outer.content",
                element: ColumnElement(
                  spacing: 48,
                  children: [
                    _anchor("source", PresentationAnchorAlignment.bottomCenter),
                    PresentationNode(
                      id: "nested",
                      element: ConnectionLayerElement(
                        connections: [_inactiveConnection()],
                        child: PresentationNode(
                          id: "target.scope",
                          element: ScopedBindingElement(
                            binding: const BindingReference(
                              bindingId: BindingId(0),
                            ),
                            scopeBindingId: targetBinding,
                            child: _exportedAnchor(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          rootValue: IntegerValue(BigInt.from(targetColor.toARGB32())),
          rootRepresentation: NamedType(standardTypeRefs.color),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final dynamic resolution = _connectionResolution(tester);
    expect(resolution.diagnostics, isEmpty);
    expect(resolution.strokes.single.color, targetColor);
  });
}
