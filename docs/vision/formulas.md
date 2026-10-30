# Formulas

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

- **Side effect free.** A formula never changes state. An update field's formula **returns changes** (`coins += 50`); the entry applies them. World actions (giving items) stay explicit entries.
- **Typed values.** Example: `protagonist.health` returns an integer.
- **Everywhere.** Most entry fields can be a formula. Organizational units (books, chapters, pages, tags) can use formulas too.

### Context

A formula's context is **everything it can use**: the protagonist, the book, `minecraft`, and more. It is not one single type. Context is **statically defined**: the realm knows exactly what is available in each formula field. Contexts must be very flexible.

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

| Formula | Kind | Nullable? |
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
- Stored data (see [data-storage.md](data-storage.md)) is read **directly**, as `entry.variable(identity)`: the entry name, a dot, and the name of the stored variable on that entry. Entry types can get generated shortcuts: a protagonist variable entry reads as `my_entry.value(my_group)`, as `my_entry(my_group)`, or with receiver sugar as `my_group.my_entry`. Only extensions define stored value blueprints (never creators); instances come from creators or extension code. The entry's own fields (with generated members) are separate:

  ```
  dragon_quest.stage(group) == dragon_quest.stages.forge_sword
  ```

  | Part | Meaning |
  | --- | --- |
  | `dragon_quest.stage(group)` | Stored value, synchronized by the realm, for this group |
  | `dragon_quest.stages.forge_sword` | A field on the entry; its members are generated from the values the creator entered |

  A formula can only use identities in its context: with only a protagonist in context, `group` is an error.
- Extensions, capabilities, the realm, and engines also contribute functions, even while the realm runs and content is being edited.

### One field type: the value type decides

Every formula field is `Var<T, CONTEXT>`: `T` is the value type, `CONTEXT` is what the field itself provides (for example the protagonist). The panel shows the normal editor for `T`; a header toggle switches to a formula. The field text is only the expression.

**What `T` is decides what the text may be:**

| `T` | Text | Example |
| --- | --- | --- |
| A plain type | An expression | `protagonist.level * 10` |
| A function type | The **body**; parameters are in scope. A constant ignores them | `reward: (protagonist: Player) -> Int`: Riverside `50`, Hilltop `protagonist.level * 10` |
| `Changes` | Several lines of changes, run in order | `quest.coins += 50` then `if (quest.coins > 100) quest.rank = gold` |
| `Type` | A type | `(protagonist: Player, town: Town) -> Int` |

A formula that does not fit `T` is an error in the panel (`"fifty"` where an integer is expected).

**Where a formula can run** follows from what it reads: only values and content (the realm can run it, for example at publish), stored data, or live engine values (only the engine). A field that runs on the realm rejects formulas that need the engine.

### Field context is chosen by the extension

Typewriter only guarantees that each field gets the correct context. What an entry does with it is up to the **extension developer** who declared the entry. The entry's context and its fields' contexts can differ.

Example: a "give money" action triggered for a group. `amount` is a normal field, so it uses `Var`, with the context the extension chose:

```kotlin
class GiveMoneyActionEntry(
    // ... default needed fields
    val amount: Var<Int, MemberContext>,
) : ActionEntry
```

```
amount: Var<Int, MemberContext>
  amount = 50                       plain value
  amount = book.reward              formula, protagonist in context
  the extension iterates the group's members and evaluates amount per protagonist

amount: Var<Int, InteractionContext>
  amount = group.members.sumOf { book.reward }
  the extension decides what one amount for a group means
```

### Implicit context arguments

A function parameter can be filled **implicitly from context**, or passed explicitly. Example: `book.reward` and `book.reward(protagonist)` are the same when a protagonist is in context. With a group in context there is no single protagonist, so it must be explicit, or used inside something that brings a protagonist into context, like `group.map { book.reward }`.

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

### Creator defined functions and values

A **definition** is a static entry with a name, a type, and a value, shared by everything in the book. A function is a definition whose type is a function type:

```
Definition "is_veteran"   type: (protagonist: Player) -> Boolean
  value: protagonist.playtime > 100.hours

amount = group.members.filter { it.is_veteran }.sumOf { book.reward }
```

Book variables have the same shape, but **each instance fills them in** (see [content-model.md](content-model.md)). Use a definition for logic that is the same everywhere, a book variable for what differs per instance.

**Imports.** A book imports other books it wants to use, so pickers and suggestions stay small. An import may get a short local name. Everything a book exports is usable by importers (no visibility levels for now).

```
Book: Utilities       Definition is_veteran
Book: Bounty board    instances riverside, hilltop
Book: Dragon quest    imports Utilities, Bounty board as bounty
  -> `Utilities`.is_veteran(protagonist), bounty.riverside.reward, and a "Bounty board" entry are available here
```

When the imported book has several instances, the caller **picks the instance like a field**: `bounty.riverside.reward`. With one instance it is left out.

**Names** can be anything. Names that look like identifiers (Unicode letters included) are written bare; others go in backticks: `` `Dragon Quest`.stage ``. Renaming something rewrites the formulas that use it.

### Unions, errors, and exceptions

There is no special error mechanism. A value that can be one of several things is a **union**: a type with several kinds, like a Kotlin sealed interface. A failure is just one kind:

```
blacksmith.location      Spawned(position) or NotSpawned(npc)

when (val loc = blacksmith.location) {
  is Spawned    -> loc.position.distance(protagonist.location) < 20
  is NotSpawned -> false
}
```

- Extensions declare unions in code; creators declare them with type definitions.
- The panel makes the creator handle every kind; a kind added later shows up as an error where it is not handled.
- `null` stays for "absent": `protagonist.title ?: "Stranger"`.
- Rust style `if let` and `let else` are wished for with the syntax decision.

