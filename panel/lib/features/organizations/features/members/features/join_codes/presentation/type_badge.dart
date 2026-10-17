import "package:typewriter_panel/typewriter_panel.dart";

/// Compact visual label for one invitation policy facet.
class TypeBadge extends StatelessWidget {
  const TypeBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space2,
        vertical: context.spacing.space1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: context.shapes.largeBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: context.spacing.space1),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
