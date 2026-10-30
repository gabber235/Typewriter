import "package:typewriter_panel/typewriter_panel.dart";

/// The Rive renderer of a test world.
///
/// Tests run without the native Rive library, so every Rive asset renders as
/// an empty box instead of loading.
final class FakeRive {
  const FakeRive();

  /// Replaces the Rive runtime renderer.
  Override get override =>
      riveRendererProvider.overrideWithValue(const _EmptyRive());
}

final class _EmptyRive implements RiveRenderer {
  const _EmptyRive();

  @override
  Widget render(RiveAsset asset) => const SizedBox.shrink();
}
