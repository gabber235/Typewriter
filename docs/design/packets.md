# Packets

A packet is one more kind of [source](events-and-handlers.md#writing-a-source). It becomes a typed Typewriter event, and handlers answer with the verdicts they already use. Extensions never see a packet. Decided 2026-11-05 in the layer 14 rough design: Typewriter has its own small wire and does not use PacketEvents.

Nothing here is built yet. See [Not proven](#not-proven).

## End to end

Scenario: nothing interrupts a dialogue's action bar. Legacy `ActionBarBlocker.kt` listens to every packet and keeps its own map of blocked players.

### 1. A typed event, with no Paper in it

```kotlin
@TypewriterType(id = "...")
data class ActionBarSent(val player: Protagonist, val message: RichText) : Event
```

### 2. A source, the same shape as a Paper event source

```kotlin
class ActionBarSource(wire: PaperWire) : Source<ActionBarSent> by
    wire.outgoing<ClientboundSetActionBarTextPacket, ActionBarSent> {
        ActionBarSent(player.protagonist, text.fromPlatform())
    }
```

Sources live in [version layers](engines.md#version-layers), like item bridges. A source is written once, and a newer one is added only when that packet changed.

### 3. A handler answers with a verdict

```kotlin
@Handler
fun ActionBarSent.block(hold: ActionBarHold): Verdict = deny()
```

It runs inline on the network thread, so it may only read [network safe data](events-and-handlers.md#threads).

### 4. The wire underneath

```kotlin
// Paper's public hook, with the same signature on 1.21.4 and 26.2.
ChannelInitializeListenerHolder.addListener(key) { channel ->
    channel.pipeline().addBefore("packet_handler", "typewriter", WireHandler(channel))
}

class WireHandler(...) : ChannelDuplexHandler() {
    override fun write(ctx: ChannelHandlerContext, packet: Any, promise: ChannelPromise) {
        // Nothing wants this packet: one lookup, then straight on.
        val source = outgoing[packet.javaClass] ?: return ctx.write(packet, promise)
        source.decide(packet) { outcome ->
            if (outcome.denied) promise.setSuccess() else ctx.write(outcome.packet, promise)
        }
    }
}
```

`channelRead` does the same for packets from the client.

### 5. Typewriter's own packets get through

`wire.send` writes from the handler's position in the pipeline, so its packets do not pass through the handler.

```kotlin
wire.send(player, ClientboundSetActionBarTextPacket(text.toPlatform()))
```

## Paper's API first

A packet is only for what Paper cannot do. These exist on both 1.21.4 and 26.2:

| Need | Use |
| --- | --- |
| Fake block, equipment | `sendBlockChange`, `sendEquipmentChange` |
| Per player time, border, particles | `setPlayerTime`, `setWorldBorder`, `spawnParticle` |
| Hurt, entity effect | `sendHurtAnimation`, `sendEntityEffect` |
| Text | Adventure: action bar, title, chat |
| Click on a fake entity | `PlayerUseUnknownEntityEvent` |
| Keys pressed, arm swing | `PlayerInputEvent`, `PlayerArmSwingEvent` |

The wire is for blocking or changing what the server sends (action bar, chat, slots), blocking movement, fake entities, per player teams, and a camera on a fake entity.

## Why our own wire

| | Own wire | PacketEvents plugin | PacketEvents in our jar |
| --- | --- | --- | --- |
| Server owner installs | Nothing extra | A second plugin | Nothing extra |
| New Minecraft release | Our schedule, only changed packets | Wait for their release | Wait, then release ours |
| Versions hidden by | Our version layers | Their wrappers | Their wrappers |
| Build | Compile against Paper's internals in each layer | No change | Relocation |
| License | Ours | GPL-3 plugin, called at run time | GPL-3 inside our own license jar |

Measured with `javap` on Paper's mapped jars, over 47 packet classes picked from what legacy uses most:

- 36 of 47 have the same public API from 1.21.4 to 26.2.
- Merged by layer that is 60 versions to write, against 423 for one per release.
- Changes per release: 1.21.5 has 4, 1.21.7 has 1, 1.21.10 has 1, 1.21.11 has 3, 26.1.1 has 2, 26.2 has 2.

## When things go differently

| Case | What happens |
| --- | --- |
| No handler wants a packet | Its source is closed, so one table lookup and no conversion |
| A verdict handler throws | It counts as `pass` and is logged, as today. The packet still goes out |
| Packets in a bundle | The wire looks inside `ClientboundBundlePacket`, so a deny drops one part |
| Before the player is in play | No protagonist yet, so packets pass |
| A packet changes in a new release | That version layer fails to compile. A newer source is added, and older ones stay |
| ViaVersion or Geyser | They should work on bytes further along, while the wire sees game objects. Not run |

## Later

The base of per viewer entities is its own node, 14b ([build-graph.md](build-graph.md)), so the scene camera (18b) and NPCs (21) both build on it without waiting on each other: `FakeEntity`, `spawn`, `move`, `remove`, and `lookThrough` (the camera packet only), built on `wire.send` ([scenes.md](scenes.md#4-the-rig-as-legacy)). Layer 21 builds NPCs on top of it, replacing EntityLib. A real game entity that was never added to a world could give its data values, so no tables per version would be needed. That idea is untested.

## Not proven

- **Nothing ran.** No handler was installed on a real server.
- **What 36 of 47 means.** It compares public signatures of the packet classes only, and misses changes inside types they carry. 1.21.6 and 1.21.9 were not checked.
- **Which packets.** The 47 come from legacy's most used wrappers, so the list is not complete.
- **Paper's internals** are not a stable API. Layers and compile errors limit the damage but do not remove it.
- **Build cost.** Compile time against Paper's dev bundle in about eight layers is not measured.
- **Replacing packets with Paper's API.** The methods exist, but whether each fully replaces its legacy packet was not checked.
