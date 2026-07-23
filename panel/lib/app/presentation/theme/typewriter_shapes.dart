import "package:flutter/material.dart";

@immutable
class TypewriterShapes extends ThemeExtension<TypewriterShapes> {
  const TypewriterShapes({this.small = 4, this.medium = 8, this.large = 12});

  final double small;
  final double medium;
  final double large;
  Radius get smallRadius => Radius.circular(small);
  Radius get mediumRadius => Radius.circular(medium);
  Radius get largeRadius => Radius.circular(large);
  BorderRadius get smallBorderRadius => BorderRadius.all(smallRadius);
  BorderRadius get mediumBorderRadius => BorderRadius.all(mediumRadius);
  BorderRadius get largeBorderRadius => BorderRadius.all(largeRadius);
  RoundedRectangleBorder get smallShape =>
      RoundedRectangleBorder(borderRadius: smallBorderRadius);
  RoundedRectangleBorder get mediumShape =>
      RoundedRectangleBorder(borderRadius: mediumBorderRadius);
  RoundedRectangleBorder get largeShape =>
      RoundedRectangleBorder(borderRadius: largeBorderRadius);
  StadiumBorder get pill => const StadiumBorder();
  CircleBorder get circle => const CircleBorder();

  @override
  TypewriterShapes copyWith({double? small, double? medium, double? large}) =>
      TypewriterShapes(
        small: small ?? this.small,
        medium: medium ?? this.medium,
        large: large ?? this.large,
      );

  @override
  TypewriterShapes lerp(covariant TypewriterShapes? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => a + (b - a) * t;
    return TypewriterShapes(
      small: l(small, other.small),
      medium: l(medium, other.medium),
      large: l(large, other.large),
    );
  }
}
