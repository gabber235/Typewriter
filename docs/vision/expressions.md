# Expressions

## What it is

A formula language (DSL) that **fully replaces** these legacy systems:

| Legacy system | Replaced by |
| --- | --- |
| Criteria (fact equals value lists) | Boolean formulas |
| Dynamic variables | Formulas in entry fields |
| Read only facts | Formulas reading any value |
| Interaction context | Formula context |

Creators write formulas as **typed text** in the panel.

### Three primitives

Everything in the language is built from three things:

| Primitive | Meaning |
| --- | --- |
| **Types** | What kind of value something is |
| **Context** | What is available to a formula to start from |
| **Functions** | Everything else. Operators such as `>=` are syntactic sugar for functions |

All types and functions can be built **dynamically** from these.

### Core properties

- **Side effect free.** A formula never changes state; changes happen only through explicit entries.
- **Typed values.** Example: `player.health` returns an integer.
- **Everywhere.** Most entry fields can be a formula. Organizational units (books, chapters, pages, tags) can use formulas too.

### Context

A formula's context is **everything it can use**: the player, the book, `minecraft`, and more. It is not one single type. Context is **statically defined**: the realm knows exactly what is available in each formula field. Contexts must be very flexible.

| Context | Example |
| --- | --- |
| Who the content runs for | A protagonist or a group |
| What happened | The start: `block.type == diamond_ore` when a block is broken |
| Interaction context | This entry, previous entries in the sequence, data from other entries (which can contain more) |
| The book instance | `book.reward` |
| Game data | `minecraft.block.diamond_ore` (only where the Minecraft capability is present) |

Data can still be **passed from one entry to the next** in a sequence. A formula reads it **through the entry that produced it**:

```
[on block break] --> [spawn guard] --> [send message]

send message text:
  "A guard appeared at ${on_block_break.block?.location}. Talk to ${spawn_guard.npc.name}."
```

| Expression | Kind | Nullable? |
| --- | --- | --- |
| `on_block_break.block` | **Produced** data: exists only when that entry ran earlier in this chain | Yes, always |
| `spawn_guard.npc` | A **field** on the entry: a reference to another entry, followed automatically | No, if the field is mandatory |
| `spawn_guard.npc.name` | A field on the referenced entry | No, if `npc` is mandatory |

Produced data being nullable also covers branches that join: a path that did not pass the producing entry simply has no value.

- **Produced data is declared by extensions**, always.
- **It lives as long as the chain.** When a running interaction follows a protagonist to another server, its chain's produced data moves with it. Once the chain has finished its last task, the data is gone. To keep it longer, an entry writes it to stored data (see [data-storage.md](data-storage.md)), which is a different thing.
- This is the role of the legacy **interaction context** (`InteractionContext` in `engine/engine-core`: values keyed by entry and key, plus global keys such as the random seed). The idea stays; the execution should be better.

Formula context and the context that flows along links between entries are **the same concept** (see [content-model.md](content-model.md)). Extensions can add their own context kinds.

### Functions are dynamic

While the available context is fixed, the **functions** on things are determined dynamically:

- Identities (book instances, NPCs, other identities) get functions declared on them. Example: an NPC instance entry gives position data.
- An entry can declare "if you have this, you can call this function". A function with no other parameters reads like a property.
- **Functions can come from an entry's field values.** Example: an entry defines a map of quest stages; the system then offers each stage, so a creator can ask "is this stored value at this quest stage?"
- Stored data (see [data-storage.md](data-storage.md)) is read **directly**, as `entry.variable(identity)`: the entry name, a dot, and the name of the stored variable on that entry. Entry types can get generated shortcuts: a player variable entry reads as `my_entry.value(my_group)`, as `my_entry(my_group)`, or with receiver sugar as `my_group.my_entry`. Only extensions define stored value blueprints (never creators); instances come from creators or extension code. The entry's own fields (with generated members) are separate:

  ```
  dragon_quest.stage(group) == dragon_quest.stages.forge_sword
  ```

  | Part | Meaning |
  | --- | --- |
  | `dragon_quest.stage(group)` | Stored value, synchronized by the realm, for this group |
  | `dragon_quest.stages.forge_sword` | A field on the entry; its members are generated from the values the creator entered |

  A formula can only use identities in its context: with only a player in context, `group` is an error.
- Extensions, capabilities, the realm, and engines also contribute functions, even while the realm runs and content is being edited.

### Two field types

| | `Var<T, CONTEXT>` | `Formula` |
| --- | --- | --- |
| Use | Normal entry fields (the legacy `var`) | Fields that are always a formula |
| Generic | Value type `T`, and `CONTEXT`: everything available to the formula (for example the player, the book, the `minecraft` root), not a single type | None |
| Panel | Shows the editor for `T`; header toggle switches to a formula | Always a formula field |
| Holds | A plain `T`, or a formula producing `T` | A function: parameters and return types |
| Returns | One `T` | Possibly several values, like Go |

