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
        NexoItems.itemFromId(value.id.key)!!.build().asQuantity(value.amount)
    override fun fromPlatform(platform: ItemStack) =
        NexoItems.idFromItem(platform)?.let { NexoItem(NexoItemId(it), platform.amount) }
}
```

Using a bridge:

```kotlin
player.inventory.addItem(reward.toPlatform()) // the bridge is picked by the value's type
val item: Item = stack.fromPlatform()         // specific bridges first, the fallback last
```

- The full path of a value is: stored data, decoded natively into a Kotlin value (`CompiledContent`), bridged into the engine's value.
- Reading back asks every bridge registered for that platform type whose Typewriter type fits the wanted type: specific bridges first (Nexo), then the fallback (Minecraft). So `fromPlatform<Position>()` and `fromPlatform<Location>()` read the same Paper `Location` through different bridges. This lookup is why bridges are registered objects, not plain extension functions.
- KSP registers bridges per engine kind, like capabilities. A future engine supplies its own bridges for the same Typewriter types, so content never changes.
- `toPlatform` on a value the engine cannot provide (an unknown Nexo id) is a typed failure; publication checks catch it earlier through the [domain](domains.md) check over `KnownIds`.

## Version layers

Extensions and most engine code never mention a Minecraft version (decided 2026-11-05). Code is written once, compiled against the oldest supported Paper (1.21.4), and runs on every release. A newer layer holds only what really changed.

```kotlin
typewriter {
    extension {
        // Runs on every supported release. Most extensions stop here.
        sourceSet("enginePaper") { engine(project(":engine-paper"), version = "^1") }

        // Optional, only to use something newer.
        sourceSet("paperSince26_2") {
            engine(project(":engine-paper"), version = "^1")
            since("26.2")
            includes("enginePaper")
        }
    }
}
```

- A server loads every layer up to its version, oldest first, so servers on different versions share one deployment.
- `since` is the only version word. There are no exact versions or upper limits, so nobody lists releases.
- For a bridge or a capability of the same type, the newest layer wins. A handler only adds; a layer cannot replace it.
- A release newer than any layer loads them all. A failing bridge is a typed failure for that one component.
- A server older than 1.21.4 fits no base layer, so the loader reports it and does not start the engine.
- The build also compiles each extension against the newest Paper, so a method that is gone is a build error and not a crash. From 1.21.4 to 26.2, 219 of the 19,783 members in `org.bukkit` are gone or changed by signature: 0 of 90 in `ItemStack`, 2 of 297 in `Player`.
- Version dependent features stay [capabilities](../vision/engines.md) to the code that uses them; a layer is how an engine provides one.

Not proven: the loader only adds parts today, so "newest wins" is new; a part per layer with its own Paper on the classpath, and KSP on it, are untried; a method that keeps its signature but acts differently is not caught.

## Wiring inside an engine

Engine internals are plain classes wired with Koin (decided 2026-11-03). Each engine deployment has one isolated `koinApplication`, closed with its runtime; `startKoin` is never used, because a global Koin would keep old engine classes alive after a reload and two engines in one test process would share it. Each engine kind brings its own module.

Paper engine code loads outside Paper's plugin system, so one line in the Paper module brings in the plugin object, and every class needing it receives it through its constructor:

```kotlin
val paperModule = module {
    single<Plugin> { JavaPlugin.getPlugin(TypewriterLoaderPlugin::class.java) }
    single { SessionListener(get(), get()) }
}
```

On a join, the session listener starts the key write off the game thread, so the tick never waits on NATS; on a quit, it shortens the key to the grace. An engine reload without a Paper restart unregisters the listener and leaves the keys alone; the new engine lists the online players and takes their keys over, so sessions survive an engine upgrade.

## Engine communication

- Engine reports are ordinary typed values keyed by the `Engine` identity ([panel-engine-communication.md](panel-engine-communication.md) question 10): what an engine knows (worlds, registries, external plugin ids) is `Stored`, so search and checks read the last known value while the engine is offline; what it is doing now (`ContentDelivery`: the applied publication or its delivery failure) is `Live`, so the publication view shows "applied on N of M engines". Panel actions are sent only once every connected engine running the content has applied the publication.
- Panel requests are ordinary events between sessions of a protagonist: the panel engine emits, the engine where the target is live handles it (teleport), and engines can emit back to panel sessions (live values, a timeline playhead that follows playback in game).
- Any engine writes authored state directly (Minecraft in game tools, recording, a future MCP server), so capture needs no round trip through an open panel and in game tools work without a panel.
- A panel user chooses a target player (any online player), remembered in the user's settings; no account link is needed. In game tools are gated by a server permission and history records the Minecraft player as `initiated_by`. Linking Minecraft accounts to a Typewriter user is beta, for presence and per user team permissions in game.
- One host can run the realm, the Paper engine, and the panel engine together (exists: standalone runs every role).
- The panel engine is to a panel client (browser tab, desktop app, or mobile app) what the Paper engine is to a Minecraft client: each connected client instance is a session of the user's protagonist, reported by the panel engine. The panel engine holds each tab's session (`typewriter.session.<tab>`) and runs its handlers and derives; the tab is a thin client over direct per tab subjects (`session.user.{user}.{session}`), and reads values through one watch ([panel-engine-communication.md](panel-engine-communication.md) question 15). Grants are per user (decided 2026-11-04): a connection is bound to its user, not to a tab, so a tab can reach other tabs of the same user and nobody else's, and the principal comes from the bound `{user}`. A minimal panel engine (session reporter) arrives with layer 3 and forwards panel emits from layer 9; its full shape and API syntax are decided later, when higher layers show what the panel engine needs.
- Panel sessions reuse the existing presence heartbeat (`skir-src/organization/v1/presence.skir`: `PanelPresence{session_id, sequence, location}` on `presence.organization.{organization}.user.{user}`, route `organization_presence`). The panel engine consumes it to report sessions; there is no second heartbeat. `organization_presence` gains `realm_participant` as a subscriber, which needs a subject family for events from a panel role to a service role (`subject.ts`). A panel engine reports only tabs whose `PresenceLocation` is in its own realm, so a tab on the members page has no session. The heartbeat is the refresh: each one rewrites the key with a 45 second TTL; `PresenceLeft` or leaving the realm rewrites it with a 10 second TTL, so a reload continues; when heartbeats stop, the key expires. The `Protagonist` comes from the permission bound `{user}` subject token, never from the payload.
- A panel request is one event delivered to the engine where its subject is live (hybrid routing); this does not contradict "interactions do not span engines".
- Same host shortcut (beta, decided 2026-11-04): engines and a realm on one host talk through the host locally instead of over NATS, for most traffic including stored data sync; engines and the realm do not notice. Contracts never assume NATS, and the host binds caller identity the way caller bound subjects do.
- Registry search and existence checks (materials, particles, worlds, a Nexo id) read `KnownIds`, the stored [domain](domains.md) values, so they work while engines are offline. Actions (capture, teleport) are events to the engine where the subject is live, not a channel through the realm.
