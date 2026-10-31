---
name: add-entity-data
description: Add an entity data entry to Typewriter's EntityExtension (EntityData + EntityProperty + apply function) that exposes an EntityLib metadata field such as a variant, pose, flag or colour, and wire it into every entity that should take it, with compile + guard-test verification.
when_to_use: The user wants an entity to show or change something it can't yet, e.g. "let the bat hang", "expose the axolotl variant", "add data for the fox sleeping", "the goat is missing its horns", or the add-entity skill found NOT COVERED setters.
argument-hint: "<ENTITY_TYPE or MetaClass> <field>"
allowed-tools: Bash(bash *entity-info.sh *) Bash(extensions/gradlew -p extensions :EntityExtension*)
---

# Add entity data to the Entity Extension

`extensions/EntityExtension/AGENTS.md` holds the tag table, rules and known issues. Read it first if it is not
in context. Commands run from the repository root.

## 1. Find the setter

```bash
bash extensions/EntityExtension/scripts/entity-info.sh <ENTITY_TYPE or MetaClass>
```

- **`covered by X`:** the data already exists. Don't write a second one; go to step 4 and wire `X` into the
  entity.
- **`NOT COVERED`:** for an enum parameter the script lists the allowed values in `[…]`; for another object it
  lists the type's full name. To read the setter itself, open the meta source: the script prints its path
  relative to `extensions/EntityExtension/build/entity-info/<version>/me/tofaa/entitylib/meta/`.

## 2. Decide who takes it

| The setter lives on | Kind | Where it goes |
| --- | --- | --- |
| The entity's own meta (`BatMeta`, `FoxMeta`) | Per-entity | `data/minecraft/living/<entity>/`, tags `"<entity>_<field>_data", "<entity>_data"`, `EntityData<P>` |
| `TameableMeta` | Group | `living/tameable/`, implement `TameableData<P>`, add a branch to `applyTameableData` |
| `AbstractDisplayMeta` | Group | `display/`, implement `DisplayEntityData<P>`, add a branch to `applyDisplayEntityData` |
| `LivingEntityMeta` | Group | `living/`, implement `LivingEntityData<P>`, add a branch to `applyLivingEntityData` |
| `EntityMeta` | Group | `data/minecraft/`, implement `GenericEntityData<P>`, add a branch to `applyGenericEntityData` |
| `AgeableMeta`, `RaiderMeta`, `BaseHorseMeta` | Group, no router | The group's folder and tag (`ageable_data`, `raider_data`, `horse_data`), plus a `when` branch in **every** wrapper that offers the tag |
| A non-living meta (`ItemFrameMeta`) | Per-entity | `data/minecraft/<group>/`, like `itemframe/` |

Paths are under `extensions/EntityExtension/src/main/kotlin/com/typewritermc/entity/entries/`. Folder names
have no separators (`armorstand`, `snowgolem`).

## 3. Write the data file

Copy [template.kt](template.kt) and fill in every `{{…}}`.

- **Value types and panel defaults.** The panel default is what a new data entry starts with. Pick the value an
  author most likely wants when they add the data, which is usually not the reset value. For example,
  `BatHangingData` starts at `true` and resets to `false`. KSP ignores Kotlin defaults, so write it with `@Default`
  as JSON:
  - A boolean flag gets `@Default("true")` when the panel should start ticked.
  - An enum gets a JSON string, `@Default("\"SCARED\"")`. Some older files write it unquoted; don't copy that.
  - A Java enum, from EntityLib or PacketEvents, can be the field type directly (`CatMeta.Variant`, see
    `cat/CatVariantData.kt`).
  - Registry-backed values get a Kotlin enum that maps to them (see `wolf/WolfVariantData.kt`).
  - Use `Var<T> = ConstVar(…)` with `.get(player)` in `build` when the value may differ per player, plus
    `@Help` when the meaning isn't obvious (see `itemframe/ItemFrameRotationData.kt`).
- **The companion default is the reset value**, e.g. `HangingProperty(false)`. Without one, the entity keeps
  its last value after the data stops applying.
- **The apply function** uses `entity.metas { meta<X> { … }; error("Could not apply … to ${entity.entityType}
  entity.") }`. One `metas` block may hold a `meta<…>` branch for every meta that has the field (see
  `living/AgeableData.kt`).
- **Naming:**
  - Data class `<Entity><Field>Data`, property `<Entity><Field>Property` (as `PuffStateProperty`), id
    `<entity>_<field>_data`, `Colors.RED`. Fields such as `State` and `Variant` are too generic to name a
    property on their own.
  - Reuse the entity's icon where it fits.
  - KDoc like `bat/BatHangingData.kt`, with a real use in a story.
  - Don't add the catch-all `"data"` tag.

## 4. Wire it into every entity that should take it

A tag only works when all three agree:

1. **The data carries the tag.** That comes from `@Tags` or from the group interface.
2. **Both `@OnlyTags` lists offer it.** That means the definition *and* the instance of every entity meant to
   take it, kept identical.
3. **The wrapper routes the property.** Either a `when` branch `is <Field>Property -> apply<Entity><Field>Data(entity,
   property)` in each wrapper, or a router branch, which serves every entity calling that router.

Check each entity's file afterwards. `bash extensions/EntityExtension/scripts/entity-info.sh <TYPE>` should now
show the setter as covered.

## 5. Verify

```bash
extensions/gradlew -p extensions :EntityExtension:compileKotlin
extensions/gradlew -p extensions :EntityExtension:test
```

Gradle prints nothing per spec when everything passes. The per-spec results are in
`extensions/EntityExtension/build/test-results/test/TEST-*.xml`.

- **"`x_data` carries no tag that any entity offers":** step 4.2 was missed.
- **"offer `x`, but no data entry carries it":** the entity offers a tag before any data carries it.
- **KSP default or icon errors:** see the table in AGENTS.md under "Rules that break the build or the runtime".

## 6. Report

List the data added, its id and tags, and which entities now take it and how (router or `when`). Also list
the setters you deliberately left out. Don't commit unless asked.
