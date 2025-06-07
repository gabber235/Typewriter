import "package:flutter/material.dart";
import "package:mocktail/mocktail.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/appearance.dart";

AppearanceMock createAppearanceMock() {
  final appearance = AppearanceMock();
  when(appearance.build).thenReturn(ThemeMode.system);
  when(() => appearance.mode(any())).thenAnswer((invocation) {
    debugPrint("mode: ${invocation.positionalArguments.first}");
  });
  return appearance;
}

List<Override> appearanceProviderOverrides({AppearanceMock? mock}) => [
  appearanceProvider.overrideWith(() => mock ?? createAppearanceMock()),
];
