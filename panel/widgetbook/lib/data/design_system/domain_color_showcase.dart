import "package:typewriter_panel/typewriter_panel.dart";

/// The colors users pick for data such as tags and Books, which live
/// outside the theme, on readable foregrounds from [ColorExtension.on].
///
/// Shows every color of [safeColors] as a tile, so a change that makes data
/// colored content illegible in either theme is visible at a glance.
class DomainColorShowcase extends StatelessWidget {
  const DomainColorShowcase({super.key});

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
                for (final (index, color) in safeColors.indexed)
                  _DomainTile(label: "Color ${index + 1}", color: color),
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
      width: 160,
      height: 72,
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: context.shapes.largeBorderRadius,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}
