import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Draws a wire icon, such as the icon of a resource appearance or a type
/// display. Without a drawable icon it keeps its square empty, so rows of
/// resources stay aligned while an appearance is unavailable.
class ResourceIcon extends StatelessWidget {
  const ResourceIcon({required this.icon, this.color, this.size, super.key});

  /// The icon to draw, or null while it is unavailable.
  final skir.Icon? icon;

  /// Color of the icon, or the ambient icon color when null.
  final Color? color;

  /// Size of the icon square, or the ambient icon size when null.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final value = icon?.iconValue;
    if (value == null) {
      return SizedBox.square(dimension: size ?? IconTheme.of(context).size);
    }
    return Icones.value(value, color: color, size: size);
  }
}
