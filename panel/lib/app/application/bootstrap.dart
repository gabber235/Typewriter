import "package:typewriter_panel/typewriter_panel.dart";

/// Initializes the global platform services the panel needs before its first
/// frame.
///
/// Storage and Rive are initialized together because neither depends on the
/// other. [bootstrap] and the end to end harness both call this, so scenarios
/// boot the same panel users run.
Future<void> initializePanel() async {
  await Future.wait([initLocalStorage(), RiveNative.init()]);
}

/// The provider retry policy of the application container.
///
/// Debug builds never retry, so failures surface immediately while developing.
Duration? panelRetry(int retryCount, Object error) =>
    kDebugMode ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Initializes Flutter and global platform services before mounting the panel.
///
/// [ProviderScope] is created here so every provider observes the same
/// application container, including the production retry policy.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializePanel();

  runApp(
    ProviderScope(
      overrides: appOverrides(),
      retry: panelRetry,
      child: const TypewriterPanel(),
    ),
  );
}
