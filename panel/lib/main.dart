import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:localstorage/localstorage.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:rive/rive.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/appearance.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/fonts.dart";
import "package:typewriter_panel/widgets/app/components/app_required.dart";
import "package:typewriter_panel/widgets/app/components/nats_connection.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/app/components/sign_out_button.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";
import "package:typewriter_panel/widgets/generic/screens/loading_screen.dart";
import "package:uuid/uuid.dart";

const uuid = Uuid();
final random = Random();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([initLocalStorage(), RiveNative.init()]);

  runApp(const ProviderScope(child: TypewriterPanel()));
}

class TypewriterPanel extends HookConsumerWidget {
  const TypewriterPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appearanceProvider);

    return AppRequiredWidgets(
      child: _EagerInitialization(
        child: MaterialApp.router(
          title: "Typewriter",
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: themeMode,
          routerConfig: router.config(
            navigatorObservers: () => [
              InvalidatorNavigatorObserver(() async {
                // We don't want to invalidate during the build phase, so we wait
                await WidgetsBinding.instance.endOfFrame;
                ref.invalidate(routeParamProvider);
              }),
              LoggerNavigatorObserver(),
            ],
          ),
          shortcuts: typewriterShortcuts,
          scrollBehavior: GlobalCustomScrollBehavior(),
          builder: (context, child) => Responsive(
            child: RequiredNatsConnection(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  static Map<ShortcutActivator, Intent>
  typewriterShortcuts = <ShortcutActivator, Intent>{
    // Default Shortcuts
    ...WidgetsApp.defaultShortcuts,

    SingleActivator(LogicalKeyboardKey.keyV): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, shift: true): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.enter, shift: true): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter, shift: true):
        ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space, shift: true): ActivateIntent(),

    // Focus Navigation
    SingleActivator(LogicalKeyboardKey.keyN, control: true): NextFocusIntent(),
    SingleActivator(LogicalKeyboardKey.keyP, control: true):
        PreviousFocusIntent(),

    // Scroll Navigation
    SingleActivator(LogicalKeyboardKey.pageUp): ScrollIntent(
      direction: AxisDirection.down,
      type: ScrollIncrementType.page,
    ),
    SingleActivator(LogicalKeyboardKey.pageDown): ScrollIntent(
      direction: AxisDirection.up,
      type: ScrollIncrementType.page,
    ),
    SingleActivator(LogicalKeyboardKey.keyU, control: true): ScrollIntent(
      direction: AxisDirection.up,
      type: ScrollIncrementType.page,
    ),
    SingleActivator(LogicalKeyboardKey.keyD, control: true): ScrollIntent(
      direction: AxisDirection.down,
      type: ScrollIncrementType.page,
    ),

    // Pane Navigation
    SingleActivator(LogicalKeyboardKey.keyH, control: true): NavigatePaneIntent(
      AxisDirection.left,
    ),
    SingleActivator(LogicalKeyboardKey.keyL, control: true): NavigatePaneIntent(
      AxisDirection.right,
    ),
    SingleActivator(LogicalKeyboardKey.keyJ, control: true): NavigatePaneIntent(
      AxisDirection.down,
    ),
    SingleActivator(LogicalKeyboardKey.keyK, control: true): NavigatePaneIntent(
      AxisDirection.up,
    ),
    SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
        NavigatePaneIntent(AxisDirection.left),
    SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
        NavigatePaneIntent(AxisDirection.right),
    SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
        NavigatePaneIntent(AxisDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
        NavigatePaneIntent(AxisDirection.up),

    // Delete Intent
    SingleActivator(LogicalKeyboardKey.keyD): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.backspace): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.keyX): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.keyD, shift: true): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.backspace, shift: true): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.delete, shift: true): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, shift: true): DeleteIntent(),
  };
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

List<ShortcutActivator> shortcutsFor(Type intent) {
  return TypewriterPanel.typewriterShortcuts.entries
      .where((entry) => entry.value.runtimeType == intent)
      .map((entry) => entry.key)
      .toList();
}

List<ShortcutActivator> shortcutsForIntent<I extends Intent>(
  bool Function(I intent) predicate,
) {
  return TypewriterPanel.typewriterShortcuts.entries
      .where((entry) => entry.value is I && predicate(entry.value as I))
      .map((entry) => entry.key)
      .toList();
}

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

class Responsive extends StatelessWidget {
  const Responsive({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: 1000, name: TABLET),
        Breakpoint(start: 1001, end: 1920, name: DESKTOP),
        Breakpoint(start: 1921, end: double.infinity, name: "4K"),
      ],
      child: child,
    );
  }
}

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  (T?, Widget?) require<T>(AsyncValue<T> value) {
    if (value.hasError) {
      return (null, _Error(value.error!));
    }
    if (value.isLoading) {
      return (null, const _Loading());
    }
    return (value.value, null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (isAuthenticated, widget) = require(
      ref.watch(isAuthenticatedProvider),
    );
    if (widget != null) {
      return widget;
    }
    if (isAuthenticated != true) {
      return child;
    }

    final (token, widget2) = require(ref.watch(accessTokenProvider));
    if (widget2 != null) {
      return widget2;
    }
    if (token == null) {
      return child;
    }

    final (_, widget3) = require(ref.watch(authUserInfoProvider));
    if (widget3 != null) {
      return widget3;
    }

    return child;
  }
}

class _Loading extends HookWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TypeWriter",
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => Responsive(child: child!),
      home: const LoadingScreen(title: "Authenticating User"),
    );
  }
}

class _Error extends HookConsumerWidget {
  const _Error(this.error);
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: "TypeWriter",
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => Responsive(child: child!),
      home: ErrorScreen(
        title: "Error",
        message:
            "Something went wrong, please report this to the Typewriter discord. $error",
        child: SignOutButton(),
      ),
    );
  }
}

class GlobalCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}
