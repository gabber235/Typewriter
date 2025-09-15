import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/widgets/app/components/app_required.dart";

/// Reusable shell for All Mock applications.
class FakeApp extends StatelessWidget {
  const FakeApp({
    required this.child,
    this.overrides = const [],
    this.shortcuts,
    this.actions,
    super.key,
  });

  final Widget child;
  final List<Override> overrides;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.maybeBrightnessOf(context);
    final themeMode = switch (brightness) {
      Brightness.light => ThemeMode.light,
      Brightness.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeMode,
        scrollBehavior: GlobalCustomScrollBehavior(),
        shortcuts: shortcuts ?? TypewriterPanel.typewriterShortcuts,
        actions: actions,
        builder: (context, innerChild) {
          return Responsive(child: innerChild ?? const SizedBox.shrink());
        },
        home: Scaffold(
          body: AppRequiredWidgets(
            child: Center(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
