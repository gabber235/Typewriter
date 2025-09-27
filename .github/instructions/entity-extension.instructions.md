---
applyTo: "extensions/EntityExtension/src/main/kotlin/com/typewritermc/entity/entries/**/*.kt"
---

# Entity Extension

This Typewriter extension provides the ability to add Minecraft entities to Typewriter.

## Overview

- Purpose: Define, spawn, animate, and interact with client-side entities (NPCs, displays, etc.) via Typewriter entries.
- Core pattern: Entries describe data; runtime uses a thin wrapper around EntityLib to construct and update entities per-viewer.
- Scope covered here: entries under `com.typewritermc.entity.entries` (entities, data, activities, events, bounds, quest hooks, and instances).

## Architecture at a glance

- Definition entries: Simple “what” an entity is (displayName, sound, data tags), e.g. `AllayDefinition`, `ArmorStandDefinition` implement `SimpleEntityDefinition`.
- Instance entries: “where/how” an entity spawns and which activity it runs, e.g. `AllayInstance`, `ArmorStandInstance` implement `SimpleEntityInstance`.
- Advanced instances: Shared/Group/Individual activity lifecycles (`SharedAdvancedEntityInstanceEntry`, `GroupAdvancedEntityInstanceEntry`, `IndividualAdvancedEntityInstanceEntry`).
- Activities: Per-tick behaviors operating on `PositionProperty` (e.g. `RandomLookActivityEntry`, `NavigationActivityTask`). Activities are either shared or individual.
- Data properties: Small, composable properties implementing `EntityProperty` (e.g. `OnFireProperty`, `GlowingEffectProperty`, pose, arms, etc.) with appliers.
- Events and bounds: `EntityInteractEventEntry` (click to trigger), `LookAtEntityInteractionBoundEntry` (force player look) integrate interactions with dialogue/flows.
- Audience/display utilities: Path stream displays and helpers for cinematic/pathfinding visualization.

## Dependency: EntityLib

This extension uses EntityLib by Tofaa2 for lightweight, packet-level entities and metadata management.

- Repo: https://github.com/Tofaa2/EntityLib
- You will see imports like `me.tofaa.entitylib.wrapper.WrapperEntity`, `WrapperLivingEntity`, and metas from `me.tofaa.entitylib.meta.*`.
- Our runtime adapter is `WrapperFakeEntity`, which bridges Typewriter’s `FakeEntity` to EntityLib wrappers.
  - It allocates entity IDs/UUIDs via EntityLib providers, spawns via packets, manages viewers, passengers, and batched metadata updates (`setNotifyAboutChanges`).

## Conventions

- Entry annotations: Use `@Entry(id, description, Colors, icon)` on all entries. Use `@Tags` on definitions to add search tags. Use `@OnlyTags` on data lists to constrain allowed data types.
- IDs and names: Keep IDs snake_case and descriptive (e.g., `armor_stand_definition`, `allay_instance`). Keep descriptions practical.
- Icons and colors: Prefer consistent icon packs in existing code (lucide:, ph:, fa6-solid:, etc.) and colors from `com.typewritermc.core.books.pages.Colors`.
- Data tagging:
  - Generic entity data: `"generic_entity_data"` (e.g., fire, glow, pose, custom name, arm swing).
  - Living entity data: `"living_entity_data"` (e.g., size, speed, living-specific metas).
  - Per-entity data: add an entity-specific tag like `"armor_stand_data"`, `"allay_data"`, etc., and reference it via `@OnlyTags` on definition/instance data.
- Property collection: Each `...Property` has a `companion object : SinglePropertyCollectorSupplier` to define default and merge behavior.

## Adding a new vanilla entity

1. Create Definition entry

   - Implement `SimpleEntityDefinition`.
   - Fields: `id`, `name`, `displayName: Var<String>`, `sound: Var<Sound>`, `data: List<Ref<EntityData<*>>>`.
   - Annotate with `@Entry` and optionally `@Tags`. Restrict `data` with `@OnlyTags("generic_entity_data", "living_entity_data", "<entity>_data")` as applicable.
   - `create(player)` should return your internal wrapper entity (see step 3).

