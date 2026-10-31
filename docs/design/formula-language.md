# Formula language

How formulas work: the field kind that holds them, how content tells the type system what it means, which names a formula can see, how formulas are checked while a creator types, and how and where they run.

Formulas are their own language with their own interpreter in the engine core. They are not the v1 portable expressions. Portable expressions encode operations the panel must perform; they have no roots, no members on types, and no per field context. Formulas never reuse the expression AST (`ExpressionNode`) or `PortableExpressionChecker`.

The product intent and full syntax tour live in [../vision/formulas.md](../vision/formulas.md). The primitives this builds on are in [overview.md](overview.md).

## Three ideas

A formula is built from three ideas:

- **Types**: every value has a catalog type.
- **Functions**: members and operators are plain functions. Their parameters are filled explicitly or from scope by type, with the same rule as handler parameters.
- **Scope**: typed named values. Lambdas and blocks stack more levels on top.

Sugar keeps formulas short: nothing in scope needs a prefix, and a call needs no parentheses when nothing is left to pass.

```
quest.coins >= 100 && protagonist.island.island_bank > 0
```

Formulas are side effect free. Conditions, text, verdicts and derives are pure. Update fields describe changes as values and the entry applies them (see [Changes fields](#changes-fields)).

## The Formula primitive in Kotlin

Extensions declare formulas in Kotlin; inputs may be stored values or other formulas. There is no separate derived value concept. A handler or derive reads a formula as a `Formula<T>` parameter and always sees the current value.

```kotlin
@Derive
fun AudienceEntry.inside(
    protagonist: Protagonist,
    parent: InAudience?,
    criterion: Formula<Boolean>,
): InAudience? = ...
```

Formulas stop propagating when their value is unchanged, and derives run only after all formulas have settled. Derives and their result kinds are in [stored-data.md](stored-data.md), [live-data.md](live-data.md) and [interactions.md](interactions.md).

## Var<T, C>: the one field kind

Every formula field on an entry or resource is `Var<T, C>`. `T` is the value type; `C` is the formula context (what the field's formulas can see). The field text is only the expression, never `amount = ...`.

```kotlin
@TypewriterType(...)
data class GiveCoinsActionEntry(
    val amount: Var<Int, MemberContext>,
    val message: Var<RichText, MemberContext>,
    override val triggers: List<Ref<Entry>>,
    override val changes: Var<Changes, InteractionContext>,
) : ActionEntry, Triggerable
```

What `T` is decides what the text may be:

| `T` | The text is | Example text |
| --- | --- | --- |
| A plain type (`Int`, `RichText`, a record) | An expression of that type | `quest.reward * 2` |
| A function type | The function body; the parameters are in scope. A constant ignores them | `protagonist.level * 10` or `12` |
| `Changes` | Change lines | `quest.coins += 50` |
| `Type` | A type expression | `Map<Ref<Npc>, Mood>?` |

Each field has a plain mode (the normal editor for `T`) and a formula mode (text). The panel toggles between them.

### Stored form

A `Var<T, C>` stores one of two forms:

```
Value(value)
Formula(source, form: Expression | Template)
```

When `T` has a `template` provider (see [Text templates](#text-templates)), its plain editor is a template editor that stores `Formula(source, Template)`, where `source` is the template body without quotes.

### Function typed fields

Function types are a catalog type, `FunctionTypeTemplate { parameters: [name, type], result }`, with any number of named parameters, named and default arguments, and an optional receiver. The receiver becomes a scope level inside the body.

A book variable of function type lets each instance supply a constant or a formula:

```
reward: (protagonist: Protagonist) -> Int
// instance A: 12
// instance B: protagonist.level * 10
```

The book then reads `book.reward`. Dot calls fill the first parameter for every function: `energy.current` is `current(energy)`.

### Type fields

A field holding a type is `Var<Type, TypeScope>`. Plain mode is a type picker: scalars, generics with argument slots, nullable, function types with named parameter rows and a result, and inline records with named field rows. Its list holds catalog types plus content types in scope (group identity types, creator types). Formula mode writes the type as text, parsed by the formula parser's type grammar and checked live:

```
(protagonist: Protagonist, town: Town) -> Int
Map<Ref<Npc>, Mood>?
```

### Changes fields

An update field is `Var<Changes, C>`. It holds several change lines that run in order; later reads see earlier pending changes. The formula only carries the changes; it writes nothing.

```
quest.coins += 50
quest.stage = forge_sword
if (quest.coins > 100) quest.rank = gold
group.members.forEach { it.reputation += 5 }
```

`Settable` members come from `stored()` declarations and their keys fill from scope. Change operators are plain stdlib provider functions; the operations they produce are in [stored-data.md](stored-data.md#change-operations).

Assigning inside a verdict or another pure field is a type error. Update fields may set and update stored values only, never world actions such as giving items; those stay explicit entries. The change operations, `apply()` transactions and the `Triggerable` trait are in [stored-data.md](stored-data.md).

## Formula contexts

A context is a plain Kotlin interface whose properties are the scope values a field gets. KSP turns `C` into the field's `scope` call. The code that evaluates the field (the entry's handler) passes an instance, with core helpers for core contexts:

```kotlin
interface InteractionContext { val group: Group; val chain: Chain }
interface MemberContext : InteractionContext { val protagonist: Protagonist }

interface ShopItemContext : MemberContext { val item: ShopItem }

val text = entry.text(memberContext(member))
```

Inheritance lets a formula written for a wider context fit a narrower one. `Var<T>` without a context gets only the surrounding scope.

Core defines every context. Capability modules define none: engine values are members on core types read from mirrors, and capability roots such as `minecraft` arrive as `scope` contributions. So contexts stay engine neutral. Extensions extend a core context.

| Context | Used by | Provides |
| --- | --- | --- |
| `InteractionContext` | Fields evaluated once per interaction | `group`, `chain` |
| `MemberContext` | Fields evaluated per member | `InteractionContext` plus `protagonist` |
| `PublishScope` | Fields evaluated by the realm at publish (book instances) | Pure values only |
| `TypeScope` | `Var<Type, TypeScope>` type fields | Pure values only; types in scope |
| `DefinitionScope` | A `Definition`'s value | The definition's surroundings |
| `ReactionScope<K, T>` | Variable reaction changes | `keys: K`, `value: Settable<T>`, `previous: T?` |
| `BookScope` | Open: no field uses it yet (book `instances` uses `PublishScope`) | Open |

In formulas the protagonist is named `protagonist`, matching the engine neutral identity.

### Group fields

The extension picks per field whether it is evaluated per member (`Var<String, MemberContext>`, `protagonist` in scope) or once per interaction (`Var<Int, InteractionContext>`, `group` in scope, no `protagonist`). The group's type comes from how the chain was widened, through `produces`:

| Widening | `group` type in scope |
| --- | --- |
| `ContinueForGroup(islands)` | `Island` |
| `ContinueForEveryone(who)` | `Snapshot` |
| None | No `group`; only `protagonist` |

Keys fill from scope by type, so `island_bank += 50` after `ContinueForEveryone` is a panel error, and `protagonist.island.island_bank += 50` is the explicit form. Groups and widening are in [interactions.md](interactions.md).

## dynamic(): what content means to the type system

Each resource and entry type has a `dynamic()` hook. It says what its content means to the type system, through these builders:

| Builder | Says |
| --- | --- |
| `bind(T) { }` | Derive a type parameter from content |
| `scope(target) { value(name, type) }` | What one own field's formulas (or my contents) can see |
| `exports { }` | What others get when they name me |
| `produces { field(...) }` | Content shaped chain context for downstream entries |
| `stored(name, keys, value, default)` | Stored data shapes, visible without an engine |

`dynamic()` does not declare which sources must run, derived relations, capability needs, or cross resource diagnostics.

### One form for code and content

Static Kotlin declarations compile through KSP to the same builder calls as generated defaults, so the realm sees one form:

- An entry's produced context becomes a default `produces { use(T) }`.
- A Kotlin `Stored` value with `@Key` fields becomes a generated `stored(...)` call. Creator blueprints (`Variable`) use the same builder.
- `Settable` members and readers such as `quest.stage(group)` are generated from `stored()`.
- Names come from types (fields, cases), `scope` and `stored`. Implementations come from static Kotlin functions:

```kotlin
fun <S : Enum> Quest<S>.progress(stage: S)
```

Content names such as quest stages are enums through `bind`.

### bind

`bind` derives a generic parameter from content. KSP generates a handle per type parameter. A bound parameter has no picker; an unbound one stays creator picked through `TypeSelection`. The realm reruns `dynamic()` on every edit and sets the configuration to the derived type; existing `ValueAdmission` flags book instances that no longer fit the derived `V`. The engine runs the same code at load. A derived type's id is (resource id, parameter name), with no revision. The generated book entry type is also a live `bind`, not a publish step.

```kotlin
bind(V) {
    for ((name, variable) in variables) {
        val type = variable.type.valueOrNull() ?: continue
        field(name, type, hasDefault = variable.default != null)
    }
}
```

`dynamic()` runs over a KSP generated content view of raw data, `XDraft`, never the real entry class. Each field is a value, missing, or invalid, so a broken field only drops its own members.

### scope and exports

Scope has two directions:

- **Inward**: `scope(target) { }` always aims at one own field (`scope(::text)`) or at my contents (`scope(contents)`), never at all fields.
- **Outward**: `exports { }`, for every resource. The generated default exports its fields, `stored()` values and bound types.

Which siblings a container makes visible is the container's own code, not a fixed realm rule. The book puts `book`, its elements by name and its imports into `scope(contents)`, and exports its variables per instance. Book scope, chain context (from upstream `produces`) and capability roots all arrive as `scope` contributions, while `C` stays the entry's own static scope.

## Lookup order

Names resolve innermost first:

1. Lambda levels
2. The context's values (`C`)
3. Element scope
4. Page
5. Book
6. Imports
7. Capability roots (`minecraft`)

### Names

Any name is allowed, Kotlin style. Identifier like names (Unicode letters, digits, `_`) are written bare; anything else uses backticks:

```
`Dragon Quest`.stage
```

`Element.name` is used directly. Variable, instance and import keys need only be non blank and unique per scope level. The realm records what each name in a formula resolved to (a resource id) and rewrites the formula text on rename, like an IDE refactor.

## Members and providers

Members on types come from code per type, like presentations: a KSP generated `XFormulaProvider`, loaded by `GeneratedProviderLoader`. Static members are plain Kotlin functions in it; the signature is the declaration and the parameters are its needs. Dynamic members come from content through `dynamic()`. Defaults are the fields.

```kotlin
// A capability declares its formula functions as an interface;
// each engine implements it (PaperPlayerFormulas), and KSP checks completeness.
class PaperPlayerFormulas : ... { ... }
```

Formula types are described with `TypeDefinition` (no id or revision).

### Standard library

The standard library is providers too (`Int.plus`, `List<T>.sumOf(f: (T) -> Int)`). It is generated from `operations.yaml` into a stdlib formula provider that calls the shared kernel through a mapping layer:

```kotlin
operator fun Int.plus(other: Int) = PortableKernel.numberAdd(this, other)
```

Units and formatting are ordinary providers through existing sugar (`5.seconds` is `val Int.seconds: Duration`, `format`). PlaceholderAPI is a provider function (`papi("player_level")`), backed by a `Tick` mirror where it is used.

## Book

A `Book` is a `Resource` (v1 `LibraryModel.kt`), not an entry. It carries the variables, the instances and the imports.

### Variables

`variables: Map<String, Type>` on the book, with key rules from the existing configuration system (`BookConfiguration`). Book variables hold per instance values and per instance functions.

### Instances

`Book<V : Record>` is generic and never names a concrete variables type. `V` is the record type the realm derives from `book.variables` through `bind`:

```kotlin
val instances: Var<Map<String, V>, PublishScope>
// Bounty board: BountyBoardVariables { town: Town; reward: (protagonist: Protagonist) -> Int }
```

Plain mode is the normal map editor whose values are real records (one field per variable, the right editor, checked by `ValueAdmission`). Formula mode generates the instances, so there is no separate formula field:

```
towns.associate { it.id to BountyBoardVariables(town = it) }
```

The map key is the instance key. Renaming an instance key moves its stored data through the book's migration ([migrations.md](migrations.md)).

### Imports

`imports` brings other books' exports into the book's contents scope. An import is `Import(book, alias: String? = null)`, named by the book title by default. An import exposes everything the other book exports.

## Definition

`Definition<T>` is a shared named value of any type, shared by all instances of a book:

```kotlin
data class Definition<T>(
    val name: String,
    val type: Var<Type, TypeScope>,
    val value: Var<T, DefinitionScope>,
) : StaticEntry
```

Its `dynamic()` does `bind(T) { use(type) }` and `exports { use(T) }`, so it is visible by name through the book's contents scope and to other books through imports.

- **Functions**: a definition whose type is a function type. The text is the body with the parameters in scope. There is no separate function entry type.

  ```
  Definition "is_veteran" type: (protagonist: Protagonist) -> Boolean
  value: protagonist.quests_done >= 10
  ```

- **Creator types**: a definition whose type is `Type`. Exported `Type` values become type names in scope; record types get a constructor.

  ```
  Definition "Energy" type: Type value: record { amount: Int, since: Instant }
  Energy(amount = 3, since = now)
  ```

Copy is a plain generated function (Kotlin data class `copy`; for creator records produced like the constructor, parameters defaulting to current values).

## Unions and errors

There is no error specific mechanism. Unions are the existing catalog subtyping: an abstract record type plus `parents` on its subtypes (Kotlin sealed interfaces, creator `Type` definitions). Values carry their concrete type (`NamedValue.actual_type`), so `is`, smart casts and `when` narrow. The polymorphic editor and `concreteForms` already handle them.

```kotlin
sealed interface NpcLocation
data class Spawned(val position: Position) : NpcLocation
data class NotSpawned(val npc: Ref<Npc>) : NpcLocation
```

```
when (npc.location) {
    is Spawned(position) -> position.distance(protagonist.position) < 10
    is NotSpawned -> false
}
```

- Unrelated types are wrapped; there is no ad hoc `A | B`.
- An unhandled union is a panel type error with quick fixes. `when` is exhaustive against the current catalog, and live checks flag it when a new subtype appears.
- `T?` stays the catalog nullable; `?.` and `?:` work on null.
- Several return values are named results, an inline record: `(gold: Int, xp: Int)`, read with `let (gold, xp) = ...`.

### Exceptions

A provider that throws, or hitting the recursion limit, fails one evaluation:

| Field kind | On failure |
| --- | --- |
| Text | Shows a fallback |
| Verdicts and conditions | Count as not met |
| `Changes` | Not applied |

## Type checking

Checking is local and bidirectional, as in Kotlin, Swift and TypeScript:

- The field's `Var<T>` pushes the expected type down into the formula. Function typed fields check their body against the result type with the parameters in scope.
- Expressions infer their type up: `let needed = 5 - x` is `Int`.
- Generics are solved per call from the arguments plus the expected type; lambda parameters come from the function's parameter types.

There is no global inference, so errors stay local. Annotations are optional: `let x: Decimal = ...`. Checking runs as `check(formula)` in the query graph and is part of the engine core formula interpreter that the realm and engines share.

## Live editing

### Query graph

The realm runs `dynamic()` and formula checks as a query graph with early cutoff, like rust-analyzer's Salsa:

```
draft(resource) → dynamic(resource) outputs → scopeAt(field) → check(formula)
```

- Reads inside `dynamic()` (`ref.resolve()`, field reads) are recorded automatically.
- An edit reruns only what read the change.
- A rerun whose output equals the previous one stops propagation.
- Cycles (A binds from B's exports, B from A's) are detected while running: both get an error and an error type; everything else keeps working.

The engine runs every `dynamic()` once at load, in dependency order, with the same code and no tracking.

### WatchFormula

The panel edits formulas language server style. The realm answers per keystroke through a subscription that follows the existing search pattern (`search.skir`: a retained job, a snapshot stream, replaced on each query):

```
WatchFormula(location: ValueLocation, text, cursor)
  streams FormulaSnapshot { diagnostics, result_type: TypeUse, completions, hover }
```

Snapshots are computed by `scopeAt` and `check` over the unapplied text. There is one checker, in Kotlin. The panel stays thin and may filter the last completion list locally while the next snapshot arrives.

### Formula checks

Formula findings go through the existing `RealmCheckProvider` and are computed through the query graph. Errors block publication: type errors (unhandled union kinds, non exhaustive `when`), formulas that need engine or stored data in realm run fields, keys not fillable from scope, and `dynamic()` cycles. The full checks list is in [live-data.md](live-data.md).

## Syntax summary

The base is Kotlin. The full tour, with examples, is in [../vision/formulas.md](../vision/formulas.md). Summary:

| Area | Rule |
| --- | --- |
| Control flow | Every construct is an expression (`if`, `when`, blocks); a block's value is its last line |
| Conditionals | `if (c) a else b` and the ternary `c ? a : b`; `?.` and `?:` stay single tokens |
| Bindings | `let`, `if let`, `let else`; Rust style shadowing (a new `let` hides the old one from its line on, the type may change) |
| Patterns | Destructuring and guards in `when`: `is Money(amount) if amount > 100 ->` |
| Shorthand | `members.filter(.is_veteran).sumOf(.coins)` |
| Collections | `[riverside, hilltop]`, `[sword: 50]`, `10..49`, `in`; indexing returns nullable |
| Calls | Named and default arguments, trailing lambdas, `with` as a plain stdlib function |
| Functions | Local functions `let double(x: Int) = x * 2` (recursion works); lambdas `{ x -> }`, `it`, `_`, `{ (k, v) -> }` |
| Comparisons | Chained `0 < x < 10`; `==` is structural only |
| Logic | `&&`, `\|\|`, `!` plus `and`, `or`, `not` |
| Change lines | `=`, `+=`, `-=`, `*=`, `?=` (set if absent), `require(cond, msg)` |
| Loops | None; ranges, `map`, `forEach` (returns all changes in change fields), `fold` |
| Literals | Raw strings `"""..."""`; numbers `1_000`, `0.5`, `1e3`, typed by context |
| Lines | A newline ends a line; `;` optional; comments `//`, `/* */`, doc comments `///` shown in autocomplete and hover |
| Not included | `!!`, `x with { }` |

Keywords: `let`, `if`, `else`, `when`, `is`, `in`, `as?`, `and`, `or`, `not`, `true`, `false`, `null`.

## Text templates

A string template is sugar for a function call, and the expected type picks which `template` provider applies:

```
"a${x}b"   means   template(listOf("a", x.interpolate(), "b"))
"${coins:#,###}"   means   coins.format("#,###").interpolate()
```

- The stdlib provides `template` for `String`; the Minecraft capability provides it for `RichText` (MiniMessage).
- `interpolate()` providers decide how a value enters text. `RichText` escapes tags by default, so player input cannot inject tags; `RichText.interpolate()` keeps them. Types can render richly (`Item.interpolate()` with hover).
- The template editor highlights holes, renders MiniMessage, and runs `WatchFormula` inside holes.

Entry authors only declare the field:

```kotlin
val text: Var<RichText, MemberContext>
```

Text the protagonist sees is live: a display derive reads it, so it follows stored data and hot publish.

## Where formulas run

The same rule as handlers: the types a function touches decide its kind.

| Kind | Touches | Can run on |
| --- | --- | --- |
| Pure | Plain values, content | Realm and engines |
| Stored | Stored values | Anywhere stored data is reachable |
| Live | Live traits such as `Player` | The engine where the subject is live |

KSP reads the kind from Kotlin signatures. A formula's kind is the strongest kind it calls, computed by the realm while typing. A field says where it runs through its context: `Var<Map<String, V>, PublishScope>` and `Var<Type, TypeScope>` accept pure formulas only; `Var<String, MemberContext>` accepts anything. The realm can evaluate formulas that need no engine type.

### Interpreter

The formula interpreter lives in the engine core and is shared by the realm and engines: it parses text, binds names, runs, and caches outcomes. How evaluation records its reads, which change signal each read kind has, and the `FormulaChanged` event are in [live-data.md](live-data.md#formula-changes).

## Time and randomness

- `now` is fixed per evaluation. In a `Changes` field it is the realm commit time.
- `random(...)` is seeded by (interaction, entry, field), so reruns give the same result and a new interaction rolls again. A fresh roll on purpose is stored through a `Changes` field.
- Random is pure for a given seed, so the realm can preview it.

## Formula starts

A formula can start a chain: when a condition turns true, or whenever a formula's output changes. Both use `FormulaChanged<T>` ([live-data.md](live-data.md#formula-changes)).

## Open

- What `BookScope` provides and which fields use it. The book's `instances` field uses `PublishScope`.
- The roadmap survey found no Kotlin `PortableKernel` (only the panel's Dart kernel); the generated stdlib needs a Kotlin kernel or another target.
- `XDraft` modeling of invalid values: confirmed by the roadmap survey (`Availability`), but its fit for `dynamic()` is not yet verified in code.
- Provider override details: whether a same name function replaces a generated member and how `hidden` hides one.
- Instances as identities (book, key), formula instances evaluated at publish, and placed generated book entries as instances are proposed, not decided.
- Where cross resource diagnostics from `dynamic()` are produced.
- Editor design for function type parameters in the panel.
- Live formula values per protagonist in the panel (vision item) have no design yet.
