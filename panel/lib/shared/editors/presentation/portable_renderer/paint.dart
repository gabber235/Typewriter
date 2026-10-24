part of "../portable_presentation_renderer.dart";

/// Renders stacks, sizes and transforms. Values that follow interaction state
/// resolve through [PresentationValueEnvironment], so they change with the
/// nearest [PresentationInteractionScope] and animate with the transition the
/// presentation declares for the entered state.
extension _PortablePaintRendering on PortablePresentationNodeRenderer {
  Widget _renderStack(
    skir.StackChildrenElement element,
    PortablePresentationScope childScope,
  ) {
    final AlignmentGeometry alignment;
    try {
      alignment = switch (element.alignment) {
        final value? => _presentationAlignment(value),
        null => AlignmentDirectional.topStart,
      };
    } on PresentationValueFailure catch (failure) {
      return _diagnostic(failure.message);
    }
    final stack = Stack(
      alignment: alignment,
      clipBehavior: Clip.none,
      children: [
        for (final child in element.children)
          switch (child) {
            skir.StackChild_flowWrapper(:final value) =>
              PortablePresentationNodeRenderer(node: value, scope: childScope),
            skir.StackChild_positionedWrapper(:final value) =>
              _PortablePositioned(child: value, scope: childScope),
            _ => _diagnostic("The stack child is unavailable"),
          },
      ],
    );
    if (element.children.any((child) => child is skir.StackChild_flowWrapper)) {
      return stack;
    }
    // Without flow children the stack takes the incoming bounds, which must be
    // finite.
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.hasBoundedWidth && constraints.hasBoundedHeight
          ? stack
          : _diagnostic(
              "A stack of only positioned children needs a bounded size",
            ),
    );
  }

  Widget _renderSize(
    skir.SizeLayout layout,
    PortablePresentationScope childScope,
  ) {
    double? bound(skir.ExpressionNode? expression) {
      if (expression == null) return null;
      final value = _number(childScope, expression);
      if (value == null || !value.isFinite || value < 0) {
        throw const PresentationValueFailure(
          "Sizes must be finite and nonnegative",
        );
      }
      return value;
    }

    final BoxConstraints constraints;
    try {
      final width = bound(layout.width);
      final height = bound(layout.height);
      final minimumWidth = width ?? bound(layout.minimumWidth) ?? 0;
      final maximumWidth = width ?? bound(layout.maximumWidth);
      final minimumHeight = height ?? bound(layout.minimumHeight) ?? 0;
      final maximumHeight = height ?? bound(layout.maximumHeight);
      if ((maximumWidth != null && minimumWidth > maximumWidth) ||
          (maximumHeight != null && minimumHeight > maximumHeight)) {
        throw const PresentationValueFailure(
          "A minimum size cannot exceed its maximum",
        );
      }
      constraints = BoxConstraints(
        minWidth: minimumWidth,
        maxWidth: maximumWidth ?? double.infinity,
        minHeight: minimumHeight,
        maxHeight: maximumHeight ?? double.infinity,
      );
    } on PresentationValueFailure catch (failure) {
      return _diagnostic(failure.message);
    }
    return ConstrainedBox(
      constraints: constraints,
      child: PortablePresentationNodeRenderer(
        node: layout.child,
        scope: childScope,
        fillAvailableSpace:
            fillAvailableSpace ||
            (layout.width != null && layout.height != null),
      ),
    );
  }

  Widget _renderTransform(
    skir.TransformLayout layout,
    PortablePresentationScope childScope,
  ) => _PortableTransform(
    layout: layout,
    scope: childScope,
    child: PortablePresentationNodeRenderer(
      node: layout.child,
      scope: childScope,
      fillAvailableSpace: fillAvailableSpace,
    ),
  );
}

/// A stack child placed by insets that follow interaction state. Changes
/// animate with the duration and curve the transition policy chooses for the
/// entered state.
final class _PortablePositioned extends StatelessWidget {
  const _PortablePositioned({required this.child, required this.scope});

  final skir.PositionedStackChild child;
  final PortablePresentationScope scope;

