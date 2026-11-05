import "package:typewriter_panel/typewriter_panel.dart";

/// The theme preference storage of a test world.
///
/// Replaces the platform storage the panel keeps the user's theme mode in;
/// choosing a mode in the panel changes it here.
final class FakeAppearance {
  FakeAppearance([this.mode = ThemeMode.light]);

  ThemeMode mode;

  /// Replaces the stored theme preference.
  Override get override => appearanceProvider.overrideWith(() => _Stored(this));
}

final class _Stored extends Appearance {
  _Stored(this._storage);

  final FakeAppearance _storage;

  @override
  ThemeMode build() => _storage.mode;

  @override
  void mode(ThemeMode mode) {
    _storage.mode = mode;
    state = mode;
  }
}
