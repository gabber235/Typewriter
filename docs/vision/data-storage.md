# Data storage

## What it is

State storage managed by the **realm**, replacing legacy **facts**. Facts (number only values, each tied to a fact entry) are removed completely.

### Transactional writes

Many engines and hosts can write the same data at the same time:

1. A writer runs a **closure** that reads the current value and computes the new value.
2. It sends the expected current value and the new value to the realm.
3. The realm checks that the stored value still equals the expected value.
   - Equal: it stores the new value.
   - Different: it rejects the write and returns the current value.
4. The writer reruns its closure with the fresh value, until it succeeds.

Many writes to the same place can be **collapsed**: the closures run one after another locally, each on the previous result, and only the final result is sent with the original expected value.

### What data belongs to: identities

Data belongs to an **identity**: anything in Typewriter that is clearly identifiable.

| Identity | Example |
| --- | --- |
| Protagonist | One player |
| Group | A party or team |
| Entity | An NPC or display entity |
| Entry | A specific entry |
| Book instance | One instance of a book |
| Items | Possible, but probably not |

Identities can be **delegated**: `protagonist.group` resolves to the protagonist's group, while still remembering the original protagonist. The panel can later show where a value came from (for example, which protagonist wrote group data).

Because data is not tied to special entries, fact entries are no longer needed.

### Reading

Formulas read stored data directly.

Read syntax is `entry.variable(identity)`, with generated shortcuts such as `my_entry(my_group)` and `my_group.my_entry`. Example, a stored value from a quest extension: `dragon_quest.stage(group) == dragon_quest.stages.forge_sword` (see [formulas.md](formulas.md)).

**Only extensions define stored value blueprints**; creators never define them in the panel. A blueprint states which identities it needs and which type it stores. The exact shape is decided later.

### Blueprints and instances

| | Who makes it |
| --- | --- |
| **Blueprint** (definition: which identities, which type, how it behaves) | Always an **extension** |
| **Instance** (a concrete stored value) | Creators, by adding an entry in the panel; or extension code |

**Entry variables** are stored values tied to an entry. Interactive, dynamic content always uses these. For them, usually:

- The entry is one identity, plus others: `times_talked(protagonist)`, `friendship(ann, smith)`. Several identities, also of the same kind, are allowed.
- Many act on a **group** (a protagonist is a group of one), but that is not forced. Example blueprints: a *permanent group variable* (one value per group) and a *permanent variable* (one value shared by everything and everyone, on all servers).
- Other identities are possible, for example a Minecraft world or a region.

**Not every stored value is tied to an entry.** Extension code can also store **global data**, or data directly on a protagonist, group, or other identity, without an entry. Creators cannot create these; only extension code can.

**Extensions keep control:**

- They can **reject writes**. Example: a friendship extension refuses a friendship with yourself.
- An entry can hold **several internal stored values** that the extension keeps in sync. Example: a daily reward entry stores the value and the time it was first changed away from its default.

### Creator made values

Extensions offer **generic entry variable** blueprints that accept any type. The creator adds one in the panel, picks the type, and uses it:

```
entry "times_talked"   (generic stored value, type integer)
times_talked(protagonist) >= 3
```

- One generic **variable** entry: a name, **keys** (who it belongs to: protagonist, group, interaction, session, an NPC, a pair of protagonists, or none for global), a **type** (any type, not only numbers), and a default. It is still checked statically, because its type and keys become a real type.
- What legacy facts did with special lifetimes is now generic: lifetime follows the keys (an `interaction` keyed value is gone when the interaction ends, a `session` keyed value on logout), and behaviour comes from **reactions** an extension can add: on every write (cap, guard, history), some time after the first or last write (timed), on a schedule for all keys (weekly reset), or at a time computed from the value (cooldowns).

### When a shape changes

- **Developer defined stored types** (core and extensions) are Typewriter types with numbered revisions; the migrator converts their data between revisions (see [importer-and-migrator.md](importer-and-migrator.md)).
- **Creator defined shapes** (a variable's type or keys) are converted by a **migration**. Changing the shape of a variable that already has values shows a **conversion formula** from the old shape to the new one, as an ordinary field. Its default clears the values; the creator can replace it (`"${old} coins"`). The realm checks it against the stored values while editing, and runs it when the change is published, together with the new content. If it fails for any value, nothing changes and the publication shows the error. The same mechanism moves data when an instance key is renamed, or moves players off a removed quest stage.
- Renaming a variable keeps its data, and widening a type (`Int` to `Int?`) needs no conversion.

### Defaults

A stored value declares a **default**, returned before anything was written. The type may be nullable with `null` as default, but that is not forced.

```
dragon_quest.stage(bo)        -> find_scales (declared default)
```

### Book instances

Each book instance **duplicates its entries**, so every copy is a separate entry identity. Data tied to an entry is therefore automatically per instance:

```
dragon_quest@Riverside.stage(party1)   = forge_sword
dragon_quest@Hilltop.stage(party1)     = find_scales
```

Publication must keep references between entries correct across these duplicated identities (see [publication.md](publication.md)).

### Admin tools in the panel

Viewing and editing a protagonist's stored data in the panel, **also for offline protagonists**. One of the most requested features ever.

- Shows the value for the group the protagonist is in **right now**, and updates live when they change groups.
- For offline protagonists, the **last group** they were in is stored, so it works even when the server is offline.
- Editing in the panel acts **as if the protagonist wrote it**, so it goes to their current group (or their last group when offline).

### Freshness

Reads may be **slightly stale**. A formula re-evaluated on one engine may briefly see an older value than another engine just wrote. Writes themselves are safe through the transactional check.

## Who it serves

Content creators (state without fact bookkeeping), server owners with many engines (consistency), panel users inspecting state.

## Why

Facts were limited to numbers and to fact entries. Concurrent engines need safe shared state.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Facts removed | closed beta | settled |
| Realm managed transactional storage | closed beta | shaped |
| Write collapsing | closed beta | shaped |
| Identities, delegated identities | closed beta | shaped |
| Slightly stale reads accepted | closed beta | settled |
| Blueprints from extensions; instances from creators or code | closed beta | shaped |
| Entry variables with flexible identities | closed beta | shaped |
| Global and identity data without an entry, from extension code | closed beta | shaped |
| Write rejection by extensions | closed beta | shaped |
| Generic stored value entries with lifetime variants | closed beta | shaped |
| Declared defaults | closed beta | shaped |
| Per instance data through duplicated entries | closed beta | shaped |
| Panel view and edit, online and offline | closed beta (not at the start) | shaped |

## Open questions

- Exact shape of a stored value definition in an extension.