  @override
  Widget build(BuildContext context) {
    final environment = PresentationValueEnvironment.of(context);
    double? inset(skir.PresentationNumber? value) =>
        value == null ? null : environment.number(value, scope);
    try {
      final start = inset(child.start);
      final end = inset(child.end);
      final width = inset(child.width);
      final top = inset(child.top);
      final bottom = inset(child.bottom);
      final height = inset(child.height);
      if ([start, end, width].nonNulls.length > 2 ||
          [top, bottom, height].nonNulls.length > 2) {
        throw const PresentationValueFailure(
          "A positioned child declares at most two bounds per axis",
        );
      }
      final motion = environment.motion(child.transition, scope);
      return AnimatedPositionedDirectional(
        duration: motion.duration,
        curve: motion.curve,
        start: start,
        end: end,
        width: width,
        top: top,
        bottom: bottom,
        height: height,
        child: PortablePresentationNodeRenderer(
          node: child.child,
          scope: scope,
          fillAvailableSpace: true,
        ),
      );
    } on PresentationValueFailure catch (failure) {
      return _diagnostic(failure.message);
    }
  }
}

/// The animatable parts of a transform; rotations in turns.
@freezed
abstract class _TransformValues with _$TransformValues {
  const factory _TransformValues({
    required double scale,
    required double rotateX,
    required double rotateY,
    required double rotateZ,
    required double translateX,
    required double translateY,
  }) = __TransformValues;

  const _TransformValues._();

  _TransformValues lerp(_TransformValues end, double t) => _TransformValues(
    scale: lerpDouble(scale, end.scale, t)!,
    rotateX: lerpDouble(rotateX, end.rotateX, t)!,
    rotateY: lerpDouble(rotateY, end.rotateY, t)!,
    rotateZ: lerpDouble(rotateZ, end.rotateZ, t)!,
    translateX: lerpDouble(translateX, end.translateX, t)!,
    translateY: lerpDouble(translateY, end.translateY, t)!,
  );

  Matrix4 matrix(double perspective) {
    const turn = 2 * pi;
    return Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..translateByDouble(translateX, translateY, 0, 1)
      ..rotateX(rotateX * turn)
      ..rotateY(rotateY * turn)
      ..rotateZ(rotateZ * turn)
      ..scaleByDouble(scale, scale, 1, 1);
  }
}

final class _TransformTween extends Tween<_TransformValues> {
  _TransformTween({super.end});

  @override
  _TransformValues lerp(double t) => begin!.lerp(end!, t);
}

/// Paints its child transformed by values that follow interaction state.
/// Layout and hit testing keep the untransformed bounds, so the host's hover
/// and press region does not move with the paint.
final class _PortableTransform extends StatelessWidget {
  const _PortableTransform({
    required this.layout,
    required this.scope,
    required this.child,
  });

  final skir.TransformLayout layout;
  final PortablePresentationScope scope;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final environment = PresentationValueEnvironment.of(context);
    double value(skir.PresentationNumber? number, double fallback) =>
        number == null ? fallback : environment.number(number, scope);
    try {
      if (!layout.perspective.isFinite) {
        throw const PresentationValueFailure(
          "Transform perspective must be finite",
        );
      }
      final target = _TransformValues(
        scale: value(layout.scale, 1),
        rotateX: value(layout.rotateX, 0),
        rotateY: value(layout.rotateY, 0),
        rotateZ: value(layout.rotateZ, 0),
        translateX: value(layout.translateX, 0),
        translateY: value(layout.translateY, 0),
      );
      final motion = environment.motion(layout.transition, scope);
      final origin = _presentationAlignment(layout.origin);
      return TweenAnimationBuilder<_TransformValues>(
        tween: _TransformTween(end: target),
        duration: motion.duration,
        curve: motion.curve,
        child: child,
        builder: (context, values, child) => Transform(
          alignment: origin.resolve(Directionality.of(context)),
          transform: values.matrix(layout.perspective),
          transformHitTests: false,
          child: child,
        ),
      );
    } on PresentationValueFailure catch (failure) {
      return _diagnostic(failure.message);
    }
  }
}
