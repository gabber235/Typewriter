# Extension Localization System

This document describes how to add localization support for extension-defined nodes and fields.

## Overview

The localization system allows extensions to ship their own translated content independently from the main Typewriter app. This means:

- Extension authors don't need to modify the core app's localization files
- Each extension can have its own translation namespace
- Translations are bundled with the extension
- The system gracefully falls back to default strings if translations are missing

## How It Works

### 1. Extension-Side: Define Localization Keys

In your extension's Entry annotation:

```kotlin
@Entry(
    name = "entity.random_patrol_activity",
    description = "A wandering NPC that patrols a random area",
    color = "#FF0000",
    icon = "mdi:walk",
    // Add localization keys for node-level text
    titleKey = "entity.random_patrol_activity.title",
    descriptionKey = "entity.random_patrol_activity.description",
)
data class RandomPatrolActivity(
    @LabelKey("entity.random_patrol_activity.fields.radius.label")
    @Help(key = "entity.random_patrol_activity.fields.radius.help")
    val radius: Double = 10.0,

    @LabelKey("entity.random_patrol_activity.fields.behavior.label")
    @Help(key = "entity.random_patrol_activity.fields.behavior.help")
    val behavior: Behavior = Behavior.WANDER,
) : Entry
```

### 2. Field-Level Localization

Use these annotations on fields:

#### `@LabelKey(value: String)`
Specifies a localization key for the field's display label.

```kotlin
@LabelKey("entity.fields.speed.label")
val speed: Double
```

#### `@Help(text: String = "", key: String = "")`
Extended to support localization keys. Provide either:
- `key` - for localized help text  
- `text` - as a fallback

```kotlin
@Help(key = "entity.fields.radius.help")
val radius: Double

@Help(key = "entity.fields.radius.help", text = "The patrol radius in blocks")
val radius: Double
```

#### `@PlaceholderKey(value: String)`
Localization key for placeholder text in string fields.

```kotlin
@PlaceholderKey("entity.fields.name.placeholder")
val name: String
```

#### `@OptionLabelsKey(keyPrefix: String)`
For enum/select fields, provides a key prefix for resolving option labels.
Keys are formed as `{keyPrefix}.{option_value}`.

```kotlin
@OptionLabelsKey("entity.fields.type.options")
val type: EntityType  // Keys resolved as "entity.fields.type.options.aggressive", etc.
```

### 3. Translation Files

Create translation files in your extension with naming convention:
`translations/extension_l10n_{locale}.json`

Example: `src/main/resources/translations/extension_l10n_en.json`

```json
{
  "entity.random_patrol_activity.title": "Random Patrol Activity",
  "entity.random_patrol_activity.description": "A wandering NPC that patrols a random area",
  "entity.random_patrol_activity.fields.radius.label": "Patrol Radius",
  "entity.random_patrol_activity.fields.radius.help": "The radius in blocks where the entity can patrol",
  "entity.random_patrol_activity.fields.radius.placeholder": "Enter radius (e.g., 10)",
  "entity.random_patrol_activity.fields.behavior.label": "Behavior Type",
  "entity.random_patrol_activity.fields.behavior.help": "How the entity should behave while patrolling",
  "entity.random_patrol_activity.fields.type.options.aggressive": "Aggressive",
  "entity.random_patrol_activity.fields.type.options.peaceful": "Peaceful",
  "entity.random_patrol_activity.fields.type.options.neutral": "Neutral"
}
```

Also create `extension_l10n_ru.json` for Russian, etc.

### 4. Bundle Translations with Extension

Translations must be packaged with your extension JAR. The extension loader will look for them at runtime.

In your build configuration (e.g., `build.gradle.kts`):

```gradle
tasks.jar {
    from("src/main/resources/translations") {
        into("translations")
    }
}
```

## Fallback Behavior

If a translation key is missing, the system falls back in this order:

1. **Localized text** - translation for the current locale
2. **Fallback string** - provided in the annotation (if any)
3. **Formatted technical key** - humanized version of the key
4. **Raw key** - the key itself as a last resort

Example:
- Translation available → Use it
- No translation, but `Help(text = "...")` provided → Use fallback text
- No translation/fallback → Format "entity.radius" as "Entity Radius"
- (Never happens) → Show the raw key

