# Minecraft value types

Value types that Minecraft capabilities and Paper extensions use in entry fields, formulas, and stored data. They live under the Minecraft capability; core primitives never depend on them (see [overview.md](overview.md)). Build order: layer 4 in [closed-beta-roadmap.md](closed-beta-roadmap.md).

## Type identity

Every type uses a generated id like every other Typewriter type: a UUIDv7 as 32 hex digits in a constant (`const val WORLD_TYPE_ID = "019d..."`, the same pattern as `COLOR_TYPE_ID` in `VisualValues.kt`), plus `revision` (default 1). Namespaced strings such as `minecraft:world` are never type ids.

## Space: world, vector, rotation

Spatial data has three parts: a **world**, a **vector** (x, y, z), and a **rotation** (yaw, pitch). Different uses need different combinations, so there is one exact type per real combination. An entry field always asks for exactly the type it needs; nothing in it is optional, and the panel shows exactly those parts (a particle field has no rotation to fill in).

| Type | Parts | Example use |
| --- | --- | --- |
| `Vec3` | vector | velocity, offsets, particle spread |
| `BlockVec` | whole number vector | a block offset |
| `Rotation` | rotation | "look in this direction" cue |
| `Pose` | vector + rotation | camera keyframe relative to a scene origin |
| `Location` | world + vector | particle spot, sound location, region center |
| `BlockLocation` | world + whole number vector | fake block, block events |
| `Position` | world + vector + rotation | teleport, NPC spawn |

A combination without a real use (world + rotation) gets no type until something needs it; adding one is a single data class.

### World

```kotlin
@JvmInline
@Serializable
@TypewriterType(id = WORLD_TYPE_ID)
value class World(val key: String) // "minecraft:overworld", "myserver:arena"
```

A world is identified by its namespaced key (Paper `World.getKey()`), not by UUID or name. A UUID changes when a world is copied to another server, which breaks templates and multi server setups; a key is stable and readable. A reference to a key that no engine reports is a publication check diagnostic. The panel edits a world through a picker of the worlds the engines report.

### Part interfaces

Each part is an interface with a self type, so operations written once return the receiver's own type:

```kotlin
interface Vector { val x: Double; val y: Double; val z: Double }

interface InWorld<S : InWorld<S>> { val world: World; fun withWorld(world: World): S }
interface HasVector<S : HasVector<S>> : Vector { fun withVector(x: Double, y: Double, z: Double): S }
interface HasRotation<S : HasRotation<S>> { val yaw: Float; val pitch: Float; fun withRotation(yaw: Float, pitch: Float): S }
interface HasBlock<S : HasBlock<S>> { val x: Int; val y: Int; val z: Int; fun withBlock(x: Int, y: Int, z: Int): S }
```

In the catalog the part interfaces are abstract records; the exact types list them in `parents`. Entry fields never use a part interface as their type, so the polymorphic form picker never appears for spatial fields. Formula functions may take them.

### Exact types

Exact types are flat data classes, so the generated `copy` works per field and returns the same type. Each implements one line per part:

```kotlin
@Serializable
@TypewriterType(id = LOCATION_TYPE_ID)
data class Location(
    override val world: World,
    override val x: Double,
    override val y: Double,
    override val z: Double,
) : InWorld<Location>, HasVector<Location> {
    override fun withWorld(world: World) = copy(world = world)
    override fun withVector(x: Double, y: Double, z: Double) = copy(x = x, y = y, z = z)
}

@Serializable
@TypewriterType(id = POSITION_TYPE_ID)
data class Position(
    override val world: World,
    override val x: Double,
    override val y: Double,
    override val z: Double,
    override val yaw: Float,
    override val pitch: Float,
) : InWorld<Position>, HasVector<Position>, HasRotation<Position> {
    override fun withWorld(world: World) = copy(world = world)
    override fun withVector(x: Double, y: Double, z: Double) = copy(x = x, y = y, z = z)
    override fun withRotation(yaw: Float, pitch: Float) = copy(yaw = yaw, pitch = pitch)
}
```

