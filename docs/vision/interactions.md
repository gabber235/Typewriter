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

Quests keep the idea of the legacy quest system (quests and objectives), rebuilt on the new primitives ([data storage](data-storage.md) and [expressions](expressions.md)).

### Running interactions across servers and sessions

Applies to engines in the same realm; data is not synchronized between realms.

- Whether a running interaction **follows a protagonist to another server** is configured **per interaction** by the creator in the panel. It can be turned off. A following interaction takes its chain's produced data along (see [expressions.md](expressions.md)).
- Running interactions are **stored**. What happens when a protagonist leaves and returns (resume, restart, or drop) is **decided by the creator** per interaction.

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

- A trigger from **inside** the running unit (for example clicking the same NPC again) is **forwarded** to it. Legacy Typewriter already forwards to the current dialogue instead of ignoring the click.
- A trigger from **another** interaction is a real clash.
- A unit that is **finishing and handing over** to the next needs its own handling.

#### What a unit is

**The unit is the flow of the chain.** Everything that flows from the start (for example a click on the smith: dialogue, option, forging cutscene, give item, closing dialogue, set quest stage) is **one unit** until the chain ends.

A unit is made of **steps**. A dialogue is a step of the interaction; so is a scene. Other kinds of steps, such as "search for something, then click it", are possible, but only as **explicit step types defined by an extension**, never implicitly. Steps can be interruptible or not on their own, without ending the whole unit.

#### Forwarding

- Forwarding applies only to **some trigger types**: NPC interaction, block interaction, and a few others. Not all, because that would block loops.
- **Unit membership is everything that could have taken part**, not only what ran. All entries that could have started or continued the unit since its inception belong to it. Reason: a stored value changed during the chain can make the same click route to a different entry; that must still count as the same unit instead of cancelling it.

| Situation | Result |
| --- | --- |
| Ann clicks the same NPC again | Forwarded to the running unit |
| Ann clicks a different NPC with its own dialogue | A different unit: a clash |
| A different NPC triggers entries that belong to the running unit | Continues the running unit |

#### Lanes

A **lane** is something an interaction occupies, so compatibility can be decided. Lanes are **fine grained**, and **extensions can introduce more**:

```
lanes (examples): camera | chat | action bar | title | subtitle | ...

dialogue step          occupies chat, action bar, title (it impedes all of them)
something else         may occupy only the title, or only the action bar
```

**Implicit by default.** What is occupied follows from what the content actually takes, **over time**. Example: a cutscene has a camera segment; while the camera runs, it occupies the camera and the lanes the camera blocks. When the camera segment ends, those lanes are **freed**, even though the cutscene continues, so something else can take them.

**Forced when needed.** A creator can explicitly make something occupy lanes for its **entire duration**.

**Clashes only happen on lanes.** Units that occupy no shared lane never clash: any number of NPCs can walk around, each its own unit. The clash rules (drop by default, replace, queue, protection) apply exactly when an incoming interaction needs a lane that is taken.

#### Bounds belong to the unit

Interaction bounds (for example "cannot walk away", "walking away ends it") are **part of the unit** and can **change over time**: first Ann cannot walk away, later walking away ends the interaction. The difference between **blocking** (Ann cannot walk away) and **interrupting** (walking away ends it) must be **explicit**; in legacy it was not.

**Outcomes:**

| Outcome | Status |
| --- | --- |
| Drop the incoming one | The default |
| Replace the running one | When the incoming one is more important |
| Queue the incoming one | Needed (see cases) |
| Pause and resume | **Not wanted** for clashes (unlike resuming after a protagonist rejoins, above). After a long interruption the protagonist may be elsewhere, and resuming a dialogue there is confusing |

**Protection:** an interaction (or part of it, for a period) can be marked **cannot be interrupted**. Even a more important incoming interaction then **queues** until the block resolves.

**Worked cases:**

| Case | Wanted outcome | Who knows |
| --- | --- | --- |
| Server wide dragon attack cutscene starts while Ann is in a story dialogue | Drop the dialogue (Ann can talk to the NPC again), unless it is marked uninterruptible; then the event queues for her. The incoming event may know what to do with what is running and what happens afterwards. Possibly server events should not force anything at all. **Unresolved** | Incoming, with protection from the running one |
| Server event starts while Ann is in a tutorial | The event should not start for her; joining afterwards would be nice | Running (protected) |
| Merchant's "talk when nearby" dialogue while Ann watches a tutorial cutscene | Drop the merchant dialogue | Priority: the tutorial is important, or the merchant is not |
| Reward cutscene right after a boss cutscene | Queue. Usually just chained in the same sequence, but queuing is needed when the second one is separate (for example a boss death animation spawned independently of the quest) | Incoming |
| Opening several loot crates quickly | Queue the crate animations one after another | Incoming |
| Clicking NPC B while in a dialogue with NPC A | Depends on the unit: same unit forwards, a different unit is a clash | The unit definition |

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
| Interaction unit = flow of the chain, made of steps | closed beta | shaped |
| Forwarding for some trigger types; membership = all entries that could take part | closed beta | shaped |
| Lanes: fine grained, extensible, implicit over time, forcible | closed beta | shaped |
| Bounds as part of the unit, changing over time; blocking vs interrupting explicit | closed beta | shaped |
| Clash outcomes: drop default, replace, queue; no pause | closed beta | sketch |
| Uninterruptible marking, whole or for a period | closed beta | sketch |

## Open questions

- How does a finishing unit hand over to the next?
- Which trigger types forward?
- Should server wide events force themselves on protagonists at all?
- Which additional concepts beyond priority are needed to express the clash cases?
