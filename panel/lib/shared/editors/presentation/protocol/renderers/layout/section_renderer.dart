part of "../../layout_renderer.dart";

extension SectionElementRendering on SectionElement {
  Widget render(PresentationRenderScope scope) =>
      PresentationNodeRenderer(node: child, scope: scope);

  Widget decorate(
    BuildContext context,
    PresentationRenderScope scope,
    Widget child,
  ) {
    final content = DepthBox(child: child);
    if (border == null) return content;
    final resolved = border!._resolve(context, scope);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    return CustomPaint(
      foregroundPainter: _SectionBorderPainter(
        border: resolved.valueOrNull!,
        radius: context.shapes.mediumRadius,
        textDirection: Directionality.of(context),
      ),
      child: content,
    );
  }
}

extension on PresentationBorder {
  TypeResult<_ResolvedSectionBorder> _resolve(
    BuildContext context,
    PresentationRenderScope scope,
  ) {
    final fallback = Theme.of(context).colorScheme.outlineVariant;
    return switch (this) {
      PresentationBorderAll(:final side) => _resolveAll(side, scope, fallback),
      PresentationBorderSides(
        :final top,
        :final start,
        :final end,
        :final bottom,
      ) =>
        _resolveSides(
          scope,
          fallback,
          top: top,
          start: start,
          end: end,
          bottom: bottom,
        ),
    };
  }
}

TypeResult<_ResolvedSectionBorder> _resolveAll(
  PresentationBorderSide side,
  PresentationRenderScope scope,
  Color fallback,
) {
  final resolved = side._resolve(scope, fallback);
  if (resolved case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  final value = resolved.valueOrNull!;
  return TypeResult.success(
    _ResolvedSectionBorder(top: value, start: value, end: value, bottom: value),
  );
}

TypeResult<_ResolvedSectionBorder> _resolveSides(
  PresentationRenderScope scope,
  Color fallback, {
  PresentationBorderSide? top,
  PresentationBorderSide? start,
  PresentationBorderSide? end,
  PresentationBorderSide? bottom,
}) {
  final resolvedTop = top?._resolve(scope, fallback);
  final resolvedStart = start?._resolve(scope, fallback);
  final resolvedEnd = end?._resolve(scope, fallback);
  final resolvedBottom = bottom?._resolve(scope, fallback);
  final diagnostics = [
    ...?resolvedTop?.diagnostics,
    ...?resolvedStart?.diagnostics,
    ...?resolvedEnd?.diagnostics,
    ...?resolvedBottom?.diagnostics,
  ];
  return diagnostics.isEmpty
      ? TypeResult.success(
          _ResolvedSectionBorder(
            top: resolvedTop?.valueOrNull,
            start: resolvedStart?.valueOrNull,
            end: resolvedEnd?.valueOrNull,
            bottom: resolvedBottom?.valueOrNull,
          ),
        )
      : TypeResult.failure(diagnostics);
}

extension on PresentationBorderSide {
  TypeResult<BorderSide> _resolve(
    PresentationRenderScope scope,
    Color fallback,
  ) {
    if (color == null) {
      return TypeResult.success(BorderSide(color: fallback, width: width));
    }
    final resolved = scope.evaluate(color!);
    if (resolved case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final value = resolved.valueOrNull;
    final resolvedColor = value is IntegerValue ? value.colorOrNull : null;
    if (resolvedColor == null) {
      return TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Section border color must evaluate to a Color",
        ),
      ]);
    }
    return TypeResult.success(BorderSide(color: resolvedColor, width: width));
  }
}

class _ResolvedSectionBorder {
  const _ResolvedSectionBorder({this.top, this.start, this.end, this.bottom});

  final BorderSide? top;
  final BorderSide? start;
  final BorderSide? end;
  final BorderSide? bottom;
}

class _SectionBorderPainter extends CustomPainter {
  const _SectionBorderPainter({
    required this.border,
    required this.radius,
    required this.textDirection,
  });

  final _ResolvedSectionBorder border;
  final Radius radius;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final left = textDirection == TextDirection.ltr ? border.start : border.end;
    final right = textDirection == TextDirection.ltr
        ? border.end
        : border.start;
    final bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      radius,
    ).scaleRadii();
    canvas
      ..save()
      ..clipRRect(bounds);
    _paintTop(canvas, size, bounds, border.top);
    _paintVertical(canvas, size, bounds, left, true, border);
    _paintVertical(canvas, size, bounds, right, false, border);
    _paintBottom(canvas, size, bounds, border.bottom);
    canvas.restore();
  }

  void _paintTop(Canvas canvas, Size size, RRect bounds, BorderSide? side) {
    if (side == null) return;
    final inset = side.width / 2;
    final path = Path()
      ..moveTo(inset, bounds.tlRadiusY)
      ..quadraticBezierTo(inset, inset, bounds.tlRadiusX, inset)
      ..lineTo(size.width - bounds.trRadiusX, inset)
      ..quadraticBezierTo(
        size.width - inset,
        inset,
        size.width - inset,
        bounds.trRadiusY,
      );
    canvas.drawPath(path, side.toPaint());
  }

  void _paintBottom(Canvas canvas, Size size, RRect bounds, BorderSide? side) {
    if (side == null) return;
    final inset = side.width / 2;
    final path = Path()
      ..moveTo(inset, size.height - bounds.blRadiusY)
      ..quadraticBezierTo(
        inset,
        size.height - inset,
        bounds.blRadiusX,
        size.height - inset,
      )
      ..lineTo(size.width - bounds.brRadiusX, size.height - inset)
      ..quadraticBezierTo(
        size.width - inset,
        size.height - inset,
        size.width - inset,
        size.height - bounds.brRadiusY,
      );
    canvas.drawPath(path, side.toPaint());
  }

  void _paintVertical(
    Canvas canvas,
    Size size,
    RRect bounds,
    BorderSide? side,
    bool left,
    _ResolvedSectionBorder border,
  ) {
    if (side == null) return;
    final inset = side.width / 2;
    final x = left ? inset : size.width - inset;
    final topRadius = left ? bounds.tlRadiusY : bounds.trRadiusY;
    final bottomRadius = left ? bounds.blRadiusY : bounds.brRadiusY;
    final top = border.top == null ? 0.0 : topRadius;
    final bottom = border.bottom == null
        ? size.height
        : size.height - bottomRadius;
    canvas.drawLine(Offset(x, top), Offset(x, bottom), side.toPaint());
  }

  @override
  bool shouldRepaint(covariant _SectionBorderPainter oldDelegate) =>
      oldDelegate.border != border ||
      oldDelegate.radius != radius ||
      oldDelegate.textDirection != textDirection;
}
