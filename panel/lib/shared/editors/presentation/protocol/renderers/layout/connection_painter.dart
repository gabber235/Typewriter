part of "../../layout_renderer.dart";

void _paintResolvedConnectorPaths(
  Canvas canvas,
  List<_ResolvedStrokePath> strokes,
) {
  for (final stroke in strokes) {
    canvas.drawPath(
      stroke.path,
      Paint()
        ..color = stroke.style.color
        ..strokeWidth = stroke.style.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
  for (final stroke in strokes) {
    _paintEndpointMarkers(canvas, stroke);
  }
}

void _paintEndpointMarkers(Canvas canvas, _ResolvedStrokePath stroke) {
  final metrics = stroke.path.computeMetrics().toList(growable: false);
  if (metrics.isEmpty) return;
  final metric = metrics.first;
  if (stroke.style.startMarker case final marker?) {
    final tangent = metric.getTangentForOffset(0);
    if (tangent != null) {
      _paintEndpointMarker(
        canvas,
        marker,
        stroke.style.color,
        tangent.position,
        -tangent.vector,
      );
    }
  }
  if (stroke.style.endMarker case final marker?) {
    final tangent = metric.getTangentForOffset(metric.length);
    if (tangent != null) {
      _paintEndpointMarker(
        canvas,
        marker,
        stroke.style.color,
        tangent.position,
        tangent.vector,
      );
    }
  }
}

void _paintEndpointMarker(
  Canvas canvas,
  _ResolvedEndpointMarker marker,
  Color color,
  Offset position,
  Offset direction,
) {
  if (marker.extent == 0) return;
  if (marker.kind == _ResolvedEndpointMarkerKind.circle) {
    canvas.drawCircle(
      position,
      marker.extent / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    return;
  }
  if (direction.distance == 0) return;
  final normalizedDirection = direction / direction.distance;
  canvas.drawPath(
    _roundedArrowPath(position, normalizedDirection, marker.extent),
    Paint()
      ..color = color
      ..style = PaintingStyle.fill,
  );
}

Path _roundedArrowPath(Offset tip, Offset direction, double extent) {
  const cornerFraction = 0.18;
  final baseCenter = tip - direction * extent;
  final normal = Offset(-direction.dy, direction.dx) * extent / 2;
  final firstBaseCorner = baseCenter + normal;
  final secondBaseCorner = baseCenter - normal;
  final roundedTipControl = tip + direction * extent * cornerFraction;

  final tipTowardFirst = Offset.lerp(tip, firstBaseCorner, cornerFraction)!;
  final tipTowardSecond = Offset.lerp(tip, secondBaseCorner, cornerFraction)!;
  final firstTowardTip = Offset.lerp(firstBaseCorner, tip, cornerFraction)!;
  final firstTowardSecond = Offset.lerp(
    firstBaseCorner,
    secondBaseCorner,
    cornerFraction,
  )!;
  final secondTowardFirst = Offset.lerp(
    secondBaseCorner,
    firstBaseCorner,
    cornerFraction,
  )!;
  final secondTowardTip = Offset.lerp(secondBaseCorner, tip, cornerFraction)!;

  return Path()
    ..moveTo(tipTowardFirst.dx, tipTowardFirst.dy)
    ..quadraticBezierTo(
      roundedTipControl.dx,
      roundedTipControl.dy,
      tipTowardSecond.dx,
      tipTowardSecond.dy,
    )
    ..lineTo(secondTowardTip.dx, secondTowardTip.dy)
    ..quadraticBezierTo(
      secondBaseCorner.dx,
      secondBaseCorner.dy,
      secondTowardFirst.dx,
      secondTowardFirst.dy,
    )
    ..lineTo(firstTowardSecond.dx, firstTowardSecond.dy)
    ..quadraticBezierTo(
      firstBaseCorner.dx,
      firstBaseCorner.dy,
      firstTowardTip.dx,
      firstTowardTip.dy,
    )
    ..close();
}
