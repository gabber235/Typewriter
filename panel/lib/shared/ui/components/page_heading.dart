import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// A prominent page heading with supporting subtext for context.
/// Includes responsive padding that adjusts based on screen size.
class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.title,
    required this.subtext,
    this.padding,
    super.key,
  });

  final String title;
  final String subtext;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final paddingValue = context.responsive(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Padding(
      padding:
          padding ??
          EdgeInsets.fromLTRB(paddingValue, paddingValue, paddingValue, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontVariations: const [boldWeight],
              letterSpacing: -1,
              fontSize: context.responsive(mobile: 24, tablet: 26, desktop: 28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              subtext,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: context.responsive(mobile: 10, tablet: 12),
                fontVariations: [FontVariation.weight(50)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
