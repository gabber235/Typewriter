part of "editor_presentation_codec.dart";

extension SkirPresentationCompositionDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _container(wire.ContainerLayout value) {
    final border = _border(value.border);
    final background = _optionalExpression(value.backgroundColor);
    final radius = _radius(value.radius);
    final diagnostics = [
      ...border.diagnostics,
      ...background.diagnostics,
      ...radius.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            ContainerElement(
              child: decodeNode(value.child),
              border: border.valueOrNull,
              backgroundColor: background.valueOrNull,
              radius: radius.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationRadius> _radius(wire.PresentationRadius value) =>
      switch (value) {
        wire.PresentationRadius.none => const TypeResult.success(
          PresentationRadius.none(),
        ),
        wire.PresentationRadius.small => const TypeResult.success(
          PresentationRadius.small(),
        ),
        wire.PresentationRadius.medium => const TypeResult.success(
          PresentationRadius.medium(),
        ),
        wire.PresentationRadius.large => const TypeResult.success(
          PresentationRadius.large(),
        ),
        wire.PresentationRadius_customWrapper(:final value) =>
          expressions.decode(value).mapValue(PresentationRadius.custom),
        wire.PresentationRadius_unknown() => invalidWire(
          "Unknown presentation radius",
        ),
      };

  TypeResult<PresentationElement> _anchor(wire.PresentationAnchorLayout value) {
    final anchors = <PresentationAnchorPoint>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in value.anchors) {
      final anchor = _anchorPoint(value);
      diagnostics.addAll(anchor.diagnostics);
      if (anchor.valueOrNull case final item?) anchors.add(item);
    }
    if (anchors.isEmpty) {
      diagnostics.add(wireDiagnostic("Presentation anchors are empty"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            PresentationAnchorElement(
              child: decodeNode(value.child),
              anchors: anchors,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationAnchorPoint> _anchorPoint(
    wire.PresentationAnchorPoint value,
  ) {
    if (value.anchorId.isEmpty || value.groupIds.any((id) => id.isEmpty)) {
      return invalidWire("Invalid presentation anchor identifier");
    }
    final alignment = value.alignment._decode;
    if (alignment == null) return invalidWire("Unknown anchor alignment");
    final offset = value.offset == null
        ? const TypeResult<PresentationOffset?>.success(null)
        : _offset(value.offset!).mapValue((value) => value);
    return combineResults(
      offset,
      _optionalExpression(value.visibleIf),
      (offset, visible) => PresentationAnchorPoint(
        id: value.anchorId,
        groupIds: value.groupIds.toList(growable: false),
        alignment: alignment,
        offset: offset,
        visibleIf: visible,
        exportToParent: value.exportToParent,
      ),
    );
  }

  TypeResult<PresentationOffset> _offset(wire.PresentationOffset value) =>
      combineResults(
        expressions.decode(value.x),
        expressions.decode(value.y),
        (x, y) => PresentationOffset(x: x, y: y),
      );
}
