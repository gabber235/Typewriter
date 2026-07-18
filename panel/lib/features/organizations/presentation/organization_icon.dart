import "package:flutter/material.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";

class OrganizationLogo extends StatelessWidget {
  const OrganizationLogo({
    super.key,
    this.logoUrl,
    this.size = 40,
    this.borderRadius = 8,
  });
  final String? logoUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null) {
      return _buildPlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        logoUrl!,
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
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Surface(
      color: color,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.business,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
