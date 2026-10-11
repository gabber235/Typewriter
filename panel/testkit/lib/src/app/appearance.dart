import "package:typewriter_panel/typewriter_panel.dart";

// ignore: depend_on_referenced_packages, implementation_imports

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
