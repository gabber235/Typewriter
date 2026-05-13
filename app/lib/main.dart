import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:stack_trace/stack_trace.dart" as stack_trace;
import "package:typewriter/app_router.dart";
import "package:typewriter/l10n/locale_provider.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:typewriter/l10n/app_localizations.dart";
import "package:typewriter/utils/fonts.dart";
import "package:typewriter/widgets/components/general/toasts.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:uuid/uuid.dart";

const uuid = Uuid();
const mcmetaUrl = "https://raw.githubusercontent.com/misode/mcmeta";

void main() async {
  FlutterError.demangleStackTrace = (stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };

  runApp(
    const ProviderScope(
      // observers: [if (kDebugMode) Logger()],
      child: TypeWriterApp(),
    ),
  );
}

class TypeWriterApp extends HookConsumerWidget {
  const TypeWriterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouter);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: "TypeWriter",
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      debugShowCheckedModeBanner: false,
      routerConfig: router.config(
        navigatorObservers: () => <NavigatorObserver>[
          InvalidatorNavigatorObserver(
            () async {
              // We don't want to invalidate during the build phase, so we wait
              await WidgetsBinding.instance.endOfFrame;
              ref.invalidate(currentRouteDataProvider);
            },
          ),
        ],
      ),
      shortcuts: WidgetsApp.defaultShortcuts,
      builder: (_, child) => ToastDisplay(child: child),
    );
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
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
        ),
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
}

class Logger extends ProviderObserver {
  const Logger();
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "field": "${provider is FieldValueProvider ? provider.path : "none"}",
  "previousValue": "$previousValue",
  "newValue": "$newValue"
}''');
  }
}
