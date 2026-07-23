import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("identity colors stay stable between light and dark themes", () {
    final light = buildTheme(Brightness.light).colors;
    final dark = buildTheme(Brightness.dark).colors;

    expect(
      [
        light.brand,
        light.accent,
        light.info,
        light.success,
        light.warning,
        light.danger,
        light.online,
      ],
      [
        dark.brand,
        dark.accent,
        dark.info,
        dark.success,
        dark.warning,
        dark.danger,
        dark.online,
      ],
    );
    expect(light.brand, const Color(0xFF009FFF));
    expect(light.accent, Colors.orange);
    expect(light.info, Colors.blue);
    expect(light.success, Colors.green);
    expect(light.warning, Colors.orange);
    expect(light.danger, Colors.redAccent);
    expect(light.brandContainer, isNot(dark.brandContainer));
  });

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      late ThemeData theme;
      setUp(() => theme = buildTheme(brightness));

      test("registers extensions and maps the color scheme", () {
        final colors = theme.colors;
        expect(
          theme.extensions.values,
          containsAll([
            isA<TypewriterColors>(),
            isA<TypewriterSpacing>(),
            isA<TypewriterShapes>(),
            isA<TypewriterStateTokens>(),
          ]),
        );
        final scheme = theme.colorScheme;
        expect(
          [
            scheme.primary,
            scheme.onPrimary,
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            scheme.secondary,
            scheme.onSecondary,
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
            scheme.surface,
            scheme.onSurface,
            scheme.onSurfaceVariant,
            scheme.surfaceContainerLowest,
            scheme.surfaceContainerLow,
            scheme.surfaceContainer,
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerHighest,
            scheme.outline,
            scheme.outlineVariant,
            scheme.error,
            scheme.onError,
            scheme.errorContainer,
            scheme.onErrorContainer,
            scheme.shadow,
            scheme.scrim,
          ],
          [
            colors.brand,
            colors.onBrand,
            colors.brandContainer,
            colors.onBrandContainer,
            colors.accent,
            colors.onAccent,
            colors.accentContainer,
            colors.onAccentContainer,
            colors.canvas,
            colors.contentPrimary,
            colors.contentSecondary,
            colors.surface,
            colors.panel,
            colors.surfaceContainer,
            colors.surfaceRaised,
            colors.surfaceEmphasized,
            colors.border,
            colors.borderSubtle,
            colors.danger,
            colors.onDanger,
            colors.dangerContainer,
            colors.onDangerContainer,
            colors.shadow,
            colors.scrim,
          ],
        );
        expect(colors.focusRing, colors.border);
        expect(
          colors.surface.computeLuminance(),
          greaterThan(colors.canvas.computeLuminance()),
          reason: "Sections should be lighter than their surroundings",
        );
        if (brightness == Brightness.dark) {
          expect(colors.panel, colors.canvas);
        }
      });

      test("defines the complete typography hierarchy", () {
        final styles = [
          theme.textTheme.displayLarge,
          theme.textTheme.displayMedium,
          theme.textTheme.displaySmall,
          theme.textTheme.headlineLarge,
          theme.textTheme.headlineMedium,
          theme.textTheme.headlineSmall,
          theme.textTheme.titleLarge,
          theme.textTheme.titleMedium,
          theme.textTheme.titleSmall,
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.bodySmall,
          theme.textTheme.labelLarge,
          theme.textTheme.labelMedium,
          theme.textTheme.labelSmall,
        ];
        expect(styles.map((style) => style!.fontFamily), [
          ...List.filled(9, "JetBrainsMono"),
          ...List.filled(3, "Lilex"),
          ...List.filled(3, "JetBrainsMono"),
        ]);
        expect(styles.map((style) => style!.fontSize), [
          40,
          36,
          32,
          28,
          26,
          22,
          20,
          16,
          14,
          16,
          14,
          12,
          14,
          13,
          11,
        ]);
        final lineHeights = styles
            .map((style) => style!.height! * style.fontSize!)
            .toList();
        final expectedHeights = [
          48,
          44,
          40,
          36,
          34,
          30,
          28,
          24,
          20,
          24,
          20,
          16,
          20,
          18,
          16,
        ];
        for (var index = 0; index < lineHeights.length; index++) {
          expect(lineHeights[index], closeTo(expectedHeights[index], 0.001));
        }
      });

      test("semantic colors meet WCAG contrast", () {
        final c = theme.colors;
        final pairs = [
          (c.brand, c.onBrand),
          (c.brandContainer, c.onBrandContainer),
          (c.accent, c.onAccent),
          (c.info, c.onInfo),
          (c.success, c.onSuccess),
          (c.warning, c.onWarning),
          (c.danger, c.onDanger),
          (c.online, c.onOnline),
          (c.offline, c.onOffline),
        ];
        for (final (background, foreground) in pairs) {
          expect(_contrast(background, foreground), greaterThanOrEqualTo(4.5));
        }
      });

      test("extensions support copy and interpolation", () {
        final other = buildTheme(
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
        );
        expect(
          theme.colors.copyWith(brand: Colors.purple).brand,
          Colors.purple,
        );
        expect(theme.spacing.copyWith(space1: 5).space1, 5);
        expect(theme.shapes.copyWith(small: 5).small, 5);
        expect(theme.states.copyWith(hoverOpacity: 0.2).hoverOpacity, 0.2);
        expect(theme.colors.lerp(other.colors, 0.5), isA<TypewriterColors>());
        expect(
          theme.spacing.lerp(other.spacing, 0.5),
          isA<TypewriterSpacing>(),
        );
        expect(theme.shapes.lerp(other.shapes, 0.5), isA<TypewriterShapes>());
        expect(
          theme.states.lerp(other.states, 0.5),
          isA<TypewriterStateTokens>(),
        );
      });

      test("component themes resolve enabled and disabled controls", () {
        final disabled = {WidgetState.disabled};
        final enabled = <WidgetState>{};
        final button = theme.filledButtonTheme.style!;
        expect(button.shape!.resolve(enabled), theme.shapes.mediumShape);
        expect(button.foregroundColor!.resolve(enabled), isNotNull);
        expect(button.foregroundColor!.resolve(disabled), isNotNull);
        expect(button.backgroundColor!.resolve(disabled), isNotNull);
        final outlined = theme.outlinedButtonTheme.style!;
        expect(outlined.side!.resolve(enabled)?.color, theme.colors.brand);
        expect(
          outlined.side!.resolve(disabled)?.color,
          theme.colors.brand.withValues(
            alpha: theme.states.disabledContainerOpacity,
          ),
        );
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(
          theme.inputDecorationTheme.fillColor,
          brightness == Brightness.light
              ? theme.colors.contentPrimary.withValues(alpha: 0.05)
              : theme.colors.shadow.withValues(alpha: 0.2),
        );
        expect(
          theme.inputDecorationTheme.hoverColor,
          theme.colors.shadow.withValues(alpha: 0.1),
        );
        expect(theme.inputDecorationTheme.focusedBorder, isNull);
        expect(theme.cardTheme.shape, theme.shapes.mediumShape);
        expect(
          theme.appBarTheme.backgroundColor,
          theme.scaffoldBackgroundColor,
        );
        expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      });

      test("state precedence and disabled behavior are stable", () {
        final states = theme.states;
        final color = theme.colors.brand;
        expect(
          states.layer(color, {WidgetState.disabled, WidgetState.pressed}),
          isNull,
        );
        expect(
          states.layer(color, {WidgetState.pressed, WidgetState.focused}),
          color.withValues(alpha: states.pressedOpacity),
        );
        expect(
          states.layer(color, {WidgetState.dragged, WidgetState.focused}),
          color.withValues(alpha: states.draggedOpacity),
        );
        expect(
          states.layer(color, {WidgetState.focused, WidgetState.hovered}),
          states.focusRing.withValues(alpha: states.focusOpacity),
        );
      });
    });
  }
}

double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
