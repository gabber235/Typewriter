# Content model

## What it is

How content is shaped and organized. Typewriter content is **configuration through a visual editor**, not visual scripting.

### Pages

The **flexible page system** gives pages different types for different purposes. Each page type is drawn on a **fundamental layout**.

| Fundamental layout | Status | Used for |
| --- | --- | --- |
| Graph | exists | Entries as nodes with links |
| Timeline | exists | Timed content |
| Canvas | future (with resource pack work) | 2D layouts where things are placed |

| Page type | Purpose |
| --- | --- |
| Sequence page | Graphs where triggers link to actions (legacy trigger and action graphs). Sequences act upon protagonists and things |
| Scene page | Scenes (formerly cinematics): timed interactions on a timeline |
| Manifest page | Manifest entries: what a protagonist has or sees based on state |
| Static page | Static entries: definitions others reference |
| More later | New page types, each with new entry types |

Planned future page types:

- **Looping scene**: plays in the world, loops, and has no primary protagonist that it blocks. Legacy looping cinematics have this awkwardly; it gets its own page type.
- **Canvas pages**: lay out things on a 2D surface. Examples:
  - an inventory layout
  - drawings or content rendered onto a Minecraft map
  - Minecraft's native dialogs (buttons and custom elements), not Typewriter's dialogue system
  - screens built with resource packs

### Entries

**Entries** are the basic unit of content. Some legacy kinds stay, some get renamed:

| Kind | Meaning |
| --- | --- |
| Trigger | Starts things |
| Action | Does things |
| Manifest | What a protagonist has or sees based on state, like legacy audiences. A base kind; audience entries are one subtype |
| Static | Reference based definitions. They never act on their own: any number of static entries changes nothing in the world or for a protagonist |
| Cue, keyframe, scene entries | Timed parts of scenes |
| New kinds | Come with new page types |

### Context and links between entries

A big change: **which kinds of context can be linked to each other** becomes explicit.

- Legacy triggers implicitly carried a player. That is no longer assumed.
- A trigger can be about the **world**, with no protagonist. From there, a protagonist can be obtained through a formula.
- An entry can **convert** one context into another, for example from a world trigger into a protagonist sequence.
- By default, linking entries with different context requires such a conversion.
- Link context and formula context are **the same concept** (see [expressions.md](expressions.md)). Whatever a formula can work with can also flow along links.
- **Extensions can add their own context kinds** (for example a region or a match context for a minigame), with conversions to and from them.

### Organizational units

| Unit | Role |
| --- | --- |
| Book | Top level unit; has instances, edges, conditions, priority |
| Chapter | Groups pages inside a book, like folders |
| Page | Holds entries; has a type |
| Tag | Labels content across books, for search, filters, and selecting content (for example when sending content to a production realm) |

Like entries, they can use **formulas** wherever useful (see [expressions.md](expressions.md)).

### Book instances

- A book has one instance by default, with no variables.
- A book can declare a list of **variables**. Every instance must define all of them.
- During publication, each instance **duplicates all its children**, all the way down.
- Formulas inside the book read the variables of the instance they belong to.
- With one instance, variables act as globals for the book; adding more instances is easy.

Example: a "Bounty board" book with variable `town`, and instances for Riverside and Hilltop.

**Where instances come from:**

| Source | Example |
| --- | --- |
| Creator by hand | Add Riverside and Hilltop in the panel and fill in `town` |
| Using the book | Wiring the book's generated entry somewhere creates an instance for that use |
| From data | One instance per item in a list or formula, for example one per town |

