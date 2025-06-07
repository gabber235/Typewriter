import "package:flutter/material.dart";
import "package:localstorage/localstorage.dart";
import "package:mocktail/mocktail.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "appearance.g.dart";

const _storageKey = "appearance_mode";

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

// ignore: prefer_mixin
class AppearanceMock extends _$Appearance with Mock implements Appearance {}
