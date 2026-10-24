import "package:typewriter_panel/typewriter_panel.dart";

/// Initializes Flutter and global platform services before mounting the panel.
///
/// Storage and Rive are initialized together because neither depends on the
/// other. [ProviderScope] is created here so every provider observes the same
/// application container, including the production retry policy.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([initLocalStorage(), RiveNative.init()]);

  runApp(
    ProviderScope(
      retry: kDebugMode
          ? (retryCount, error) => null
          : ProviderContainer.defaultRetry,
      child: const TypewriterPanel(),
    ),
  );
}
