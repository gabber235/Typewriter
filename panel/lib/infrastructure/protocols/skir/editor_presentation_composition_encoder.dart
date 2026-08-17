part of "editor_presentation_encoder.dart";

extension SkirPresentationCompositionEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _container(ContainerElement value) {
    final child = encodeNode(value.child);
    final border = _border(value.border);
    final background = _optional(value.backgroundColor);
    final radius = _radius(value.radius);
    final diagnostics = [
      ...child.diagnostics,
      ...border.diagnostics,
      ...background.diagnostics,
      ...radius.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createContainer(
              child: child.valueOrNull!,
              border: border.valueOrNull,
              backgroundColor: background.valueOrNull,
              radius: radius.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationRadius> _radius(PresentationRadius value) =>
      switch (value) {
        NoPresentationRadius() => const TypeResult.success(
          wire.PresentationRadius.none,
        ),
        SmallPresentationRadius() => const TypeResult.success(
          wire.PresentationRadius.small,
        ),
        MediumPresentationRadius() => const TypeResult.success(
          wire.PresentationRadius.medium,
        ),
        LargePresentationRadius() => const TypeResult.success(
          wire.PresentationRadius.large,
        ),
        CustomPresentationRadius(:final value) =>
          expressions
              .encode(value)
              .mapValue(wire.PresentationRadius.wrapCustom),
      };

  TypeResult<wire.PresentationElement> _anchor(
    PresentationAnchorElement value,
  ) {
    final child = encodeNode(value.child);
    final anchors = <wire.PresentationAnchorPoint>[];
    final diagnostics = [...child.diagnostics];
    for (final value in value.anchors) {
      final anchor = _anchorPoint(value);
      diagnostics.addAll(anchor.diagnostics);
      if (anchor.valueOrNull case final item?) anchors.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createAnchor(
              child: child.valueOrNull!,
              anchors: anchors,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationAnchorPoint> _anchorPoint(
    PresentationAnchorPoint value,
  ) {
    final offset = value.offset == null
        ? const TypeResult<wire.PresentationOffset?>.success(null)
        : _offset(value.offset!).mapValue((value) => value);
    return combineResults(
      offset,
      _optional(value.visibleIf),
      (offset, visible) => wire.PresentationAnchorPoint(
        anchorId: value.id,
        groupIds: value.groupIds,
        alignment: value.alignment._encode,
        offset: offset,
        visibleIf: visible,
        exportToParent: value.exportToParent,
      ),
    );
  }

  TypeResult<wire.PresentationOffset> _offset(PresentationOffset value) =>
      combineResults(
        expressions.encode(value.x),
        expressions.encode(value.y),
        (x, y) => wire.PresentationOffset(x: x, y: y),
      );
}
