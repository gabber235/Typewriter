import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/shared/utilities/color.dart";
import "package:typewriter_panel/shared/utilities/fonts.dart";

ThemeData buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final baseTheme = ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF009FFF),
      secondary: Colors.orange,
      secondaryContainer: isLight
          ? Colors.orangeAccent.shade100
          : Colors.deepOrange.shade700,
      onSecondaryContainer: Colors.deepOrange.shade700.onBrightness(brightness),
      error: Colors.redAccent,
      onError: Colors.black,
      brightness: brightness,
      surface: isLight ? const Color(0xFFF5F5F5) : const Color(0xFF141218),
      onSurfaceVariant: isLight
          ? const Color(0xFF6c6d76)
          : const Color(0xFFC4C6D0),
      surfaceContainerLowest: isLight
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF1F2123),
      surfaceContainer: isLight
          ? const Color(0xFFF3EDF7)
          : const Color(0xFF1f1d23),
    ),
  );

  final textTheme = baseTheme.textTheme
      .apply(fontFamily: "JetBrainsMono")
      .copyWith(
        labelLarge: TextStyle(
          fontFamily: "JetBrainsMono",
          color: baseTheme.colorScheme.onSurface,
          fontSize: 14,
          letterSpacing: 0.5,
          fontVariations: [FontVariation("wght", 700)],
        ),
        labelMedium: TextStyle(
          fontFamily: "JetBrainsMono",
          color: baseTheme.colorScheme.onSurface,
          fontSize: 13,
          letterSpacing: 0.5,
          fontVariations: [FontVariation("wght", 700)],
        ),
        labelSmall: TextStyle(
          fontFamily: "JetBrainsMono",
          color: baseTheme.colorScheme.onSurface,
          fontSize: 12,
          letterSpacing: 0.5,
          fontVariations: [FontVariation("wght", 700)],
        ),
        bodySmall: TextStyle(
          fontFamily: "JetBrainsMono",
          color: isLight
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.6),
          fontSize: 11,
          letterSpacing: 0.2,
          fontVariations: [FontVariation("wght", 300)],
        ),
      );

  final inputDecorationTheme = InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    fillColor: isLight
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.2),
    filled: true,
    hoverColor: Colors.black.withValues(alpha: 0.1),
    errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    hintStyle: TextStyle(
      color: isLight ? const Color(0x99000000) : const Color(0x99FFFFFF),
      fontSize: 16,
      fontVariations: const [normalWeight],
    ),
    prefixIconColor: isLight
        ? const Color(0x99000000)
        : const Color(0x99FFFFFF),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.redAccent.shade200, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: inputDecorationTheme,
    tooltipTheme: TooltipThemeData(
      preferBelow: false,
      triggerMode: TooltipTriggerMode.longPress,
      verticalOffset: 32,
      waitDuration: 100.ms,
      decoration: BoxDecoration(
        color: baseTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: baseTheme.colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: baseTheme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: isLight ? FontWeight.w400 : FontWeight.w200,
      ),
    ),
    hoverColor: Colors.black.withValues(alpha: 0.1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      strokeCap: StrokeCap.round,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: baseTheme.colorScheme.onPrimary,
        disabledForegroundColor: baseTheme.colorScheme.onSurface.withValues(
          alpha: 0.38,
        ),
        iconSize: 18,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: baseTheme.colorScheme.primary,
        disabledForegroundColor: baseTheme.colorScheme.onSurface.withValues(
          alpha: 0.38,
        ),
        iconSize: 18,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: baseTheme.colorScheme.primary,
        disabledForegroundColor: baseTheme.colorScheme.onSurface.withValues(
          alpha: 0.38,
        ),
        iconSize: 18,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.zero,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      disabledElevation: 0,
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: MenuItemButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        iconSize: 16,
        textStyle: textTheme.bodySmall?.copyWith(fontSize: 12),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevation: WidgetStatePropertyAll(1),
        visualDensity: VisualDensity.defaultDensityForPlatform(
          defaultTargetPlatform,
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: inputDecorationTheme,
      menuStyle: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
        elevation: WidgetStatePropertyAll(1),
        minimumSize: WidgetStatePropertyAll<Size>(Size(112, 0.0)),
        maximumSize: WidgetStatePropertyAll<Size>(Size.infinite),
        visualDensity: VisualDensity.standard,
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(style: BorderStyle.none),
      shape: StadiumBorder(),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: baseTheme.colorScheme.onPrimaryContainer,
      unselectedLabelColor: baseTheme.colorScheme.onSurfaceVariant,
      indicator: ShapeDecoration(
        color: baseTheme.colorScheme.surfaceContainerHighest,
        shape: StadiumBorder(),
      ),
      indicatorAnimation: TabIndicatorAnimation.elastic,
      splashBorderRadius: BorderRadius.circular(100),
      splashFactory: InkSplash.splashFactory,
      labelPadding: EdgeInsets.symmetric(horizontal: 8),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: baseTheme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
