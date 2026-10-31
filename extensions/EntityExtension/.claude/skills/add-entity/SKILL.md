---
name: add-entity
description: Add a vanilla Minecraft entity type (mob, animal, monster, display, frame) to Typewriter's EntityExtension. Covers the definition, instance and wrapper, the right data tags and routers, the size row, new data for uncovered metadata, and compile + guard-test verification.
when_to_use: The user wants a new entity type in the Entity Extension, e.g. "add the axolotl entity", "support armadillos", "implement the zombie villager", "new mob for Typewriter", "which entities are still missing?".
argument-hint: "<ENTITY_TYPE, e.g. AXOLOTL>"
allowed-tools: Bash(bash *entity-info.sh *) Bash(extensions/gradlew -p extensions :EntityExtension*)
---

# Add an entity to the Entity Extension

`extensions/EntityExtension/AGENTS.md` holds the tag table, the rules and the known issues this workflow
relies on. Read it first if it is not in context. Commands run from the repository root.

## 1. Look the type up

```bash
bash extensions/EntityExtension/scripts/entity-info.sh $ARGUMENTS
```

With no type given, run it with `--missing`. Then pick the type the user named, or ask; living types are listed
first. Read the output before writing anything:

| Output | What to do |
| --- | --- |
| `Implemented: yes` | Stop: it exists. Offer to extend it with the `add-entity-data` skill instead |
| `Size row: MISSING` | Step 4 is required |
| `Registry: … TODO` | EntityLib hasn't verified this mapping. Read the meta source; adding data for its setters is fine, but tell the user that the type's own metadata is untested in-game |
| `Living: no` | Living data cannot apply, so don't offer `living_entity_data` |
| `NOT COVERED` setters | Candidates for new data (step 5) |
| `Suggested wiring` | The `@OnlyTags` list and the router calls to use |

## 2. Names, icon and a sibling

- **Name** is the PascalCase of the type (`ZOMBIE_VILLAGER` → `ZombieVillager`); the snake form is `zombie_villager`.
- **Icon:** search with `curl -s "https://api.iconify.design/search?query=<name>&limit=10"`, preferring `mdi:`,
  `game-icons:`, `ph:` and `lucide:`. Confirm it with `curl -s "https://api.iconify.design/<prefix>.json?icons=<name>"`;
  `not_found` must be absent. KSP rejects icons that don't exist.
- **Sibling:** pick the existing entity with the closest meta chain as a reference.
  - `BatEntity.kt` for a plain mob.
  - `CatEntity.kt` for a tameable.
  - `SheepEntity.kt` for an ageable with its own data.
  - `HuskEntity.kt` for a humanoid that can sit.
  - `IllusionerEntity.kt` for a raider.
  - `HorseEntity.kt` for a horse.
  - `BlockDisplayEntity.kt` for a display.
  - `ItemFrameEntity.kt` for one wrapper serving two types.

## 3. Write the entity file

Copy [template.kt](template.kt) to
`extensions/EntityExtension/src/main/kotlin/com/typewritermc/entity/entries/entity/minecraft/<Name>Entity.kt`
and fill in every `{{…}}`:

- `@OnlyTags` is the script's suggestion, character for character the same on the definition and the instance.
- Add `"<snake>_data"` only once a data entry carries it (step 5). The guard test fails on tags no data carries.
- Give the `when` one branch per entity-specific property, plus the group properties that have no router
  (`AgeableProperty`, `CelebratingProperty`, horse properties). After the `when`, call the routers in the order
  the script prints them.
- For a humanoid that should be able to sit, copy `HuskEntity.kt`'s `RideableSittingSupport` wiring
  (`applyPose`, `applyPosition`, `spawn`, `contains`, `dispose`) and add `pose = EntityPose.SITTING` size rows.
- Drop imports you don't use, e.g. `applyLivingEntityData` for a non-living entity.
- Write the KDoc the way `BatEntity.kt` does, and give a real use for the entity in a story.

## 4. Size row (only when the script says MISSING)

Add a row to `manualEntityData` in `entity/custom/EntityTypeProperty.kt`:

```kotlin
EntityDataMatcher(EntityTypes.{{TYPE}}) to EntityData(width = 0.6, height = 1.8, eyeHeight = 1.62),
```

- Take the vanilla hitbox from the Minecraft Wiki page of the mob; `eyeHeight` defaults to 0.85 × height.
- Ageable types get two rows, `isBaby = false` and `isBaby = true`.
- Never edit the `<editor-fold>` block; it is generated.

## 5. Data for uncovered setters

For each `NOT COVERED` setter on the entity's **own** meta that a story author would want to set (looks,
variant, pose, a visible state), follow the `add-entity-data` skill
([../add-entity-data/SKILL.md](../add-entity-data/SKILL.md)). Then add `"<snake>_data"` to both `@OnlyTags`
lists and a `when` branch for each new property.

Skip, and list in your summary with the reason:
- Setters that change nothing visible: owners, UUIDs, internal counters and timers.
- `MobMeta` setters (`setNoAi`, `setLeftHanded`, `setAggressive`). `mob_data` is reserved for these, but adding
  them touches every mob, so suggest it as its own task.
- Setters on shared group metas (`AgeableMeta.setAgeLocked`, display interpolation). They belong to the group,
  not to this entity, so suggest them as their own task too.
- Setters the user said to leave out.

## 6. Verify

```bash
extensions/gradlew -p extensions :EntityExtension:compileKotlin
extensions/gradlew -p extensions :EntityExtension:test
```

A cold first compile builds the engine too and takes about two minutes, so run it in the background. Gradle
prints nothing per spec when everything passes. The per-spec results are in
`extensions/EntityExtension/build/test-results/test/TEST-*.xml`. Fix every failure:

| Failure | Fix |
| --- | --- |
| KSP: icon not found | Choose another icon (step 2) |
| KSP: `NoTagsFoundException` | The definition is missing `@Tags("<snake>_definition")` |
| KSP: missing default | Every constructor parameter needs a default |
| `EntityEntriesSpec`: "offer `x`, but no data entry carries it" | Drop the tag, or add the data |
| `EntityEntriesSpec`: "offers … but … offers" | Make both `@OnlyTags` lists equal |
| `EntityEntriesSpec`: "has a size row" | Step 4 |

## 7. Report

Tell the user:
- the files added and changed,
- the tags offered,
- the data created,
- each skipped setter and why,
- the icon,
- any known issue from AGENTS.md you ran into.

Don't commit unless asked; the subject style is `feat(EntityExtension): add <name> entity`.