`Vec3`, `BlockVec`, `Rotation`, `Pose`, and `BlockLocation` follow the same pattern.

### Operations

Written once against the part interfaces; chaining keeps the type:

```kotlin
fun <S : HasVector<S>> S.add(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0): S =
    withVector(this.x + x, this.y + y, this.z + z)
operator fun <S : HasVector<S>> S.plus(v: Vector): S = add(v.x, v.y, v.z)
fun <S : HasVector<S>> S.lerp(to: Vector, t: Double): S = ...
fun <S> S.lookAt(target: Vector): S where S : HasVector<S>, S : HasRotation<S> = ...

spawn.copy(y = 64.0).add(z = 2.0).withWorld(arena) // a Location
```

Switching between types is explicit, through plain properties and functions:

```kotlin
position.location     // drop the rotation
location.with(rotation) // a Position
location.block        // a BlockLocation (floor)
blockLocation.center  // a Location
```

### Distance

Distance between values that have a world respects the world: values in different worlds have no distance, as in legacy (`Position.kt` on `origin/develop`).

```kotlin
fun Vector.distance(other: Vector): Double // Vec3, Pose
fun <A, B> A.distance(other: B): Double?   // null across worlds
    where A : InWorld<A>, A : Vector, B : InWorld<B>, B : Vector
fun <A, B> A.isInRange(other: B, range: Double): Boolean // false across worlds
    where A : InWorld<A>, A : Vector, B : InWorld<B>, B : Vector
```

In a formula:

```
protagonist.location.isInRange(npc_spot, 5)
spawn.copy(y = 64).add(z = 2)
```

### Panel

Each exact type has its own editor showing exactly its parts. Capture (layer 13) fills exactly those parts from the player; teleport to a `Location` keeps the player's current facing.

## Items

Building an item and recognizing an item are separate jobs with separate tools.

### Item forms

`Item` is an open interface; each item source is one form. The panel switches forms through the existing union editor.

```kotlin
interface Item { val amount: Int }

@TypewriterType(id = MINECRAFT_ITEM_TYPE_ID)
data class MinecraftItem(
    val material: Material,
    override val amount: Int = 1,
    val components: Set<ItemComponent> = emptySet(),
) : Item

// Nexo extension: Nexo owns the item's look and behavior
data class NexoItem(val id: NexoId, override val amount: Int = 1) : Item
```

