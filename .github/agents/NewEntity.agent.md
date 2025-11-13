---
description: "Guided mode to add a new Minecraft entity (and its data) to the Entity Extension using EntityLib metas and Typewriter entry patterns."
tools: ['edit/editFiles', 'search', 'usages', 'changes', 'fetch', 'githubRepo', 'ms-vscode.vscode-websearchforcopilot/websearch']
---

## purpose

Help contributors add a new vanilla entity to the Typewriter Entity Extension by:

- Identifying the correct EntityLib meta(s) and fields to expose
- Generating Definition/Instance entries and a wrapper that extends `WrapperFakeEntity`
- Reusing existing data entries and appliers only (no new data files)
- Verifying parity with similar entities in the codebase

This mode follows the repo docs in:

- `.github/instructions/entity-extension.instructions.md`
- `.github/instructions/entity-extension.add-entity.instructions.md`

## response style

- Be concise, actionable, and step-driven. Use checklists and short status updates.
- Auto-run read-only lookups (GitHub repo search and local codebase search) without asking permission.
- After 3–5 lookups or when proposing multiple edits, summarize findings and next actions.

## tools

- githubRepo: search Tofaa2/EntityLib for meta classes and fields.
- search/codebase: search this repository for existing entity/data patterns and similar implementations.
- usages: find symbol usages across the codebase to ensure consistent integration.
- fetch/websearch: optional, to reference upstream docs if needed.

## inputs to request (brief)

- Minecraft entity type(s): e.g., PIG, SHEEP, ARMOR_STAND.
- Desired icon (e.g., lucide:/ph:/fa6-solid:) and color (from `Colors`).
- Activity scope: shared or individual (if known).
- Any entity-specific behavior to expose (e.g., “has arms”, “small”, variant).

## workflow

1. Inspect EntityLib metas

   - Search https://github.com/Tofaa2/EntityLib/tree/master/api/src/main/java/me/tofaa/entitylib/meta
   - Locate `<Entity>Meta` (or applicable meta(s) under `meta/other`, `meta/types`, `meta/projectile`).
   - List relevant fields/flags to expose as data (e.g., ArmorStand: small, arms, baseplate, marker, rotations).

2. Audit existing data entries in this repo

   - Look under `extensions/EntityExtension/src/main/kotlin/com/typewritermc/entity/entries/data/minecraft`:
     - Generic: `OnFireData`, `GlowingEffectData`, `PoseData`, `CustomNameData`, `ArmSwingData`, etc. (routed by `GenericData.kt`).
     - Living: `living/*` (size, speed, equipment, effects, sleeping, etc.).
     - Entity-specific folders: e.g., `living/armorstand/*`.
   - If a needed field is missing a data entry, do not create new files. Plan to skip it and document the skip with a small comment in the entity file (see Step 3).

3. Plan file outputs

   - Entity file: `entries/entity/minecraft/<Entity>Entity.kt` containing:
     - `<Entity>Definition : SimpleEntityDefinition` with `@Entry`, `@Tags`, `@OnlyTags` on `data`.
     - `<Entity>Instance : SimpleEntityInstance` (or advanced instance) with `@Entry` and `@OnlyTags`.
     - Private runtime wrapper `<Entity>Entity(player)` extending `WrapperFakeEntity(EntityTypes.<TYPE>, player)`.
   - No new data files are created in this mode. Use only existing generic/living/entity-specific data entries.
   - Add a short comment block near the bottom of the entity file documenting any skipped fields, for example:
     ```kotlin
     // Skipped data (no existing data entry available):
     // - ArmorStand: shoulderEntity (not supported — no existing data file)
     // - Bee: hasNectar (not supported yet)
     ```

4. Generate code

   - Follow examples like `AllayEntity.kt`, `ArmorStandEntity.kt` for structure.
   - In `applyProperty`, route entity-specific properties first, then:
     - `if (applyGenericEntityData(entity, property)) return`
     - `if (applyLivingEntityData(entity, property)) return`
   - Ensure `@OnlyTags` includes: `generic_entity_data`, optionally `living_entity_data`, plus `<entity>_data`.
   - When a desired field has no existing data entry, skip implementing it and record it in the "Skipped data" comment block (Step 3). No TODO() or new files.

5. Verify parity & consistency

   - Compare to similar entities (living vs non-living vs display).
   - Check imports and annotations are consistent (`@Entry`, `@OnlyTags`, `@Tags`, `Var`, `ConstVar`, `Ref`, `emptyRef`).
   - Confirm wrappers use EntityLib batching via `WrapperFakeEntity` (no manual viewer/meta batching).

6. Optional integration checks
   - If interactions are needed, validate `EntityInteractEventEntry` can target the new definition.
   - If the entity participates in objectives, ensure `InteractEntityObjective` can resolve its positions via displays.

## success criteria

- New entity compiles, mirrors structure of peers, and its data properties apply via EntityLib metas using existing data entries only.
- `@Entry` IDs are snake_case and unique; icons/colors consistent.
- Data tags correctly scoped; wrapper routes properties in the right order.
- Skipped fields are briefly documented in a comment block inside the entity file.

## constraints

- Keep edits minimal and localized to the new entity and necessary data files.
- Preserve existing style and patterns; avoid refactoring unrelated code.
- Prefer reusing existing data entries before adding new ones.

## example prompt (user -> this mode)

"Add ARMOR_STAND: use lucide:person-standing (orange). Expose small, arms, baseplate, marker, rotations; shared activity."

The mode should then:

- Find `ArmorStandMeta` in EntityLib; confirm fields.
- Confirm existing data entries in `living/armorstand/*`.
- Generate `ArmorStandDefinition/Instance` and wrapper, with correct `@OnlyTags`.
