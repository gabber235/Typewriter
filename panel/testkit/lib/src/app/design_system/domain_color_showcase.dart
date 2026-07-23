import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// A visual test fixture for colors that intentionally live outside the theme.
///
/// Typewriter uses data-driven colors for concepts such as tags, blueprints,
/// page types, and service roles. Those colors must not be replaced by design
/// system semantic colors, but their surrounding layout and foreground contrast
/// must still work in both light and dark themes.
///
/// This showcase renders a representative set of arbitrary colors using
/// [ColorExtension.on] to calculate a readable foreground. It is shared by
/// Widgetbook and the committed design-system golden tests, helping catch theme
/// changes that would make data-colored UI inconsistent or illegible.
///
/// This is test infrastructure only; production features continue to render
/// their real domain colors and models.
class DomainColorShowcase extends StatelessWidget {
  const DomainColorShowcase({super.key});

  /// Representative colors used to exercise a range of hues and luminance.
  ///
  /// They are deliberately not references to production domain constants. That
  /// keeps this fixture independent while testing the same contrast behavior.
  static const domainColors = <Color>[
    Color(0xFF7E57C2),
    Color(0xFF00897B),
    Color(0xFFF4511E),
    Color(0xFF3949AB),
    Color(0xFFD81B60),
    Color(0xFF6D4C41),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1200,
      height: 900,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Domain colors",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: context.spacing.space6),
            Wrap(
              spacing: context.spacing.space4,
              runSpacing: context.spacing.space4,
              children: [
                for (final (index, color) in domainColors.indexed)
                  _DomainTile(label: "Category ${index + 1}", color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainTile extends StatelessWidget {
  const _DomainTile({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = color.on(context);
    return Container(
      width: 240,
      height: 120,
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: context.shapes.largeBorderRadius,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: foreground),
      ),
    );
  }
}