A real stack read from the game comes back in its most specific form (see [engines.md](engines.md#bridges)), so `it is NexoItem && it.id == ruby` works in match formulas. Legacy `SerializedItem` (Bukkit bytes) does not exist: everything an item carries is a typed component, and anything that cannot be represented is dropped on capture with a panel notice.

### Components

`ItemComponent` is an open interface; any extension adds components through catalog `parents`. Each component is a small, complete record.

```kotlin
interface ItemComponent

data class Name(val text: RichText) : ItemComponent
data class Lore(val lines: List<RichText>) : ItemComponent
data class Consumable(val duration: Duration, val animation: UseAnimation, val sound: Sound) : ItemComponent
data class Food(val nutrition: Int, val saturation: Float, val alwaysEdible: Boolean = false) : ItemComponent
data class UseCooldown(val duration: Duration, val group: String = "") : ItemComponent
data class Durability(val max: Int, val remaining: Int = max) : ItemComponent
data class Tag(@Key val key: String, val value: String) : ItemComponent
```

- A component without `@Key` appears at most once per item; with `@Key`, once per key. `with(x)` replaces the component with the same type and key; two equal-keyed components written by hand are a publication check error.
- Reading falls back to the material default: `item[Food]?.nutrition` on an apple is 4. `without(Food)` stores a removal, so defaults can be removed.
- Components follow Minecraft's composable split (an edible item is `Consumable` + `Food`) and merge only true duplicates: one `Name` (`item_name` and `custom_name`), one `Enchantments` (`enchantments` and `stored_enchantments`), hiding as a field on the component (`tooltip_display`), `Durability(max, remaining)` (`max_damage` and `damage`), and real `Duration`, `Color`, and `Sound` values.
- The Minecraft capability owns the mapping from components to Minecraft data components (Java 26.3 has 122). Components Paper's typed API lacks are written through NMS by the Paper engine. Not stored: components the game never encodes (`creative_slot_lock`, `map_post_processing`, `additional_trade_cost`, `debug_stick_state`) and raw NBT components (`entity_data`, `bucket_entity_data`, `block_entity_data`, `bees`, `lock`).
- Item behavior ("on use, do X") is not part of the item: it is an event with a match formula.

### Recognizing items

Matching is a formula over an item, through formula function types:

```kotlin
class RemoveItem(val matches: Var<(Item) -> Boolean, MemberContext>, val amount: Var<Int, MemberContext>)
```

```
it is MinecraftItem and it.material == minecraft.item.diamond
it[Tag("quest")]?.value == "lost_key"
it.is_like(reward_item)        // same item, amount ignored
protagonist.inventory.count { it.is_like(reward_item) } >= 5
```

## Types still to design

Inventory of Minecraft values that need their own typed value in entry fields, formulas, stored data, or events, including ones legacy never had. Each row is designed later; this list fixes only the name and the reason. **(R)** marks a registry id: valid values are data driven per server and version, so the engines report them and the panel picks from that report. Legacy is `origin/develop` (`engine/`, `extensions/`).

### Registry ids

| Type | What it is | Why we need it | Hard part | Legacy had it |
| --- | --- | --- | --- | --- |
| `Material` (R) | item or block kind | item form, block checks | items and blocks are two registries; changes every version | yes |
| `BlockType` (R) | block kind without state | "player breaks any oak log" | split from `Material`; changes every version | partial (`Material`) |
| `EntityType` (R) | entity kind | spawn check, kill objective | variant data differs per type | yes |
| `SoundEvent` (R) | sound id | play a sound | custom sounds from resource packs are not in the registry | yes (`SoundId`) |
| `ParticleType` (R) | particle id | particle effect | options differ per particle (see `Particle`) | yes (enum only) |
| `PotionEffectType` (R) | status effect id | give speed | changes every version | yes |
| `Potion` (R) | potion recipe id (`strong_swiftness`) | potion item component | data driven | no |
| `Enchantment` (R) | enchantment id | `Enchantments` component, checks | data driven per server (datapacks) | no |
| `Attribute` (R) | attribute id (`max_health`) | attribute modifier on item or player | changes every version | no |
| `DamageType` (R) | damage source kind | "player dies from fall" | data driven per server | partial (`DamageCause`) |
| `Biome` (R) | biome id | "player enters a desert" | data driven per server | partial |
| `Dimension` (R) | dimension type id | world rules by dimension | data driven; distinct from `World` | no |
| `Structure` (R) | structure id | "player enters a village" | data driven; needs world query | no |
| `Advancement` (R) | advancement id | grant or check advancement | data driven per server | no |
| `Recipe` (R) | recipe id | unlock or detect craft | data driven per server | no |
| `LootTable` (R) | loot table id | reward from a table | data driven per server | no |
| `ItemTag` (R) | item tag (`#logs`) | match any log in a formula | data driven; content changes per version | no |
| `BlockTag` (R) | block tag | "break any ore" | data driven | no |
| `EntityTypeTag` (R) | entity type tag | "kill any undead" | data driven | no |
| `GameRule` (R) | game rule id with typed value | set `doDaylightCycle` per world | value type differs per rule (boolean or int) | no |
| `Statistic` (R) | statistic id | "walked 1000 blocks" | nested: statistic type plus target | no |
| `VillagerProfession` (R) | profession id | NPC villager look | changes every version | yes |
| `VillagerType` (R) | villager biome skin | NPC villager look | data driven | yes |
| `PaintingVariant` (R) | painting motive | display or reward | data driven per server | no |
| `TrimPattern` (R) | armor trim pattern | armor component | data driven | no |
| `TrimMaterial` (R) | armor trim material | armor component | data driven | no |
| `BannerPattern` (R) | banner pattern id | banner component | data driven | no |
| `JukeboxSong` (R) | music disc song | `JukeboxPlayable` component | data driven | yes (component) |
| `Instrument` (R) | goat horn sound | instrument component | data driven | no |
| `MobVariant` (R) | wolf, cat, frog, pig, cow, chicken variant | NPC look | one registry per mob; grows each version | partial (per mob enums) |
| `Font` (R) | font id | rich text font | resource pack defined; not a server registry | no |
| `ItemModel` (R) | item model id | `ItemModel` component | resource pack defined | yes (component) |
| `DialogId` (R) | data driven dialog | open a datapack dialog | new (1.21.6); data driven | no |

### World and blocks

| Type | What it is | Why we need it | Hard part | Legacy had it |
| --- | --- | --- | --- | --- |
| `BlockState` | block type plus property values | fake block, block display, block event match | properties per block change every version; per property conditional fields | partial (`Material` only) |
| `BlockStateMatch` | block type plus a subset of properties | "any lit furnace" | partial match semantics | no |
| `Direction` | six faces | sign facing, block face clicked | none | yes |
| `Region` | shaped area in a world (box, sphere, polygon) | area enter and leave | panel editing in 3D; spatial index | partial (extensions) |
| `Weather` | clear, rain, thunder | per player weather | per player versus world | yes (`WeatherType`) |
| `TimeOfDay` | world ticks in a day | per player time, time window checks | ticks versus clock time | yes (`GameTimeRange`) |
| `WorldBorder` | center, size, warning, damage | per player border cinematic | per player border is packet only | yes (segment) |
| `Difficulty` | peaceful to hard | world rule checks | none | no |
| `Heightmap` | surface kind | "highest block" queries | rarely needed | no |

### Entities

| Type | What it is | Why we need it | Hard part | Legacy had it |
| --- | --- | --- | --- | --- |
| `GameMode` | survival, creative, adventure, spectator | set or check mode | none | partial (internal) |
| `EquipmentSlot` | hand, offhand, armor, body, saddle | equipment data, events | slots grow per version | yes |
| `Hand` | main or off hand | interact events | none | yes (`HoldingHand`) |
| `EntityPose` | standing, sneaking, swimming, sleeping | NPC pose | grows per version | yes |
| `Skin` | texture value plus signature | NPC skin | signing; fetching from Mojang | yes (`SkinProperty`) |
| `PlayerProfile` | uuid, name, skin | head item, NPC identity | lookup and caching | partial |
| `EntityData` | per entity type settable data | NPC look (sheep color, slime size) | per entity type conditional fields; changes every version | yes (about 90 data classes) |
| `AttributeModifier` | attribute, amount, operation, slot | item and player stats | operation and slot groups | no |
| `DisplayTransform` | translation, scale, rotation (quaternions) | display entity cinematics | quaternion editing; needs panel preview | partial |
| `Billboard` | fixed, vertical, horizontal, center | display entities | none | yes |
| `Brightness` | block and sky light | display entities | none | yes |
| `ArmSwing` | swing animation | NPC animation | none | yes |
| `Team` | scoreboard team id | glow color, name tag rules | per player teams via packets | no |

### Effects and visuals

| Type | What it is | Why we need it | Hard part | Legacy had it |
| --- | --- | --- | --- | --- |
| `Sound` | sound event, source, volume, pitch, seed | play, stop, item `Consumable` | custom ids; per player versus world | yes |
| `SoundSource` | master, music, records, ambient | volume channel | none | yes (`Source`) |
| `Particle` | particle type plus options | particle effect | options per type: dust (color, scale), block, item, vibration, trail, entity effect color; changes every version | partial (no options) |
| `PotionEffect` | type, amplifier, duration, ambient, particles, icon | give or check an effect | infinite duration | yes (segment) |
| `FireworkEffect` | shape, colors, fade colors, trail, twinkle | fireworks cinematic, item component | lists of colors | partial |
| `DyeColor` | sixteen dye colors | sheep, beds, banners | maps to `Color` for some uses | yes |
| `ScreenEffect` | camera overlay (pumpkin, freeze, blindness) | cinematic overlays | some are effects, some packets | partial (segments) |

### Text and UI

| Type | What it is | Why we need it | Hard part | Legacy had it |
| --- | --- | --- | --- | --- |
| `RichText` | styled text with click and hover events, fonts | messages, names, lore | needs panel preview; placeholders | yes (MiniMessage string) |
| `ClickAction` | open url, run command, copy, show dialog, custom | rich text and dialogs | action set grows per version | partial |
| `HoverContent` | text, item, or entity tooltip | rich text | nested values | partial |
| `TextColor` | named or hex text color | text, teams, glowing | named versus hex | partial (`Color`) |
| `Title` | title, subtitle, fade in, stay, fade out | title cue | times as `Duration` | yes |
| `BossBar` | text, progress, color, overlay, flags | progress display | color and overlay enums | yes (parts) |
| `ScoreboardSidebar` | objective title plus lines | sidebar display | per player, number format | partial |
| `ObjectiveCriteria` | scoreboard criterion | vanilla scoreboard link | data driven names | no |
| `DisplaySlot` | sidebar, list, below name | scoreboard placement | team colored sidebars | no |
| `MenuType` | chest rows, anvil, hopper, crafter | custom menus | per type slot layout | partial (`InventoryType`) |
| `Dialog` | native dialog screen: notice, confirmation, multi action, inputs | quest choices, input forms | new (1.21.6); input kinds and actions grow per version; needs panel preview | no |
| `Toast` | advancement style popup | quest notifications | needs a fake advancement | no |
| `WaypointStyle` (R) | locator bar style | quest marker on the locator bar | new (1.21.6); data driven | no |
| `KeyBind` | client key id (`key.jump`) | "press [jump]" in text | client side only | no |
| `TabListEntry` | header, footer, entry name | tab list display | per player | no |

### Gameplay and rules

| Type | What it is | Why we need it | Hard part | Legacy had it |
| --- | --- | --- | --- | --- |
| `Command` | command line to run | run as console or player | placeholders; validation | yes (string) |
| `Permission` | permission node | gate content | provider plugins | yes |
| `InteractAction` | left or right click, on block or air | interact events | none | yes |
| `ItemUseAnimation` | eat, drink, block, bow, spear | `Consumable` component | grows per version | no |
| `ExperienceAmount` | levels or points | reward, check | levels versus points | no |
| `Damage` | amount plus damage type and source | damage action, death events | source entity optional | partial |
| `Cooldown` | duration plus group | `UseCooldown` component | none | no |

### Other

| Type | What it is | Why we need it | Hard part | Legacy had it |
| --- | --- | --- | --- | --- |
| `NamespacedKey` | generic `namespace:path` | data container keys, custom ids | which registry it points to | yes |
| `CronSchedule` | calendar schedule | daily quests, resets | time zones | yes (`CronExpression`) |
| `Server` | server id in a network | cross server teleport | network topology | no |
| `ResourcePack` | pack url, hash, prompt | send a pack | hash and per player status | no |

## Requirements on other layers

- Formula type checker (layer 1): bounded generics (`S : HasVector<S>`) and `where` clauses with several bounds.

## Open

- Verify in layer 4 that Kotlin overload resolution picks the world aware `distance` for `Location` and `Position` over `Vector.distance`; if not, the worldless version gets its own name.
- The full component list (every settable Minecraft data component as a component type).
- Registry ids (sound, particle, material, entity type, potion effect) and sounds are not designed yet.
