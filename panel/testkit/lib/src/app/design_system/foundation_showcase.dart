import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class FoundationShowcase extends StatelessWidget {
  const FoundationShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colors;
    final textStyles = <String, TextStyle?>{
      "Display large": theme.textTheme.displayLarge,
      "Display medium": theme.textTheme.displayMedium,
      "Display small": theme.textTheme.displaySmall,
      "Headline large": theme.textTheme.headlineLarge,
      "Headline medium": theme.textTheme.headlineMedium,
      "Headline small": theme.textTheme.headlineSmall,
      "Title large": theme.textTheme.titleLarge,
      "Title medium": theme.textTheme.titleMedium,
      "Title small": theme.textTheme.titleSmall,
      "Body large": theme.textTheme.bodyLarge,
      "Body medium": theme.textTheme.bodyMedium,
      "Body small": theme.textTheme.bodySmall,
      "Label large": theme.textTheme.labelLarge,
      "Label medium": theme.textTheme.labelMedium,
      "Label small": theme.textTheme.labelSmall,
    };
    final palette = <String, Color>{
      "Brand": colors.brand,
      "Accent": colors.accent,
      "Canvas": colors.canvas,
      "Panel": colors.panel,
      "Surface": colors.surface,
      "Container": colors.surfaceContainer,
      "Raised": colors.surfaceRaised,
      "Emphasized": colors.surfaceEmphasized,
      "Primary content": colors.contentPrimary,
      "Secondary content": colors.contentSecondary,
      "Disabled": colors.contentDisabled,
      "Border": colors.border,
      "Divider": colors.divider,
      "Focus": colors.focusRing,
      "Selection": colors.selection,
      "Info": colors.info,
      "Success": colors.success,
      "Warning": colors.warning,
      "Danger": colors.danger,
      "Online": colors.online,
      "Offline": colors.offline,
    };
    return SizedBox(
      width: 1200,
      height: 900,
      child: ColoredBox(
        color: colors.canvas,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: textStyles.entries
                      .map((entry) => Text(entry.key, style: entry.value))
                      .toList(),
                ),
              ),
              SizedBox(width: context.spacing.space6),
              Expanded(
                child: Wrap(
                  spacing: context.spacing.space2,
                  runSpacing: context.spacing.space2,
                  children: palette.entries
                      .map(
                        (entry) => Container(
                          width: 132,
                          height: 72,
                          padding: EdgeInsets.all(context.spacing.space2),
                          decoration: BoxDecoration(
                            color: entry.value,
                            borderRadius: context.shapes.mediumBorderRadius,
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Text(
                            entry.key,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  ThemeData.estimateBrightnessForColor(
                                        entry.value,
                                      ) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
