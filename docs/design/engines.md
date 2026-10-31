# Engines

How Typewriter values cross into an engine's own types and back. Engine kinds (Paper, the panel engine, future engines) are described in [live-data.md](live-data.md).

## Bridges

Every Typewriter value type that an engine uses natively needs a conversion in both directions: `Location` to Paper's `Location`, `MinecraftItem` to `ItemStack`, `Sound` to Adventure's `Sound`. A bridge is that conversion, declared once per Typewriter type and engine kind:

```kotlin
interface Bridge<T : Any, P : Any> {
    fun toPlatform(value: T): P
    fun fromPlatform(platform: P): T? // null: this bridge does not claim the value
}
```

```kotlin
// Paper engine, Minecraft capability
object LocationBridge : Bridge<Location, org.bukkit.Location> { ... }
object MinecraftItemBridge : Bridge<MinecraftItem, ItemStack> { ... } // fallback: claims every stack

// Nexo extension
object NexoItemBridge : Bridge<NexoItem, ItemStack> {
    override fun toPlatform(value: NexoItem) =
        NexoItems.itemFromId(value.id.value)!!.build().asQuantity(value.amount)
    override fun fromPlatform(platform: ItemStack) =
        NexoItems.idFromItem(platform)?.let { NexoItem(NexoId(it), platform.amount) }
}
```

Using a bridge:

```kotlin
player.inventory.addItem(reward.toPlatform()) // the bridge is picked by the value's type
val item: Item = stack.fromPlatform()         // specific bridges first, the fallback last
```

- The full path of a value is: stored data, decoded natively into a Kotlin value (`CompiledContent`), bridged into the engine's value.
- Reading back asks every bridge registered for that platform type: specific bridges first (Nexo), then the fallback (Minecraft). This lookup is why bridges are registered objects, not plain extension functions.
- KSP registers bridges per engine kind, like capabilities. A future engine supplies its own bridges for the same Typewriter types, so content never changes.
- `toPlatform` on a value the engine cannot provide (an unknown Nexo id) is a typed failure; publication checks catch it earlier through an engine request.

## Open

- Engine requests: one channel from the panel through the realm to engines for registry search (materials, particles, worlds), existence checks (a Nexo id, a world key), and actions (capture, teleport).