**The signature is declared.** Whoever declares a `Formula` field (an extension for entry fields, the book author for book variables) declares its parameters and return types. Every formula filled in must fit it:

```
reward: Formula (player) -> integer
  Riverside: 50                    ok, ignores player
  Hilltop:   player.level * 10     ok
  Hilltop:   "fifty"               error in the panel: must return integer
```

**`Formula` in the realm:** the realm does not run it. It **inspects** it: which parameter types it needs and what it returns. This feeds outference and suggestions in the panel. A formula whose types do not fit a use does not show up as a suggestion, or shows an error where it is used (for example at `book.reward`).

**`Formula` on the engine:** it has a `run` operation. The caller must provide everything it needs; content can wire those inputs up from other things.

### Field context is chosen by the extension

Typewriter only guarantees that each field gets the correct context. What an entry does with it is up to the **extension developer** who declared the entry. The entry's context and its fields' contexts can differ.

Example: a "give money" action triggered for a group. `amount` is a normal field, so it uses `Var`, with the context the extension chose:

```kotlin
class GiveMoneyActionEntry(
    // ... default needed fields
    val amount: Var<Int, PlayerContext>,
) : ActionEntry
```

```
amount: Var<Int, PlayerContext>
  amount = 50                       plain value
  amount = book.reward              formula, player in context
  the extension iterates the group's members and evaluates amount per player

amount: Var<Int, GroupContext>
  amount = group.members.sumOf { book.reward }
  the extension decides what one amount for a group means
```

### Implicit context arguments

A function parameter can be filled **implicitly from context**, or passed explicitly. Example: `book.reward` and `book.reward(player)` are the same when a player is in context. With a group in context there is no single player, so it must be explicit, or used inside something that brings a player into context, like `group.map { book.reward }`.

### Lists and lambdas

Formulas work with lists and maps, including small inline functions:

```
group.members.all { it.health > 5 }
quest.stages.count
```

### Functions as values

Functions are values. A function can take functions as parameters and return them, and creators can write lambdas anywhere a function is expected. This is needed for most real use.

```
group.members.filter { it.isVeteran }
```

**Receiver sugar** applies here: `isVeteran(it)` is written `it.isVeteran`, and inside `sumOf { book.reward }` the call `book.reward(it)` is written `book.reward`, because the lambda's parameter fills the first parameter.

### Borrow the best syntax

The language should take the best syntactic sugar and general features from mainstream and functional programming languages, so common things read nicely.

### Creator defined functions

Creators define named, reusable functions in a **`Formula` field on an entry**. Parameter types are always declared:

```
fun isVeteran(player: Player) = player.playtime > 100.hours

amount = group.members.filter { it.isVeteran }.sumOf { book.reward }
```

**Scope: visibility plus imports.** Nice to have; if it turns out to be very difficult, it will not be done. The same rule applies to a book's generated entry types (see [content-model.md](content-model.md)).

- The **definition** says whether it may be used outside its book (`public`) or only inside it (`book`), like Kotlin visibility.
- A book **imports** what it wants to use from other books, so pickers and suggestions stay small.

```
Book: Utilities       fun isVeteran(player: Player) ...   public
Book: Bounty board    generated entry type                public
Book: Dragon quest    uses Utilities, Bounty board
  -> isVeteran(player) and a "Bounty board" entry are available here
```

When the defining book has several instances, the caller **picks the instance**: `utilities@Riverside.isVeteran(player)` (example syntax only; likely to change).

### Errors and exceptions

Two different things, like errors and panics in Rust:

| | Error | Exception |
| --- | --- | --- |
| How | A **value**, part of the type | Thrown at runtime |
| When | Most failures (missing NPC, unset stored value) | Rare; a much bigger problem |
| Who handles it | The type system; the panel makes the creator handle it | Runtime |

Creators get several ways to handle errors, taken from Kotlin, Rust, and functional languages:

```
// fallback
dragon_npc.location?.distance(player.location) ?: 999

// match on the error type
when (val loc = dragon_npc.location) {
  is NotSpawned -> false
  else          -> loc.distance(player.location) < 20
}

// Rust style `if let` and `let else` are also wanted
```

### Look and feel

Formulas read **Kotlin-like**:

```
player.health < 5 && dragon_quest.stage(player.group) >= 3

group.members.all { it.health > 5 }

when (player.level) {
  in 0..9   -> "Novice"
  in 10..49 -> "Adventurer"
  else      -> "Hero"
}

player.title ?: "Stranger"
```

**Multi line formulas with local names** are allowed; the last expression is the result of the field. `when` works as an expression and replaces long if else chains:

```
let scales = dragon_quest.scales_found(player.group)
let needed = 5 - scales
if (needed <= 0) "Go to the dragon!" else "Find $needed more scales."
```

**No special literals in the language.** Durations, positions, game ids, and entry references are not built into the language. They are ordinary types and data driven members:

