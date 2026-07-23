import "package:flutter/material.dart";

@immutable
class TypewriterSpacing extends ThemeExtension<TypewriterSpacing> {
  const TypewriterSpacing({
    this.space1 = 4,
    this.space2 = 8,
    this.space3 = 12,
    this.space4 = 16,
    this.space5 = 20,
    this.space6 = 24,
    this.space8 = 32,
    this.space10 = 40,
    this.space12 = 48,
  });

  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double space8;
  final double space10;
  final double space12;

  @override
  TypewriterSpacing copyWith({
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    double? space6,
    double? space8,
    double? space10,
    double? space12,
  }) => TypewriterSpacing(
    space1: space1 ?? this.space1,
    space2: space2 ?? this.space2,
    space3: space3 ?? this.space3,
    space4: space4 ?? this.space4,
    space5: space5 ?? this.space5,
    space6: space6 ?? this.space6,
    space8: space8 ?? this.space8,
    space10: space10 ?? this.space10,
    space12: space12 ?? this.space12,
  );

  @override
  TypewriterSpacing lerp(covariant TypewriterSpacing? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => a + (b - a) * t;
    return TypewriterSpacing(
      space1: l(space1, other.space1),
      space2: l(space2, other.space2),
      space3: l(space3, other.space3),
      space4: l(space4, other.space4),
      space5: l(space5, other.space5),
      space6: l(space6, other.space6),
      space8: l(space8, other.space8),
      space10: l(space10, other.space10),
      space12: l(space12, other.space12),
    );
  }
}
