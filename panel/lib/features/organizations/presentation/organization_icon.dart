import "package:typewriter_panel/typewriter_panel.dart";

/// The generated organization icon and the one way to pick another: pressing
/// it rolls a new one. Creating an organization and its settings both use
/// it.
///
/// [onRandomize] may be async, as when the settings page saves the new icon;
/// the icon is busy while it runs, and a failure shakes it and is reported.
class OrganizationIconPicker extends StatelessWidget {
  const OrganizationIconPicker({
    required this.iconUrl,
    required this.onRandomize,
    this.description =
        "For now, generated and can be randomized again by clicking the icon.",
    super.key,
  });

  final String? iconUrl;

  /// Rolls a new icon; null makes the picker unavailable.
  final FutureOr<void> Function()? onRandomize;

  /// The line under the Icon title that says what pressing does.
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Button(
      face: ButtonFace.bare,
      label: "Randomize icon",
      busyLabel: "Randomizing",
      onPressed: onRandomize,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space3),
        child: Row(
          children: [
            OrganizationLogo(logoUrl: iconUrl, size: 64),
            SizedBox(width: context.spacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: "Icon"),
                  SizedBox(height: context.spacing.space1),
                  Text(
                    description,
                    style: context.text.sentence.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A new icon for the organization [name]: the same name rolls a different
/// icon every time.
String randomOrganizationIconUrl(String name) {
  final seed = Random().nextInt(1000000).toString();
  return generateOrganizationIconUrl(name.isEmpty ? seed : name + seed);
}

/// Renders an organization logo with a stable placeholder recovery path.
///
/// Network failures and absent URLs are intentionally presentation failures. The
/// organization projection remains intact while the widget falls back to the
/// business icon, preventing a broken image from disrupting navigation.
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
