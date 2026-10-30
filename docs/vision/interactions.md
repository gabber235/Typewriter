# Interactions

## What it is

How Typewriter content runs for protagonists: what it covers, what starts it, and how running experiences behave.

### Scope

Typewriter serves all of these:

| Kind | Examples |
| --- | --- |
| Story | Dialogue, quests, scenes, NPC conversations |
| Server systems | Shops, ranks, tutorials, onboarding, region rules, rewards, daily tasks |
| Minigames and events | Races, boss fights, server wide events, synchronized shows |
| World behaviour | Timed changes, NPC routines, ambient effects, without a specific protagonist |

### What starts things

Creators can configure all of these starts:

| Start | Examples |
| --- | --- |
| Protagonist actions | Click, enter a region, break a block, chat, join |
| State changes | A stored value changes; a formula becomes true |
| Time | Schedules and delays |
| Outside world | The panel, a website, Discord, another server, an API call |

### Controlling Minecraft rules

Content can fully **allow, deny, or change** what a protagonist does in Minecraft (break, place, move, chat, and more), per protagonist and through formulas. A denied action can still start something else, for example cancel a block break and start a dialogue.

When content disagrees about a rule (book A denies breaking blocks in a region, book B allows breaking ore there), creators set a **priority**; the higher priority wins.

### Priority

- Priority is **inherited** down the content tree: a book's priority applies to its pages, and a page's to its entries.
- Any lower level can **override** it.
- The same priority is used for rule conflicts and for clashing interactions (below).

### Quests are not interactions

Two different things:

| | Quest | Interaction |
| --- | --- | --- |
| Examples | Quests, objectives | Scenes, dialogues, possibly more |
| Nature | Deterministic state, derived from formulas over stored data | A running experience with a beginning and an end |
| Across servers | Follows automatically, because stored data is synchronized by the realm | Configurable per interaction |

Quests keep the idea of the legacy quest system (quests and objectives), rebuilt on the new primitives ([data storage](data-storage.md) and [formulas](formulas.md)).

### Running interactions across servers and sessions

Applies to engines in the same realm; data is not synchronized between realms.

- A **server move** is a leave and a rejoin: the same per step choice applies (drop, restart the step, or restart the interaction), so there is no separate "follow" setting. Restarted steps keep their chain's produced data.
- Running interactions are **stored**. What happens when a protagonist leaves and returns is **decided by the creator** per step: each step entry says drop, restart the step, or restart the interaction, and the strictest running step wins. A group interaction only pauses when every member is gone; a member who returns while it runs rejoins it.

### Several interactions at once

A protagonist can be in several interactions at once when they are **compatible**. Compatibility depends on the type of interaction and what it uses:

| Combination | Compatible? | Why |
| --- | --- | --- |
| Two scenes that both control the camera | No | Only one camera |
| A scene with a camera and a scene that only moves an NPC | Yes | No shared resource |
| A scene without dialogue and an open dialogue | Yes | The dialogue stays |
| Two spoken dialogues | No | They overlap |
| Two action bar dialogues | No | They overlap |

### When interactions clash

**Prerequisite: the interaction as one coherent unit.** Before clashes can be handled, Typewriter needs a way to define an **interaction chain**: everything that belongs together as one unit, even though several units can run at once and parts of them can be interrupted. Then:

- A trigger from **inside** the running interaction (for example clicking the same NPC again) is **forwarded** to it. Legacy Typewriter already forwards to the current dialogue instead of ignoring the click.
- A trigger from **another** interaction is a real clash.
- An interaction that is **finishing and handing over** to the next needs its own handling.

#### What an interaction is

**The interaction is the flow of the chain.** An interaction starts when a start fires into an entry that is not part of a running interaction, and it ends when no step runs and nothing is pending in any branch. Everything that flows from the start (for example a click on the smith: dialogue, option, forging cutscene, give item, closing dialogue, set quest stage) is **one interaction** until the chain ends.

An interaction is made of **steps**. A dialogue is a step of the interaction; so is a scene. Other kinds of steps, such as "search for something, then click it", are possible, but only as **explicit step types defined by an extension**, never implicitly. Steps can be interruptible or not on their own, without ending the whole interaction. Steps are what **takes time** (a dialogue, a scene, a delay); instant entries such as giving an item run inside the interaction without being a step.

#### Forwarding

- Forwarding applies only to **some trigger types**: NPC interaction, block interaction, and a few others. Not all, because that would block loops. **The trigger type declares it** (its extension marks it forwardable), so creators never configure it.
- **Interaction membership is everything that could have taken part**, not only what ran. Publication computes it: every entry reachable from the start through links, also across book edges. All entries that could have started or continued the interaction since its inception belong to it. Reason: a stored value changed during the chain can make the same click route to a different entry; that must still count as the same interaction instead of cancelling it.

| Situation | Result |
| --- | --- |
| Ann clicks the same NPC again | Forwarded to the running interaction |
| Ann clicks a different NPC with its own dialogue | A different interaction: a clash |
| A different NPC triggers entries that belong to the running interaction | Continues the running interaction |

#### Holds (formerly "lanes")

What an interaction occupies is a **hold**: a live change it makes to a protagonist, such as controlling the camera, taking the chat, or showing a title. **Each kind of hold is its own type**, and that type is what used to be called a lane. Holds are **fine grained**, and **extensions can introduce more** by defining new hold types.