2. Create Instance entry

   - Implement `SimpleEntityInstance` (or one of the Advanced variants when needed).
   - Fields: `id`, `name`, `definition: Ref<...Definition>`, `spawnLocation`, `data`, and `activity: Ref<out SharedEntityActivityEntry>` (or `IndividualEntityActivityEntry`).

3. Implement the runtime entity wrapper

   - Extend `WrapperFakeEntity(EntityTypes.<TYPE>, player)`.
   - Override `applyProperty(property: EntityProperty)` and route properties to appliers:
     - First, try per-entity properties (e.g., arms/baseplate/marker for armor stands).
     - Then fall back to generic/living appliers:
       - `if (applyGenericEntityData(entity, property)) return`
       - `if (applyLivingEntityData(entity, property)) return`
   - Do not manage viewers or metadata batching yourself—`WrapperFakeEntity` handles spawn, viewers, passenger mgmt, and `setNotifyAboutChanges`.

4. Per-entity data appliers (if needed)
   - For each new property:
     - Define `data class <X>Property(...): EntityProperty { companion object : SinglePropertyCollectorSupplier(...) }`.
     - Define an entry `class <X>Data(...) : GenericEntityData<<X>Property>` with `type()` and `build(player)`.
     - Write `fun apply<X>Data(entity: WrapperEntity, property: <X>Property)` using EntityLib metas:
       ```kotlin
       entity.metas {
       		 meta<DesiredMeta> { /* apply fields from property */ }
       		 error("Could not apply <X>Data to ${entity.entityType} entity.")
       }
       ```
     - Hook your applier from the wrapper entity’s `applyProperty` when property is matched.

## Using activities

- Implement `GenericEntityActivityEntry` and return an `EntityActivity` via `create(context, currentLocation)`.
- In your activity, update `currentPosition` and return `TickResult`.
- For smooth rotations/movement, use helpers like `updateLookDirection`, `Velocity`, and `PositionProperty`.
- Choose the right activity scope:
  - Shared: same behavior/position for all viewers (`SharedEntityActivityEntry`).
  - Individual: per-viewer behavior/position (`IndividualEntityActivityEntry`).

## Instances: simple vs advanced

- Simple: `SimpleEntityDefinition` + `SimpleEntityInstance` for straightforward spawn and optional shared activity.
- Advanced: use `SharedAdvancedEntityInstanceEntry`, `GroupAdvancedEntityInstanceEntry`, or `IndividualAdvancedEntityInstanceEntry` for complex lifecycles and show ranges.

## Events and interaction bounds

- `EntityInteractEventEntry`: fires on left/right click with filters for shift state and interaction type. Common use: start or continue dialogue with the clicked NPC.
- `LookAtEntityInteractionBoundEntry`: temporarily forces a player to look at an NPC within a radius and dynamically adjusts movement speed (zoom) using attribute modifiers. Useful for cutscenes or focused interactions.

## Quests integration

- `InteractEntityObjective`: objective text can include `<entity>` placeholder; highlights/interacts with NPCs and provides positions by querying active `AudienceEntityDisplay`s.

## Practical checklist when adding/changing entries

- Definition/Instance
  - [ ] IDs use snake_case; icon/color selected; `@OnlyTags` includes correct tags.
  - [ ] Instance uses the right activity scope (shared, group, individual) and sensible showRange.
- Properties/Data
  - [ ] New property has a `SinglePropertyCollectorSupplier` default and a matching `GenericEntityData` entry.
  - [ ] Applier uses `entity.metas { meta<...> { ... } }` with a helpful error fallback.
  - [ ] Wrapper entity routes properties in `applyProperty` and falls back to `applyGenericEntityData` and `applyLivingEntityData` as appropriate.
- Activities
  - [ ] Smooth movement/rotation (Velocity helpers) and returns proper `TickResult`.
  - [ ] Uses `Var` values via `.get(player)` where applicable.
- Events/Bounds/Quest
  - [ ] Event filters (shift, interaction type) match intended UX.
  - [ ] Bounds clean up (attribute modifiers removed on teardown) and are responsive.

## Notes

- PacketEvents `EntityTypes` drives the visual type; EntityLib wrappers + metas drive state/appearance without server-side entities.
- Avoid directly mutating Bukkit entities; operate via `WrapperEntity` and Typewriter’s `EntityProperty`s.
- Use `@Help` and `@Default` annotations to improve UX in the editor for ranges, booleans, durations, etc.
