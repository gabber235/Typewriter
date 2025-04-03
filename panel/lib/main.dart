import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:localstorage/localstorage.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/utils/fonts.dart";

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
    return _EagerInitialization(
      child: MaterialApp.router(
        title: "TypeWriter",
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        routerConfig: router.config(),
        shortcuts: WidgetsApp.defaultShortcuts,
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final baseTheme = ThemeData(brightness: brightness);

  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: "JetBrainsMono"),
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
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: Colors.blueAccent,
      brightness: brightness,
      error: Colors.redAccent,
      surfaceContainer: brightness == Brightness.light
          ? const Color(0xFFF3EDF7)
          : const Color(0xFF1f1d23),
    ),
  );
}

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(isAuthenticatedProvider);

    if (result.isLoading) {
      return _Loading();
    } else if (result.hasError) {
      return _Error(result.error!);
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
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _Error extends HookWidget {
  const _Error(this.error);
  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TypeWriter",
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: Scaffold(
        body: Center(
          child: Text("Error: $error"),
        ),
      ),
    );
  }
}
