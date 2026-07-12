import "package:flutter/material.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/appearance.dart";

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
