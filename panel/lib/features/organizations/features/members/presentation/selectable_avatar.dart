import "package:flutter/material.dart";

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
          ? Colors.green
          : theme.inputDecorationTheme.fillColor,
      child: isSelected
          ? Icon(Icons.check, color: Colors.white, size: radius)
          : null,
    );
  }
}
