# AGENT Instructions – Entity Extension

The Entity Extension turns Typewriter entries into client-side, packet-only entities: NPCs, mobs, holograms
and displays. It is built on [EntityLib](https://github.com/Tofaa2/EntityLib) (metadata) and PacketEvents
(`EntityTypes`). Everything here is read from the code, not from memory. If something disagrees with the code,
trust the code and fix this file.

## Fast path

| Task | Start here |
| --- | --- |
| Add a vanilla entity | `.claude/skills/add-entity/SKILL.md` (Claude: `/add-entity <TYPE>`) |
| Add or expose entity data | `.claude/skills/add-entity-data/SKILL.md` (Claude: `/add-entity-data`) |
| What does a type support, what is covered? | `bash scripts/entity-info.sh <TYPE>` (e.g. `BAT`, `armor_stand`) |
| Which entities are still missing? | `bash scripts/entity-info.sh --missing` |
| What does one EntityLib meta class expose? | `bash scripts/entity-info.sh AgeableMeta` |

`entity-info.sh` reads the EntityLib sources of the version in `engine/engine-paper/build.gradle.kts` from the
Gradle cache. Use it instead of browsing EntityLib on GitHub, because `master` is not the version we build
against.

## Map

Paths are relative to `src/main/kotlin/com/typewritermc/entity/entries/`.

| Folder | What lives there |
| --- | --- |
| `entity/minecraft/` | One `<Name>Entity.kt` per vanilla type: definition, instance and private wrapper |
| `entity/custom/` | Composite entities (`Npc`, `SelfNpc`, `NamedEntity`, `HologramEntity`, `StackedEntity`, `HitBoxEntity`, `InteractionIndicator`) and the size table `EntityTypeProperty.kt` |
| `entity/` | `WrapperFakeEntity` (base of every wrapper) and `RideableSittingSupport` |
| `data/minecraft/` | Generic data, routed by `GenericData.kt` |
| `data/minecraft/living/` | Living data (routed by `LivingData.kt`), plus one folder per mob or group (`bat/`, `tameable/`, `horse/` …) |
| `data/minecraft/display/`, `itemframe/`, `other/` | Display, item frame and leftover data |
| `activity/` | Activities: what an entity does each tick (look, patrol, path, …) |
| `instance/` | Advanced instances (shared, group, individual, multiple) |
| `audience/`, `quest/`, `event/`, `bound/`, `cinematic/`, `variable/` | Path streams, the interact objective, the interact event, look-at bound, cinematic entity, variables |

## How an entity works

- **Definition** (`SimpleEntityDefinition`) says *what* the entity is: `displayName`, `sound` and the `data`
  it carries. `create(player)` returns the wrapper.
- **Instance** (`SimpleEntityInstance`) says *where* it is (`spawnLocation`), adds its own `data` and picks an
  `activity`. Instance data always beats definition data. Properties set by the current activity beat both.
- **Wrapper** is a private class extending `WrapperFakeEntity(EntityTypes.X, player)`, which handles spawning,
  viewers, passengers and metadata batching. A wrapper only implements `applyProperty(property)`. It is
  called once per property that *changed*, inside a batch with notifications off.
- **Data → Property → apply.** A data entry (`EntityData<P>`) builds a `P : EntityProperty` per player. The
  property is a `data class` whose companion is a `SinglePropertyCollectorSupplier(P::class, default)`, and
  that default must be the *reset* value. When no data applies any more, the default is what the entity goes
  back to. An `apply<X>Data(entity, property)` function writes the property into EntityLib metadata.

## Meta → tags → wiring

Pick the tags from the entity's EntityLib meta chain, which `entity-info.sh` prints:

| Meta in the chain | Offer tag | Wire in `applyProperty` |
| --- | --- | --- |
| every entity | `generic_entity_data` | `if (applyGenericEntityData(entity, property)) return` |
| `LivingEntityMeta` | `living_entity_data` | `if (applyLivingEntityData(entity, property)) return` |
| `MobMeta` | `mob_data` | nothing yet: reserved for mob-level data (noAi, leftHanded, aggressive) |
| `AgeableMeta` | `ageable_data` | `is AgeableProperty -> applyAgeableData(entity, property)` in the `when` |
| `TameableMeta` | `tameable_data` | `if (applyTameableData(entity, property)) return` |
| `RaiderMeta` | `raider_data` | `is CelebratingProperty -> applyCelebratingData(entity, property)` in the `when` |
| `BaseHorseMeta` | `horse_data` only for a `HorseMeta`; other horses offer `saddled_data`, `eating_data`, `tamed_data`, `rearing_data` | a `when` branch for each horse property the entity takes (see `SkeletonHorseEntity.kt`) |
| `AbstractDisplayMeta` | `display_data` | `if (applyDisplayEntityData(entity, property)) return` |
| the entity's own meta | `<entity>_data` | a `when` branch per property, **only** once a data entry carries the tag |

Canonical shape, from `entity/minecraft/BatEntity.kt`:

```kotlin
override fun applyProperty(property: EntityProperty) {
    when (property) {
        is HangingProperty -> applyBatHangingData(entity, property)
        else -> {}
    }
    if (applyGenericEntityData(entity, property)) return
    if (applyLivingEntityData(entity, property)) return
}
```

A group tag offers *every* data carrying it. When some of that data can't apply to the entity, offer the
individual data tags instead (each data entry carries its own id as a tag). For example, `horse_data` includes
`HorseVariantData`, which only a `HorseMeta` takes.

A tag only works when three things agree:
- the data entry carries it,
- *both* `@OnlyTags` lists offer it (definition and instance, identical), and
- the wrapper routes its property.

Miss any one and the data silently does nothing. The parrot `tameable_data` fix (f48e405b41) was exactly this.

## Rules that break the build or the runtime

- **Size row.** Every `EntityTypes.X` needs a row in `entity/custom/EntityTypeProperty.kt`, or `state()` throws
  for that entity. Check with `entity-info.sh <TYPE>`. Add missing rows to `manualEntityData`, e.g.
  `EntityDataMatcher(EntityTypes.X) to EntityData(width = 0.6, height = 1.8, eyeHeight = 1.62)`, using the
  vanilla dimensions. Don't edit the `<editor-fold>` block: `code_generator/src/bin/entity_type_properties.rs`
  writes it. Humanoids that can sit also need a `pose = EntityPose.SITTING` row (see the zombie rows).
- **`@Tags("<x>_definition")` first.** `Ref<XDefinition>` resolves through the first `@Tags` value declared on the
  definition class. Leaving it out fails KSP with `NoTagsFoundException`.
- **KSP validates every entry while compiling.**
  - Ids match `^[a-z0-9_]+$`.
  - Every constructor parameter has a default.
  - No state outside the constructor.
  - Entry classes are neither `data` nor `abstract`.
  - Colours are hex.
  - Icons must exist on Iconify. Check one with `curl -s "https://api.iconify.design/mdi.json?icons=bat"`
    (`not_found` lists misses) and search with `curl -s "https://api.iconify.design/search?query=axolotl"`.
- **`@Default`.** KSP does not see Kotlin default values. Add `@Default("true")`, `@Default("\"CENTER\"")` and
  so on whenever the panel default should not be the type's zero value.
- **`metas {}` inside apply functions, never `meta<>()`.** `entity.metas { meta<X> { … }; error("…") }` runs
  every block whose meta matches and logs a warning when none does. `entity.meta<X> {}` turns notifications
  back on in the middle of `WrapperFakeEntity`'s batch.
- **Living data needs a living meta.** `applyLivingEntityData` returns false unless EntityLib registered a
  `LivingEntityMeta` for the type. `entity-info.sh` prints `Living: yes/no`.

## Conventions

- **Entity file:** `entity/minecraft/<Name>Entity.kt` holding `<Name>Definition`, `<Name>Instance` and a
  `private class <Name>Entity`.
  - Ids are `<snake>_definition` and `<snake>_instance`.
  - Definition: `Colors.ORANGE`, `@Tags("<snake>_definition")`.
  - Instance: `Colors.YELLOW`. The instance shares the definition's icon.
  - Instances take `activity: Ref<out SharedEntityActivityEntry>`.
- **Data file:** `data/minecraft/living/<entity>/<Entity><Field>Data.kt`, with no separator in the folder name
  (`armorstand`, `snowgolem`).
  - Id `<entity>_<field>_data`, `@Tags("<entity>_<field>_data", "<entity>_data")`, `Colors.RED`.
  - Property `<Entity><Field>Property`, as `PuffStateProperty` or `CatVariantProperty`. Older ones such as the
    bat's `HangingProperty` leave the entity out.
  - Data that several entities share goes in a group folder with a group tag (`tameable/`, `horse/`).
  - Don't add the catch-all `"data"` tag: nothing filters on it. `BatHangingData`, the bee data and
    `DancingData` still carry it.
  - `@Default` takes JSON: `@Default("true")`, or `@Default("\"SCARED\"")` for an enum.
  - Use a plain field for a fixed value. Use `Var<T> = ConstVar(…)` and `.get(player)` in `build` when the
    value may differ per player (see `itemframe/ItemFrameRotationData.kt`).
- **KDoc** goes between the annotations and the class:
  `The \`XDefinition\` class is an entry that …`, then `## How could this be used?`.
- **Code style** comes from `../AGENTS.md`: 4 spaces, 120 columns, guard clauses, no inline comments.
  - Fields a new entity leaves out go in your summary or PR description, not in a "Skipped data" comment.
  - Older files have such comments; leave them be.
- **Docs:** a new entity needs no docs change.
  - `documentation/docs/adapters` is generated and outdated; don't touch it.
  - `documentation/src/libs/adapters.json` is hand-curated; edit it only if a page has to show the entry.
- **Commits:** `feat(EntityExtension): add <name> entity`, subject under 72 characters.

## Verify

Run from `extensions/` (`.\gradlew.bat` in PowerShell):

```bash
./gradlew :EntityExtension:compileKotlin
```

That compiles and runs every KSP validator. It takes about 30s once Gradle is warm. On a cold cache it builds
the engine first, which takes about two minutes. From the repository root the same commands are
`extensions/gradlew -p extensions :EntityExtension:<task>`.

```bash
./gradlew :EntityExtension:test
```

This runs the kotest specs, including `EntityEntriesSpec`. That spec reads the entry manifest KSP writes to
`build/generated/ksp/main/resources/extension.json`, which `processResources` copies to
`build/resources/main/`. It also checks the sources. Gradle prints nothing per spec when everything passes; the
results are in `build/test-results/test/TEST-*.xml`. The spec fails when:
- two entries share an id,
- an instance and its definition offer different tags,
- an entity offers a tag no data carries,
- a data entry is offered to no entity, or
- an entity type has no size row.

CI runs `./gradlew :EntityExtension:test :EntityExtension:buildRelease`.

## Known issues, don't copy these

These were in the code before `EntityEntriesSpec` existed. The named sets there allowlist them, and the spec
fails once one of them is fixed, so the lists only shrink. Fixing one means deleting it from the spec and from
here.

| Issue | Allowlisted in |
| --- | --- |
| `marker_data` and `small_data` exist twice (`living/armorstand/` and `other/`). The armor stand routes one pair, the size table reads the other | `knownDuplicateIds` |
| `mob_data` is offered by most mobs but no data carries it yet | `reservedTags` |
| Placeholder `<entity>_data` tags no data carries: allay, block_display, breeze, camel, cave_spider, chicken, cow, creeper, donkey, elder_guardian, goat, interaction, piglin_dancing, polar_bear, skeleton, sniffer, spider, turtle | `placeholderTags` |
| Llamas offer `chested_horse_data`, but the chest data is tagged `chested_horse_chest_meta` / `chested_horse_meta` | `placeholderTags`, `unreachableData` |
| `PuffStateData` is offered to no entity | `unreachableData` |

These issues are not caught by the spec:
- EntityLib's `TraderLlamaMeta` extends `EntityMeta`, so the trader llama takes no living or llama data.
- EntityLib maps `DONKEY` to an `AgeableMeta`, not to `ChestedHorseMeta`, so horse data can't apply to it.
- Pig offers `SaddledData` but doesn't route it. Horse offers `TamedData` but doesn't route it.
- Llama offers every `horse_data` entry but routes none of them.
- Warden routes `AgeableProperty` on a `MobMeta`. Piglin routes `TremblingProperty` without offering
  `trembling_data`.
- `HitBoxEntity.applyProperties` batches notifications without the `try/finally` that `WrapperFakeEntity` has.
- Some names are misspelled: folder `living/scheep/`, files `BeeNectorData.kt` and `DIsplayTypeData.kt`, and
  `FrogVariantData.kt` holds `FrogData`.
- The armor stand definition id is `armorstand_definition`, while its tag is `armor_stand_definition`.