**Variables are typed fields.** A book variable uses the same two field types as entry fields (see [expressions.md](expressions.md#two-field-types)):

| Variable type | Instance fills in |
| --- | --- |
| `Var<T, CONTEXT>` | A plain value of `T` (text, number, location, entry reference, ...), or a formula producing `T` using what `CONTEXT` makes available (player, book, `minecraft`, ...) |
| `Formula` | Always a formula: a function with parameters and return types |

```
Book: Dragon quest
  town:   Var<text, ...>                    Riverside: "Riverside"   Hilltop: "Hilltop"
  reward: Formula (player) -> integer       Riverside: 50            Hilltop: player.level * 10
```

The book author declares the signature; every instance's formula must fit it.

Using `reward` inside the book:

```
amount = book.reward                 player in context: passed implicitly
amount = book.reward(player)         same, explicit
group in context: book.reward        error, which player?
group.map { book.reward }            ok, map puts a player in context
```

**Stored data is per instance automatically.** A book instance is an identity (see [data-storage.md](data-storage.md)), so progress in the Riverside bounty board is separate from Hilltop.

### Links between books

- Entries can link to each other across pages within a book.
- By default, entries **cannot** link across books.
- To connect books, a book declares typed **incoming edges** and **outgoing edges**. They are black boxes wired to something else:
  - An incoming edge says "I am triggered by something of this type".
  - An outgoing edge says "I trigger something of this type".
- From a book's edges, publication generates an **entry type** on the fly:
  - Outgoing edges become fields on the generated entry.
  - The incoming edge decides what can trigger it.
  - With several instances, there is one such entry per instance, or one wiring to all instances.
- A generated entry can expose undefined book variables as fields to fill in, like any entry.

A generated entry type is **scoped** by the same rule as creator defined functions: its book marks it `public` or `book`, and other books import it to use it (see [expressions.md](expressions.md)). This scoping is nice to have and dropped if very difficult.

This makes a set of entries reusable as **one new entry type**, similar to a function, built inside Typewriter without code. Each use creates its own book instance.

### Conditional books

A book can be applied to a protagonist conditionally, through a boolean formula (what replaces legacy criteria). Example: a book applies only when a formula holds **and** the protagonist has the book's resource pack loaded (see [resource-packs.md](resource-packs.md)).

```
Book: Dragon quest
  condition: player.level >= 10 && player.has_resource_pack(dragon_pack)

Ann (level 12, pack loaded)  -> applies
Bo  (level 4)                -> does not apply
```

**When a book does not apply, its content acts as if it does not exist** for that protagonist:

| Content | For Bo |
| --- | --- |
| Triggers (click the smith NPC) | Do not fire |
| Manifest entries (visible NPC, quest in sidebar) | Not shown |
| Rule control (deny breaking blocks in a region) | Does not apply to him |
| Stored data (his progress) | Kept, unused |

- **The condition turns false mid interaction:** the running interaction from that book **stops right away**.
- **Groups are filtered.** When a group meets a conditional book, the group is narrowed to the members the book applies to. Example: Ann (applies) and Bo (does not) enter the dragon cave as a party; the cutscene plays for Ann alone, and Bo sees nothing.
- **Content without a protagonist** (a world trigger such as "every day at 18:00") **always runs**; the condition does not apply to it.
- **Per instance:** the condition can use book variables, so each instance applies to different protagonists: `player.town == book.town`.
- **Books only.** Chapters and pages have no conditions. The book is the boundary: nothing outside it can reach in except through edges, so a protagonist outside the book simply never triggers its content. Inside a book, pages reference each other freely, so a page condition would make no sense.

### Groups as the trigger unit

Entries are triggered for a **group of protagonists**, not one by one. A group can contain one protagonist, and groups allow synchronized experiences for many protagonists at once.

Groups come in two forms, and both are wanted:

- **Lasting groups** (a party, a team) with their own identity and stored data (see [data-storage.md](data-storage.md)).
- **Ad hoc groups**: whoever a trigger is for right now (for example everyone in a region).

## Who it serves

Content creators (reuse, composition), marketplace sellers (sellable, tweakable books), protagonists (personalized and shared experiences).

## Why

Reuse and composition without code: books behave like functions with parameters, and instances let one design serve many places.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Graph and timeline layouts; sequence, scene, manifest, static pages | closed beta | shaped |
| Explicit context on links, world triggers, context conversion | closed beta | shaped |
| Link context is the same concept as formula context | closed beta | shaped |
| Context kinds from extensions | closed beta? | shaped |
| Looping scene page | later | sketch |
| Canvas layout and canvas pages (with resource packs) | later | sketch |
| Manifest entries | closed beta | shaped |
| Formulas on organizational units | closed beta | shaped |
| Book instances and variables | closed beta | shaped |
| Edges between books, generated entry types | closed beta | shaped |
| Conditional books | closed beta | shaped (work started) |
| Non applying content acts as absent; running interactions stop | closed beta | shaped |
| Conditions per instance using book variables | closed beta | shaped |
| Groups filtered to members the book applies to | closed beta | shaped |
| Conditions only on books, not chapters or pages | closed beta | settled |
| Groups as the trigger unit | closed beta | shaped |

## Open questions

- None yet.

