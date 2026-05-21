# Example: Migrating an Extension to Use Localization

This example shows how to migrate an existing extension to use the new localization system.

## Before: Without Localization

**Entity Definition (Kotlin):**
```kotlin
@Entry(
    name = "entity.random_patrol",
    description = "Makes an NPC patrol a random area",
    color = "#FF0000",
    icon = "mdi:walk"
)
@Tags("entity", "movement")
data class RandomPatrolEntity(
    @Help("The radius in blocks where the entity can patrol")
    val radius: Double = 10.0,

    @Help("How fast the entity moves")
    val speed: Double = 1.0,

    @Help("The behavior when encountering obstacles")
    val behavior: PatrolBehavior = PatrolBehavior.WANDER,
) : Entry

enum class PatrolBehavior {
    WANDER, RETURN_HOME, STOP
}
```

**Result in UI:**
- Node shows as "Entity Random Patrol" (formatted from id)
- Description shows the hardcoded text
- Fields show as "Radius", "Speed", "Behavior" (formatted)
- Help text shows the hardcoded strings

---

## After: With Localization

### Step 1: Update Kotlin Entry

```kotlin
@Entry(
    name = "entity.random_patrol",
    description = "Makes an NPC patrol a random area",
    color = "#FF0000",
    icon = "mdi:walk",
    // Add localization keys
    titleKey = "entity.random_patrol.title",
    descriptionKey = "entity.random_patrol.description"
)
@Tags("entity", "movement")
data class RandomPatrolEntity(
    @LabelKey("entity.random_patrol.fields.radius.label")
    @Help(key = "entity.random_patrol.fields.radius.help")
    val radius: Double = 10.0,

    @LabelKey("entity.random_patrol.fields.speed.label")
    @Help(key = "entity.random_patrol.fields.speed.help")
    val speed: Double = 1.0,

    @LabelKey("entity.random_patrol.fields.behavior.label")
    @Help(key = "entity.random_patrol.fields.behavior.help")
    @OptionLabelsKey("entity.random_patrol.fields.behavior.options")
    val behavior: PatrolBehavior = PatrolBehavior.WANDER,
) : Entry

enum class PatrolBehavior {
    WANDER, RETURN_HOME, STOP
}
```

### Step 2: Create Translation Files

**src/main/resources/translations/extension_l10n_en.json:**
```json
{
  "entity.random_patrol.title": "Random Patrol",
  "entity.random_patrol.description": "Makes an NPC patrol randomly within a specified area",
  
  "entity.random_patrol.fields.radius.label": "Patrol Radius",
  "entity.random_patrol.fields.radius.help": "The maximum radius in blocks where the entity can wander",
  
  "entity.random_patrol.fields.speed.label": "Movement Speed",
  "entity.random_patrol.fields.speed.help": "How fast the entity moves (1.0 = normal)",
  
  "entity.random_patrol.fields.behavior.label": "Behavior Type",
  "entity.random_patrol.fields.behavior.help": "What the entity does when it encounters an obstacle",
  "entity.random_patrol.fields.behavior.options.wander": "Wander",
  "entity.random_patrol.fields.behavior.options.return_home": "Return Home",
  "entity.random_patrol.fields.behavior.options.stop": "Stop"
}
```

**src/main/resources/translations/extension_l10n_ru.json:**
```json
{
  "entity.random_patrol.title": "Случайный Патруль",
  "entity.random_patrol.description": "Заставляет NPC патрулировать случайную область",
  
  "entity.random_patrol.fields.radius.label": "Радиус Патруля",
  "entity.random_patrol.fields.radius.help": "Максимальный радиус в блоках, где может бродить сущность",
  
  "entity.random_patrol.fields.speed.label": "Скорость Движения",
  "entity.random_patrol.fields.speed.help": "Насколько быстро движется сущность (1.0 = нормально)",
  
  "entity.random_patrol.fields.behavior.label": "Тип Поведения",
  "entity.random_patrol.fields.behavior.help": "Что делает сущность при столкновении с препятствием",
  "entity.random_patrol.fields.behavior.options.wander": "Бродить",
  "entity.random_patrol.fields.behavior.options.return_home": "Вернуться Домой",
  "entity.random_patrol.fields.behavior.options.stop": "Остановиться"
}
```

### Step 3: Update build.gradle.kts

```gradle
tasks.jar {
    // ... existing configurations ...
    
    // Include translation files
    from("src/main/resources/translations") {
        into("translations")
    }
}
```

### Step 4: Using Localized UI (Optional - for UI Components)

If you're rendering custom UI for this entity, you can use the localization system:

