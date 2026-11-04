# Generated types

Minecraft has more than 100 item components and more than 150 entity types. Typewriter owns its data, so each needs a typed record and a mapping at the bridge. A KSP processor writes them from a game schema, with automatic corrections and with hand written types taking priority. Decided 2026-11-05 in the layer 10 rough design.

The output is ordinary typed Kotlin. The schema is only an input: nothing serialized or raw reaches our data.

Nothing here is built yet. See [Not proven](#not-proven).

## What it writes

The first generator runs once and holds no Paper. Counts are from the schema on 26.2.

| What | How many | Example |
| --- | --- | --- |
| Component types | 111 | `Food`, `Glider`, `MaxStackSize` |
| Named records | 59, many of them components | `ToolRule` |
| Enums | 28 | `Rarity`, `DyeColor` |
| Id types, each a [domain](domains.md) | About 40 | `JukeboxSong`, `Attribute` |
| Sealed families | A few | `ConsumeEffect`, with 5 kinds |
| Entity data | 136 groups and types | `Sheep`, `Breedable` |
| Shape list | 1 file | Compared with the shape lock |

The shape of a component decides its class:

```kotlin
// A number. The schema also gives the range, 1..99.
@TypewriterType(id = "...") @JvmInline
value class MaxStackSize(val value: Int) : ItemComponent

// No fields.
@TypewriterType(id = "...")
data object Glider : ItemComponent

// An enum used by one component: the enum is the component, so there is no second type.
@TypewriterType(id = "...")
enum class Rarity : ItemComponent { COMMON, UNCOMMON, RARE, EPIC }

// A shape that depends on a type field.
@TypewriterType(id = "...") sealed interface ConsumeEffect
@TypewriterType(id = "...") data class PlaySound(val sound: Sound) : ConsumeEffect

// An id type, and its name in formulas: minecraft.jukeboxSong.cat
@TypewriterType(id = "...") @JvmInline
value class JukeboxSong(override val key: String) : DomainValue
val Minecraft.jukeboxSong: Domain<JukeboxSong> get() = Domain()
```

Value types inside components split the same way (decided 2026-11-05): Minecraft specific ones such as `ToolRule`, `EquipmentSlot`, and `ConsumeEffect` are generated, and ones used all over Typewriter (`RichText`, `Duration`, `Color`, `Sound`) are hand written.

It runs in steps: read the schema and drop what is not on the newest version; build a small model (record, sealed, enum, id, list, number, empty); apply the corrections, each a plain function from model to model; skip what is hand written; write Kotlin with KotlinPoet, plus the shape list. Fields keep the game's names (`canAlwaysEat`, `cooldownGroup`); only hand written merges such as `Name` and `Durability` differ.

## Sources

| Source | Gives | Does not give |
| --- | --- | --- |
| Game reports (`--reports`) | All ids, block properties, default item values | Component fields, only samples of them |
| [vanilla-mcdoc](https://github.com/SpyglassMC/vanilla-mcdoc), MIT, exported as JSON | Every field, docs, version ranges, which fields are ids, entities | Default values, except as text in the docs |
| Paper's API, on the compile classpath | The getters and builders a mapping must call | Nine components, anything newer than the compiled Paper |

Measured on 26.2 (schema revision `0ca060a4f`, 2026-10-28):

- 111 of 111 components and 155 of 158 entity types are in the schema. 43 of 49 block entity types are; whether the missing six hold data was not checked.
- 3573 of the 3574 unique default values in the game's reports fit the schema. Those values cover 59 components; the other 52 have no sample.

## End to end

### 1. A processor in one module

No new annotation. Only the Minecraft types module runs it, and the main processor is unchanged.

```kotlin
dependencies { ksp(project(":minecraft-codegen")) }

// A checked in copy of the schema, so builds work offline.
ksp { arg(MinecraftInputs(schema = file("schema/vanilla-mcdoc.json"))) }
```

### 2. It writes the records, with corrections

The module holds no Paper types, so another engine can use the same records.

```kotlin
@TypewriterType(id = "...")               // hash of "minecraft:consumable"
data class Consumable(
    val consumeSeconds: Duration? = null, // was Float: the name rule
    val animation: ItemUseAnimation? = null,
    val onConsumeEffects: List<ConsumeEffect>? = null,
)
sealed interface ConsumeEffect            // the 5 effect kinds, from the schema
```

### 3. The existing processor takes over

KSP hands generated files to the next round, so generated records get their SDK like any other type. Hand written code can use them.

### 4. The Paper module generates the bridges

A second generator runs once per version layer. It reads the same schema, finds each generated type, and looks for the matching Paper API on the compile classpath. Each component gets one object, and `MinecraftItemBridge` loops over them, found by supertype.

```kotlin
object FoodBridge : ItemComponentBridge<Food> {
    override fun write(stack: ItemStack, value: Food) {
        stack.setData(DataComponentTypes.FOOD, FoodProperties.food()
            .nutrition(value.nutrition)
            .saturation(value.saturation)
            .also { b -> value.canAlwaysEat?.let(b::canAlwaysEat) }
            .build())
    }

    override fun read(stack: ItemStack): Food? =
        stack.getData(DataComponentTypes.FOOD)?.let {
            Food(it.nutrition(), it.saturation(), it.canAlwaysEat())
        }
}

object GliderBridge : ItemComponentBridge<Glider> {
    override fun write(stack: ItemStack, value: Glider) = stack.setData(DataComponentTypes.GLIDER)
    override fun read(stack: ItemStack) = Glider.takeIf { stack.hasData(DataComponentTypes.GLIDER) }
}
```

`ItemComponentBridge` is one new small interface. `Bridge<T, P>` does not fit, because `Glider` has no Paper value.

| Case | Newest Paper | Older Paper |
| --- | --- | --- |
| No Paper component | Build error, unless a hand written bridge exists | No bridge, so it is dropped |
| A field has no getter | Build error: add a rule or a bridge | The field is skipped |
| Hand written bridge exists | The generator skips that one | The generator skips that one |

### 5. Hand written always wins

The processor sees a hand written type or bridge in its first round and skips that one. This is how friendly merges such as `Name` and `Durability` stay possible, with no override file and no annotation.

```kotlin
@TypewriterType(id = CONSUMABLE_TYPE_ID)
data class Consumable(val consumeTime: Duration, val effects: List<ConsumeEffect>)
```

### 6. The shape lock

Records live in the build folder, so a changed record shows no code diff. A checked in list of every stored field shows it instead. The build fails when the list differs, and a maintainer accepts the change with one command.

```
food.nutrition           Int
food.saturation          Float
consumable.animation     ItemUseAnimation?
```

## Supported versions

Every release from 1.21.4 to the newest is supported, and the newest gets the best support. Nobody has to support each version separately: bridges merge through [version layers](engines.md#version-layers) (decided 2026-11-05).

The generator puts each bridge in the first layer where it appears, and adds another only when Paper's API changed. Merged, that is 121 bridges for 104 components, against 811 for one full set per release. 90 components need one bridge for all versions.

| Layer | Bridges | Example |
| --- | --- | --- |
| 1.21.4 | 59 | `Food`, on every version |
| Since 1.21.5 | 39 | New components, and a new `Enchantments` |
| Since 1.21.7 | 3 | A new `Equippable` |
| Since 1.21.8 | 1 | A new `Consumable` |
| Since 1.21.10 | 1 | A new `Profile` |
| Since 1.21.11 | 9 | |
| Since 26.1.1 | 8 | |
| Since 26.2 | 1 | |

Hand written bridges for core merges such as `Name` and `Durability` sit in the 1.21.4 layer. So does `CustomData`, with a second bridge since 1.21.5, because reading a game tag changed there and recognizing items must work on every version. The other eight components outside Paper's typed API sit in the newest layer. A component without a bridge is dropped when an item reaches the game, but the record stays in the content, so it works again on a newer server.

## When Minecraft updates

1. Bump the Paper version and the schema copy.
2. The build fails and lists what changed.
3. Accept the new shape, so the pull request shows every change.
4. A changed or removed field gets a migration in our database, on our terms.
5. The real game test runs on the new version: every record goes through real game classes and back.

## Automatic corrections

The rules are code in the generator, which we own.

| Problem | Rule | Measured on 26.2 |
| --- | --- | --- |
| Field name differs from Paper | Exact match, then a contained name: `on_consume_effects` holds `consumeEffects` | 84 of 103 match. 19 left, some because Paper wraps them: `trim` in `armorTrim` |
| Builder differs from getter | Lists use `addX`, and required values go through the factory | 80 of 110 share a name. The rule for the other 30 is untried |
| Seconds and ticks | A name with `seconds` or `ticks` becomes `Duration` | 9 fields, 0 wrong, 2 missed (`duration`, `HuntingCooldown`) |
| Either-or fields | One or many becomes a list; short or full form becomes the full form | Of 43: 23 by rule, 13 become RichText, 7 map to our types in the generator |
| Shape depends on a type field | Becomes a sealed type | `consume_effect` has 5 kinds |
| Defaults | Read from the docs and shown as a hint. The stored value stays null, so it follows the game | 49 of 276 optional fields are readable |
| Stable type ids | A hash of the game's key | Same on every build |
| Wrong schema | A real value lacks a required field, so the field becomes optional | Fixes `writable_book_content.pages`, the 1 of 3574. Needs the game's values as an input |

## Cost

Measured from the current processor: about 240 generated lines per type, plus 82 per field. This comes from the SDK, so it applies with or without this generator.

| What | Types | Fields | Lines |
| --- | --- | --- | --- |
| Today, `typewriter-api` | | | 7,800 |
| All item components | 170 | 369 | 71,000 |
| Entities, shared groups | 136 | 407 | 66,000 |
| Entities, flat | 165 | 6,802 | 597,000 |

So entity records never flatten: `Sheep` nests its shared groups.

## Not proven

- **Ran:** a throwaway test on the real processors. A new processor generated `@TypewriterType` records in round 1, and the main processor made their SDK in round 3. A hand written type using a generated one compiled. The new processor saw a hand written type in round 1 and read a library class from the classpath. The skip itself was not run.
- **Real Paper classes through KSP.** The test read `UUID`, not Paper. The Paper numbers came from reflection on 26.2.
- **No real generator exists.** The numbers above came from throwaway scripts.
- **Classes and bridges above are sketches.** Only `Food` and `Consumable` came from a script run, and the Paper calls were not compiled.
- **Ranges.** Whether our type system can hold `1..99` was not checked.
- **What 121 means.** It compares signatures of Paper's component API. It can overcount a harmless overload, and it misses a method that keeps its signature but acts differently, and Bukkit types inside a component.
- **Merging in KSP.** A later layer must know what an earlier one wrote, and each compile sees one Paper. A small file passed along is the likely form; it is untried.
- **Number of layers.** About eight compiles, mostly tiny, counted from the Paper releases available locally. 1.21.6 and 1.21.9 were not checked. Build time is not measured.
- **26.3.** The measurements stop at 26.2, which is the newest API available locally.
- **API stability.** Paper marks this API experimental.
- **Nine components outside Paper's typed API** need a second mapping through NMS, or hand written bridges.
- **Build time** for the generated lines, in one module that should rarely rebuild.
- **Stale builds.** KSP must rerun when the schema file changes. `MinecraftInputs` is the plan; it is untried.
- **Version diffs in the schema.** A first test found 3 changed components from 1.21.4 to 1.21.5, against 6 measured from game values, because it skipped either-or fields.
