import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_colors.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_shapes.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_spacing.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_state_tokens.dart";

ThemeData applyComponentThemes(
  ThemeData base,
  TypewriterColors colors,
  TypewriterSpacing spacing,
  TypewriterShapes shapes,
  TypewriterStateTokens states,
) {
  final input = InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(horizontal: spacing.space3),
    border: OutlineInputBorder(
      borderRadius: shapes.mediumBorderRadius,
      borderSide: BorderSide.none,
    ),
    fillColor: base.brightness == Brightness.light
        ? colors.contentPrimary.withValues(alpha: 0.05)
        : colors.shadow.withValues(alpha: 0.2),
    filled: true,
    hoverColor: colors.shadow.withValues(alpha: 0.1),
    errorStyle: base.textTheme.bodySmall?.copyWith(color: colors.danger),
    hintStyle: base.textTheme.bodyLarge?.copyWith(
      color: colors.contentPrimary.withValues(alpha: 0.6),
    ),
    prefixIconColor: colors.contentPrimary.withValues(alpha: 0.6),
    errorBorder: OutlineInputBorder(
      borderRadius: shapes.mediumBorderRadius,
      borderSide: BorderSide(color: colors.danger, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: shapes.mediumBorderRadius,
      borderSide: BorderSide(color: colors.danger, width: 2),
    ),
  );
  ButtonStyle button(Color foreground) => ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith(
      (values) => values.contains(WidgetState.disabled)
          ? colors.contentDisabled
          : foreground,
    ),
    overlayColor: states.overlay(foreground),
    shape: WidgetStatePropertyAll(shapes.mediumShape),
    textStyle: WidgetStatePropertyAll(base.textTheme.labelLarge),
    iconSize: const WidgetStatePropertyAll(18),
  );
  return base.copyWith(
    scaffoldBackgroundColor: colors.canvas,
    hoverColor: colors.contentPrimary.withValues(alpha: states.hoverOpacity),
    focusColor: colors.focusRing.withValues(alpha: states.focusOpacity),
    highlightColor: colors.contentPrimary.withValues(
      alpha: states.pressedOpacity,
    ),
    splashColor: colors.contentPrimary.withValues(alpha: states.pressedOpacity),
    inputDecorationTheme: input,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.canvas,
      foregroundColor: colors.contentPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: colors.contentPrimary,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceRaised,
      shape: shapes.largeShape,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceRaised,
      modalBarrierColor: colors.scrim,
      shape: shapes.largeShape,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceEmphasized,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: colors.contentPrimary,
      ),
      shape: shapes.mediumShape,
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.selection,
      selectionColor: colors.selectionContainer,
      selectionHandleColor: colors.selection,
    ),
    tooltipTheme: TooltipThemeData(
      preferBelow: false,
      triggerMode: TooltipTriggerMode.longPress,
      verticalOffset: spacing.space8,
      waitDuration: 100.ms,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.16),
            blurRadius: spacing.space1,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: shapes.mediumBorderRadius,
      ),
      textStyle: base.textTheme.bodySmall?.copyWith(
        color: colors.contentPrimary,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.brand,
      strokeCap: StrokeCap.round,
    ),
    listTileTheme: ListTileThemeData(
      shape: shapes.mediumShape,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing.space2,
        vertical: spacing.space1,
      ),
      textColor: colors.contentPrimary,
      iconColor: colors.contentSecondary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: button(colors.onBrand).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (values) => values.contains(WidgetState.disabled)
              ? colors.brand.withValues(alpha: states.disabledContainerOpacity)
              : colors.brand,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: button(colors.onBrand).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (values) => values.contains(WidgetState.disabled)
              ? colors.brand.withValues(alpha: states.disabledContainerOpacity)
              : colors.brand,
        ),
        elevation: WidgetStateProperty.resolveWith(
          (values) => values.contains(WidgetState.disabled) ? 0 : 1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: button(colors.brand)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button(colors.brand).copyWith(
        side: WidgetStateProperty.resolveWith(
          (values) => BorderSide(
            color: values.contains(WidgetState.disabled)
                ? colors.brand.withValues(
                    alpha: states.disabledContainerOpacity,
                  )
                : colors.brand,
          ),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: button(
        colors.contentPrimary,
      ).copyWith(padding: const WidgetStatePropertyAll(EdgeInsets.zero)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.brandContainer,
      foregroundColor: colors.onBrandContainer,
      disabledElevation: 0,
      shape: shapes.largeShape,
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: button(colors.contentPrimary).copyWith(
        shape: WidgetStatePropertyAll(shapes.smallShape),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: spacing.space2,
            vertical: spacing.space1,
          ),
        ),
        iconSize: const WidgetStatePropertyAll(16),
        textStyle: WidgetStatePropertyAll(base.textTheme.labelSmall),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surfaceRaised),
        shape: WidgetStatePropertyAll(shapes.mediumShape),
        elevation: const WidgetStatePropertyAll(1),
        visualDensity: VisualDensity.defaultDensityForPlatform(
          defaultTargetPlatform,
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: input,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surfaceRaised),
        shape: WidgetStatePropertyAll(shapes.mediumShape),
        padding: WidgetStatePropertyAll(EdgeInsets.all(spacing.space1)),
        elevation: const WidgetStatePropertyAll(1),
        minimumSize: const WidgetStatePropertyAll(Size(112, 0)),
        maximumSize: const WidgetStatePropertyAll(Size.infinite),
        visualDensity: VisualDensity.standard,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceContainer,
      selectedColor: colors.selectionContainer,
      side: BorderSide.none,
      shape: shapes.pill,
      labelStyle: base.textTheme.labelMedium,
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: colors.onSelectionContainer,
      unselectedLabelColor: colors.contentSecondary,
      indicator: ShapeDecoration(
        color: colors.selectionContainer,
        shape: shapes.pill,
      ),
      indicatorAnimation: TabIndicatorAnimation.elastic,
      splashBorderRadius: BorderRadius.circular(100),
      splashFactory: InkSplash.splashFactory,
      labelPadding: EdgeInsets.symmetric(horizontal: spacing.space2),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surfaceContainer,
      shape: shapes.mediumShape,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((values) {
        if (values.contains(WidgetState.disabled)) {
          return colors.brand.withValues(
            alpha: states.disabledContainerOpacity,
          );
        }
        return values.contains(WidgetState.selected) ? colors.brand : null;
      }),
      checkColor: WidgetStateProperty.resolveWith(
        (values) => values.contains(WidgetState.disabled)
            ? colors.contentDisabled
            : colors.onBrand,
      ),
      overlayColor: states.overlay(colors.brand),
      shape: shapes.smallShape,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((values) {
        if (values.contains(WidgetState.disabled)) {
          return colors.contentPrimary.withValues(
            alpha: states.disabledForegroundOpacity,
          );
        }
        return values.contains(WidgetState.selected)
            ? colors.brand
            : colors.contentSecondary;
      }),
      overlayColor: states.overlay(colors.brand),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((values) {
        if (values.contains(WidgetState.disabled)) {
          return colors.contentDisabled;
        }
        return values.contains(WidgetState.selected)
            ? colors.onBrand
            : colors.contentSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((values) {
        if (values.contains(WidgetState.disabled)) {
          return colors.contentPrimary.withValues(
            alpha: states.disabledContainerOpacity,
          );
        }
        return values.contains(WidgetState.selected)
            ? colors.brand
            : colors.surfaceEmphasized;
      }),
      overlayColor: states.overlay(colors.brand),
    ),
  );
}
