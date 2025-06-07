import "package:flutter/material.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/fonts.dart";

/// A prominent page heading with optional subtext for context.
class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.title,
    this.subtext,
    super.key,
  });

  final String title;
  final String? subtext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        if (subtext != null && subtext!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              subtext!,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: context.responsive(
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
            ),
          ),
      ],
    );
  }
}
