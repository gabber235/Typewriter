# Capture

Capture copies a value from a player in the game into a field: a position, a held item, the block they look at. It is a formula run on the player's engine, with the result written into the field. Decided 2026-11-04 in the layer 10 rough design. `Capture` is an ordinary event sent through `emit`, so it is a convenience on top of what any event can do, not a replacement for it.

Nothing here is built yet. See [Not proven](#not-proven).

## End to end

A creator clicks Capture on a teleport entry's `Location` field, and the target's position lands in that field.

### 1. The player's values are mirrors

Copies made at tick end, only while someone reads them. The capture never touches Bukkit itself.

```kotlin
@Handler fun Tick<EveryTick>.position(player: PaperPlayer) =
    Mirror(player.protagonist, player.location.fromPlatform<Position>())

@Handler fun Tick<EverySecond>.heldItem(player: PaperPlayer) =
    HeldItem(player.protagonist, player.inventory.itemInMainHand.fromPlatform())

@Handler fun Tick<EveryTick>.lookingAt(player: PaperPlayer): LookingAt? =
    player.getTargetBlockExact(5)?.let { LookingAt(player.protagonist, it.fromPlatform()) }
```

### 2. Each type says what to capture

```kotlin
object LocationEditor : LocationPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun LocationPresentationScope.present() {
        section(header = {
            captureButton("Capture", "protagonist.position.location")
        }) { remainingFields() }
    }
}

// Other types: only the lines differ.
captureButton("Standing on", "protagonist.position.block")   // BlockLocation
captureButton("Looking at", "protagonist.lookingAt")         // BlockLocation
captureButton("Held item", "protagonist.heldItem")           // Item
```

### 3. One event and one button, in core

```kotlin
@TypewriterType(id = CAPTURE_TYPE_ID)
data class Capture(
    val player: Protagonist,
    val formula: Formula,
    val into: BoundPath<*>,
) : Event

fun HeaderScope.captureButton(text: String, formula: String) =
    button(HeaderItemId(text)) {
        icon(literal("crosshair"))
        label(literal(text))
        action(emit(Capture) {
            player(context.read(EditorContext.targetProtagonist))
            formula(literal(Formula(formula, emptyList())))
            into(valueLocation)
        })
    }
```

### 4. The click

The button is disabled while the target is offline or a publish is running. The click publishes if needed, waits until every engine running the content has applied it, then sends the event. The panel engine adds `Origin` and forwards it to the target's engine ([panel-engine-communication.md](panel-engine-communication.md) questions 7 and 8).

### 5. The engine runs the formula and saves

`BoundPath` already carries the expected type (`TypedPath.kt`), so the formula is checked against the field. A mirror read that misses waits for the next tick end ([live-data.md](live-data.md)).

```kotlin
@Handler
suspend fun Capture.write(
    target: PaperPlayer,   // runs only where the player is live
    formulas: FormulaRuntime,
    realm: RealmAuthoring,
    origin: Origin,
) {
    val context = CaptureContext(target.protagonist)
    val value = when (val result = formulas.evaluate(formula, into.expected, context)) {
        is Evaluation.Value -> result.value
        is Evaluation.Failed -> fail(result.reason)
    }
    realm.edit(
        scope = AuthoringScope.resources(listOf(into.location.resource)),
        initiatedBy = origin.principal,
    ) { into.set(Var.value(value)) }
}
```

### 6. The result comes back

The commit lands in `AuthoringCommit` and history names the user, so undo works. The panel updates like any other edit, and the tab gets `Done` or `Failed(reason)`. The value never goes through the panel.

## Custom events stay

`emit` works for any event, and a handler can do anything. Write your own event when a formula is not enough: the action triggers something in the game instead of capturing, it needs Kotlin steps, or it needs its own checks and messages.

```kotlin
@TypewriterType(id = CAPTURE_LOCATION_TYPE_ID)
data class CaptureLocation(val player: Protagonist, val into: BoundPath<Location>) : Event

@Handler
suspend fun CaptureLocation.capture(target: PaperPlayer, realm: RealmAuthoring, origin: Origin) {
    val location = target.location.fromPlatform()
    realm.edit(
        scope = AuthoringScope.resources(listOf(into.location.resource)),
        initiatedBy = origin.principal,
    ) { into.set(Var.value(location)) }
}

// In the type's presentation.
button(HeaderItemId("capture")) {
    action(emit(CaptureLocation) { into(valueLocation); player(context.read(targetProtagonist)) })
}
```

## When things go differently

| Case | What happens |
| --- | --- |
| Target quits first | No holder, so `NotHandled` right away. The button was already disabled. |
| Looking at the sky | `LookingAt` has no value, so the bare read gives `Failed(NoValue)`. The panel needs a friendlier message than that. |
| Field deleted meanwhile | The edit is refused, so the tab gets `Failed(reason)`. |
| Field held a formula | Replaced by the plain value. Undo brings it back. |
| Forged formula from a tab | Formulas have no side effects, and members can already edit and read this content. History records the user. |
| Item with a component that has no record yet | That component is not captured, with no notice. See [item components](minecraft-types.md#components). |
| Started in game | Not in layer 10. Commands (layer 5) emit the same event later. |

## Live formula values

Not part of this. A one time run is a different path from a value that keeps updating. Live values (scenario B2) should use `Watched<T>` and the tab's watch from layers 8 and 9; that is not traced yet.

## Not proven

- **Formula from a tab.** Content formulas are checked by the realm. This one is checked first on the engine, and that path is not designed yet.
- **Formula text in a presentation.** KSP cannot check it. It should be checked when the catalog loads; whether that fits is not confirmed.
- **`BoundPath<*>` as an event field.** KSP rejects `Ref<_, *>` (`star_reference_target.kt`), so this may need another form.
- **Which engine.** `PaperPlayer` ties the handler to Paper, so another engine needs its own one line handler.
- **Nothing here ran.** It rests on layers 1, 4, 8, and 9, none of which are built.
