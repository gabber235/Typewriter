import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the prominent title used by inspector and editor headers.
///
/// Set [isDeprecated] when the represented item remains visible but should be
/// presented as no longer current.
class Title extends StatelessWidget {
  const Title({
    required this.title,
    required this.color,
    this.isDeprecated = false,
    super.key,
  });

  final String title;
  final Color color;

  /// Adds a wavy strike through without hiding the title.
  final bool isDeprecated;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      title,
      style: Theme.of(context).textTheme.displayLarge!.copyWith(
        color: color,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        decoration: isDeprecated ? TextDecoration.lineThrough : null,
        decorationThickness: 2.8,
        decorationStyle: TextDecorationStyle.wavy,
        decorationColor: color,
      ),
      maxLines: 1,
    );
  }
}