**Dart Widget (Flutter):**
```dart
import "package:typewriter/widgets/components/localized_entry_widgets.dart";

class RandomPatrolEntityCard extends ConsumerWidget {
  final EntryBlueprint blueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          // Localized title
          LocalizedEntryTitle(blueprint),
          
          // Localized description
          LocalizedEntryDescription(blueprint),
          
          // Field with localized label and help
          Row(
            children: [
              LocalizedFieldLabel(blueprint.id, "radius"),
              if (showHelp) LocalizedFieldHelp(blueprint.id, "radius"),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Results

### English (Default)

**Node Title:** "Random Patrol" (from titleKey translation)
**Node Description:** "Makes an NPC patrol randomly within a specified area" (from descriptionKey)

**Fields:**
- **Patrol Radius** (from labelKey) - "The maximum radius in blocks where the entity can wander" (from Help key)
- **Movement Speed** (from labelKey) - "How fast the entity moves (1.0 = normal)" (from Help key)
- **Behavior Type** (from labelKey) - "What the entity does when it encounters an obstacle" (from Help key)
  - Options: "Wander", "Return Home", "Stop" (from optionLabelsKey)

### Russian

**Node Title:** "Случайный Патруль"
**Node Description:** "Заставляет NPC патрулировать случайную область"

**Fields:**
- **Радиус Патруля** - "Максимальный радиус в блоках, где может бродить сущность"
- **Скорость Движения** - "Насколько быстро движется сущность (1.0 = нормально)"
- **Тип Поведения** - "Что делает сущность при столкновении с препятствием"
  - Options: "Бродить", "Вернуться Домой", "Остановиться"

---

## Key Benefits of This Approach

1. ✅ **Third-party independent** - No changes needed to core Typewriter app
2. ✅ **Extensible** - Easy to add more locales later (French, Spanish, etc.)
3. ✅ **Maintainable** - All strings for this entity in one place
4. ✅ **Professional** - Native-language support for players
5. ✅ **Future-proof** - Supports new fields automatically (just add translation)
6. ✅ **Safe fallbacks** - If translation missing, formatted name shown
7. ✅ **No breaking changes** - Old extensions continue to work without updates

---

## Quick Migration Checklist

- [ ] Add `titleKey` and `descriptionKey` to `@Entry` annotation
- [ ] Add `@LabelKey()` to each field
- [ ] Convert `@Help("text")` to `@Help(key = "...")`
- [ ] Add `@PlaceholderKey()` to string fields if needed
- [ ] Add `@OptionLabelsKey()` to enum/select fields
- [ ] Create `extension_l10n_en.json` with all translation keys
- [ ] Create `extension_l10n_ru.json` (or other locales)
- [ ] Update `build.gradle.kts` to include translations in JAR
- [ ] Test with different locales to verify keys resolve correctly
- [ ] (Optional) Create custom UI components using localized providers

---

## Common Patterns

### String Field with Placeholder

```kotlin
@LabelKey("entity.fields.name.label")
@PlaceholderKey("entity.fields.name.placeholder")
@Help(key = "entity.fields.name.help")
val name: String = ""
```

Translations:
```json
{
  "entity.fields.name.label": "Entity Name",
  "entity.fields.name.placeholder": "Enter a name (e.g., 'Patrol Guard')",
  "entity.fields.name.help": "A unique identifier for this entity"
}
```

### Enum Field

```kotlin
@LabelKey("entity.fields.type.label")
@Help(key = "entity.fields.type.help")
@OptionLabelsKey("entity.fields.type.options")
val type: EntityType = EntityType.NEUTRAL
```

Translations:
```json
{
  "entity.fields.type.label": "Entity Type",
  "entity.fields.type.help": "The type determines behavior and interactions",
  "entity.fields.type.options.aggressive": "Aggressive",
  "entity.fields.type.options.peaceful": "Peaceful",
  "entity.fields.type.options.neutral": "Neutral"
}
```

### Complex Nested Object

```kotlin
@LabelKey("entity.fields.config.label")
@Help(key = "entity.fields.config.help")
val config: PatrolConfig = PatrolConfig()

@Serializable
data class PatrolConfig(
    @LabelKey("entity.fields.config.fields.waypoints.label")
    val waypoints: List<String> = emptyList(),
    
    @LabelKey("entity.fields.config.fields.timeout.label")
    @Help(key = "entity.fields.config.fields.timeout.help")
    val timeout: Int = 300,
)
```

Translations:
```json
{
  "entity.fields.config.label": "Patrol Configuration",
  "entity.fields.config.help": "Advanced patrol settings",
  "entity.fields.config.fields.waypoints.label": "Waypoints",
  "entity.fields.config.fields.timeout.label": "Timeout (ticks)",
  "entity.fields.config.fields.timeout.help": "How long to wait at each waypoint before moving"
}
```
