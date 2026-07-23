import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Reusable shell for All Mock applications.
class FakeApp extends StatelessWidget {
  const FakeApp({
    required this.child,
    this.overrides = const [],
    this.shortcuts,
    this.actions,
    this.themeMode,
    this.locale,
    super.key,
  });

  final Widget child;
  final List<Override> overrides;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final ThemeMode? themeMode;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final ancestorBrightness = Theme.maybeBrightnessOf(context);
    final resolvedThemeMode =
        themeMode ??
        switch (ancestorBrightness) {
          Brightness.dark => ThemeMode.dark,
          _ => ThemeMode.light,
        };
    return ProviderScope(
      overrides: overrides,
      // Disable retry logic for both tests and widgetbooks to make them more deterministic.
      retry: (retryCount, error) => null,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: resolvedThemeMode,
        locale: locale,
        scrollBehavior: GlobalCustomScrollBehavior(),
        shortcuts: shortcuts ?? typewriterShortcuts,
        actions: actions,
        builder: (context, innerChild) {
          return Responsive(child: innerChild ?? const SizedBox.shrink());
        },
        home: Scaffold(
          body: AppRequiredWidgets(child: Center(child: child)),
        ),
      ),
    );
  }
}