**Exceptions** are rare (broken extension code, recursion limit). They fail one evaluation: text shows a fallback, conditions count as not met, and changes are not applied.

### Look and feel

Formulas read **Kotlin-like**:

```
protagonist.health < 5 && dragon_quest.stage(protagonist.group) >= 3

group.members.all { it.health > 5 }

when (protagonist.level) {
  in 0..9   -> "Novice"
  in 10..49 -> "Adventurer"
  else      -> "Hero"
}

protagonist.title ?: "Stranger"
```

**Multi line formulas with local names** are allowed; the last expression is the result of the field. `when` works as an expression and replaces long if else chains:

```
let scales = dragon_quest.scales_found(protagonist.group)
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

**String interpolation** works in formula mode: `"Find $needed more scales."`, `"Hello ${protagonist.name}"`.

### Type checking

Formulas carry no type annotations (they are allowed where they help). Types flow inside one formula: the field says what it expects, names in scope and functions say what they give, and generic functions are solved per call. There is no global guessing, so errors stay local and readable ("expected integer, got text"). Reference for later refinements: Ross Tate, [Type-Outference with Label-Listeners](https://dl.acm.org/doi/10.1145/3763797) (OOPSLA 2025).

### Fields in the panel

A field shows its **normal editor** by default (a field can have its own UI layout). A small toggle in the field header switches it to a **formula field**, and back. This works like legacy variables.

### Syntax

Kotlin is the base, with additions that make content formulas short and safe:

```
protagonist.level > 10 ? "Hero" : "Novice"                    ternary; if and when are expressions too
if (let quest = protagonist.active_quest) quest.name else "No quest"
when (reward) { is Money(amount) if amount > 100 -> "Big payday"; is Item(item) -> item.name }
members.filter(.is_veteran).sumOf(.coins)                      member shorthand
town in [riverside, hilltop]                                   collection literals
give(sword, amount = 3)                                        named and default arguments
let price = price * 0.8                                        shadowing instead of mutation
let double(x: Int) = x * 2                                     local functions
0 < reputation < 10                                            chained comparisons
is_veteran and level > 10                                      and, or, not as readable aliases
```

- A function's first argument can be written as a receiver (`player.health` is `health(player)`), and a function with nothing left to pass needs no brackets.
- No loops: ranges and list functions (`(1..5).map { it * 10 }`).
- No `!!`: absent values are handled explicitly.
- Text fields are templates in their normal editor: `<gold>Welcome back, ${protagonist.name}!</gold>`, with formatting `${coins:#,###}`. Values put into rich text are escaped, so player input cannot inject tags.

### Formulas as starts

**Any formula** can be a start ("when this becomes true"), whatever it reads.

Besides "becomes true", a start can fire **whenever a formula's value changes**, with the **old and new value**.

A formula itself only answers one question: **run it, what is the value?** That value can be cached. Everything else (for which protagonists it is checked, whether it fires once when it turns true or while it is true, how changes are noticed) is decided by **where the formula is used**, by the extension that declared the field and its context.

Evaluation must be smart:

- Typewriter knows which parts of a formula changed and recomputes only those.
- If nothing a formula depends on changed, the old result is reused.

This is about execution on engines, not editing in the panel.

### Time and randomness

Both are allowed.

- A formula that reads the current time states that it must **always be recomputed**. This loses some optimization, not all of it.
- Randomness is **seeded by where it runs** (the interaction, the entry, and the field), so recomputing gives the same result and a new interaction rolls again. A fresh roll on purpose is stored through an update field.
- In an update field, `now` is the moment the changes are committed.

### Several return values

A function can return several named values, read like a record or unpacked: `let (gold, xp) = split_reward(100)`.

### Recursion

Recursion is allowed, with a **recursion limit**.

### Creator defined types

Creators define their own types with a definition whose type is `Type`: `Definition "Energy" type: Type value: record { amount: Int, since: Instant }`. The type then appears in every type picker in the book and gets a constructor: `Energy(amount = 3, since = now)`.

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
| Time and randomness seeded by where it runs | closed beta | shaped |
| Several named return values | closed beta | shaped |
| Recursion with a limit | closed beta | shaped |
| Creator defined types (definitions of type `Type`) | closed beta | shaped |
| Live formula values per protagonist in the panel | closed beta (not at the start) | sketch |
| Any formula as a start (becomes true, or value changed with old and new), with smart recomputation | closed beta | shaped |
| Lists, maps, lambdas | closed beta | shaped |
| Functions as values (higher order functions) | closed beta | shaped |
| Best of breed syntactic sugar | closed beta? | sketch |
| Creator definitions (shared values and functions) | closed beta | shaped |
| Imports with optional local names; no visibility levels for now | closed beta? | shaped |
| Unions (errors are one kind), rare exceptions | closed beta | shaped |
| Compiled or JIT formulas | someday | wish |
| Kotlin-like look and feel | closed beta | shaped |
| String interpolation | closed beta | settled |
| Local type checking, no annotations needed | closed beta | shaped |
| Let blocks, multi line formulas | closed beta | shaped |
| No special literals; registries and units as data driven members | closed beta | shaped |
| Normal field with a formula toggle | closed beta | settled |
| One field type `Var<T, CONTEXT>`; the value type decides (function body, changes, type) | closed beta | shaped |
| Concrete syntax (Kotlin base, ternary, if let, patterns, member shorthand, collection literals, named arguments, shadowing, text templates) | closed beta | shaped |

## Open questions

- This area needs much more detail later; much of it is still loose.

