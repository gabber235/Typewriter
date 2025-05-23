import "package:flutter/material.dart";

class OrganizationIcon extends StatelessWidget {
  const OrganizationIcon({
    super.key,
    this.iconUrl,
    this.size = 40,
    this.borderRadius = 8,
  });
  final String? iconUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (iconUrl == null) {
      return _buildPlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(error.toString());
          return _buildPlaceholder(context);
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.business,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
