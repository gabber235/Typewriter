# Domains

A domain is a type whose valid values live somewhere else: worlds and items on a server, skills in MythicMobs, custom sounds in a resource pack. The code holds no list of them. Three questions have one answer for every domain: list them, does this one exist, and which reporters know it. Decided 2026-11-04 in the layer 10 rough design. It replaces `ReportedId` and the `minecraft` capability root, and builds only on types, providers, stored values, handlers, presentations, search, and checks.

Nothing here is built yet. See [Not proven](#not-proven).

## End to end

A creator gives a diamond when a player breaks a block. One id, from the code to the player's inventory.

### 1. Core: two small types

```kotlin
// typewriter-contracts
interface DomainValue { val key: String }

// Unknown values are a warning instead of an error.
interface OpenDomainValue : DomainValue

// No fields. Only exists inside formulas, never stored.
@TypewriterType(id = DOMAIN_TYPE_ID)
class Domain<T : DomainValue>
```

### 2. A capability declares its ids

The root is a top level provider, like `now`. The rest are plain provider properties, the same form as `val Int.seconds`.

```kotlin
@TypewriterType(id = MINECRAFT_TYPE_ID) object Minecraft
val minecraft: Minecraft get() = Minecraft

// Per id type: the value and its name in formulas, side by side.
@TypewriterType(id = ITEM_TYPE_TYPE_ID)
@JvmInline @Serializable
value class ItemType(override val key: String) : DomainValue

val Minecraft.item: Domain<ItemType> get() = Domain()
```

There is no namespace concept. A key without a namespace means `minecraft`, which is how Bukkit already reads it (checked on the 1.21.4 API: `NamespacedKey.fromString("diamond")` gives `minecraft:diamond`). `mypack:ruby` keeps its namespace, and a Nexo id is just `ruby`.

### 3. The engine reports what it has

An ordinary stored value written by an ordinary handler. Asking for `PaperServer` means it never runs on the panel engine.

```kotlin
data class KnownIds(
    @Key val engine: Engine,
    @Key val type: TypeDefinitionId,
    val ids: Set<String>,
) : Stored

@Transaction
context(tx: Transaction)
fun reportIds(engine: Engine, reports: Map<TypeDefinitionId, Set<String>>) {
    for ((type, ids) in reports) knownIds(engine, type).set(ids)
}

@Handler
fun Added<ContentDelivery>.reportRegistries(server: PaperServer) =
    reportIds(engine, mapOf(
        typeOf<ItemType>() to Registry.ITEM.ids(),
        typeOf<BlockType>() to Registry.BLOCK.ids(),
        // the other registries, then the ids with their own lister
    ))

// "minecraft:diamond" becomes "diamond", so there is one spelling.
private fun Registry<*>.ids() = map { it.key().asMinimalString() }.toSet()
```

### 4. The creator picks it

One presentation on the interface, so every domain gets it. Same pattern as the `Icon` picker (`CoreIconSdkProvider.kt`).

```kotlin
object DomainValuePicker : DomainValuePresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun DomainValuePresentationScope.present() {
        key {
            searchInput<KnownIdRow> {
                customValue(query)
                result {
                    key(row.id); selectedValue(row.id); label(row.id)
                    presentation { row { text(row.id); text(row.engines) } }
                }
                provider(
                    sources.realmCallback(SearchKnownIds, payload(fieldType))
                        .debounce(150.milliseconds)
                        .limit(literal(64))
                )
            }
        }
    }
}
```

### 5. The realm answers the search

```kotlin
@RealmCapability.Search
context(_: RealmSearchContext)
fun searchKnownIds(
    request: RealmSearchRequest<KnownIdQuery>,
): RealmSearch<KnownIdRow> = realmSearch {
    // A stored read through the query graph.
    val reports = stored.all<KnownIds>(type = request.payload.type)
    emit(reports.toRows(matching = request.query))
}
```

### 6. Plain value or formula

```kotlin
Var.Value(ItemType("diamond"))                     // plain mode: the picker fills it
Var.Computed(Formula("minecraft.item.diamond"))    // formula mode: text only, nothing linked
```

### 7. The checker types the formula

One rule in member lookup, after real members. Any name on a `Domain<T>` calls `T`'s generated constructor and notes the use. It reads no game data, so engines bind formulas without `KnownIds`, and the formula is pure: it works in `PublishScope`, in a `Definition`, and in a `Changes` field, and the realm can evaluate it. Completion after a `Domain<T>` uses the picker's search.

```kotlin
is Domain<T> -> constructorOf(T).call(literal(name)).also {
    uses += DomainUse(at = nameRange, type = T, key = name)
}
```

### 8. The realm check looks for typos

It covers plain values and formula uses, and runs in the query graph, so only affected resources rerun.

```kotlin
object DomainCheck : RealmCheckProvider {
    override fun RealmChecks.register() {
        each(anyResource) { resource ->
            for (use in resource.domainUses()) {
                val reported = stored.all<KnownIds>(type = use.type)
                when {
                    reported.isEmpty() -> warning(use.at, "No reports yet")
                    reported.none { use.key in it.ids } -> unknown(use)
                }
            }
        }
    }
}

private fun CheckContext.unknown(use: DomainUse) =
    if (use.isOpen) warning(use.at, "No engine reports ${use.key}")
    else error(use.at, "No engine reports ${use.key}")
```

### 9. The engine runs it

`minecraft.item.diamond` evaluates to `ItemType("diamond")`. Only here does it touch a real registry.

```kotlin
@Handler
fun Triggered<GiveItemActionEntry>.give(player: PaperPlayer, item: Item) {
    player.inventory.addItem(item.toPlatform())
}

fun ItemType.toPlatform(): org.bukkit.inventory.ItemType =
    Registry.ITEM.get(NamespacedKey.fromString(key)!!)
        ?: throw UnknownDomainValue(this)
```

## Any extension

No core change. The picker, completion, check, and formula name all come along.

```kotlin
@TypewriterType(id = MYTHIC_TYPE_ID) object Mythic
val mythic: Mythic get() = Mythic

@TypewriterType(id = MYTHIC_SKILL_TYPE_ID)
@JvmInline @Serializable
value class MythicSkill(override val key: String) : DomainValue

val Mythic.skill: Domain<MythicSkill> get() = Domain()

@Handler
fun Added<ContentDelivery>.reportSkills(mythic: MythicBukkit) =
    reportIds(engine, mapOf(typeOf<MythicSkill>() to mythic.skillNames()))
```

```
mythic.skill.fireball
```

## When things go differently

| Case | What happens |
| --- | --- |
| Fresh install, no engines yet | A warning. Formulas still type check and the id can be saved. |
| Typo: `minecraft.item.diamnd` | An error that blocks publish, with the same text in a plain field. |
| Engine offline | Its `KnownIds` stay, so search and check keep working. |
| Engine removed | Its identity ends, so its `KnownIds` end. |
| Two server versions | The check uses the union over the engines that run the book. The picker shows "only paper-1". The other engine gets a typed failure at run time. |
| Custom pack sound | `SoundEvent : OpenDomainValue`, so a warning only. A creator can name it: `Definition "boom" = minecraft.sound.`mypack:boom``. |
| Computed id | `World("arena_${n}")` is the normal constructor. It is unchecked and can fail at run time. |
| World loads at run time | A `WorldLoaded` handler appends the key, and only uses of that id recheck. |

## What it does not cover

- **Online players.** An offline player is not an error, the realm cannot read mirrors, and the value is a `Protagonist`. The layer 9 picker stays.
- **`Ref`.** Links have rename and delete rules.
- **Closed enums.** They stay as they are.
- **Item defaults and tag members.** `item[Food]` and tag checks declare `context(engine: Engine)`, which makes them Live. Live reads already travel with a `Changes` write.
- **Editor shapes per id.** `GameRule` value types and `BlockState` properties need facts per id. They arrive with the first type that uses them, by growing `KnownIds`.

## Sources other than engines

The key is an `Engine` today. Asset ids and realm known names (server names from the topology) fit once something reports them; that needs the key to be a reporter. Decided with assets (layer 20), not here.

## Not proven

- **Field type in the picker.** A presentation written on an interface must know the field's real type (`fieldType` above). Not found in the code yet.
- **`realmCallback`** exists (`SearchControls.kt:68`) but nothing calls it yet.
- **Finding the values.** `each(anyResource)` exists (`ResourceTypeMatch.AnyResource`, `RealmSelections.kt`), but it needs a walk over typed values in a resource. `domainUses()` is unbuilt.
- **One spelling.** `ItemType("minecraft:diamond")` must be rejected, or it does not equal `ItemType("diamond")`. A value class can reject it in `init` but cannot rewrite it.
- **Generic providers.** KSP has no formula providers yet, so `typeOf<T>()` and `Domain<T>` as a provider result are design only.
- **Measured:** the largest sets in the 1.21.4 API are 1651 sounds, 1385 items, and 1095 blocks. 21 of the 33 registry id types are Paper registries; the other 12 need their own lister.
