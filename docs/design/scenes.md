# Scenes

How a scene plays: the step that starts it, the shared playhead, tracks on the timeline, the camera and its rig, landing after a scene, preparation waits, skip, cues, and the key way out. Layer 18 rough design, decided 2026-11-07. Nothing here is built yet; see [Not proven](#not-proven).

A scene is a step ([interactions.md](interactions.md#steps)) that plays a scene page. Everything a viewer sees is a Hold derived from the page's tracks at the current frame, so the scene reuses Holds, snapshots, grace, clashes, key offers, and ways out as they are.

## The timeline model, as it exists

The authoring model exists in current code; this layer only plays it.

| Part | Code |
| --- | --- |
| A scene page lists its tracks in `elements` | `ScenePage` (`CorePages.kt:77`) |
| A track is a `SceneEntry`, placed with `TimelineEntryPlacement(trackIndex)` | `CorePages.kt:48`, `Placement.kt:49` |
| A cue is its own resource: `Cue : Resource`, `Segment : Cue`, `Keyframe : Cue` | `ElementModel.kt:26` |
| A segment spans `TimelineSegmentPlacement(startFrame, endFrame)`, both ends inclusive | `Placement.kt:57` |
| A keyframe sits at `TimelineKeyframePlacement(frame)` | `Placement.kt` |
| A track owns its cues, and a segment can own keyframes, through `Owning` contracts: CASCADE on the owner, CLEAR on the cues | `SyntheticCues.kt:17`, `SyntheticCues.kt:26` |

Frames are whole numbers. A frame is 50 ms of wall clock, 20 a second, as legacy (`TemporalInteraction.kt:41` on `origin/develop`), so the importer maps legacy frames one to one.

## End to end

Scenario: Ann and Bo accept the smith's quest together. A 12 second scene (240 frames) flies over Riverside, then cuts into the mine, which is another world. Bo is on a slow connection.

```
Sequence page "Smith quest":  accept_line  links to  arrival (PlaySceneEntry, scene = "Arrival")
                              arrival  links to  teleport (riverside.gate)  links to  smith_greeting
Scene page "Arrival":
  camera   Bezier segment 0 to 120 over Riverside, Catmull-Rom segment 121 to 239 in the mine
  potion   darkness 0 to 19; night vision 108 to 239; darkness 115 to 129
  title    "Riverside" 20 to 79
  skip     40 to 219
  cue      keyframe at 180 gives the map
```

### 1. The step and the playhead

```kotlin
class PlaySceneEntry(
    /* page, name, placement, triggers, refused, changes */
    override val rules: StepRules = StepRules(),
    val scene: Ref<PlayScene.Scene, ScenePage>,
    val waitAtMost: Duration = 10.seconds,   // how long one member may hold the others up
) : StepEntry, SequenceEntry

val FRAME: Duration = 50.milliseconds

// The scene's clock: one row per step, removed with the step. Every engine reads the same row,
// so every member sees the same frame.
data class Playhead(
    @Key val step: Step,
    val frame: Int,                     // where it stood at `since`
    val since: Instant,
    val waits: Set<Wait> = emptySet(),  // not empty: paused at `frame`, for everyone in the step
) : Stored

// One member getting one cue ready. A cue is a Resource, so it is an identity (stored-data.md#identity).
data class Wait(val who: Protagonist, val cue: Cue)

fun Playhead.at(now: Instant): Double =   // fractional, for a smooth camera
    if (waits.isNotEmpty()) frame.toDouble() else frame + (now - since) / FRAME
fun Playhead.frame(now: Instant): Int = at(now).toInt()

@Handler
fun Added<Running<PlaySceneEntry>>.start() { val _ = StartPlayhead(value.step).attempt() }

@Transaction context(tx: Transaction)
fun startPlayhead(step: Step) { playhead(step).set(Playhead(step, frame = 0, since = now)) }
```

The playhead replaces the `Skipped` row for scenes: a skip, a pause, and later a preview seek are writes to this one row.

```kotlin
// The page plays for this member: the same shape as InAudience for an audience node.
data class ScenePlaying(
    @Key val who: Protagonist,
    @Key val page: ScenePage,
    val step: Step,
    val context: ChainContext,
    val startedAt: Instant,
    val playhead: Playhead,
    val waitAtMost: Duration,
) : Live

@Derive
fun Running<PlaySceneEntry>.playing(who: Protagonist, playhead: Playhead) =
    ScenePlaying(who, entry.scene, step, context, startedAt, playhead, entry.waitAtMost)

fun ScenePlaying.frame(now: Instant): Int = playhead.frame(now)
fun ScenePlaying.member(): MemberContext = ...   // this member, in the step's chain

// The end. A paused playhead does not move, so it does not end.
@Handler
suspend fun Tick<EveryTick>.end(running: Running<PlaySceneEntry>, playhead: Playhead) {
    if (playhead.frame(now) > running.entry.scene.lastFrame()) running.complete()
}

fun ScenePage.lastFrame(): Int = ...   // the last frame of any cue its tracks own
```

### 2. A track derives a Hold that exists

A track is the conformance pattern (`SyntheticCues.kt:17`, `SyntheticEntry.kt:92`) plus one derive over `ScenePlaying`. The potion track returns layer 15's `PotionHold`, so applying, snapshot, and restore are that display's own handlers. The effect sits in the segment, so one track plays several effects at once.

```kotlin
@ReferenceContract(POTION_TRACK_SEGMENTS_ID)
interface PotionTrackSegmentsContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE) interface Track : One<PotionTrackEntry>
    @DeletionPolicy(RelationDeletePolicy.CLEAR) interface Segment : Many<PotionSegment>
}

data class PotionTrackEntry(
    override val page: Ref<PageElements.Element, ScenePage>,
    override val name: String = "",
    override val placement: TimelineEntryPlacement,
    val segments: List<Ref<PotionTrackSegments.Track, PotionSegment>> = emptyList(),
) : SceneEntry

data class PotionSegment(
    override val placement: TimelineSegmentPlacement,
    val effect: PotionEffectType,
    val level: Var<Int, MemberContext> = Var.Value(1),
) : Segment

// Every segment on this frame. Inclusive end, as Placement.kt:57.
fun <S : Segment> List<S>.activeAt(frame: Int): List<S> =
    filter { frame in it.placement.startFrame..it.placement.endFrame }

// PotionHold is keyed by (who, effect), so each effect is its own Hold.
@Derive
fun PotionTrackEntry.holds(who: Protagonist, playing: ScenePlaying): List<PotionHold> {
    val member = playing.member()
    return segments.activeAt(playing.frame(now))
        .map { PotionHold(who, it.effect, it.level(member)) }
        .groupBy { it.effect }.map { (_, same) -> same.maxBy { it.level } }   // same effect twice: the strongest, as Minecraft
}
```

### 3. Camera kinds

`CameraSegment` is an interface, as `SequenceEntry` is. Each kind owns its own keyframes, so each kind can get its own in game editor (layer 25). Where the camera looks is a field of its own, apart from where it goes, so kinds combine with every aim.

```kotlin
data class CameraTrackEntry(
    /* page, name, placement */
    val segments: List<Ref<CameraTrackSegments.Track, CameraSegment>> = emptyList(),
) : SceneEntry

interface CameraSegment : Segment {
    val aim: Var<CameraAim, MemberContext>
    fun path(member: MemberContext): CameraPath   // formulas resolved for one member
}

// Resolved, so a Hold can carry and compare it. The points of one segment share a world (a check).
interface CameraPath {
    val world: World
    fun at(frame: Double): Position
}

sealed interface CameraAim {
    data object Keyframes : CameraAim                 // each point's own yaw and pitch, eased between
    data object Ahead : CameraAim                     // look where the path goes (Blender: follow path)
    data class At(val target: Location) : CameraAim   // keep a spot in frame (Blender: track to)
}

// A still shot. With At, it pans to follow a spot.
data class FixedCameraSegment(
    override val placement: TimelineSegmentPlacement,
    val at: Var<Position, MemberContext>,
    override val aim: Var<CameraAim, MemberContext> = Var.Value(CameraAim.Keyframes),
) : CameraSegment

// Passes through every point, as legacy. A point's frame is its time.
data class CatmullRomCameraSegment(
    override val placement: TimelineSegmentPlacement,
    val points: List<Ref<CatmullRomPoints.Segment, CameraPoint>> = emptyList(),
    override val aim: Var<CameraAim, MemberContext> = Var.Value(CameraAim.Keyframes),
) : CameraSegment

data class CameraPoint(
    override val placement: TimelineKeyframePlacement,
    val at: Var<Position, MemberContext>,
) : Keyframe

// Shaped like a curve in Blender: handles set the direction and the flow.
data class BezierCameraSegment(
    override val placement: TimelineSegmentPlacement,
    val points: List<Ref<BezierPoints.Segment, BezierPoint>> = emptyList(),
    override val aim: Var<CameraAim, MemberContext> = Var.Value(CameraAim.Keyframes),
) : CameraSegment

data class BezierPoint(
    override val placement: TimelineKeyframePlacement,
    val at: Var<Position, MemberContext>,
    val handle: Vec3 = Vec3.ZERO,     // the direction it leaves in, and how far that pull reaches
    val handleIn: Vec3? = null,       // null: the mirror of handle, a smooth turn; set: a sharp corner
    val ease: Ease = Ease.InOut,      // speed toward the next point
) : Keyframe

enum class Ease { Linear, In, Out, InOut }

// The newest start wins, so dragging a segment over another is a cut. An overlap is a check warning.
fun List<CameraSegment>.current(frame: Int): CameraSegment? =
    activeAt(frame).maxByOrNull { it.placement.startFrame }
```

One camera per protagonist: two camera scenes clash, and back to back scenes adopt it within grace.

```kotlin
data class CameraHold(
    @Key val who: Protagonist,
    val step: Step,
    val segment: CameraSegment,   // the cue a wait names
    val path: CameraPath,
    val aim: CameraAim,
    val playhead: Playhead,       // the Hold carries what its handlers read
    val waitAtMost: Duration,
) : Hold

@Derive
fun CameraTrackEntry.camera(who: Protagonist, playing: ScenePlaying): CameraHold? {
    val segment = segments.current(playing.frame(now)) ?: return null
    val member = playing.member()
    return CameraHold(who, playing.step, segment, segment.path(member), segment.aim(member),
        playing.playhead, playing.waitAtMost)
}

fun CameraHold.pose(now: Instant): Position = aim.apply(path, playhead.at(now))
```

Later kinds take this shape with no core change: an orbit (a circle path with `At(center)`), following an NPC (`At` an entity, layer 21), a handheld shake over any path, and a recorded flight that becomes Catmull-Rom points (recording, A1).

### 4. The rig, as legacy

The camera works the way legacy's does (`CameraCinematicEntry.kt` on `origin/develop`). Every piece is deliberate:

| Legacy | Why | Here |
| --- | --- | --- |
| A fake `TEXT_DISPLAY` with interpolation 10 (`:399`) | It exists only on the wire, so a crash leaves nothing behind | `FakeEntity` on the wire |
| The camera packet only, no spectator mode (`:424`) | The server keeps the player as is; the client thinks the body is still where it was and only moves its camera | `wire.lookThrough` |
| The body is teleported (`:364`) | The server, chunk loading, and other plugins (holograms) know where the player is | `follow`, by distance |
| y + 500 on outgoing positions, y − 500 on incoming ones (`:288` to `:297`) | Mods that draw your own body show nothing, while the server keeps the true position | Two `change` verdicts on the wire |
| Interacting with yourself cancelled (`:302`) | Otherwise the client interacts with itself and is kicked | A wire verdict |
| Fake flight, the flying kick cancelled (`:226`, `:272`) | The server would kick for floating | Wire, and a verdict |
| Fake cleared inventory, not in creative (`:250`) | In creative, opening the inventory would really clear it | Wire, the same rule |
| Damage and targeting cancelled (`:258` to `:270`) | The body stands in the open | Verdicts |
| Hidden from other players | Others do not see the body follow the camera | By packets, so nothing is persisted |

The base of per viewer entities is node 14b ([build-graph.md](build-graph.md)), built before the camera so NPCs need not wait on scenes. Layer 21 builds NPCs on top of it: viewer audiences, tracking range, skins, equipment, behaviour.

```kotlin
// Exists only on the wire. The entity data per version lives in the version layers.
data class FakeEntity(val id: EntityId, val type: EntityType)

// PaperWire helpers, built on wire.send.
fun PaperWire.spawn(viewer: Player, entity: FakeEntity, at: Position, data: EntityData = EntityData())
fun PaperWire.move(viewer: Player, entity: FakeEntity, to: Position)
fun PaperWire.remove(viewer: Player, entity: FakeEntity)
fun PaperWire.lookThrough(viewer: Player, entity: FakeEntity?)   // ClientboundSetCameraPacket only; null: back to the player
```

```kotlin
class CameraRig(var entity: FakeEntity, var world: World) : Runtime

@Handler
suspend fun Added<CameraHold>.film(player: PaperPlayer, wire: PaperWire, paper: PaperEvents): CameraRig {
    val start = value.pose(now)
    value.waitIfNewWorld(player.world)
    paper.moveBody(player, start)
    val rig = CameraRig(wire.spawnCamera(player, start), start.world)   // TEXT_DISPLAY, interpolation 10
    wire.lookThrough(player, rig.entity)
    return rig                                                            // plus fake flight and inventory
}

// Speed decides how often: a fast camera leaves the body behind every tick, a slow one rarely.
// Legacy also teleported every 10 frames; its distance check compared a location with itself (:368).
const val FOLLOW_DISTANCE = 8.0

@Handler
suspend fun Tick<EveryTick>.follow(camera: CameraHold, rig: CameraRig, player: PaperPlayer, wire: PaperWire, paper: PaperEvents) {
    val at = camera.pose(now)
    wire.move(player, rig.entity, at)
    val behind = player.location.distance(at) ?: return   // another world: cut moves it
    if (behind > FOLLOW_DISTANCE) paper.moveBody(player, at)
}

// A new segment. As legacy switchSeamless and switchWithStop (:450, :463).
@Handler
suspend fun Changed<CameraHold>.cut(rig: CameraRig, player: PaperPlayer, wire: PaperWire, paper: PaperEvents) {
    if (new.segment == old.segment) return   // a pause or a resume
    val start = new.pose(now)
    if (new.path.world != rig.world) {
        new.waitIfNewWorld(player.world)     // the playhead holds until the client has loaded
        wire.lookThrough(player, null)
    }
    paper.moveBody(player, start)
    val previous = rig.entity
    rig.entity = wire.spawnCamera(player, start)
    rig.world = start.world
    wire.lookThrough(player, rig.entity)
    wire.remove(player, previous)
}

@Handler
fun Removed<CameraHold>.stop(rig: CameraRig, player: PaperPlayer, wire: PaperWire) {
    wire.lookThrough(player, null)
    wire.remove(player, rig.entity)          // then RestoreSnapshot teleports her back
}

// Chunks load off thread, as Paper's teleportAsync does, then one ordinary teleport as Typewriter's own move.
suspend fun PaperEvents.moveBody(player: Player, to: Position) {
    to.world.loadChunksAsync(to).await()
    own(player) { teleport(to.toPlatform()) }
}
```

The guards:

```kotlin
// Out: the client's own body sits 500 up. In: the client answers each teleport with its position,
// so shifting back keeps the server's view true.
@Handler fun PositionSent.hideBody(camera: CameraHold): Verdict = change(copy(to = to.up(500.0)))
@Handler fun ClientPosition.trueBody(camera: CameraHold): Verdict = change(copy(at = at.down(500.0)))
@Handler fun ClientInteractEntity.notSelf(camera: CameraHold): Verdict = if (target == player) deny() else pass()

@Handler fun PlayerKicked.flying(camera: CameraHold): Verdict = if (cause == FlyingPlayer) deny() else pass()
@Handler fun PlayerDamaged.filming(camera: CameraHold): Verdict = deny()
@Handler fun EntityTargets.filming(camera: CameraHold): Verdict = deny()

@Derive fun CameraHold.keys() = KeysLeft(who, step, setOf(Jump, Sneak))
```

While `CameraHold` is held, the formula member `protagonist.position` reads the camera position. This covers legacy `PlayerPositionOverride` in the context; the override ends with the Hold.

### 5. Typewriter's own moves

The follow teleports are ordinary Paper teleports, so other plugins see them as usual. Typewriter makes no `Teleport` event of them, the same rule as `wire.send` for packets ([packets.md](packets.md#5-typewriters-own-packets-get-through)):

```kotlin
// A Paper event raised inside `change`, for that player, is Typewriter's own: the source sees `own`.
// `change` is not suspending, so the mark covers exactly the call that raises the event.
fun PaperEvents.own(player: Player, change: Player.() -> Unit)

class TeleportSource(paper: PaperEvents) : Source<Teleport> by
    paper.source<PlayerTeleportEvent, Teleport> {
        if (own) null else Teleport(player.protagonist, to.fromPlatform())
    }
```

Paper's `teleportAsync` loads the chunks off thread and then runs the ordinary teleport on the main thread (`CraftEntity.teleportAsync`, Paper main). `moveBody` does the same two steps itself, so the event fires inside `own`. A quest's "teleported" event therefore never fires on a follow move, and the landing verdict sees only real teleports.

### 6. Landing

The camera Hold still exists while the Teleport linked after `arrival` runs, because the grace of a Hold from a step starts only when its chain has settled ([interactions.md](interactions.md#grace-and-adoption)). One handler holds the decision and the reaction: a deny follow up runs only when the final outcome is denied ([events-and-handlers.md](events-and-handlers.md#follow-ups-and-cancel)).

```kotlin
@Handler
fun Teleport.land(camera: CameraHold): Verdict = deny { val _ = Land(player, to).attempt() }

@Transaction context(tx: Transaction)
fun land(who: Protagonist, at: Position) {
    snapshot<CameraHold>(who).update { it.copy(location = at) }   // RestoreSnapshot puts her here
}

// No flight in the snapshot: the flight is faked on the wire only.
data class CameraSnapshot(val location: Position, val velocity: Vec3)

@Handler fun TakeSnapshot<CameraHold>.save(location: HasLocation, velocity: HasVelocity) =
    CameraSnapshot(location.location, velocity.velocity)
@Handler fun RestoreSnapshot<CameraHold>.back(location: HasLocation, velocity: HasVelocity,
    snapshot: CameraSnapshot) = ...   // one teleport, then the velocity
```

Our Teleport action and another plugin's `/spawn` are both denied into the snapshot. Quit, crash, or leaving during the scene never reach the link, so she goes back where she stood.

### 7. Preparation waits

Some cues need time before they can play: a cut into another world, a resource pack (layer 20). Any cue can hold the playhead for the whole step until the member is ready, so everyone stays in sync and nobody misses a frame.

```kotlin
// Any cue, on the member's engine.
@Transaction context(tx: Transaction)
fun wait(step: Step, who: Protagonist, cue: Cue, atMost: Duration) {
    val head = playhead(step).get() ?: return
    playhead(step).set(head.copy(frame = head.frame(now), since = now, waits = head.waits + Wait(who, cue)))
    waitDue(step, who, cue).set(WaitDue(step, who, cue, at = now + atMost))
}

// The answer for that wait. The last one out starts the clock again at the same frame.
@Transaction context(tx: Transaction)
fun release(step: Step, who: Protagonist, cue: Cue, result: Readiness) {
    val head = playhead(step).get() ?: return
    val wait = Wait(who, cue)
    if (wait !in head.waits) return   // already answered, by the timeout or a second report
    playhead(step).set(head.copy(since = now, waits = head.waits - wait))
    waitDue(step, who, cue).clear()
    prepared(step, who, cue).set(Prepared(step, who, cue, result))
}

sealed interface Readiness {
    data object Ready : Readiness
    data class Failed(val reason: String) : Readiness
    data object TimedOut : Readiness
}

// Kept until the step ends: after the resume, every engine and the debug view know how each member came through.
data class Prepared(@Key val step: Step, @Key val who: Protagonist, @Key val cue: Cue, val result: Readiness) : Stored

// The realm is the clock, so a crashed engine or a member who quit cannot hold everyone forever.
data class WaitDue(@Key val step: Step, @Key val who: Protagonist, @Key val cue: Cue, override val at: Instant) : Due

@Handler // realm, exactly once
fun Elapsed<WaitDue>.giveUp() { val _ = Release(due.step, due.who, due.cue, Readiness.TimedOut).attempt() }
```

Pause and resume change the frame and the waits together, so they live in one row: one write, and no query over part of a key.

The camera waits on a cut into another world, and the client says when it is ready. It sends `ServerboundPlayerLoadedPacket` after every respawn packet, so also after a world change (`ClientPacketListener.handleRespawn`, then `notifyPlayerLoaded`, 26.3). Paper's `PlayerClientLoadedWorldEvent` is documented for join and respawn only, so the wire reads the packet:

```kotlin
fun CameraHold.waitIfNewWorld(current: World) {
    if (path.world != current) { val _ = Wait(step, who, segment, waitAtMost).attempt() }
}

@TypewriterType(id = "...")
data class ClientLoaded(val player: Protagonist) : Event

class ClientLoadedSource(wire: PaperWire) : Source<ClientLoaded> by
    wire.incoming<ServerboundPlayerLoadedPacket, ClientLoaded> { ClientLoaded(player.protagonist) }

// Also fires on join and respawn: release ignores a wait that is not there.
@Handler
fun ClientLoaded.ready(camera: CameraHold) {
    val _ = Release(camera.step, camera.who, camera.segment, Readiness.Ready).attempt()
}
```

A member who is not ready (`Failed` or `TimedOut`) leaves through a way out, when the creator added one and leaving is allowed. When leaving is blocked, or there is no such way out, they play on with whatever has loaded.

```kotlin
class NotReadyEntry(
    /* page, name, placement, triggers, refused, changes */
    override val children: List<Ref<AudienceEntry>> = emptyList(),
) : WayOut

@Handler
fun Added<Prepared>.notReady(exit: Exits) {
    if (value.result == Readiness.Ready || exit.way !is NotReadyEntry) return
    if (exit.allowed) emit(LeaveAsked(value.who, exit.way, exit.interactions))
    // blocked: plays on with whatever has loaded
}
```

Layer 17's group rule applies: when Bo leaves, the interaction ends for both. To end it for Bo alone, the scene is fired per member (`ContinueForEachMember`).

### 8. Skip and cues

The skip uses the existing key offer. A press jumps the playhead past the skip segment.

```kotlin
data class SkipTrackEntry(
    /* page, name, placement */
    val key: ConfirmationKey? = null,
    val segments: List<Ref<SkipTrackSegments.Track, SkipSegment>> = emptyList(),
) : SceneEntry
data class SkipSegment(override val placement: TimelineSegmentPlacement) : Segment

@Derive
fun SkipTrackEntry.offer(who: Protagonist, playing: ScenePlaying): KeyOffer? {
    if (segments.activeAt(playing.frame(now)).isEmpty()) return null
    return KeyOffer(who, by = playing.step, preferred = key, since = playing.startedAt,
        press = Confirm(who, playing.step))
}

@Handler
fun Confirm.skip(running: Running<PlaySceneEntry>, playhead: Playhead) {
    val frame = playhead.frame(now)
    val end = running.entry.scene.elements.filterIsInstance<SkipTrackEntry>()
        .flatMap { it.segments.activeAt(frame) }.maxOfOrNull { it.placement.endFrame } ?: return
    val _ = Skip(step, end + 1).attempt()
}

@Transaction context(tx: Transaction)
fun skip(step: Step, to: Int) {
    val head = playhead(step).get() ?: return
    playhead(step).set(head.copy(frame = to, since = now))   // waits stay: a paused scene stays paused
}
```

A cue keyframe fires links once it is reached. Its frame is passed by a skip too, so a skipped cue still fires; legacy lost it.

```kotlin
data class CueTrackEntry(
    /* page, name, placement */
    val cues: List<Ref<CueTrackCues.Track, CueKeyframe>> = emptyList(),
) : SceneEntry

data class CueKeyframe(
    override val placement: TimelineKeyframePlacement,
    val fire: List<Ref<CueKeyframeLinks.Fire, Triggerable>> = emptyList(),
) : Keyframe

// A Due is seconds precise (stored-data.md#due), so a cue reads now.
data class CueReached(@Key val step: Step, @Key val cue: CueKeyframe, val context: ChainContext) : Live
data class CueFired(@Key val step: Step, @Key val cue: CueKeyframe) : Stored   // removed with the step

@Derive
fun CueTrackEntry.reached(playing: ScenePlaying): List<CueReached> =
    cues.filter { playing.frame(now) >= it.placement.frame }
        .map { CueReached(playing.step, it, playing.context) }

// The owed state pattern (stored-data.md#due): a guard makes it fire once, across engines and rejoins.
@Handler
suspend fun Added<CueReached>.fire() {
    when (FireCue(value.step, value.cue).ensure()) {
        Committed -> value.cue.fire.forEach { it.complete(value.context) }
        is Refused -> Unit
    }
}

@Transaction context(tx: GuardedTransaction)
fun fireCue(step: Step, cue: CueKeyframe) {
    require(!cueFired(step, cue).exists(), "Already fired")
    cueFired(step, cue).set(CueFired(step, cue))
}
```

A paused playhead reaches no new cue. Layer 18's actions (`PlaySound`, `StopSound`, `SpawnParticle`, `Firework`, `SetBlock`) are ordinary actions, fired by a cue or by any link.

### 9. The key way out

Deferred from layer 17. A key offer carries what its press emits, so one offer serves steps and ways out ([dialogue.md](dialogue.md#6-the-key)):

```kotlin
data class KeyOffer(@Key val who: Protagonist, @Key val by: Identity,
    val preferred: ConfirmationKey?, val since: Instant, val press: Event) : Live

class KeyWayOutEntry(
    /* page, name, placement, triggers, refused, changes */
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    val key: ConfirmationKey? = null,
) : WayOut

// Offered only while leaving is allowed, so no hint shows when it would refuse.
@Derive
fun KeyWayOutEntry.offer(who: Protagonist, inside: InAudience, exit: Exits): KeyOffer? {
    if (exit.way != this || !exit.allowed) return null
    return KeyOffer(who, by = this, preferred = key, since = inside.since,
        press = LeaveAsked(who, this, exit.interactions))
}
```

### The whole run

| Frame | What runs | Ann and Bo see |
| --- | --- | --- |
| 0 | `arrival` starts: `StartPlayhead`, `playing`, then the track derives. `TakeSnapshot`, then `film`: a rig each, `lookThrough` | Dark, the camera over the gate |
| 20 | The darkness segment ends; the title starts | "Riverside" |
| 108 | Night vision, then a second darkness over it: two `PotionHold`s, two keys | A fade before the cut |
| 121 | The Catmull-Rom segment in the mine: `Changed<CameraHold>`, `cut`, a wait for each. Ann's client loads: `Release`. Bo's loads 1.6 s later: `Release`, and the clock runs again | Ann: a still frame. Bo: loading. Then both at 121 |
| 140 | Bo sneaks: the offered key emits `Confirm`, and `Skip` moves to 220 | Both jump ahead |
| 220 | The cue at 180 is passed: `FireCue`, then its links | Both get the map |
| 240 | `end` completes the step. The Teleport link: `land` denies it and moves both snapshots to the gate | The smith starts talking |
| + 10 ticks | The chain settled and the grace is over: `Removed`, `stop`, `RestoreSnapshot` | One teleport, to the gate |

## When things go differently

| Case | Result | Why |
| --- | --- | --- |
| Bo's world never loads | After `waitAtMost`, everyone goes on; Bo leaves if a `NotReadyEntry` allows it | `WaitDue` releases with `TimedOut` |
| Bo's engine crashes while waiting | The same | The realm fires the due |
| Bo sneaks while paused | It skips, and stays paused at 220 | `skip` keeps the waits |
| Another plugin's `/spawn` mid scene | Denied; she lands at spawn after the scene | `land` |
| Quit, crash, rejoin | Back where she stood | The snapshot row; the rig never existed on the server |
| Server move | Goes on at the same frame | `Playhead` is stored; `Added` makes a new rig |
| Another camera scene starts | Its `onClash` decides | Both pages have a camera track |
| A title only scene during a dialogue | Both run | No shared Hold type |
| Two scenes back to back | A cut, no teleport between | The camera is adopted within grace |
| The same effect in two overlapping segments | The strongest level | `maxBy` per effect |
| A creator moves a keyframe and publishes | The running scene follows | Track derives rerun on hot publish |
| Lag | Stays on time | Frames come from the wall clock |

A scene has the normal step rule `onRejoin`, so the creator decides. The default is `Drop`, like legacy; `RestartStep` plays the scene again from its start.

## Clashes for page content

A track's derive is on the track entry, not on `Running<E>`, so the clash rule names it: a Hold counts for a step when its derive is on `Running<E>`, or on content (an element) and asks for a `Live` made on that `Running<E>` ([interactions.md](interactions.md#clashes)). Publication reads the scene page, so a scene with no camera track never counts the camera. `OfferedKey` stays out: its derive is on a `KeyOffer`, not on content.

## Legacy cinematic entries

| Legacy | Here |
| --- | --- |
| Camera, Skip, TriggerSequence | The camera, skip, and cue tracks above |
| PotionEffect, Blinding | The potion track |
| Title, ActionBarMessage, Message | Tracks over layer 15's and 16's displays |
| Sound, Particle, BlockCommand, CinematicCommand | Cue keyframes firing actions |
| SetFakeBlock | A fake block Hold, designed with its track in the plan |
| SpokenDialogue, ActionBarDialogue, SubtitleDialogue, DisplayDialogue | Dialogue views as tracks, designed in the plan |
| ScreenShake, PumpkinHat, Worldborder | Tracks over a Hold each, designed in the plan |
| GameTime, GameWeather | The conversion track, with those displays |
| Entity | Layer 21 |
| MythicMob, MythicSkill | The conversion track |

## What later layers need

| Consumer | Needs | Fit |
| --- | --- | --- |
| 21 NPCs | An NPC track playing recorded movement, entities per viewer | The same track shape; the fake entity base from this layer |
| Recording (A1) | Write frames over a segment's range | Keyframes are resources, so a recording is one authoring edit that creates them |
| Scrub and preview (A1, A3) | Seek, pause, speed | Writes to `Playhead`; speed later extends that row |
| 19 debug | Watch a running scene | `Playhead`, `Prepared`, `ScenePlaying`, the Holds |
| 20 assets | A resource pack ready before a cue | A keyframe that waits and releases on the pack status |
| 25 in game editor | One editor per camera kind | Each kind owns its points and handles |
| 27 visibility | Who sees whom | Takes over hiding the filming body as a rule |
| 29 importer | Legacy frames, inclusive | The same unit and rule, one to one |
| Looping scenes | No protagonist to hold | Later, as the vision says (`vision/content-model.md:180`) |

## Not proven

- **Nothing ran.** It rests on layers 7, 14, 15, 16, and 17, none of which are built.
- **The PlayerTeleportEvent inside the ordinary teleport.** `CraftEntity.teleport0` calls the NMS teleport; that the event fires inside that call, so `own` covers it, is not read. The first test of this layer checks it on a real Paper server: an own move gives no `Teleport` event, another plugin's teleport still does.
- **The loaded packet after a world change**: read from client bytecode (26.3), not run.
- **A derive returning a list** (`holds`, `reached`), and **a parameter keyed through another** (`end`'s `playhead`).
- **Refs read as resources at runtime** (`segments`, `scene`, `scene.elements`, `points`), the same helper as layer 17's `of.points`.
- **A key from the receiver's page link**: `playing`'s `page` filled from the track's `page`.
- **The `change` verdict syntax** and the wire events `PositionSent`, `ClientPosition`, `ClientInteractEntity`, `PlayerKicked`, `EntityTargets`: named, not shaped. The snapshot writer `snapshot<CameraHold>(who)` and `wire.incoming` are assumed names.
- **`FOLLOW_DISTANCE` of 8 blocks** is a guess; holograms and chunk loading decide it.
- **Hiding the filming body from others by packets**: which packets, per version.
- **Cost**: track derives read `now`, so they rerun each tick per viewer; a pause or resume changes `Playhead`, so every track derive reruns.
- **The frame rule in the panel**: overlap is inclusive, but `frameDuration` is `end − start` (`timeline_data.dart:177`). One rule must win.
- **Bedrock** cameras are not designed.
