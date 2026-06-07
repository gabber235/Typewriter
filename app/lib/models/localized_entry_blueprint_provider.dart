import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/l10n/extension_l10n_provider.dart";
import "package:typewriter/l10n/locale_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/localized_entry_metadata.dart";

part "localized_entry_blueprint_provider.g.dart";

/// Provides localized title for an entry blueprint
@riverpod
String entryBlueprintLocalizedTitle(
  EntryBlueprintLocalizedTitleRef ref,
  String blueprintId,
) {
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) return "";

  final explicitTitleKey = LocalizedEntryMetadata.getTitleKey(blueprint);
  final titleKey = explicitTitleKey.isNotEmpty
      ? explicitTitleKey
      : LocalizedEntryMetadata.defaultTitleKey(blueprint);

  // Resolve using extension localization system
  final resolver = ref.watch(extensionL10nResolverProvider);
  return resolver.resolve(
    blueprint.extension,
    ref.watch(localeControllerProvider),
    titleKey,
    fallback: blueprint.name.formatted,
  );
}

/// Provides localized description for an entry blueprint
@riverpod
String entryBlueprintLocalizedDescription(
  EntryBlueprintLocalizedDescriptionRef ref,
  String blueprintId,
) {
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) return "";

  final explicitDescriptionKey =
      LocalizedEntryMetadata.getDescriptionKey(blueprint);
  final descriptionKey = explicitDescriptionKey.isNotEmpty
      ? explicitDescriptionKey
      : LocalizedEntryMetadata.defaultDescriptionKey(blueprint);

  // Resolve using extension localization system
  final resolver = ref.watch(extensionL10nResolverProvider);
  return resolver.resolve(
    blueprint.extension,
    ref.watch(localeControllerProvider),
    descriptionKey,
    fallback: blueprint.description,
  );
}

/// Provides localized label for a field
@riverpod
String fieldLocalizedLabel(
  FieldLocalizedLabelRef ref,
  String blueprintId,
  String fieldPath,
) {
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) return fieldPath;

  // Navigate to the field blueprint
  var current = blueprint.dataBlueprint as DataBlueprint;
  final parts = fieldPath.split(".");
  
  for (final part in parts) {
    if (current is ObjectBlueprint) {
      final field = current.fields[part];
      if (field == null) {
        return part.formatted;
      }
      current = field;
    } else {
      return part.formatted;
    }
  }

  final labelKey = LocalizedEntryMetadata.getLabelKey(current) ??
      LocalizedEntryMetadata.defaultFieldLabelKey(blueprint, fieldPath);

  final resolver = ref.watch(extensionL10nResolverProvider);
  return resolver.resolve(
    blueprint.extension,
    ref.watch(localeControllerProvider),
    labelKey,
    fallback: parts.last.formatted,
  );
}

/// Provides localized help text for a field
@riverpod
String? fieldLocalizedHelp(
  FieldLocalizedHelpRef ref,
  String blueprintId,
  String fieldPath,
) {
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) return null;

  // Navigate to the field blueprint
  var current = blueprint.dataBlueprint as DataBlueprint;
  final parts = fieldPath.split(".");
  
  for (final part in parts) {
    if (current is ObjectBlueprint) {
      final field = current.fields[part];
      if (field == null) {
        return null;
      }
      current = field;
    } else {
      return null;
    }
  }

  final (:key, :fallback) =
      LocalizedEntryMetadata.getHelpKeyAndFallback(current);
  if (key == null &&
      fallback == null &&
      LocalizedEntryMetadata.findModifier(current, "help") == null) {
    return null;
  }
  final helpKey =
      key ?? LocalizedEntryMetadata.defaultFieldHelpKey(blueprint, fieldPath);
  
  if (helpKey.isEmpty) {
    return fallback;
  }

  final resolver = ref.watch(extensionL10nResolverProvider);
  return resolver.resolve(
    blueprint.extension,
    ref.watch(localeControllerProvider),
    helpKey,
    fallback: fallback,
  );
}
