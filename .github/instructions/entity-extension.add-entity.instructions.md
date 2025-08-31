---
applyTo: "extensions/EntityExtension/src/main/kotlin/com/typewritermc/entity/entries/**/*"
---

# Entity Extension — Add a new entity (Copilot toolset)

This guide is an actionable checklist for Copilot to add a new Minecraft entity to the Entity Extension. It covers the two main areas you must touch:

- entity classes in `entries/entity/...`
- use existing data properties and appliers in `entries/data/...` (no new data files)

It also references EntityLib (Tofaa2) to discover supported metadata for the entity.

Upstream library: https://github.com/Tofaa2/EntityLib/tree/master/api/src/main/java/me/tofaa/entitylib/meta

## Inputs Copilot needs

- The vanilla entity type name (e.g., ARMOR_STAND, ALLAY, PIG, …) as defined in PacketEvents `EntityTypes`.
- The matching EntityLib meta class (e.g., `ArmorStandMeta`, `LivingEntityMeta`, `PlayerMeta`, …) and any entity-specific meta fields.
- A consistent entry ID prefix (e.g., `armor_stand_definition`, `armor_stand_instance`, tag `armor_stand_data`).
- A short description, an icon id, and a color from `Colors`.

## Step 1: Discover entity metadata in EntityLib

1. Search the EntityLib repo for the meta class:
   - Query: `<EntityName>Meta` OR check folders: `meta/other`, `meta/types`, `meta/projectile`, `meta/living`.
   - Note important fields and flags you want to expose as Typewriter data (e.g., small/arms/baseplate/marker for ArmorStand).
2. Check generic/living metadata available in EntityLib (e.g., `EntityMeta`, `LivingEntityMeta`) to reuse existing data entries.

## Step 2: Check existing data entries in this repo

In `extensions/EntityExtension/src/main/kotlin/com/typewritermc/entity/entries/data/minecraft`:

- Generic data exists: `OnFireData`, `GlowingEffectData`, `PoseData`, `CustomNameData`, `ArmSwingData`, etc. (`GenericData.kt` routes them).
- Living data exists: `living/` folder (size, speed, equipment, potion color, sleeping, etc.).
- Per-entity data often lives under `living/<entity>/` or entity-specific folders (e.g., `living/armorstand/*` for arms, baseplate, marker, small, rotation).

Copilot checklist (reuse-only mode):

- [ ] Use only existing data entries. Do not create new `...Data.kt` or `...Property` files.
- [ ] If a needed field has no existing data entry, skip it and document the skip with a small comment in the entity file (see Step 3).

## Step 3: Create Definition and Instance entries

Definition entry (SimpleEntityDefinition):

- File: `entries/entity/minecraft/<EntityName>Entity.kt`
- Class: `<EntityName>Definition` annotated with `@Entry` and optional `@Tags`.
- Fields: `id`, `name`, `displayName: Var<String>`, `sound: Var<Sound>`, `data: List<Ref<EntityData<*>>>`.
- Constrain `data` with `@OnlyTags("generic_entity_data", "living_entity_data", "<entity>_data")` where applicable.
- `create(player)` returns your private runtime wrapper entity.

Add a short comment block at the bottom of the entity file for any skipped fields:

```kt
// Skipped data (no existing data entry available):
// - ArmorStand: shoulderEntity (not supported — no existing data file)
// - Bee: hasNectar (not supported yet)
```

Instance entry (SimpleEntityInstance or Advanced):

- Class: `<EntityName>Instance` annotated with `@Entry`.
- Fields: `id`, `name`, `definition: Ref<<EntityName>Definition>`, `spawnLocation`, `data` (+ `@OnlyTags`), and `activity: Ref<out SharedEntityActivityEntry>` (or individual).

Follow existing examples like `AllayEntity.kt` and `ArmorStandEntity.kt` for structure, icons, and colors.

## Step 4: Implement the runtime wrapper

- Create a private class `<EntityName>Entity(player: Player) : WrapperFakeEntity(EntityTypes.<TYPE>, player)`.
- Override `applyProperty(property: EntityProperty)`:
  1. First handle entity-specific `...Property` types by calling your appliers.
  2. Then attempt generic and living:
     - `if (applyGenericEntityData(entity, property)) return`
     - `if (applyLivingEntityData(entity, property)) return`
