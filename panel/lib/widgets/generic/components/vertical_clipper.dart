import "package:flutter/widgets.dart";

class VerticalClipper extends CustomClipper<Path> {
  const VerticalClipper({this.additionalWidth = 0});
  final double additionalWidth;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(-additionalWidth, 0)
      ..lineTo(size.width + additionalWidth, 0)
      ..lineTo(size.width + additionalWidth, size.height)
      ..lineTo(-additionalWidth, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    if (oldClipper is VerticalClipper) {
      return oldClipper.additionalWidth != additionalWidth;
    }
    return true;
  }
}
