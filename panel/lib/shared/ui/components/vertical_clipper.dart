import "package:typewriter_panel/typewriter_panel.dart";

/// Clips a rectangle while optionally extending both vertical edges.
///
/// The extension is useful when a translated or overflowing child must remain
/// visible without changing the clip's height.
class VerticalClipper extends CustomClipper<Path> {
  const VerticalClipper({this.additionalWidth = 0});

  /// Extra width added symmetrically beyond the left and right edges.
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
