import "package:flutter/material.dart";
import "package:typewriter_panel/generated/models/module.pb.dart";
import "package:typewriter_panel/utils/context.dart";

extension ModuleTypeExtensions on ModuleType {
  /// Display name for this module type
  String get displayName => switch (this) {
    ModuleType.MODULE_TYPE_ENGINE => "Engine",
    ModuleType.MODULE_TYPE_EXTENSION => "Extension",
    _ => "Unknown",
  };

  /// Light theme color for this module type
  Color get lightColor => switch (this) {
    ModuleType.MODULE_TYPE_ENGINE => Colors.blue,
    ModuleType.MODULE_TYPE_EXTENSION => Colors.green,
    _ => Colors.grey,
  };

  /// Dark theme color for this module type
  Color get darkColor => lightColor;

  /// Documentation URL for this module type
  String get docsUrl => switch (this) {
    ModuleType.MODULE_TYPE_ENGINE => "https://docs.typewritermc.com/develop",
    ModuleType.MODULE_TYPE_EXTENSION =>
      "https://docs.typewritermc.com/develop/extensions",
    _ => "",
  };

  /// Theme-aware color for this module type
  Color themedColor(BuildContext context) {
    return context.isDarkMode ? darkColor : lightColor;
  }
}
