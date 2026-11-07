# Dialogue, chat, and input

How a dialogue reaches the player: who owns the chat, how chat history works, who gets the hotbar and the keys. Steps and clashes themselves are in [interactions.md](interactions.md). Layer 16 rough design, decided 2026-11-05.

Nothing here is built yet. See [Not proven](#not-proven).

## End to end

Scenario: the smith asks "What do you need?" with Repair, Buy, and Leave. The player scrolls to Buy and presses the key.

### 1. The entry

```kotlin
@TypewriterType(id = "...")
data class Option(
    val text: Var<RichText, MemberContext>,
    val available: Var<Boolean, MemberContext> = Var.Value(true),
    override val triggers: ...,
    override val refused: ...,
    override val changes: Var<Changes, InteractionContext>,
) : Triggerable

class OptionDialogueEntry(
    /* page, name, placement, triggers, refused, changes */
    override val rules: StepRules = StepRules(),
    val speaker: Var<RichText, MemberContext>,
    val text: Var<RichText, MemberContext>,
    val duration: Var<Duration, MemberContext>,
    val options: List<Option>,
    val config: Configured<OptionDialogueConfiguration> = Configured(),
) : StepEntry

data class Chosen(val index: Int)   // chain record this entry produces

@TypewriterType(id = "...")
data class OptionDialogueConfiguration(
    val format: Var<
        (speaker: RichText, message: RichText, options: RichText, key: RichText) -> RichText,
        MemberContext,
    > = ...,
    val optionDelay: Var<Duration, MemberContext> = Var.Value(100.milliseconds),
)
```

### 2. Core chat

`HasChat` has two primitives. Everything else builds on them.

```kotlin
interface HasChat {
    fun send(message: RichText)         // through the server: a ChatHold blocks it
    fun sendPacket(message: RichText)   // wire.send: passes the wire handler, so nothing blocks it
}

data class ChatHold(@Key val who: Protagonist) : Hold   // no data: "this chat is held"

@TypewriterType(id = "...")
data class ChatSent(val player: Protagonist, val message: RichText) : Event

class ChatHistory(private val keep: Int = 100) : Runtime {
    private val lines = ConcurrentLinkedDeque<RichText>()   // written and read from worker threads
    val recent: List<RichText> get() = lines.toList()
    fun add(message: RichText) {
        lines.addLast(message)
        while (lines.size > keep) lines.pollFirst()
    }
}

// Pure helpers over the history, ported from legacy composeDarkMessage and resendMessages.
fun ChatHistory.over(screen: RichText): RichText    // blank lines, dark history, then the screen
fun ChatHistory.batches(): List<RichText>           // blank lines and all lines, split by packet size

@Handler fun ProtagonistJoined.history() = ChatHistory()
@Handler fun ChatSent.block(hold: ChatHold): Verdict = deny()
// Asking for Outcome also sees denied events, so blocked messages are recorded too.
@Handler fun ChatSent.record(history: ChatHistory, outcome: Outcome) = history.add(message)
// Fires only after the grace, and a next holder inside the grace keeps the same Hold.
@Handler fun Removed<ChatHold>.restore(chat: HasChat, history: ChatHistory) =
    history.batches().forEach(chat::sendPacket)
```

A step that only needs the chat quiet stops here:

```kotlin
@Derive fun Running<MinigameEntry>.quiet(who: Protagonist) = ChatHold(who)
```

### 3. The dialogue package

Shared by the dialogue kinds, not core. `doneAt` and `render` belong to dialogues, so a custom entry that holds the chat never sees them.

```kotlin
interface DialogueView : Live {
    val step: Step
    val who: Protagonist
    val doneAt: GameTick
    fun render(at: GameTick): RichText
}

// Exists only while animating, so the every tick handler has nothing to run otherwise.
data class Animating(
    @Key val step: Step,
    @Key val who: Protagonist,
    val view: DialogueView,
) : Live

@Derive fun DialogueView.animating() = Animating(step, who, this).takeIf { tick < doneAt }

fun HasChat.draw(view: DialogueView, history: ChatHistory) =
    sendPacket(history.over(view.render(tick)))

@Handler
fun <V : DialogueView> Added<V>.draw(chat: HasChat, history: ChatHistory) = chat.draw(value, history)

@Handler
fun <V : DialogueView> Changed<V>.draw(chat: HasChat, history: ChatHistory) = chat.draw(new, history)

@Handler
fun Tick<EveryTick>.animate(animating: Animating, chat: HasChat, history: ChatHistory) =
    chat.draw(animating.view, history)

@Handler
fun <V : DialogueView> Tick<EverySecond>.keep(view: V, chat: HasChat, history: ChatHistory) =
    chat.draw(view, history)
```

### 4. What the option dialogue asks for

Only a `Hold` from a `Running` clashes. `Live` values from a step never do.

```kotlin
data class ShownOptions(@Key val step: Step, @Key val who: Protagonist,
    val options: List<Int>) : Live
data class Selected(@Key val step: Step, @Key val who: Protagonist,
    val index: Int, val among: List<Int>) : Live
data class TypingSkipped(@Key val step: Step, @Key val who: Protagonist,
    val at: GameTick) : Live

data class OptionView(
    @Key override val step: Step,
    @Key override val who: Protagonist,
    val format: (RichText, RichText, RichText, RichText) -> RichText,
    val speaker: RichText,
    val text: RichText,
    val options: List<RichText>,
    val shown: List<Int>,
    val selected: Int,
    val key: ConfirmationKey?,
    val typingFrom: GameTick,
    val typedAt: GameTick,
    val optionDelay: Ticks,
) : DialogueView {
    override val doneAt get() = typedAt + optionDelay * min(4, options.size)

    override fun render(at: GameTick): RichText {
        val fraction =
            if (typedAt <= typingFrom) 1.0 else (at - typingFrom) / (typedAt - typingFrom)
        val count = ((at - typedAt) / optionDelay).toInt().coerceIn(0, 4)
        return format(speaker, text.typed(fraction), optionLines(options, selected, count),
            key?.label ?: RichText(""))
    }
}

// Holds: KSP gives holdTypes(entry) = { ChatHold, HotbarScrollHold }.
@Derive fun Running<OptionDialogueEntry>.chat(who: Protagonist) = ChatHold(who)
@Derive fun Running<OptionDialogueEntry>.wheel(who: Protagonist) = HotbarScrollHold(who)

// Live values.
@Derive
fun Running<OptionDialogueEntry>.shown(who: Protagonist, context: MemberContext) =
    ShownOptions(step, who, entry.options.indices.filter { entry.options[it].available(context) })

@Derive
fun Running<OptionDialogueEntry>.offer(who: Protagonist, clock: StepClock) =
    KeyOffer(who, step, preferred = null, since = clock.startedAt)

// A changed list resets the selection, as legacy does.
fun Selected?.indexIn(shown: ShownOptions): Int =
    this?.takeIf { it.among == shown.options }?.index ?: 0

@Derive
fun Running<OptionDialogueEntry>.view(
    who: Protagonist,
    speaker: RichText,        // the next three are Var fields of the entry
    text: RichText,
    duration: Duration,
    shown: ShownOptions,
    selected: Selected?,
    key: OfferedKey?,
    skipped: TypingSkipped?,
    clock: StepClock,
    context: MemberContext,
) = OptionView(
    step = step,
    who = who,
    format = entry.config.value.format(context),
    speaker = speaker,
    text = text,
    options = shown.options.map { entry.options[it].text(context) },
    shown = shown.options,
    selected = selected.indexIn(shown),
    key = key?.key,
    typingFrom = clock.startedAt,
    typedAt = skipped?.at ?: (clock.startedAt + typingTime(text, duration).toTicks()),
    optionDelay = entry.config.value.optionDelay(context).toTicks(),
)
```

Typing counts engine ticks ([interactions.md](interactions.md#steps)); the creator's durations convert at 20 ticks per second. Legacy used wall time (`PlayerSession.kt:61`).

`typed`, `typingTime`, and `optionLines` port legacy `asPartialFormattedMini`, `totalDuration`, and `formatOptions`.

### 5. The wheel

Only a step that uses the wheel holds it.

```kotlin
// Source: PlayerItemHeldEvent. Number keys fire it too, so it is not named "Scrolled".
@TypewriterType(id = "...")
data class HotbarSlotChanged(val player: Protagonist, val from: Int, val to: Int) : Event

val HotbarSlotChanged.distance: Int get() = loopingDistance(from, to, 8)

data class HotbarScrollHold(@Key val who: Protagonist) : Hold

@Handler fun HotbarSlotChanged.block(hold: HotbarScrollHold): Verdict = deny()

// Outcome: this handler also sees the denied event.
@Handler
fun HotbarSlotChanged.move(view: OptionView, outcome: Outcome): Selected? {
    if (view.shown.isEmpty()) return null
    val next = (view.selected + distance).mod(view.shown.size)
    return Selected(view.step, player, next, view.shown)
}

// A wand that is not a step: no Outcome, so it does not run while the wheel is held.
data class HeldWand(@Key val who: Protagonist, val power: Int) : Live
@Handler fun HotbarSlotChanged.adjust(wand: HeldWand) = ...
```

### 6. The key

Keys are offers, not holds. Several can exist, so a dialogue can run beside a scene's skip key. The newest takes presses, and the other gets the key back when the newest ends. A press needs an intent event here, because the offer names the step and the handlers do not care which key it was.

```kotlin
enum class ConfirmationKey(val label: RichText) {
    Jump(...), Sneak(...), SwapHands(...), LeftClick(...), RightClick(...),
}

@TypewriterType(id = "...")
data class ConfirmationConfiguration(val key: ConfirmationKey = ConfirmationKey.Sneak)

// Asked for by a step.
data class KeyOffer(@Key val who: Protagonist, @Key val step: Step,
    val preferred: ConfirmationKey?, val since: GameTick) : Live

// What a camera or a lock leaves usable.
data class KeysLeft(@Key val who: Protagonist, @Key val step: Step,
    val keys: Set<ConfirmationKey>) : Live
@Derive fun Running<CameraEntry>.keys(who: Protagonist) = KeysLeft(who, step, setOf(Jump, Sneak))

// The one answer per player. A Hold, but not from a Running, so it is not counted in clashes.
data class OfferedKey(@Key val who: Protagonist, val key: ConfirmationKey, val step: Step) : Hold

@Derive
fun KeyOffer.offered(
    all: List<KeyOffer>,            // who is filled from the receiver, step is free
    left: List<KeysLeft>,
    config: ConfirmationConfiguration,
): OfferedKey? {
    if (this != all.maxBy { it.since }) return null           // only the newest answers
    val usable = left.fold(ConfirmationKey.entries.toSet()) { keys, l -> keys intersect l.keys }
    val key = listOfNotNull(preferred, config.key).firstOrNull { it in usable }
        ?: usable.firstOrNull() ?: return null
    return OfferedKey(who, key, step)
}

@TypewriterType(id = "...")
data class KeyPressed(val player: Protagonist, val key: ConfirmationKey) : Event

@TypewriterType(id = "...")
data class Confirm(val who: Protagonist, val step: Step) : Event

@Handler
fun KeyPressed.take(offered: OfferedKey): Verdict =
    if (offered.key == key) deny { emit(Confirm(player, offered.step)) } else pass()

// Jump cannot be cancelled, so legacy weakens jump strength. A Hold adds a restore after a crash.
data class JumpLock(@Key val who: Protagonist) : Hold
data class JumpLocked(val locked: Boolean = true)
@Derive fun OfferedKey.jumpLock() = JumpLock(who).takeIf { key == ConfirmationKey.Jump }
@Handler fun TakeSnapshot<JumpLock>.none() = JumpLocked()
@Handler fun Added<JumpLock>.lock(jump: HasJumpStrength) = jump.lock()
@Handler fun RestoreSnapshot<JumpLock>.unlock(jump: HasJumpStrength) = jump.unlock()
```

| Key | Paper source | Can deny |
| --- | --- | --- |
| Jump | `PlayerInputEvent` | No, it is not cancellable, so `JumpLock` |
| Sneak | `PlayerInputEvent`, `PlayerToggleSneakEvent` joins | Through the toggle |
| SwapHands | `PlayerSwapHandItemsEvent` | Yes |
| Left and right click | `PlayerInteractEvent` | Yes |

Paper 26.2's `handlePlayerInput` fires `PlayerInputEvent` with no game mode check, so one source may replace legacy's two key listeners.

### 7. Choosing

```kotlin
// First press finishes the typing, the next one chooses.
@Handler
fun Confirm.skipTyping(view: OptionView): TypingSkipped? =
    if (tick < view.doneAt) TypingSkipped(step, who, tick) else null

@Handler
suspend fun Confirm.choose(running: Running<OptionDialogueEntry>, view: OptionView) {
    if (tick < view.doneAt || view.shown.isEmpty()) return
    val index = view.shown[view.selected]
    running.complete(
        links = listOf(running.entry, running.entry.options[index]),   // both, as legacy
        context = running.context.with(Chosen(index + 1)),             // 1 based, as legacy
    )
}

// No options for anyone: move on, as legacy.
data class NoOptions(@Key val step: Step) : Live

@Derive
fun Running<OptionDialogueEntry>.noOptions(shown: List<ShownOptions>) =
    NoOptions(step).takeIf { shown.isNotEmpty() && shown.all { it.options.isEmpty() } }

@Handler suspend fun Added<NoOptions>.next(running: Running<OptionDialogueEntry>) = running.complete()
```

### 8. The whole run

| Moment | What runs | Player sees |
| --- | --- | --- |
| Step starts | Derives give `ChatHold`, `HotbarScrollHold`, `KeyOffer`, `OfferedKey`, `OptionView`. `Added<V>.draw` | Dark history and the screen |
| Typing | `Animating` exists, so `animate` runs each tick | Text types, then options appear one by one |
| Typing done | `Animating` is gone, `keep` runs each second | Screen stays |
| Friend sends a message | `block` denies, `record` keeps it | Nothing yet |
| Scroll | `block` denies, `move` writes `Selected`, the view derive reruns, `Changed<V>.draw` | Slot stays, selection moves |
| Press | `take` emits `Confirm`, `choose` commits, then fires links | |
| Next dialogue in grace | Same `ChatHold` keys, so no `Removed`; its view draws | New screen, no flicker |
| Nothing follows | Grace ends, `Removed<ChatHold>.restore` | Chat back, with the friend's message |

## When things go differently

| Case | Result | Why |
| --- | --- | --- |
| Wand scroll during a spoken dialogue | Wand works | Spoken has no `wheel` derive, so `block` never runs |
| Wand scroll during an option dialogue | Selection moves, wand does not | `block` denies, so `adjust` does not run |
| Wand as a step that holds the wheel | Normal clash with the dialogue | Both return `HotbarScrollHold` |
| Right click while the key is Sneak | Normal click | `offered.key == key` is false |
| Scene skip plus dialogue | Both run, newest takes presses | `KeyOffer` is `Live`, and `offered` picks the newest |
| Camera starts during a dialogue | Key moves to Jump or Sneak, hint redraws | `KeysLeft` reruns `offered`; `key` is a parameter of `view` |
| An option becomes unavailable | Selection back to the first | `among` differs in `indexIn` |
| Press after the step ended | Nothing | The `Step` finds no `Running`, so the handler is skipped |
| Two group members press, `advance = Anyone` | First one chooses | The `CompleteStep` guard refuses the second |
| Two scrolls in one tick | One notch lost | `Selected` is written at tick end |
| Hold that wrote and blocked nothing ends | Chat redrawn anyway, looks the same | `restore` does not check, on purpose: no tracking |
| Dialogue with no animation | Redrawn once a second only | `doneAt` is in the past, so no `Animating` |

## The other kinds

| Kind | Holds | Key offer | Ends by |
| --- | --- | --- | --- |
| Spoken | `ChatHold` | Yes | `Confirm` |
| Option | `ChatHold`, `HotbarScrollHold` | Yes | `Confirm` |
| Action bar | `ActionBarHold` | Yes | `Confirm` |
| Timed | `ChatHold` | Only while skippable | Timer or `Confirm` |
| Input | `ChatHold`, `TypedInput` | No | Valid text |
| Message | None | No | At once |

```kotlin
// Timed: legacy holds a confirmation only while canSkip. An offer follows the same formula.
@Derive
fun Running<TimedDialogueEntry>.offer(who: Protagonist, canSkip: Boolean, clock: StepClock) =
    KeyOffer(who, step, null, clock.startedAt).takeIf { canSkip }

// Input: one holder, so no routing is needed. Raw event, hold, and a handler on the raw event.
data class TypedInput(@Key val who: Protagonist) : Hold
@Handler fun PlayerChatted.block(hold: TypedInput): Verdict = deny()
```

## What this removes

| Legacy | Now |
| --- | --- |
| `Confirmations`, its two stacks, `rebind` | The `offered` derive reruns by itself |
| `"no-index"` prefix, `ResendTokenRegistry` | `sendPacket` skips the wire handler |
| `startBlockingMessages`, `stopBlocking` | `ChatHold` exists or not |
| Jump modifier left behind by a crash | `RestoreSnapshot<JumpLock>` |
| `PlayerSession`'s single interaction slot | Any number of steps; only the same Hold type clashes |

## Not proven

Nothing compiled or ran. The key table comes from Paper 26.2 jar classes; spectator input was not run in game.

- **`tick` in a derive body.** `animating` must rerun each tick while typing. A derive that reads `tick` rerunning per tick is assumed.
- **Generic handlers over a `Live` interface** (`<V : DialogueView>`). Precedents use events and `Elapsed`.
- **One view per player.** `view: OptionView` has a free `step` key. One run only because `ChatHold` clashes.
- **Order at start.** The view may draw just before the Hold starts blocking.
- **`context.with(...)` and a configuration type as a derive parameter.** Both are new forms.
- **`ProtagonistJoined` as the creator of a `Runtime`.** No precedent, and its close is assumed.
- **Cost.** Every chat packet turns into `RichText` for the history, and `batches` needs a size estimate from text.
- **`Everyone` and `Leader`.** The existing `advance` rule is not drawn here; the code above is `Anyone`.
- **Not drawn.** Speaker sound, darkening of `RichText`, Bedrock forms (a candidate to leave out of the alpha).
