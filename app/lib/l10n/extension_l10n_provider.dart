import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/l10n/locale_provider.dart";
import "package:typewriter/models/extension.dart";

part "extension_l10n_provider.g.dart";

/// Manages localization for extension-defined nodes and fields.
/// 
/// Extensions can ship their own translation files with their build,
/// allowing third-party authors to provide localized content independently.
/// 
/// The resolver supports:
/// - Per-extension translation namespaces
/// - Runtime resolution with fallback to default values
/// - Multiple locales (English, Russian, etc.)
class ExtensionLocalizationResolver {
  final Map<String, Map<String, Map<String, String>>> _translations = {};

  /// Load translations for an extension.
  /// 
  /// translations should be a map like:
  /// {
  ///   'en': {
  ///     'entity.random_patrol_activity.title': 'Random Patrol Activity',
  ///     'entity.random_patrol_activity.description': 'A wandering entity...',
  ///     'entity.random_patrol_activity.fields.radius.label': 'Radius',
  ///   },
  ///   'ru': { ... }
  /// }
  void loadExtensionTranslations(
    String extensionKey,
    Map<String, Map<String, String>> translations,
  ) {
    _translations[extensionKey] = translations;
  }

  /// Resolve a localization key for an extension.
  /// 
  /// Returns the localized string if available, otherwise:
  /// 1. The fallback string if provided
  /// 2. Formatted technical name (capitalize and replace underscores)
  /// 3. The raw key
  String resolve(
    String extensionKey,
    Locale locale,
    String key, {
    String? fallback,
  }) {
    final localeKey = locale.toLanguageTag().replaceAll("-", "_");
    final languageCode = locale.languageCode;

    // Try exact locale
    var result = _translations[extensionKey]?[localeKey]?[key];
    if (result != null && result.isNotEmpty) return result;

    // Fall back to language only (e.g., 'en' from 'en_US')
    if (localeKey != languageCode) {
      result = _translations[extensionKey]?[languageCode]?[key];
      if (result != null && result.isNotEmpty) return result;
    }

    // Fall back to English
    if (languageCode != "en") {
      result = _translations[extensionKey]?["en"]?[key];
      if (result != null && result.isNotEmpty) return result;
    }

    // Use provided fallback string
    if (fallback != null && fallback.isNotEmpty) return fallback;

    // Format technical key as last resort
    return _formatTechnicalKey(key);
  }

  /// Resolve multiple keys for option labels.
  /// 
  /// Given a key prefix like 'entity.field.options',
  /// returns a map of option values to localized labels.
  Map<String, String> resolveOptionLabels(
    String extensionKey,
    Locale locale,
    String keyPrefix,
    List<String> optionValues, {
    Map<String, String>? fallbacks,
  }) {
    return Map.fromEntries(
      optionValues.map((value) {
        final fullKey = "$keyPrefix.$value";
        return MapEntry(
          value,
          resolve(
            extensionKey,
            locale,
            fullKey,
            fallback: fallbacks?[value],
          ),
        );
      }),
    );
  }

  String _formatTechnicalKey(String key) {
    return key
        .split(".")
        .last
        .split("_")
        .map(
          (part) => part.isNotEmpty
              ? part[0].toUpperCase() + part.substring(1).toLowerCase()
              : "",
        )
        .join(" ");
  }
}

/// Global instance of the localization resolver
final _extensionL10nResolver = ExtensionLocalizationResolver();

/// Provides access to the extension localization resolver
@riverpod
ExtensionLocalizationResolver extensionL10nResolver(Ref ref) {
  // Ensure all extensions have their translations loaded
  final extensions = ref.watch(extensionsProvider);
  ref.watch(extensionL10nInitializerProvider(extensions));

  return _extensionL10nResolver;
}

/// Helper provider that initializes translations for all loaded extensions
@riverpod
void extensionL10nInitializer(Ref ref, List<Extension> extensions) {
  for (final ext in extensions) {
    _extensionL10nResolver.loadExtensionTranslations(
      ext.extension.name,
      ext.translations,
    );
    if (ext.extension.key.isNotEmpty &&
        ext.extension.key != ext.extension.name) {
      _extensionL10nResolver.loadExtensionTranslations(
        ext.extension.key,
        ext.translations,
      );
    }
  }
}

/// Resolve a localization key for an extension
@riverpod
String resolveExtensionKey(
  ResolveExtensionKeyRef ref,
  String extensionKey,
  String key, {
  String? fallback,
}) {
  final resolver = ref.watch(extensionL10nResolverProvider);
  final locale = ref.watch(localeControllerProvider);
  return resolver.resolve(extensionKey, locale, key, fallback: fallback);
}

/// Resolve option labels for an extension enum/select field
@riverpod
Map<String, String> resolveExtensionOptions(
  ResolveExtensionOptionsRef ref,
  String extensionKey,
  String keyPrefix,
  List<String> optionValues, {
  Map<String, String>? fallbacks,
}) {
  final resolver = ref.watch(extensionL10nResolverProvider);
  final locale = ref.watch(localeControllerProvider);
  return resolver.resolveOptionLabels(
    extensionKey,
    locale,
    keyPrefix,
    optionValues,
    fallbacks: fallbacks,
  );
}