```
hold types (examples): camera | chat | action bar | title | subtitle | ...

dialogue step          holds chat, action bar, title (several holds at once)
something else         may hold only the title, or only the action bar
```

**Implicit by default.** Holds follow from what the content actually does, **over time**. Example: a cutscene has a camera segment; while the camera runs, it holds the camera. When the camera segment ends, the hold is **released**, even though the cutscene continues, so something else can take it.

**Known before it starts.** Publication knows which hold types each step can produce, so a clash is decided **before** a step starts, and a **check** can report it as a diagnostic in the panel.

**Forced when needed.** A creator can explicitly keep a hold for a step's or interaction's **entire duration**.

**Clashes only happen on holds.** Interactions that need no shared hold type never clash: any number of NPCs can walk around, each its own interaction. The clash rules (drop by default, replace, queue, protection) apply **at every step start**, exactly when a step needs a hold type that another interaction has.

**Handover without restore.** When a hold is no longer needed, its release waits a **short grace** (a few ticks, about half a second by default). If an equal hold appears for the same protagonist within the grace, from the same interaction or another one, it **takes over** the hold, and nothing is restored in between. Two camera scenes back to back, or a choice inside a scene that picks the next scene, are therefore invisible cuts without flicker.

**What a hold restores is changeable.** A hold remembers what to restore (for example where the protagonist stood). Content can change that, so after a camera scene the protagonist lands at a new place with **one** teleport, instead of being sent back first.

#### Bounds belong to the interaction

Interaction bounds (for example "cannot walk away", "walking away ends it") are **part of the interaction** and can **change over time**: first Ann cannot walk away, later walking away ends the interaction. The difference between **blocking** (Ann cannot walk away) and **interrupting** (walking away ends it) must be **explicit**; in legacy it was not.

**Outcomes:**

| Outcome | Status |
| --- | --- |
| Drop the incoming one | The default |
| Replace the running one | When the incoming one is more important |
| Queue the incoming one | Needed (see cases) |
| Pause and resume | **Not wanted** for clashes (unlike resuming after a protagonist rejoins, above). After a long interruption the protagonist may be elsewhere, and resuming a dialogue there is confusing |

**Who declares what:** the incoming interaction declares its outcome (drop by default, replace, or queue). The running one declares protection. Replace only wins against lower priority; against protection it queues. **Replacing ends the whole running interaction**, so it can simply be started again. A queued interaction gives up when a **formula** says so (for example after waiting 10 seconds, or when the protagonist left the arena), or when its book stops applying. Server wide events are normal interactions: the creator chooses per event whether it forces itself, queues, or skips busy protagonists.

**Protection:** an interaction (or part of it, for a period) can be marked **cannot be interrupted**. Even a more important incoming interaction then **queues** until the block resolves.

**Worked cases:**

| Case | Wanted outcome | Who knows |
| --- | --- | --- |
| Server wide dragon attack cutscene starts while Ann is in a story dialogue | Drop the dialogue (Ann can talk to the NPC again), unless it is marked uninterruptible; then the event queues for her. The incoming event may know what to do with what is running and what happens afterwards. Possibly server events should not force anything at all. **Unresolved** | Incoming, with protection from the running one |
| Server event starts while Ann is in a tutorial | The event should not start for her; joining afterwards would be nice | Running (protected) |
| Merchant's "talk when nearby" dialogue while Ann watches a tutorial cutscene | Drop the merchant dialogue | Priority: the tutorial is important, or the merchant is not |
| Reward cutscene right after a boss cutscene | Queue. Usually just chained in the same sequence, but queuing is needed when the second one is separate (for example a boss death animation spawned independently of the quest) | Incoming |
| Opening several loot crates quickly | Queue the crate animations one after another | Incoming |
| Clicking NPC B while in a dialogue with NPC A | Depends on the interaction: same interaction forwards, a different interaction is a clash | The interaction definition |

These are hard. They may need **additional concepts** beyond priority.

## Who it serves

Content creators (one toolset for stories, systems, games, and world behaviour), protagonists, server owners.

## Why

Typewriter's value is personalized, composable interactions. They must cover the whole server experience, not only story content, and behave predictably across servers.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Scope: story, systems, minigames, world behaviour | closed beta | shaped |
| Starts: protagonist actions, state changes | closed beta | shaped |
| Starts: time, outside world | later | shaped |
| Full control of Minecraft rules | closed beta | shaped |
| Quests as formula derived state (when legacy entries are moved over) | closed beta | shaped |
| Interaction follows protagonist, per interaction | closed beta | shaped |
| Running interactions stored; creator decides resume, restart, or drop | closed beta | shaped |
| Several interactions at once when compatible | closed beta | shaped |
| Inherited priority with overrides | closed beta | shaped |
| Interaction = flow of the chain, made of steps | closed beta | shaped |
| Forwarding for some trigger types; membership = all entries that could take part | closed beta | shaped |
| Holds (formerly lanes): one type per kind, extensible, implicit over time, forcible, known at publication | closed beta | shaped |
| Handover through a short grace; restore target changeable | closed beta | shaped |
| Bounds as part of the interaction, changing over time; blocking vs interrupting explicit | closed beta | shaped |
| Clash outcomes: drop default, replace, queue; no pause | closed beta | sketch |
| Uninterruptible marking, whole or for a period | closed beta | sketch |

## Open questions

- Which additional concepts beyond priority are needed to express the clash cases?
