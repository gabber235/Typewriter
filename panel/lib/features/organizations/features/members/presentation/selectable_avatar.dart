import "package:typewriter_panel/typewriter_panel.dart";

/// Avatar treatment that makes membership selection visible without relying
/// on row background color alone.
///
/// Unselected members use the supplied network image. Selection intentionally
/// replaces the image with a check state, giving the same semantic signal in
/// the desktop table and touch card layouts.
class SelectableAvatar extends StatelessWidget {
  const SelectableAvatar({
    required this.avatarUrl,
    required this.isSelected,
    super.key,
    this.radius = 24,
  });

  final String avatarUrl;
  final bool isSelected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundImage: isSelected ? null : NetworkImage(avatarUrl),
      backgroundColor: isSelected
          ? context.colors.success
          : theme.inputDecorationTheme.fillColor,
      child: isSelected
          ? Icon(Icons.check, color: context.colors.onSuccess, size: radius)
          : null,
    );
  }
}
