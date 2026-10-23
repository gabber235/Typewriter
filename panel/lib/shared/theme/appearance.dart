import "package:typewriter_panel/typewriter_panel.dart";

part "appearance.g.dart";

const _storageKey = "appearance_mode";

/// Stores the panel's theme preference and exposes it to the application shell.
///
/// The preference is read from browser or platform storage when the provider is
/// first built. [mode] updates both storage and the provider state so the shell
/// changes theme immediately and keeps the choice for the next launch.
@riverpod
class Appearance extends _$Appearance {
  @override
  ThemeMode build() {
    final savedMode = localStorage.getItem(_storageKey);

    switch (savedMode) {
      case "light":
        return ThemeMode.light;
      case "dark":
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Selects [mode] and persists the selection for future launches.
  void mode(ThemeMode mode) {
    String? value;

    switch (mode) {
      case ThemeMode.light:
        value = "light";
      case ThemeMode.dark:
        value = "dark";
      case ThemeMode.system:
        value = "system";
    }

    localStorage.setItem(_storageKey, value);
    state = mode;
  }
}
