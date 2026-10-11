import "package:typewriter_panel/typewriter_panel.dart";

enum DimensionResizeBound { minimum, maximum }

final class ResizeDimensionIntent extends Intent {
  const ResizeDimensionIntent({required this.delta});

  final double delta;
}

final class ResizeDimensionToBoundIntent extends Intent {
  const ResizeDimensionToBoundIntent(this.bound);

  final DimensionResizeBound bound;
}

final class DimensionResizeOperation {
  const DimensionResizeOperation({
    required this.getSize,
    required this.onSizeChange,
    this.minSize,
    this.maxSize,
    this.sizeResolver,
  });

  final SizeGetter getSize;
  final SizeChanged onSizeChange;
  final double? minSize;
  final double? maxSize;
  final SizeResolver? sizeResolver;

  double resolve(double start, double delta) {
    final resolved = sizeResolver?.call(start, delta) ?? start + delta;
    return resolved.clamp(
      minSize ?? double.negativeInfinity,
      maxSize ?? double.infinity,
    );
  }

  void to(double value) => onSizeChange(
    value.clamp(minSize ?? double.negativeInfinity, maxSize ?? double.infinity),
  );

  void from(double start, double delta) => onSizeChange(resolve(start, delta));

  void by(double delta) => from(getSize(), delta);

  void toBound(DimensionResizeBound bound) {
    final value = switch (bound) {
      DimensionResizeBound.minimum => minSize,
      DimensionResizeBound.maximum => maxSize,
    };
    if (value != null) to(value);
  }
}
