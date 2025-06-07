import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:localstorage/localstorage.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/appearance.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/utils/fonts.dart";
import "package:typewriter_panel/widgets/generic/components/nats_connection.dart";
import "package:typewriter_panel/widgets/generic/components/sign_out_button.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";
import "package:typewriter_panel/widgets/generic/screens/loading_screen.dart";

final random = Random();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();

  runApp(const ProviderScope(child: TypewriterPanel()));
}

class TypewriterPanel extends HookConsumerWidget {
  const TypewriterPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appearanceProvider);

    return _EagerInitialization(
      child: MaterialApp.router(
        title: "Typewriter",
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeMode,
        routerConfig: router.config(),
        shortcuts: WidgetsApp.defaultShortcuts,
        builder: (context, child) => Responsive(
          child: RequiredNatsConnection(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final baseTheme = ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: brightness,
      error: Colors.redAccent,
      surface: brightness == Brightness.light
          ? const Color(0xFFF5F5F5)
          : const Color(0xFF141218),
      onSurfaceVariant: brightness == Brightness.light
          ? const Color(0xFF6c6d76)
          : const Color(0xFFC4C6D0),
      surfaceContainerLowest: brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF1F2123),
      surfaceContainer: brightness == Brightness.light
          ? const Color(0xFFF3EDF7)
          : const Color(0xFF1f1d23),
    ),
  );

  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: "JetBrainsMono").copyWith(
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
        ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      fillColor: brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.2),
      filled: true,
      hoverColor: Colors.black.withValues(alpha: 0.1),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      hintStyle: TextStyle(
        color: brightness == Brightness.light
            ? const Color(0x99000000)
            : const Color(0x99FFFFFF),
        fontSize: 16,
        fontVariations: const [normalWeight],
      ),
      prefixIconColor: brightness == Brightness.light
          ? const Color(0x99000000)
          : const Color(0x99FFFFFF),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.redAccent.shade200, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    ),
    hoverColor: Colors.black.withValues(alpha: 0.1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      strokeCap: StrokeCap.round,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.zero,
      ),
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
        Breakpoint(start: 451, end: 800, name: TABLET),
        Breakpoint(start: 801, end: 1920, name: DESKTOP),
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
    final (isAuthenticated, widget) =
        require(ref.watch(isAuthenticatedProvider));
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