## Resolver API in Flutter

### Using Pre-built Providers

The Flutter app provides convenient providers for resolving localized text:

```dart
// Resolve entry title
final title = ref.watch(
  entryBlueprintLocalizedTitleProvider(blueprintId)
);

// Resolve entry description
final description = ref.watch(
  entryBlueprintLocalizedDescriptionProvider(blueprintId)
);

// Resolve field label
final label = ref.watch(
  fieldLocalizedLabelProvider(blueprintId, "fields.radius")
);

// Resolve field help
final help = ref.watch(
  fieldLocalizedHelpProvider(blueprintId, "fields.radius")
);
```

### Manual Resolution

If you need custom resolution logic:

```dart
final resolver = ref.watch(extensionL10nResolverProvider);
final locale = ref.watch(localeControllerProvider);

final text = resolver.resolve(
  extensionKey: "my-extension",
  locale: locale,
  key: "my.translation.key",
  fallback: "Default text if missing",
);

// For option labels
final options = resolver.resolveOptionLabels(
  "my-extension",
  locale,
  "entity.fields.type.options",
  ["aggressive", "peaceful", "neutral"],
  fallbacks: {
    "aggressive": "Aggressive (fallback)",
    "peaceful": "Peaceful (fallback)",
  },
);
```

## Loading Extension Translations

During app initialization, you'll need to load translations for loaded extensions:

```dart
void initializeExtensionLocalizations(List<Extension> extensions) {
  final resolver = ref.read(extensionL10nResolverProvider);
  
  for (final ext in extensions) {
    // Load translations from the extension bundle
    // This typically happens when the extension metadata is loaded
    final translations = loadExtensionTranslations(ext.key);
    resolver.loadExtensionTranslations(ext.key, translations);
  }
}
```

## Best Practices

1. **Use consistent naming conventions**
   - Structure: `{extension}.{entity/field}.{component}.{key}`
   - Example: `entity.random_patrol.fields.radius.label`

2. **Provide meaningful fallbacks**
   - Always provide text or use a well-formatted key
   - Never rely only on raw key formatting

3. **Keep translations organized**
   - Group related keys (all one entity's translations together)
   - Use a single comprehensive file per extension per locale

4. **Test with missing translations**
   - Verify fallback behavior works correctly
   - Test with disabled translations to see formatted fallbacks

5. **Support multiple locales**
   - At minimum, provide English (en) translations
   - Consider common locales (ru, es, fr, de, etc.)

6. **Avoid dynamic keys**
   - Keys should be static and known at compile time
   - Don't generate keys from runtime data

## Migration Guide

### From Old System to New

If your extension currently uses hardcoded text:

**Before:**
```kotlin
@Entry(name = "my.entity", description = "Some entity")
data class MyEntity(
    @Help("The entity's speed")
    val speed: Double
) : Entry
```

**After:**
```kotlin
@Entry(
    name = "my.entity",
    description = "Some entity",
    titleKey = "my.entity.title",
    descriptionKey = "my.entity.description"
)
data class MyEntity(
    @LabelKey("my.entity.fields.speed.label")
    @Help(key = "my.entity.fields.speed.help")
    val speed: Double
) : Entry
```

Then create `extension_l10n_en.json`:
```json
{
  "my.entity.title": "My Entity",
  "my.entity.description": "Some entity",
  "my.entity.fields.speed.label": "Speed",
  "my.entity.fields.speed.help": "The entity's speed in blocks/tick"
}
```

## Troubleshooting

**Problem:** Text appears as formatted key (e.g., "My Entity Fields Speed Label")
- **Cause:** Translation key not found and no fallback provided
- **Solution:** Ensure translation file is loaded and key name matches exactly

**Problem:** Extension doesn't load translations
- **Cause:** Translation files not packaged with JAR
- **Solution:** Verify build config includes translations in `resources/translations/`

**Problem:** Wrong locale being used
- **Cause:** Locale provider returning unexpected value
- **Solution:** Check `localeControllerProvider` in app settings

**Problem:** UI not updating after locale change
- **Cause:** Not watching `localeControllerProvider`
- **Solution:** Use the provided providers which automatically watch locale changes
