import "package:typewriter_panel/typewriter_panel.dart";

/// Applies panel wide Material component defaults to [base].
///
/// [colors], [spacing], [shapes], [states], and [text] must come from the
/// same theme build. Keeping these inputs explicit prevents component defaults from
/// silently diverging from the extensions exposed to widgets.
ThemeData applyComponentThemes(
  ThemeData base,
  TypewriterColors colors,
  TypewriterSpacing spacing,
  TypewriterShapes shapes,
  TypewriterStateTokens states,
  TypewriterText text,
) {
  final surfaceColor = colors.surface;
  final ring = BorderSide(color: colors.focusRing, width: shapes.ringWidth);
  // An empty check box or radio outlines in secondary content, never in the
  // focus colour; the ring layer shows focus.
  final unselectedSide = WidgetStateBorderSide.resolveWith(
    (values) => values.contains(WidgetState.selected)
        ? null
        : BorderSide(color: colors.contentSecondary, width: 2),
  );
  final input = InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(horizontal: spacing.space3),
    border: OutlineInputBorder(
      borderRadius: shapes.mediumBorderRadius,
      borderSide: BorderSide.none,
    ),
    fillColor: Color.alphaBlend(
      base.brightness == Brightness.light
          ? colors.contentPrimary.withValues(alpha: 0.05)
          : colors.shadow.withValues(alpha: 0.2),
      surfaceColor,
    ),
    filled: true,
    hoverColor: colors.shadow.withValues(alpha: 0.1),
    errorStyle: text.sentenceSmall.copyWith(color: colors.dangerText),
    hintStyle: base.textTheme.bodyLarge?.copyWith(
      color: colors.contentSecondary,
    ),
    // The ring layer hides while a field is typed in, so the field shows
    // its own focused border.
    focusedBorder: OutlineInputBorder(
      borderRadius: shapes.mediumBorderRadius,
      borderSide: ring,
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
    helperStyle: text.sentenceSmall.copyWith(color: colors.contentSecondary),
  );
  // The query suggestions and the drop chooser still list MenuItemButtons.
  ButtonStyle menuItem(Color foreground) => ButtonStyle(
    // Unavailable text keeps 4.5:1.
    foregroundColor: WidgetStateProperty.resolveWith(
      (values) => values.contains(WidgetState.disabled)
          ? colors.contentSecondary
          : foreground,
    ),
    overlayColor: states.overlay(foreground),
    shape: WidgetStatePropertyAll(shapes.mediumShape),
    textStyle: WidgetStatePropertyAll(base.textTheme.labelLarge),
    iconSize: const WidgetStatePropertyAll(18),
  );
  return base.copyWith(
    scaffoldBackgroundColor: colors.canvas,
    // The Material that stays draws no ink: a press is the Button's move and
    // focus is the ring layer's ring, never a wash.
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
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
      contentTextStyle: text.sentence.copyWith(color: colors.contentPrimary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceRaised,
      modalBarrierColor: colors.scrim,
      shape: shapes.largeShape,
    ),
    dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.selection,
      selectionColor: colors.selectionContainer,
      selectionHandleColor: colors.selection,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.brand,
      linearTrackColor: colors.surfaceEmphasized,
      circularTrackColor: colors.surfaceEmphasized,
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
    menuButtonTheme: MenuButtonThemeData(
      style: menuItem(colors.contentPrimary).copyWith(
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
    // The query bar's suggestion list reads this menu style.
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
      splashFactory: NoSplash.splashFactory,
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
      side: unselectedSide,
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
      side: unselectedSide,
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
