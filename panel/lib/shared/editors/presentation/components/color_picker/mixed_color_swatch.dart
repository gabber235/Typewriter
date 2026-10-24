import "package:typewriter_panel/typewriter_panel.dart";

/// Represents several differing colors without inventing a shared color.
class MixedColorSwatch extends StatelessWidget {
  const MixedColorSwatch({this.size = 24, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Checkerboard(
    borderRadius: context.shapes.smallBorderRadius,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: context.shapes.smallBorderRadius,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.remove_rounded,
        size: size * 0.7,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