| Need | Comes from | Style |
| --- | --- | --- |
| Durations | Types from core or extensions | Kotlin style, for example `5.seconds` |
| Coordinates, vectors | Types | Ordinary values |
| Items, blocks, sounds | A `minecraft` root in context, generated from game data. Ordinary context: present in fields under the Minecraft capability, absent elsewhere (for example a future Hytale engine) | For example `minecraft.block.diamond_ore` |
| Entry references | Data driven members, like everything else | |

Members are defined by the core engine, extensions, or engine capabilities. The realm runs the type information and linting, so the panel knows what is possible, what each formula produces, and what will error. Values are computed on the engine during execution.

**String interpolation** works in formula mode: `"Find $needed more scales."`, `"Hello ${player.name}"`.

### Type checking direction: outference

Formulas carry no type annotations. The direction is **type outference** rather than classic type inference: the realm decides whether a formula is type consistent without having to infer every missing type. Reference: Ross Tate, [Type-Outference with Label-Listeners](https://dl.acm.org/doi/10.1145/3763797) (OOPSLA 2025), and his KotlinConf 2025 talk "Designing Kotlin Beyond Type Inference".

### Fields in the panel

A field shows its **normal editor** by default (a field can have its own UI layout). A small toggle in the field header switches it to a **formula field**, and back. This works like legacy variables.

### Syntax direction

The exact syntax is decided later. Known intent:

- A function's first argument can be an **extension receiver**: `health(player)` can be written `player.health`.
- A function with no other parameters needs no brackets.
- Chaining must be easy.

### Formulas as starts

**Any formula** can be a start ("when this becomes true"), whatever it reads.

A formula itself only answers one question: **run it, what is the value?** That value can be cached. Everything else (for which protagonists it is checked, whether it fires once when it turns true or while it is true, how changes are noticed) is decided by **where the formula is used**, by the extension that declared the field and its context.

Evaluation must be smart:

- Typewriter knows which parts of a formula changed and recomputes only those.
- If nothing a formula depends on changed, the old result is reused.

This is about execution on engines, not editing in the panel.

### Time and randomness

Both are allowed.

- A formula that reads the current time states that it must **always be recomputed**. This loses some optimization, not all of it.
- Randomness **may be seeded**, but does not have to be. With a seed, the same seed always gives the same result. Seeding from something with an identity (for example the current interaction) makes a random value stable for that interaction.

### Several return values

A `Formula` can return several values; callers receive them **like in Go**.

### Recursion

Recursion is allowed, with a **recursion limit**.

### Creator defined types

Creators defining their own types (records, enums) would be useful, but may be too difficult. It is out of scope if so.

### Live formula values

Seeing the value of a formula **right now for a specific protagonist**, in the panel. Needs communication between the panel and engines, and knowing which panel account belongs to which Minecraft account. The same system is needed when content capture is redone (see [panel.md](panel.md)).

Far future, only if needed for speed: compile formulas to bytecode, or JIT. Not in the closed beta, probably not in any beta.

## Who it serves

Content creators (one consistent way to compute values and conditions), extension and engine developers (one way to expose data).

## Why

The variable system is complex and unpleasant to use. One expressive language built from three primitives replaces several special mechanisms.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Replaces criteria, variables, read only facts, interaction context (required) | closed beta | shaped |
| Typed text authoring | closed beta | settled |
| Types, context, functions as the only primitives | closed beta | shaped |
| Side effect free | closed beta | settled |
| Statically known context per formula field | closed beta | settled |
| Dynamic functions, including from entry field values | closed beta | shaped |
| Direct reads of stored data | closed beta | shaped |
| Time and seeded randomness | closed beta | shaped |
| Several return values, Go style | closed beta | shaped |
| Recursion with a limit | closed beta | shaped |
| Creator defined types (may be out of scope) | ? | wish |
| Live formula values per protagonist in the panel | closed beta (not at the start) | sketch |
| Any formula as a start, with smart recomputation | closed beta | shaped |
| Lists, maps, lambdas | closed beta | shaped |
| Functions as values (higher order functions) | closed beta | shaped |
| Best of breed syntactic sugar | closed beta? | sketch |
| Creator defined functions | closed beta | shaped |
| Scope: visibility on the definition plus imports (nice to have; dropped if very difficult) | closed beta? | wish |
| Errors as values, rare exceptions | closed beta | shaped |
| Compiled or JIT formulas | someday | wish |
| Kotlin-like look and feel | closed beta | shaped |
| String interpolation | closed beta | settled |
| Type outference, no annotations | closed beta? | sketch |
| Let blocks, multi line formulas | closed beta | shaped |
| No special literals; registries and units as data driven members | closed beta | shaped |
| Normal field with a formula toggle | closed beta | settled |
| `Var<T, CONTEXT>` and `Formula` field types | closed beta | shaped |
| Concrete syntax details | closed beta | open |

## Open questions

- This area needs much more detail later; much of it is still loose.

