part of "../../layout_renderer.dart";

extension ContainerElementRendering on ContainerElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final resolvedRadius = radius._resolve(context, scope);
    final resolvedBorder = border?._resolve(context, scope);
    final resolvedBackground = _resolveBackground(scope);
    final diagnostics = [
      ...resolvedRadius.diagnostics,
      ...?resolvedBorder?.diagnostics,
      ...resolvedBackground.diagnostics,
    ];
    if (diagnostics.isNotEmpty) {
      return presentationDiagnostic(context, diagnostics);
    }
    final radiusValue = resolvedRadius.valueOrNull!;
    final background = resolvedBackground.valueOrNull;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.all(radiusValue),
      ),
      child: PresentationNodeRenderer(node: child, scope: scope),
    );
    if (resolvedBorder?.valueOrNull case final borderValue?) {
      return CustomPaint(
        foregroundPainter: _SectionBorderPainter(
          border: borderValue,
          radius: radiusValue,
          textDirection: Directionality.of(context),
        ),
        child: content,
      );
    }
    return content;
  }

  TypeResult<Color?> _resolveBackground(PresentationRenderScope scope) {
    if (backgroundColor == null) return const TypeResult.success(null);
    final result = scope.evaluate(backgroundColor!);
    if (result case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final value = result.valueOrNull;
    final color = value is IntegerValue ? value.colorOrNull : null;
    return color == null
        ? TypeResult.failure([
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: "Container background must evaluate to a Color",
            ),
          ])
        : TypeResult.success(color);
  }
}

extension on PresentationRadius {
  TypeResult<Radius> _resolve(
    BuildContext context,
    PresentationRenderScope scope,
  ) => switch (this) {
    NoPresentationRadius() => const TypeResult.success(Radius.zero),
    SmallPresentationRadius() => TypeResult.success(context.shapes.smallRadius),
    MediumPresentationRadius() => TypeResult.success(
      context.shapes.mediumRadius,
    ),
    LargePresentationRadius() => TypeResult.success(context.shapes.largeRadius),
    CustomPresentationRadius(:final value) => _resolveCustomRadius(
      value,
      scope,
    ),
  };
}

TypeResult<Radius> _resolveCustomRadius(
  TypedExpression expression,
  PresentationRenderScope scope,
) {
  final result = scope.evaluate(expression);
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  final value = switch (result.valueOrNull) {
    FloatValue(:final value) => value,
    IntegerValue(:final value) => value.toDouble(),
    _ => null,
  };
  if (value == null || !value.isFinite || value < 0) {
    return TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Container radius must be a finite nonnegative number",
      ),
    ]);
  }
  return TypeResult.success(Radius.circular(value));
}
