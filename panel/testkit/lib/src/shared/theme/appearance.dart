import "package:typewriter_panel/typewriter_panel.dart";

class AppearanceMock extends Appearance {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  @override
  void mode(ThemeMode mode) {
    state = mode;
  }
}

List<Override> appearanceProviderOverrides({AppearanceMock? mock}) => [
  appearanceProvider.overrideWith(() => mock ?? AppearanceMock()),
];
