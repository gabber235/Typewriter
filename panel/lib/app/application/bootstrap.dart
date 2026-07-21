import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:localstorage/localstorage.dart";
import "package:rive/rive.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