- Do not manage viewers/spawn batching; `WrapperFakeEntity` handles metadata batching with EntityLib (`EntityMeta#setNotifyAboutChanges(false/true)`).
- When a desired field has no existing data entry, don’t add new files—just leave it out and keep it listed in the "Skipped data" comment.

## Step 5: Verification and parity checks

Copilot should verify:

- [ ] The new file lives under `entries/entity/minecraft` and compiles alongside peers.
- [ ] `@Entry` IDs are snake_case and unique (e.g., `allay_definition`, `allay_instance`).
- [ ] `@OnlyTags` includes the right tags: `generic_entity_data`, optionally `living_entity_data`, plus `<entity>_data` if that entity-specific set already exists.
- [ ] The wrapper calls `applyGenericEntityData` and `applyLivingEntityData` after entity-specific properties.
- [ ] For living entities, confirm that living data applies; for non-living, only generic applies.
- [ ] Compare to similar entities (e.g., `SheepEntity.kt`, `AllayEntity.kt`) for consistent structure, icons, and descriptions.

Optional runtime checks (when activities/quests interact):

- If interaction support is needed, ensure `EntityInteractEventEntry` filters can target this definition.
- If used in objectives, confirm `InteractEntityObjective` can resolve positions from displays.

## Patterns and helpers to reuse

- Property defaults: `companion object : SinglePropertyCollectorSupplier<Prop>(Prop::class, Prop(default))`.
- Metadata application: `entity.metas { meta<SomeMeta> { /* apply fields */ }; error("Could not apply ... to ${entity.entityType} entity.") }`.
- Smooth rotation/movement in activities: `updateLookDirection`, `Velocity`, update `PositionProperty`.

## Minimal example outline

Skeleton for a new vanilla entity file (abbreviated):

```kt
// ... imports ...

@Entry("allay_definition", "A allay entity", Colors.ORANGE, "ph:flying-saucer-fill")
@Tags("allay_definition")
/**
 * The `AllayDefinition` class is an entry that represents an allay entity.
 *
 * ## How could this be used?
 * This could be used to create an allay entity.
 */
class AllayDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "allay_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = AllayEntity(player)
}

@Entry("allay_instance", "An instance of a allay entity", Colors.YELLOW, "ph:flying-saucer-fill")
/**
 * The `Allay Instance` class is an entry that represents an instance of an allay entity.
 *
 * ## How could this be used?
 *
 * This could be used to create an allay entity.
 */
class AllayInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<AllayDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "allay_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class AllayEntity(player: Player) : WrapperFakeEntity(EntityTypes.ALLAY, player) {
    override fun applyProperty(property: EntityProperty) {
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}
```

## Where to add new data entries

Do not add new data files in this mode. Use only existing entries routed by `applyGenericEntityData` and `applyLivingEntityData`. If a field isn’t available, skip it and document the skip inside the entity file.

## Notes on EntityLib usage

- `WrapperFakeEntity` bridges Typewriter to EntityLib wrappers: it creates IDs/UUIDs via `EntityLib.getPlatform().entityUuidProvider` and `entityIdProvider`, spawns, manages viewers, and batches metadata updates.
- Use meta classes like `EntityMeta`, `LivingEntityMeta`, `ArmorStandMeta`, etc., to set flags/fields via `entity.metas { meta<...> { ... } }`.
- Use only existing shared data entries; if something is missing, skip it and document the skip in the entity file.

## Final sanity checklist (Copilot)

- [ ] New definition and instance files created under `entries/entity/minecraft` with correct annotations and tags.
- [ ] Wrapper entity routes properties and falls back to generic/living appliers.
- [ ] No new data entries were added; only existing data entries are used.
- [ ] Skipped fields are briefly documented in a comment block inside the entity file.
- [ ] Build compiles; types `Ref`, `Var`, `ConstVar`, and `OnlyTags` imports correct.
- [ ] Visual parity: consistent color/icon/description with similar entities.
