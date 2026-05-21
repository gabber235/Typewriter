// ignore_for_file: avoid_classes_with_only_static_members

import "package:collection/collection.dart";
import "package:typewriter/models/entry_blueprint.dart";

/// Helper utilities for working with localized entry metadata
class LocalizedEntryMetadata {
  /// Extract the localization key or fallback for an entry title
  static String getTitleKey(EntryBlueprint blueprint) => blueprint.titleKey;

  /// Extract the localization key or fallback for an entry description
  static String getDescriptionKey(EntryBlueprint blueprint) =>
      blueprint.descriptionKey;

  static String defaultTitleKey(EntryBlueprint blueprint) =>
      "${_extensionNamespace(blueprint)}.${blueprint.name}.title";

  static String defaultDescriptionKey(EntryBlueprint blueprint) =>
      "${_extensionNamespace(blueprint)}.${blueprint.name}.description";

  static String defaultFieldLabelKey(EntryBlueprint blueprint, String path) =>
      "${_extensionNamespace(blueprint)}.${blueprint.name}.fields.$path.label";

  static String defaultFieldHelpKey(EntryBlueprint blueprint, String path) =>
      "${_extensionNamespace(blueprint)}.${blueprint.name}.fields.$path.help";

  static String defaultFieldPlaceholderKey(
    EntryBlueprint blueprint,
    String path,
  ) =>
      "${_extensionNamespace(blueprint)}.${blueprint.name}.fields.$path.placeholder";

  static String _extensionNamespace(EntryBlueprint blueprint) =>
      blueprint.extension.toLowerCase();

  /// Extract the localization key from help modifier data
  static String? getHelpKey(dynamic modifierData) {
    if (modifierData is String) return null;
    if (modifierData is Map) {
      return modifierData["key"] as String?;
    }
    return null;
  }

  /// Extract the help text fallback from modifier data
  static String? getHelpFallback(dynamic modifierData) {
    if (modifierData is String) return modifierData.isNotEmpty ? modifierData : null;
    if (modifierData is Map) {
      final fallback = modifierData["fallback"] as String?;
      return fallback?.isNotEmpty ?? false ? fallback : null;
    }
    return null;
  }

  /// Find a modifier by name in a field's modifier list
  static Modifier? findModifier(
    DataBlueprint blueprint,
    String modifierName,
  ) {
    return blueprint.modifiers.firstWhereOrNull((m) => m.name == modifierName);
  }

  /// Extract label key from field modifiers
  static String? getLabelKey(DataBlueprint blueprint) {
    final modifier = findModifier(blueprint, "labelKey");
    return modifier?.data is String ? modifier!.data as String : null;
  }

  /// Extract placeholder key from field modifiers
  static String? getPlaceholderKey(DataBlueprint blueprint) {
    final modifier = findModifier(blueprint, "placeholderKey");
    return modifier?.data is String ? modifier!.data as String : null;
  }

  /// Extract option labels key prefix from field modifiers
  static String? getOptionLabelsKeyPrefix(DataBlueprint blueprint) {
    final modifier = findModifier(blueprint, "optionLabelsKeyPrefix");
    return modifier?.data is String ? modifier!.data as String : null;
  }

  /// Get help key or fallback from a field
  static ({String? key, String? fallback}) getHelpKeyAndFallback(
    DataBlueprint blueprint,
  ) {
    final modifier = findModifier(blueprint, "help");
    if (modifier == null) return (key: null, fallback: null);

    return (
      key: getHelpKey(modifier.data),
      fallback: getHelpFallback(modifier.data),
    );
  }
}
